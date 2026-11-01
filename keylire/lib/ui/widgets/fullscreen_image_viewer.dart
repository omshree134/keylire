import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/daylog_theme.dart';

class FullscreenImageViewer extends StatelessWidget {
  const FullscreenImageViewer({
    super.key,
    required this.imagePath,
    required this.caption,
    this.tag,
    this.time,
    this.calories,
  });

  final String imagePath;
  final String caption;
  final String? tag;
  final String? time;
  final int? calories;

  static void show(
    BuildContext context, {
    required String imagePath,
    required String caption,
    String? tag,
    String? time,
    int? calories,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        barrierDismissible: true,
        pageBuilder: (ctx, anim1, anim2) => FullscreenImageViewer(
          imagePath: imagePath,
          caption: caption,
          tag: tag,
          time: time,
          calories: calories,
        ),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final file = File(imagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: file.existsSync()
                    ? Image.file(
                        file,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : const Center(
                        child: Text(
                          'Image not found on device',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
              ),
            ),
            Positioned(
              top: dl.x2,
              left: dl.x4,
              right: dl.x4,
              child: Row(
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: dl.x3),
                  if (tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        tag!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (time != null)
                    Text(
                      time!,
                      style: DlType.mono(context, color: Colors.white70, size: 14),
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: dl.x4,
              left: dl.x4,
              right: dl.x4,
              child: Container(
                padding: EdgeInsets.all(dl.x4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(Dl.radius),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (caption.isNotEmpty)
                      Text(
                        caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    if (calories != null) ...[
                      SizedBox(height: dl.x1),
                      Text(
                        'Estimated Calories: ~$calories kcal',
                        style: TextStyle(
                          color: Colors.amberAccent.shade100,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
