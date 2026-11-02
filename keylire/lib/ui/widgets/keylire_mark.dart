import 'package:flutter/material.dart';

import '../theme/daylog_theme.dart';

/// The Keylire mark: a stylised musical natural sign with interlocking hooks,
/// a dawn-coloured filled dot on the left stem, and a dusk-coloured ring on
/// the right stem.
class KeylireMark extends StatelessWidget {
  const KeylireMark({
    super.key,
    this.size = 20,
    this.color,
    this.dawnColor,
    this.duskColor,
  });

  final double size;
  final Color? color;
  final Color? dawnColor;
  final Color? duskColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stroke = color ?? theme.colorScheme.onSurface;
    final dawn = dawnColor ?? DlColors.dawn;
    final dusk = duskColor ?? DlColors.dusk;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _KeylireMarkPainter(
          strokeColor: stroke,
          dotColor: dawn,
          ringColor: dusk,
        ),
      ),
    );
  }
}

class _KeylireMarkPainter extends CustomPainter {
  const _KeylireMarkPainter({
    required this.strokeColor,
    required this.dotColor,
    required this.ringColor,
  });

  final Color strokeColor;
  final Color dotColor;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final scale = size.width / 180.0;
    canvas.scale(scale);
    canvas.translate(-91, -94);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path1 = Path()
      ..moveTo(68, 50)
      ..lineTo(68, 118)
      ..lineTo(114, 102);
    canvas.drawPath(path1, strokePaint);

    final path2 = Path()
      ..moveTo(114, 134)
      ..lineTo(114, 64)
      ..lineTo(68, 80);
    canvas.drawPath(path2, strokePaint);

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(68, 38), 12, dotPaint);

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(const Offset(114, 150), 10, ringPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_KeylireMarkPainter old) =>
      old.strokeColor != strokeColor ||
      old.dotColor != dotColor ||
      old.ringColor != ringColor;
}

