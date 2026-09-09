import 'package:flutter/material.dart';

import '../controllers/app_state.dart';
import '../theme/daylog_theme.dart';
import '../widgets/heatmap.dart';

/// One key at a time. Twelve weeks, four numbers, the usual hour (tap to
/// set it yourself), and a sparkline if the key carries numbers.
class PatternsScreen extends StatefulWidget {
  const PatternsScreen({super.key, this.isActive = true});
  final bool isActive;
  @override
  State<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends State<PatternsScreen> with WidgetsBindingObserver {
  PatternsController? _c;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _c?.load();
  }

  @override
  void didUpdateWidget(PatternsScreen old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _c?.load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c == null) {
      _c = PatternsController(ServicesScope.of(context));
      _c!.load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _setUsual() async {
    final c = _c!;
    final m = c.usualMinute ?? 540;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
        helpText: 'Usual time');
    if (t == null) return;
    await c.setUsualOverride(t.hour * 60 + t.minute);
  }

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _c ?? Listenable.merge(const []),
      builder: (context, _) {
        final c = _c!;
        if (c.keys.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(dl.x8),
            child: Text('Patterns appear after a few days of logs.', style: theme.textTheme.bodyMedium),
          );
        }
        final hue = c.usualMinute == null ? theme.colorScheme.onSurfaceVariant : arcColorOfMinute(c.usualMinute!);
        final name = c.keys.firstWhere((k) => k.id == c.selectedKeyId, orElse: () => c.keys.first).name;
        final usual = c.usualMinute == null
            ? '—'
            : '${(c.usualMinute! ~/ 60).toString().padLeft(2, '0')}:${(c.usualMinute! % 60).toString().padLeft(2, '0')}';

        return ListView(
          padding: EdgeInsets.fromLTRB(dl.x5, dl.x3, dl.x5, dl.x8),
          children: [
            Text(name, style: theme.textTheme.displaySmall!.copyWith(color: hue)),
            Text('Last twelve weeks', style: theme.textTheme.bodySmall),
            SizedBox(height: dl.x4),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: c.keys.length,
                separatorBuilder: (_, __) => SizedBox(width: dl.x2),
                itemBuilder: (context, i) {
                  final k = c.keys[i];
                  return ChoiceChip(label: Text(k.name), selected: k.id == c.selectedKeyId, onSelected: (_) => c.select(k.id));
                },
              ),
            ),
            SizedBox(height: dl.x5),
            Heatmap(counts: c.heat, hue: hue),
            SizedBox(height: dl.x5),
            Row(children: [
              _Stat('${c.count7d}', 'this week'),
              _Stat('${c.count30d}', 'this month'),
              _Stat('${c.streak}d', 'streak'),
              InkWell(
                onTap: _setUsual,
                borderRadius: BorderRadius.circular(6),
                child: _Stat(usual, c.usualIsOverride ? 'usual · set by you' : 'usual · tap to set', hue: hue),
              ),
            ]),
            if (c.plannedCount > 0) ...[
              SizedBox(height: dl.x4),
              Text('${c.doneOfPlanned} of ${c.plannedCount} plans done', style: theme.textTheme.bodyMedium),
            ],
            if (c.totalMinutes30d > 0) ...[
              SizedBox(height: dl.x1),
              Text('${_hours(c.totalMinutes30d)} this month', style: theme.textTheme.bodyMedium),
            ],
            if (c.quantitySeries.length >= 2) ...[
              SizedBox(height: dl.x5),
              Text('${c.quantityUnit ?? ''} per day', style: theme.textTheme.titleSmall),
              SizedBox(height: dl.x2),
              SizedBox(height: 64, child: _Sparkline(series: c.quantitySeries, hue: hue)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(c.quantitySeries.first.day.substring(5), style: DlType.mono(context, size: 10.5)),
                Text('total ${_n(c.quantitySeries.fold(0.0, (a, b) => a + b.value))} ${c.quantityUnit ?? ''}',
                    style: DlType.mono(context, size: 10.5)),
                Text(c.quantitySeries.last.day.substring(5), style: DlType.mono(context, size: 10.5)),
              ]),
            ],
          ],
        );
      },
    );
  }

  static String _hours(int m) => m >= 60 ? '${(m / 60).toStringAsFixed(m % 60 == 0 ? 0 : 1)} h' : '$m min';
  static String _n(double q) => q == q.roundToDouble() ? '${q.toInt()}' : q.toStringAsFixed(1);
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, {this.hue});
  final String value, label;
  final Color? hue;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: DlType.mono(context, size: 20, weight: FontWeight.w600, color: hue ?? theme.colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ]),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.series, required this.hue});
  final List<({String day, double value})> series;
  final Color hue;
  @override
  Widget build(BuildContext context) => CustomPaint(
      size: Size.infinite, painter: _SparkPainter(series.map((e) => e.value).toList(), hue, Theme.of(context).colorScheme.outline));
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.v, this.hue, this.line);
  final List<double> v;
  final Color hue, line;
  @override
  void paint(Canvas canvas, Size size) {
    if (v.length < 2) return;
    final max = v.reduce((a, b) => a > b ? a : b);
    final dx = size.width / (v.length - 1);
    final path = Path();
    for (var i = 0; i < v.length; i++) {
      final y = size.height - (max == 0 ? 0 : v[i] / max) * (size.height - 6) - 3;
      if (i == 0) {
        path.moveTo(0, y);
      } else {
        path.lineTo(i * dx, y);
      }
    }
    canvas.drawLine(Offset(0, size.height - 0.5), Offset(size.width, size.height - 0.5), Paint()..color = line);
    canvas.drawPath(path, Paint()..color = hue..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeJoin = StrokeJoin.round);
    final last = v.length - 1;
    canvas.drawCircle(Offset(last * dx, size.height - (max == 0 ? 0 : v[last] / max) * (size.height - 6) - 3), 3, Paint()..color = hue);
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.v != v || o.hue != hue;
}
