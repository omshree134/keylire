import 'dart:typed_data';

/// Which cloud-assisted feature is asking. Each has its own user toggle so
/// "AI summaries on, photo upload off" is expressible.
enum CloudFeature { dayClose, photoExtract, textSplit, insights }

extension CloudFeatureSetting on CloudFeature {
  String get settingKey => switch (this) {
        CloudFeature.dayClose => 'cloud_day_close',
        CloudFeature.photoExtract => 'cloud_photo_extract',
        CloudFeature.textSplit => 'cloud_text_split',
        CloudFeature.insights => 'cloud_insights',
      };

  String get label => switch (this) {
        CloudFeature.dayClose => 'Smarter day summaries',
        CloudFeature.photoExtract => 'Read photos into entries',
        CloudFeature.textSplit => 'Split long notes into entries',
        CloudFeature.insights => 'Pattern insights',
      };

  /// What leaves the phone. Shown verbatim in Settings.
  String get sends => switch (this) {
        CloudFeature.dayClose => 'one day\'s entry lines and computed stats',
        CloudFeature.photoExtract => 'the photo and your caption, nothing else',
        CloudFeature.textSplit => 'the text you typed or spoke',
        CloudFeature.insights => 'weekly counts and times per key, never entry text',
      };
}

/// One contract, two implementations (your own key, or Keylire-hosted).
/// Everything returns parsed JSON; callers own the schema.
abstract class CloudProvider {
  String get id;

  /// Whether this provider can actually make a call right now.
  Future<bool> get isConfigured;

  Future<Map<String, dynamic>> completeJson({
    required String system,
    required String user,
    double temperature = 0.3,
    int maxTokens = 1500,
  });

  Future<Map<String, dynamic>> completeVisionJson({
    required String system,
    required String prompt,
    required Uint8List imageBytes,
    String mediaType = 'image/jpeg',
    double temperature = 0.2,
    int maxTokens = 1200,
  });
}

class CloudException implements Exception {
  CloudException(this.message, {this.retryable = false});
  final String message;
  final bool retryable;
  @override
  String toString() => 'CloudException: $message';
}

class CloudNotEntitled extends CloudException {
  CloudNotEntitled() : super('This feature needs Keylire Premium or your own API key');
}

