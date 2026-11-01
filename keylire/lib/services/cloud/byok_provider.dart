import 'dart:convert';
import 'dart:typed_data';

import '../llm/llm_client.dart';
import '../settings/settings_service.dart';
import 'cloud_provider.dart';

/// Bring-your-own-key. Any OpenAI-compatible chat endpoint (Groq, OpenAI,
/// OpenRouter, a local Ollama with the compat layer...). Key, base URL and
/// model names all come from Settings; nothing is baked in.
class ByokProvider implements CloudProvider {
  ByokProvider(this.settings);
  final SettingsService settings;

  @override
  String get id => 'byok';

  @override
  Future<bool> get isConfigured async => await settings.hasApiKey();

  Future<LlmClient> _client() async => LlmClient(
        settings: settings,
        baseUrl: await settings.cloudBaseUrl(),
        model: await settings.cloudTextModel(),
        visionModel: await settings.cloudVisionModel(),
      );

  @override
  Future<Map<String, dynamic>> completeJson({
    required String system,
    required String user,
    double temperature = 0.3,
    int maxTokens = 1500,
  }) async {
    try {
      return await (await _client()).completeJson(
        system: system,
        messages: [{'role': 'user', 'content': user}],
        temperature: temperature,
        maxTokens: maxTokens,
      );
    } on LlmBudgetExceeded {
      throw CloudException('Monthly budget reached');
    } on LlmException catch (e) {
      throw CloudException(e.message, retryable: true);
    }
  }

  @override
  Future<Map<String, dynamic>> completeVisionJson({
    required String system,
    required String prompt,
    required Uint8List imageBytes,
    String mediaType = 'image/jpeg',
    double temperature = 0.2,
    int maxTokens = 1200,
  }) async {
    try {
      return await (await _client()).completeVisionJson(
        system: system,
        prompt: prompt,
        base64Image: base64Encode(imageBytes),
        mediaType: mediaType,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    } on LlmBudgetExceeded {
      throw CloudException('Monthly budget reached');
    } on LlmException catch (e) {
      throw CloudException(e.message, retryable: true);
    }
  }
}

