import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_state.dart';
import '../theme/daylog_theme.dart';
import '../widgets/heatmap.dart';
import 'search_screen.dart';

/// One key at a time. Twelve weeks, four numbers, the usual hour (tap to
/// set it yourself), and a sparkline if the key carries numbers.
class PatternsScreen extends StatefulWidget {
  const PatternsScreen({super.key, this.isActive = true});
  final bool isActive;
  @override
  State<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends State<PatternsScreen>
    with WidgetsBindingObserver {
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
    _c?.dispose();
    super.dispose();
  }

  Future<void> _showWeeklyReview() async {
    final c = _c;
    if (c == null) return;
    final retro = await c.getWeeklyRetrospective(days: 7);
    if (!mounted) return;
    final dl = Dl.of(context);
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(dl.x5, 0, dl.x5, dl.x8),
          children: [
            Row(
              children: [
                Icon(Icons.insights,
                    size: 22, color: theme.colorScheme.primary),
                SizedBox(width: dl.x2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly Retrospective',
                          style: theme.textTheme.titleMedium),
                      Text('${retro.startDate} to ${retro.endDate}',
                          style: DlType.mono(context,
                              size: 11,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  tooltip: 'Copy retrospective',
                  onPressed: () {
                    final buf = StringBuffer();
                    buf.writeln(
                        '# Weekly Review (${retro.startDate} — ${retro.endDate})');
                    buf.writeln(
                        '- Entries: ${retro.totalEvents} across ${retro.activeDays}/7 active days');
                    if (retro.plannedCount > 0) {
                      buf.writeln(
                          '- Planned completion: ${retro.completedPlannedCount}/${retro.plannedCount} (${(retro.plannedCompletionRate * 100).toInt()}%)');
                    }
                    if (retro.topKeys.isNotEmpty) {
                      buf.writeln('\n## Top Activities');
                      for (final k in retro.topKeys) {
                        final timeStr = k.totalMinutes > 0
                            ? ' · ${k.totalMinutes ~/ 60}h ${k.totalMinutes % 60}m'
                            : '';
                        buf.writeln('- ${k.name}: ${k.count} logs$timeStr');
                      }
                    }
                    if (retro.daySummaries.isNotEmpty) {
                      buf.writeln('\n## Day Reflections');
                      for (final s in retro.daySummaries) {
                        buf.writeln('- $s');
                      }
                    }
                    Clipboard.setData(ClipboardData(text: buf.toString()));
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Weekly review copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: dl.x4),
            Row(
              children: [
                Expanded(
                    child: _Stat('${retro.totalEvents}', 'entries logged')),
                Expanded(child: _Stat('${retro.activeDays}/7', 'active days')),
                if (retro.plannedCount > 0)
                  Expanded(
                    child: _Stat(
                      '${(retro.plannedCompletionRate * 100).toInt()}%',
                      'plans done',
                    ),
                  ),
              ],
            ),
            SizedBox(height: dl.x5),
            Text('Top Keys & Time', style: theme.textTheme.titleSmall),
            SizedBox(height: dl.x2),
            if (retro.topKeys.isEmpty)
              Text('No logged activities recorded this week.',
                  style: theme.textTheme.bodySmall)
            else
              for (final k in retro.topKeys)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          k.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${k.count} ${k.count == 1 ? 'log' : 'logs'}',
                        style: DlType.mono(context, size: 12),
                      ),
                      if (k.totalMinutes > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '· ${_hours(k.totalMinutes)}',
                          style: DlType.mono(context,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
            if (retro.daySummaries.isNotEmpty) ...[
              SizedBox(height: dl.x5),
              Text('Day Reflections', style: theme.textTheme.titleSmall),
              SizedBox(height: dl.x2),
              for (final s in retro.daySummaries)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(dl.x3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(Dl.radius),
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    s,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _setUsual() async {
    final c = _c!;
    final m = c.usualMinute ?? 540;
    final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
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
            child: Text('Patterns appear after a few days of logs.',
                style: theme.textTheme.bodyMedium),
          );
        }
        final hue = c.usualMinute == null
            ? theme.colorScheme.onSurfaceVariant
            : arcColorOfMinute(c.usualMinute!);
        final name = c.keys
            .firstWhere((k) => k.id == c.selectedKeyId,
                orElse: () => c.keys.first)
            .name;
        final usual = c.usualMinute == null
            ? '—'
            : '${(c.usualMinute! ~/ 60).toString().padLeft(2, '0')}:${(c.usualMinute! % 60).toString().padLeft(2, '0')}';

        return ListView(
          padding: EdgeInsets.fromLTRB(dl.x5, dl.x3, dl.x5, dl.x8),
          children: [
            if (c.patternProposals.isNotEmpty) ...[
              Text('Patterns to confirm', style: theme.textTheme.titleSmall),
              SizedBox(height: dl.x2),
              for (final proposal in c.patternProposals)
                Card(
                  margin: EdgeInsets.only(bottom: dl.x2),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(dl.x3, dl.x3, dl.x2, dl.x2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proposal.isReconfirmation
                              ? 'Still ${proposal.keyName}?'
                              : '${proposal.keyName} on ${proposal.weekday}',
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(proposal.evidence,
                            style: theme.textTheme.bodySmall),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => c.dismissPattern(proposal.id),
                                child: const Text('No'),
                              ),
                              FilledButton.tonal(
                                onPressed: () => c.confirmPattern(proposal.id),
                                child: const Text('Confirm'),
                              ),
                            ]),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: dl.x3),
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: theme.textTheme.displaySmall!
                              .copyWith(color: hue)),
                      Text('Last twelve weeks',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.insights_outlined, size: 22),
                  tooltip: 'Weekly Retrospective',
                  onPressed: _showWeeklyReview,
                ),
                IconButton(
                  icon: const Icon(Icons.search, size: 22),
                  tooltip: 'Search entries for $name',
                  onPressed: () => Navigator.of(context).push(
                    SearchScreen.route(initialKeyId: c.selectedKeyId),
                  ),
                ),
              ],
            ),
            SizedBox(height: dl.x4),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: c.keys.length,
                separatorBuilder: (_, __) => SizedBox(width: dl.x2),
                itemBuilder: (context, i) {
                  final k = c.keys[i];
                  return ChoiceChip(
                      label: Text(k.name),
                      selected: k.id == c.selectedKeyId,
                      onSelected: (_) => c.select(k.id));
                },
              ),
            ),
            SizedBox(height: dl.x5),
            Heatmap(counts: c.heat, hue: hue),
            SizedBox(height: dl.x5),
            Row(children: [
              Expanded(child: _Stat('${c.count7d}', 'this week')),
              Expanded(child: _Stat('${c.count30d}', 'this month')),
              Expanded(child: _Stat('${c.streak}d', 'streak')),
              Expanded(
                child: InkWell(
                  onTap: _setUsual,
                  borderRadius: BorderRadius.circular(6),
                  child: _Stat(
                      usual,
                      c.usualIsOverride
                          ? 'usual · set by you'
                          : 'usual · tap to set',
                      hue: hue),
                ),
              ),
            ]),
            if (c.plannedCount > 0) ...[
              SizedBox(height: dl.x4),
              Text('${c.doneOfPlanned} of ${c.plannedCount} plans done',
                  style: theme.textTheme.bodyMedium),
            ],
            if (c.totalMinutes30d > 0) ...[
              SizedBox(height: dl.x1),
              Text('${_hours(c.totalMinutes30d)} this month',
                  style: theme.textTheme.bodyMedium),
            ],
            if (c.quantitySeries.length >= 2) ...[
              SizedBox(height: dl.x5),
              Text('${c.quantityUnit ?? ''} per day',
                  style: theme.textTheme.titleSmall),
              SizedBox(height: dl.x2),
              SizedBox(
                  height: 64,
                  child: _Sparkline(series: c.quantitySeries, hue: hue)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(c.quantitySeries.first.day.substring(5),
                    style: DlType.mono(context, size: 10.5)),
                Text(
                    'total ${_n(c.quantitySeries.fold(0.0, (a, b) => a + b.value))} ${c.quantityUnit ?? ''}',
                    style: DlType.mono(context, size: 10.5)),
                Text(c.quantitySeries.last.day.substring(5),
                    style: DlType.mono(context, size: 10.5)),
              ]),
            ],
          ],
        );
      },
    );
  }

  static String _hours(int m) =>
      m >= 60 ? '${(m / 60).toStringAsFixed(m % 60 == 0 ? 0 : 1)} h' : '$m min';
  static String _n(double q) =>
      q == q.roundToDouble() ? '${q.toInt()}' : q.toStringAsFixed(1);
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, {this.hue});
  final String value, label;
  final Color? hue;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: DlType.mono(context,
              size: 20,
              weight: FontWeight.w600,
              color: hue ?? theme.colorScheme.onSurface)),
      const SizedBox(height: 2),
      Text(label, style: theme.textTheme.bodySmall),
    ]);
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.series, required this.hue});
  final List<({String day, double value})> series;
  final Color hue;
  @override
  Widget build(BuildContext context) => CustomPaint(
      size: Size.infinite,
      painter: _SparkPainter(series.map((e) => e.value).toList(), hue,
          Theme.of(context).colorScheme.outline));
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
      final y =
          size.height - (max == 0 ? 0 : v[i] / max) * (size.height - 6) - 3;
      if (i == 0) {
        path.moveTo(0, y);
      } else {
        path.lineTo(i * dx, y);
      }
    }
    canvas.drawLine(Offset(0, size.height - 0.5),
        Offset(size.width, size.height - 0.5), Paint()..color = line);
    canvas.drawPath(
        path,
        Paint()
          ..color = hue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round);
    final last = v.length - 1;
    canvas.drawCircle(
        Offset(
            last * dx,
            size.height -
                (max == 0 ? 0 : v[last] / max) * (size.height - 6) -
                3),
        3,
        Paint()..color = hue);
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.v != v || o.hue != hue;
}
