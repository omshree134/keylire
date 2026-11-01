import 'package:flutter/material.dart';

import '../../core/time/day_resolver.dart';
import '../theme/daylog_theme.dart';

/// 12-week calendar heatmap, GitHub-style but on the day-arc hue of the
/// key's usual hour. Rows = weekdays (Mon top), columns = weeks, newest on
/// the right. Sizes itself to any phone width via LayoutBuilder.
class Heatmap extends StatelessWidget {
  const Heatmap({
    super.key,
    required this.counts,
    required this.hue,
    this.weeks = 12,
  });

  final Map<String, int> counts; // dayDate -> count
  final Color hue;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      const gap = 3.0;
      final cell = ((box.maxWidth - 22 - (weeks - 1) * gap) / weeks)
          .clamp(8.0, 18.0);
      final maxCount =
          counts.values.fold<int>(1, (a, b) => b > a ? b : a);

      return CustomPaint(
        size: Size(box.maxWidth, 7 * cell + 6 * gap),
        painter: _HeatPainter(
          counts: counts,
          hue: hue,
          weeks: weeks,
          cell: cell,
          gap: gap,
          maxCount: maxCount,
          empty: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          label: DlType.mono(context, size: 9),
        ),
      );
    });
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter({
    required this.counts,
    required this.hue,
    required this.weeks,
    required this.cell,
    required this.gap,
    required this.maxCount,
    required this.empty,
    required this.label,
  });

  final Map<String, int> counts;
  final Color hue;
  final int weeks;
  final double cell, gap;
  final int maxCount;
  final Color empty;
  final TextStyle label;

  @override
  void paint(Canvas canvas, Size size) {
    final today = DateTime.now();
    // Anchor the rightmost column to the current ISO week (Mon start).
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));

    const wd = ['M', '', 'W', '', 'F', '', 'S'];
    for (var row = 0; row < 7; row++) {
      if (wd[row].isEmpty) continue;
      final tp = TextPainter(
          text: TextSpan(text: wd[row], style: label),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(0, row * (cell + gap) + (cell - tp.height) / 2));
    }

    for (var col = 0; col < weeks; col++) {
      final monday =
          thisMonday.subtract(Duration(days: 7 * (weeks - 1 - col)));
      for (var row = 0; row < 7; row++) {
        final date = monday.add(Duration(days: row));
        if (date.isAfter(today)) continue;
        final count = counts[DayResolver.formatDay(date)] ?? 0;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
              22 + col * (cell + gap), row * (cell + gap), cell, cell),
          const Radius.circular(3),
        );
        final paint = Paint()
          ..color = count == 0
              ? empty
              : hue.withValues(alpha: 0.25 + 0.75 * (count / maxCount));
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.counts != counts || old.hue != hue || old.maxCount != maxCount;
}
