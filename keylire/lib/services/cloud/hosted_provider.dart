import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../entitlements/entitlements_service.dart';
import 'cloud_provider.dart';

/// Keylire-hosted inference for Premium. The phone never sees a model key.
///
/// Proxy contract (POST {baseUrl}/v1/complete):
///   headers:  Authorization: Bearer `<entitlement token>`
///   body:     { "kind": "text" | "vision", "system": "...", "prompt": "...",
///               "image": "`<base64>`"?, "media_type": "image/jpeg"?,
///               "temperature": 0.3, "max_tokens": 1500 }
///   200:      { "json": { ... model output, already parsed ... },
///               "usage": { "input_tokens": n, "output_tokens": n } }
///   402:      quota exhausted for the period
///   401/403:  token invalid or expired -> entitlements.refresh() then retry once
///   429/5xx:  retryable
class HostedProvider implements CloudProvider {
  HostedProvider(this.entitlements, {required this.baseUrl, http.Client? client,
      this.timeout = const Duration(seconds: 45)})
      : _client = client;

  final EntitlementsService entitlements;
  final String baseUrl;
  final http.Client? _client;
  final Duration timeout;

  @override
  String get id => 'hosted';

  @override
  Future<bool> get isConfigured async =>
      baseUrl.isNotEmpty && await entitlements.tier() == Tier.premium;

  @override
  Future<Map<String, dynamic>> completeJson({
    required String system,
    required String user,
    double temperature = 0.3,
    int maxTokens = 1500,
  }) =>
      _call({
        'kind': 'text',
        'system': system,
        'prompt': user,
        'temperature': temperature,
        'max_tokens': maxTokens,
      });

  @override
  Future<Map<String, dynamic>> completeVisionJson({
    required String system,
    required String prompt,
    required Uint8List imageBytes,
    String mediaType = 'image/jpeg',
    double temperature = 0.2,
    int maxTokens = 1200,
  }) =>
      _call({
        'kind': 'vision',
        'system': system,
        'prompt': prompt,
        'image': base64Encode(imageBytes),
        'media_type': mediaType,
        'temperature': temperature,
        'max_tokens': maxTokens,
      });

  Future<Map<String, dynamic>> _call(Map<String, dynamic> body,
      {bool retried = false}) async {
    final token = await entitlements.hostedToken();
    if (token == null) throw CloudNotEntitled();
    final client = _client ?? http.Client();
    http.Response resp;
    try {
      resp = await client
          .post(Uri.parse('$baseUrl/v1/complete'),
              headers: {
                'content-type': 'application/json',
                'authorization': 'Bearer $token',
              },
              body: jsonEncode(body))
          .timeout(timeout);
    } catch (e) {
      throw CloudException('Network: $e', retryable: true);
    } finally {
      if (_client == null) client.close();
    }

    switch (resp.statusCode) {
      case 200:
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final out = decoded['json'];
        if (out is Map<String, dynamic>) return out;
        throw CloudException('Malformed response from Keylire cloud');
      case 401:
      case 403:
        if (retried) throw CloudNotEntitled();
        await entitlements.refresh();
        return _call(body, retried: true);
      case 402:
        throw CloudException('Your Premium quota for this period is used up');
      case 429:
        throw CloudException('Busy, try again in a moment', retryable: true);
      default:
        throw CloudException('Keylire cloud error ${resp.statusCode}',
            retryable: resp.statusCode >= 500);
    }
  }
}
