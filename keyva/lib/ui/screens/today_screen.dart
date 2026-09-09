import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/time/day_resolver.dart';
import '../controllers/app_state.dart';
import '../theme/daylog_theme.dart';
import '../widgets/capture_bar.dart';
import '../widgets/day_ring.dart';
import '../widgets/edit_entry_sheet.dart';
import '../widgets/time_ribbon_timeline.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  TodayController? _t;
  Map<String, int> _counts = const {};

  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_t == null) {
      _t = TodayController(ServicesScope.of(context));
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final db = ServicesScope.of(context).db;
    await _t!.load();
    if (!mounted) return;
    final cutoff = DayResolver.formatDay(DateTime.now().subtract(const Duration(days: 35)));
    final rows = await db.customSelect(
      "SELECT day_date, COUNT(*) AS c FROM events WHERE deleted_at IS NULL AND status='done' AND day_date >= ?1 GROUP BY day_date",
      variables: [Variable.withString(cutoff)],
    ).get();
    if (!mounted) return;
    setState(() => _counts = {for (final r in rows) r.read<String>('day_date'): r.read<int>('c')});
  }

  void _shift(int d) {
    final n = DateTime.parse(_t!.dayDate).add(Duration(days: d));
    if (n.isAfter(DateTime.now().add(const Duration(days: 7)))) return;
    HapticFeedback.selectionClick();
    _t!.load(DayResolver.formatDay(n));
  }

  double _fraction() {
    final n = DateTime.now();
    return (n.hour * 60 + n.minute) / 1440.0;
  }

  // ----------------------------------------------------------- sheets

  Future<void> _dayGrid() async {
    final theme = Theme.of(context);
    final dl = Dl.of(context);
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final start = monday.subtract(const Duration(days: 21));
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(dl.x5, dl.x4, dl.x5, dl.x5),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Four weeks', style: theme.textTheme.titleLarge),
            SizedBox(height: dl.x3),
            Row(children: [
              for (final w in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(child: Center(child: Text(w, style: theme.textTheme.bodySmall)))
            ]),
            SizedBox(height: dl.x1),
            for (var wk = 0; wk < 5; wk++)
              Row(children: [
                for (var d = 0; d < 7; d++) Expanded(child: _cell(ctx, start.add(Duration(days: wk * 7 + d)), today))
              ]),
          ]),
        ),
      ),
    );
  }

  Widget _cell(BuildContext ctx, DateTime date, DateTime today) {
    final theme = Theme.of(context);
    final id = DayResolver.formatDay(date);
    final future = date.isAfter(today.add(const Duration(days: 7)));
    final isFuture = date.isAfter(today);
    final selected = id == _t!.dayDate;
    final n = _counts[id] ?? 0;
    return InkWell(
      onTap: future
          ? null
          : () {
              Navigator.pop(ctx);
              _t!.load(id);
            },
      borderRadius: BorderRadius.circular(Dl.radiusSmall),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : null, borderRadius: BorderRadius.circular(Dl.radiusSmall)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${date.day}',
              style: DlType.mono(context,
                  size: 14,
                  weight: FontWeight.w600,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : isFuture
                          ? theme.colorScheme.outline
                          : theme.colorScheme.onSurface)),
          SizedBox(
            height: 6,
            child: n > 0
                ? Icon(Icons.circle, size: 4, color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant)
                : null,
          ),
        ]),
      ),
    );
  }

  Future<void> _options(EventView e) async {
    HapticFeedback.mediumImpact();
    final dl = Dl.of(context);
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dl.x2),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (e.isGhost) ...[
              ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Done just now'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _t!.completeGhost(e.id);
                  }),
              ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Done at…'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final at = await _pickTime(e.local);
                    if (at != null) _t!.completeGhost(e.id, at: at);
                  }),
              ListTile(
                  leading: const Icon(Icons.remove_circle_outline),
                  title: const Text('Skip'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _t!.skip(e.id);
                  }),
            ],
            ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _edit(e);
                }),
            ListTile(
                leading: const Icon(Icons.delete_outline, color: DlColors.danger),
                title: const Text('Delete', style: TextStyle(color: DlColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  _delete(e);
                }),
          ]),
        ),
      ),
    );
  }

  Future<DateTime?> _pickTime(DateTime base) async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(base));
    if (t == null) return null;
    return DateTime(base.year, base.month, base.day, t.hour, t.minute);
  }

  Future<void> _edit(EventView e) async {
    final changed = await showEditEntrySheet(context, e);
    if (changed == true) _refresh();
  }

  Future<void> _delete(EventView e) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text(e.rawText, maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) {
      await _t!.deleteEvent(e.id);
      _refresh();
    }
  }

  Future<void> _completeGhost(EventView e) async {
    HapticFeedback.mediumImpact();
    await _t!.completeGhost(e.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${e.rawText} — done'),
      action: SnackBarAction(label: 'Earlier…', onPressed: () async {
        final at = await _pickTime(DateTime.now());
        if (at != null) {
          _t!.updateEvent(id: e.id, rawText: e.rawText, keyId: e.keyId, at: at, note: e.note,
              durationMin: e.durationMin, quantity: e.quantity, unit: e.unit);
        }
      }),
    ));
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AnimatedBuilder(
        animation: _t ?? Listenable.merge(const []),
        builder: (context, _) {
          final t = _t!;
          final date = DateTime.parse(t.dayDate);
          final isFutureDay = date.isAfter(DateTime.now()) && !t.isToday;
          return Column(children: [
            // ---- header --------------------------------------------------
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v > 200) _shift(-1);
                if (v < -200) _shift(1);
              },
              onVerticalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v > 200) _shift(-1);
                if (v < -200) _shift(1);
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(dl.x5, dl.x3, dl.x4, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                    child: InkWell(
                      onTap: _dayGrid,
                      borderRadius: BorderRadius.circular(Dl.radiusSmall),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: dl.x1),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(
                            children: [
                              Text(
                                  t.isToday
                                      ? 'Today, ${_weekdays[date.weekday - 1]}'
                                      : isFutureDay
                                          ? '${_weekdays[date.weekday - 1]} · planned'
                                          : _weekdays[date.weekday - 1],
                                  style: theme.textTheme.bodySmall),
                              if (!t.isToday) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _t!.load(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('Go to Today',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onPrimaryContainer)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text('${date.day} ${_months[date.month - 1]}', style: theme.textTheme.displayLarge),
                          if (t.arithmetic.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(t.arithmetic, style: theme.textTheme.bodySmall),
                            ),
                        ]),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    tooltip: 'Previous day',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _shift(-1),
                  ),
                  Semantics(
                    label: t.isToday ? 'Day progress' : 'Closed day',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                      child: DayRing(fraction: t.isToday ? _fraction() : (isFutureDay ? 0 : 1.0), size: 50),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
                    tooltip: 'Next day',
                    visualDensity: VisualDensity.compact,
                    onPressed: date.isAfter(DateTime.now().add(const Duration(days: 6))) ? null : () => _shift(1),
                  ),
                ]),
              ),
            ),

            // ---- morning review -------------------------------------------
            if (t.pending.isNotEmpty)
              _ReviewStrip(
                items: t.pending,
                onDidIt: t.reviewDidIt,
                onToday: t.reviewToday,
                onSkip: (e) => t.skip(e.id),
                onDismiss: t.reviewSkipAll,
              ),

            // ---- summary (closed days) ------------------------------------
            if (t.daySummary != null && !t.isToday)
              Padding(
                padding: EdgeInsets.fromLTRB(dl.x5, dl.x3, dl.x5, dl.x1),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.daySummary!,
                      style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
                  for (final f in t.flags)
                    Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('— $f', style: theme.textTheme.bodySmall)),
                ]),
              ),

            // ---- ribbon -----------------------------------------------------
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v > 300) _shift(-1);
                  if (v < -300) _shift(1);
                },
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: TimeRibbonTimeline(
                    events: t.events,
                    showNow: t.isToday,
                    onTapEvent: _edit,
                    onLongPressEvent: _options,
                    onCompleteGhost: _completeGhost,
                  ),
                ),
              ),
            ),
            CaptureBar(onLogged: _refresh, targetDayDate: t.isToday ? null : t.dayDate),
          ]);
        },
      ),
    );
  }
}

/// "Yesterday: gym, call mom — did you?" Three taps per item, or dismiss.
class _ReviewStrip extends StatelessWidget {
  const _ReviewStrip({
    required this.items,
    required this.onDidIt,
    required this.onToday,
    required this.onSkip,
    required this.onDismiss,
  });
  final List<EventView> items;
  final Future<void> Function(EventView) onDidIt, onToday, onSkip;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.fromLTRB(dl.x5, dl.x3, dl.x5, 0),
      padding: EdgeInsets.fromLTRB(dl.x4, dl.x3, dl.x2, dl.x3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Dl.radius),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Yesterday you planned', style: theme.textTheme.titleSmall)),
          IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Skip all',
              onPressed: onDismiss),
        ]),
        for (final e in items)
          Padding(
            padding: EdgeInsets.only(top: dl.x1),
            child: Row(children: [
              Expanded(child: Text(e.rawText, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              _b('Did it', () => onDidIt(e)),
              _b('Today', () => onToday(e)),
              _b('Skip', () => onSkip(e)),
            ]),
          ),
      ]),
    );
  }

  Widget _b(String t, VoidCallback f) => TextButton(
      onPressed: f,
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 36)),
      child: Text(t));
}
