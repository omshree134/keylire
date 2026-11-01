// Keylire cloud proxy. The phone never sees UPSTREAM_KEY.
//
//   POST /v1/token     { app_user_id }            -> { token, expires_at }
//   POST /v1/complete  (Bearer token) see below    -> { json, usage }

export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    if (req.method !== "POST") return text(405, "method not allowed");
    try {
      if (url.pathname === "/v1/token") return await issueToken(req, env);
      if (url.pathname === "/v1/complete") return await complete(req, env);
      return text(404, "not found");
    } catch (e) {
      return text(500, `worker error: ${e.message}`);
    }
  },
};

// ------------------------------------------------------------------ token

async function issueToken(req, env) {
  const { app_user_id } = await req.json().catch(() => ({}));
  if (!app_user_id || typeof app_user_id !== "string") return text(400, "app_user_id required");

  const rc = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(app_user_id)}`,
    { headers: { Authorization: `Bearer ${env.RC_SECRET_KEY}` } },
  );
  if (!rc.ok) return text(403, "could not verify subscription");
  const info = await rc.json();
  const ent = info?.subscriber?.entitlements?.[env.RC_ENTITLEMENT];
  const active = ent && (!ent.expires_date || new Date(ent.expires_date) > new Date());
  if (!active) return text(403, "no active premium entitlement");

  const ttl = Number(env.TOKEN_TTL_SECONDS || 86400);
  const exp = Math.floor(Date.now() / 1000) + ttl;
  const token = await signJwt({ sub: app_user_id, exp }, env.JWT_SECRET);
  return json(200, { token, expires_at: exp });
}

// --------------------------------------------------------------- complete

async function complete(req, env) {
  const auth = req.headers.get("authorization") || "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7) : null;
  if (!token) return text(401, "missing token");
  const claims = await verifyJwt(token, env.JWT_SECRET);
  if (!claims) return text(401, "invalid or expired token");
  const uid = claims.sub;

  const body = await req.json().catch(() => null);
  if (!body || !["text", "vision"].includes(body.kind)) return text(400, "bad body");
  if (typeof body.system !== "string" || typeof body.prompt !== "string") return text(400, "system/prompt required");
  if (body.kind === "vision" && typeof body.image !== "string") return text(400, "image required");
  if (body.kind === "vision" && body.image.length > 6_000_000) return text(413, "image too large");

  // ---- metering (per user, per calendar month)
  const month = new Date().toISOString().slice(0, 7);
  const key = `usage:${uid}:${month}:${body.kind}`;
  const used = Number((await env.USAGE.get(key)) || 0);
  const cap = Number(body.kind === "vision" ? env.CAP_VISION : env.CAP_TEXT);
  if (used >= cap) return text(402, `monthly ${body.kind} quota used`);

  // ---- upstream call (OpenAI-compatible, JSON mode)
  const messages = [{ role: "system", content: body.system }];
  if (body.kind === "text") {
    messages.push({ role: "user", content: body.prompt });
  } else {
    messages.push({
      role: "user",
      content: [
        { type: "text", text: body.prompt },
        { type: "image_url", image_url: { url: `data:${body.media_type || "image/jpeg"};base64,${body.image}` } },
      ],
    });
  }

  const up = await fetch(env.UPSTREAM_URL, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${env.UPSTREAM_KEY}` },
    body: JSON.stringify({
      model: body.kind === "vision" ? env.VISION_MODEL : env.TEXT_MODEL,
      temperature: clamp(body.temperature ?? 0.3, 0, 1),
      max_tokens: clamp(body.max_tokens ?? 1500, 64, 4000),
      response_format: { type: "json_object" },
      messages,
    }),
  });

  if (up.status === 429 || up.status >= 500) return text(429, "upstream busy");
  if (!up.ok) return text(502, `upstream ${up.status}`);

  const data = await up.json();
  const content = data?.choices?.[0]?.message?.content ?? "";
  const parsed = parseJsonLoose(content);
  if (!parsed) return text(502, "upstream returned non-JSON");

  await env.USAGE.put(key, String(used + 1), { expirationTtl: 40 * 86400 });

  return json(200, {
    json: parsed,
    usage: {
      input_tokens: data?.usage?.prompt_tokens ?? 0,
      output_tokens: data?.usage?.completion_tokens ?? 0,
      month_used: used + 1,
      month_cap: cap,
    },
  });
}

// ---------------------------------------------------------------- helpers

function parseJsonLoose(s) {
  let t = String(s).trim();
  if (t.startsWith("```")) t = t.replace(/^```(json)?\s*/, "").replace(/```$/, "");
  const a = t.indexOf("{"), b = t.lastIndexOf("}");
  if (a < 0 || b < a) return null;
  try { return JSON.parse(t.slice(a, b + 1)); } catch { return null; }
}

const clamp = (n, lo, hi) => Math.min(hi, Math.max(lo, Number(n)));
const text = (status, s) => new Response(s, { status, headers: { "content-type": "text/plain" } });
const json = (status, o) => new Response(JSON.stringify(o), { status, headers: { "content-type": "application/json" } });

// Minimal HS256 JWT. Enough for a first-party client; swap for a library
// if you ever need rotation or multiple keys.
const b64u = (buf) => btoa(String.fromCharCode(...new Uint8Array(buf))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const b64uStr = (s) => b64u(new TextEncoder().encode(s));
const fromB64u = (s) => Uint8Array.from(atob(s.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(s.length / 4) * 4, "=")), (c) => c.charCodeAt(0));

async function hmacKey(secret, usage) {
  return crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, [usage]);
}

async function signJwt(payload, secret) {
  const head = b64uStr(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const body = b64uStr(JSON.stringify(payload));
  const sig = await crypto.subtle.sign("HMAC", await hmacKey(secret, "sign"), new TextEncoder().encode(`${head}.${body}`));
  return `${head}.${body}.${b64u(sig)}`;
}

async function verifyJwt(token, secret) {
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  const ok = await crypto.subtle.verify("HMAC", await hmacKey(secret, "verify"), fromB64u(parts[2]), new TextEncoder().encode(`${parts[0]}.${parts[1]}`));
  if (!ok) return null;
  try {
    const claims = JSON.parse(new TextDecoder().decode(fromB64u(parts[1])));
    if (!claims.exp || claims.exp < Math.floor(Date.now() / 1000)) return null;
    return claims;
  } catch { return null; }
}

