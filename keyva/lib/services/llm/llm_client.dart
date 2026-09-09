import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/ai_config.dart';
import '../settings/settings_service.dart';

/// Groq Cloud API Client (Free, ultra-fast LPU inference).
/// Supports:
///   - Text: llama-3.3-70b-versatile / llama-3.1-8b-instant
///   - Vision: qwen/qwen3.6-27b / llama-3.2-11b-vision-preview
///   - OpenAI-compatible chat completions with JSON mode
class LlmClient {
  LlmClient({
    String apiKey = '',
    required this.settings,
    this.model = AiConfig.defaultTextModel,
    this.visionModel = AiConfig.defaultVisionModel,
    this.baseUrl = AiConfig.groqBaseUrl,
    this.inputUsdPerMtok = 0.59,
    this.outputUsdPerMtok = 0.79,
  }) : _apiKey = apiKey;

  final String _apiKey;
  final SettingsService settings;
  final String model;
  final String visionModel;
  final String baseUrl;
  final double inputUsdPerMtok;
  final double outputUsdPerMtok;

  Future<String?> getEffectiveApiKey() async {
    final k = await settings.apiKey();
    if (k != null && k.isNotEmpty) return k;
    if (_apiKey.isNotEmpty) return _apiKey;
    return null;
  }

  /// Returns decoded JSON (Map) from the text model.
  Future<Map<String, dynamic>> completeJson({
    required String system,
    required List<Map<String, dynamic>> messages,
    String? modelOverride,
    int maxTokens = 1500,
    double temperature = 0.3,
  }) async {
    if (await settings.budgetExceeded()) {
      throw LlmBudgetExceeded();
    }

    final key = await getEffectiveApiKey();
    if (key == null || key.isEmpty) {
      throw LlmException('No Groq API key configured');
    }

    final allMessages = <Map<String, dynamic>>[
      {'role': 'system', 'content': system},
      ...messages,
    ];

    final candidateModels = <String>[modelOverride ?? model];

    for (final candidate in candidateModels) {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final resp = await http.post(
            Uri.parse(baseUrl),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer $key',
            },
            body: jsonEncode({
              'model': candidate,
              'max_tokens': maxTokens,
              'temperature': temperature,
              'response_format': {'type': 'json_object'},
              'messages': allMessages,
            }),
          );

          if (resp.statusCode == 503 || resp.statusCode == 404 || resp.statusCode == 400) {
            // Over capacity or decommissioned - instantly try next candidate
            break;
          }
          if (resp.statusCode == 429 || resp.statusCode >= 500) {
            await Future<void>.delayed(Duration(seconds: 1 * (attempt + 1)));
            continue;
          }
          if (resp.statusCode != 200) {
            // Try next candidate model
            break;
          }

          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          await _recordUsage(body['usage']);

          final choices = body['choices'] as List?;
          if (choices == null || choices.isEmpty) {
            continue;
          }

          final text = (choices[0] as Map)['message']?['content'] as String? ?? '';
          final cleaned = _stripFences(text);
          try {
            return jsonDecode(cleaned) as Map<String, dynamic>;
          } on FormatException {
            if (attempt == 0) continue;
            break;
          }
        } catch (_) {
          break;
        }
      }
    }
    throw LlmException('Groq LLM call failed after retries across candidate models');
  }

  /// Returns decoded JSON (Map) from the vision model.
  Future<Map<String, dynamic>> completeVisionJson({
    required String system,
    required String prompt,
    required String base64Image,
    String mediaType = 'image/jpeg',
    int maxTokens = 800,
    double temperature = 0.2,
  }) async {
    if (await settings.budgetExceeded()) {
      throw LlmBudgetExceeded();
    }

    final key = await getEffectiveApiKey();
    if (key == null || key.isEmpty) {
      throw LlmException('No Groq API key configured');
    }

    final messages = [
      {'role': 'system', 'content': system},
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:$mediaType;base64,$base64Image',
            },
          },
        ],
      },
    ];

    final candidateModels = <String>[visionModel];

    for (final candidate in candidateModels) {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final resp = await http.post(
            Uri.parse(baseUrl),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer $key',
            },
            body: jsonEncode({
              'model': candidate,
              'max_tokens': maxTokens,
              'temperature': temperature,
              'response_format': {'type': 'json_object'},
              'messages': messages,
            }),
          );

          if (resp.statusCode == 503 || resp.statusCode == 404 || resp.statusCode == 400) {
            // Over capacity or decommissioned - instantly try next candidate
            break;
          }
          if (resp.statusCode == 429 || resp.statusCode >= 500) {
            await Future<void>.delayed(Duration(seconds: 1 * (attempt + 1)));
            continue;
          }
          if (resp.statusCode != 200) {
            // Model might not be supported on this endpoint; try next candidate
            break;
          }

          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          await _recordUsage(body['usage']);

          final choices = body['choices'] as List?;
          if (choices == null || choices.isEmpty) {
            continue;
          }

          final text = (choices[0] as Map)['message']?['content'] as String? ?? '';
          final cleaned = _stripFences(text);
          try {
            return jsonDecode(cleaned) as Map<String, dynamic>;
          } on FormatException {
            if (attempt == 0) continue;
            break;
          }
        } catch (_) {
          break;
        }
      }
    }
    throw LlmException('Groq Vision call failed across candidates');
  }

  Future<void> _recordUsage(dynamic usage) async {
    if (usage is! Map) return;
    final inTok = (usage['prompt_tokens'] as num?)?.toDouble() ?? 0;
    final outTok = (usage['completion_tokens'] as num?)?.toDouble() ?? 0;
    final usd = inTok / 1e6 * inputUsdPerMtok + outTok / 1e6 * outputUsdPerMtok;
    await settings.addSpendMicrocents((usd * 100 * 1e6).round());
  }

  static String _stripFences(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```(json)?\s*'), '');
      if (t.endsWith('```')) t = t.substring(0, t.length - 3);
    }
    final first = t.indexOf('{');
    final last = t.lastIndexOf('}');
    if (first >= 0 && last >= first) t = t.substring(first, last + 1);
    return t.trim();
  }
}

class LlmException implements Exception {
  LlmException(this.message);
  final String message;
  @override
  String toString() => 'LlmException: $message';
}

class LlmBudgetExceeded extends LlmException {
  LlmBudgetExceeded() : super('Monthly LLM budget cap reached');
}

