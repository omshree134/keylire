import 'dart:io';

import 'package:flutter/services.dart';

import 'photo_understanding_service.dart';

/// Android bridge for ML Kit's on-device Gemini Nano image description.
/// Unsupported devices simply report [PhotoModelStatus.unsupported], leaving
/// Keylire's bundled ML Kit labels and OCR as the always-available fallback.
class MlKitGenAiCaptioner implements PlatformCaptioner {
  static const _channel = MethodChannel('com.keylire.app/image_description');

  @override
  Future<PhotoModelStatus> status() async {
    if (!Platform.isAndroid) return PhotoModelStatus.unsupported;
    try {
      final value = await _channel.invokeMethod<String>('status');
      return switch (value) {
        'downloadable' => PhotoModelStatus.downloadable,
        'downloading' => PhotoModelStatus.downloading,
        'available' => PhotoModelStatus.available,
        _ => PhotoModelStatus.unsupported,
      };
    } on PlatformException {
      return PhotoModelStatus.unsupported;
    } on MissingPluginException {
      return PhotoModelStatus.unsupported;
    }
  }

  @override
  Future<void> download() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('download');
  }

  @override
  Future<String?> describe(File image) async {
    if (!Platform.isAndroid) return null;
    if (await status() != PhotoModelStatus.available) return null;
    try {
      return await _channel.invokeMethod<String>(
        'describe',
        <String, Object>{'path': image.path},
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
