import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/daylog_theme.dart';

/// A small 24-hour dial. The full circle is the day; the swept arc (in the
/// day-arc gradient) is how much of it has passed. Midnight at the top.
/// On past days the ring is complete - a closed day.
class DayRing extends StatelessWidget {
  const DayRing({super.key, required this.fraction, this.size = 44});

  /// 0..1 through the day; pass 1.0 for closed/past days.
  final double fraction;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _RingPainter(
        fraction: fraction.clamp(0.0, 1.0),
        track: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction, required this.track});
  final double fraction;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = track.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8);

    if (fraction <= 0) return;
    final sweep = 2 * math.pi * fraction;
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: [
        arcColor(0),
        arcColor(6 / 24),
        arcColor(12 / 24),
        arcColor(18 / 24),
        arcColor(1),
      ],
      stops: const [0.0, 6 / 24, 12 / 24, 18 / 24, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );
    canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round);

    // If day is active (fraction < 1.0), draw a glowing tip dot
    if (fraction < 0.999) {
      final angle = -math.pi / 2 + sweep;
      final tipX = center.dx + radius * math.cos(angle);
      final tipY = center.dy + radius * math.sin(angle);
      final tipHue = arcColor(fraction);

      canvas.drawCircle(
        Offset(tipX, tipY),
        4.0,
        Paint()..color = tipHue,
      );
      canvas.drawCircle(
        Offset(tipX, tipY),
        2.0,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}
