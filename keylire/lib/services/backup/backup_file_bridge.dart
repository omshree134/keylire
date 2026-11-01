import 'dart:io';

import 'package:flutter/services.dart';

/// Android bridge for sharing encrypted backups and receiving `.keylire` files.
/// Other platforms simply fall back to the save-file flow in Settings.
class BackupFileBridge {
  BackupFileBridge._();

  static const _channel = MethodChannel('com.keylire.app/backup');

  static void configure(Future<void> Function(String path)? onBackupOpened) {
    _channel.setMethodCallHandler(onBackupOpened == null
        ? null
        : (call) async {
            if (call.method == 'backupOpened') {
              final path = call.arguments as String?;
              if (path != null && path.isNotEmpty) {
                await onBackupOpened(path);
              }
            }
          });
  }

  static Future<String?> takePendingImport() async {
    try {
      return await _channel.invokeMethod<String>('takePendingImport');
    } on MissingPluginException {
      return null;
    }
  }

  static Future<void> share(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'keylire' => 'application/vnd.keylire.backup',
      'csv' => 'text/csv',
      'md' => 'text/markdown',
      _ => 'application/octet-stream',
    };
    await _channel.invokeMethod<void>('share', {
      'path': file.path,
      'name': file.uri.pathSegments.last,
      'mimeType': mimeType,
    });
  }
}
