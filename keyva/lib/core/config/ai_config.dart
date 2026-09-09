/// Centralized AI configuration for Keyva.
///
/// There is deliberately NO default API key here. A key baked into the
/// binary is extractable by anyone with the APK, gets shared across every
/// install (one rate limit for all users), and will eventually be revoked by
/// the provider. Cloud AI is bring-your-own-key: the user pastes a key in
/// Settings > Privacy & AI, or the app stays fully local. Local is the default.
class AiConfig {
  /// Groq (OpenAI-compatible) chat completions endpoint.
  static const String groqBaseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Text model used for the once-per-day close analysis (only when the user
  /// has entered a key and turned the toggle on).
  static const String defaultTextModel = 'llama-3.3-70b-versatile';

  /// Vision model for optional photo classification (same opt-in gate).
  static const String defaultVisionModel =
      'meta-llama/llama-4-scout-17b-16e-instruct';

  /// Identifier of the on-device embedder currently in use. Stored in
  /// settings as `embedder_id`; when it changes, all key_examples vectors are
  /// re-embedded from their raw text at startup.
  static const String onnxEmbedderId = 'minilm-l6-v2-int8-384';
  static const String hashingEmbedderId = 'hashing-dev-384';
}
