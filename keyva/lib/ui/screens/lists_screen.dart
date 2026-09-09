import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/db/database.dart';
import '../controllers/app_state.dart';
import '../theme/daylog_theme.dart';

/// Things to do. Circle = done now (it lands on Today's ribbon at the fold).
/// Clock = say when it actually happened. Long-press for a time, a section,
/// or delete. Sections are headings, nothing more.
class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key, this.isActive = true});
  final bool isActive;
  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> with WidgetsBindingObserver {
  ListsController? _c;
  final _add = TextEditingController();
  final _focus = FocusNode();
  String? _addingTo;

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
  void didUpdateWidget(ListsScreen old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _c?.load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c == null) {
      _c = ListsController(ServicesScope.of(context));
      _c!.load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _add.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submitAdd() async {
    final t = _add.text.trim();
    if (t.isEmpty) return;
    _add.clear();
    await _c!.add(t, section: _addingTo);
  }

  Future<void> _tick(ListItem it) async {
    HapticFeedback.mediumImpact();
    await _c!.tick(it.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${it.title} — done'),
      action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await ServicesScope.of(context).capture.uncompleteListItem(it.id);
            _c!.load();
          }),
    ));
  }

  Future<void> _tickAt(ListItem it) async {
    final theme = Theme.of(context);
    final dl = Dl.of(context);
    final when = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(dl.x5, dl.x4, dl.x5, dl.x5),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.title, style: theme.textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
            SizedBox(height: dl.x1),
            Text('When did you do it?', style: theme.textTheme.bodySmall),
            SizedBox(height: dl.x3),
            Wrap(spacing: dl.x2, runSpacing: dl.x2, children: [
              ActionChip(label: const Text('Just now'), onPressed: () => Navigator.pop(ctx, DateTime.now())),
              ActionChip(
                  label: const Text('Earlier today'),
                  onPressed: () async {
                    final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                    if (t == null) return;
                    final n = DateTime.now();
                    if (ctx.mounted) Navigator.pop(ctx, DateTime(n.year, n.month, n.day, t.hour, t.minute));
                  }),
              ActionChip(
                  label: const Text('Another day'),
                  onPressed: () async {
                    final d = await showDatePicker(
                        context: ctx, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now(), initialDate: DateTime.now());
                    if (d == null || !ctx.mounted) return;
                    final t = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 12, minute: 0));
                    if (t == null || !ctx.mounted) return;
                    Navigator.pop(ctx, DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  }),
            ]),
          ]),
        ),
      ),
    );
    if (when != null) {
      HapticFeedback.mediumImpact();
      await _c!.tick(it.id, at: when);
    }
  }

  Future<void> _longPress(ListItem it) async {
    HapticFeedback.mediumImpact();
    final services = ServicesScope.of(context);
    final dl = Dl.of(context);
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dl.x2),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('Give it a time'),
                subtitle: const Text('Shows on the ribbon as planned'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final d = await showDatePicker(
                      context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: DateTime.now());
                  if (d == null || !mounted) return;
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (t == null) return;
                  await _c!.promote(it.id, DateTime(d.year, d.month, d.day, t.hour, t.minute));
                }),
            ListTile(
                leading: const Icon(Icons.segment),
                title: const Text('Move to section'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final s = await _askSection(it.section);
                  if (s == null) return;
                  await services.db.updateListItem(it.id, ListItemsCompanion(section: Value(s.isEmpty ? null : s)));
                  _c!.load();
                }),
            ListTile(
                leading: const Icon(Icons.delete_outline, color: DlColors.danger),
                title: const Text('Delete', style: TextStyle(color: DlColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  _c!.remove(it.id);
                }),
          ]),
        ),
      ),
    );
  }

  Future<String?> _askSection(String? current) async {
    final c = TextEditingController(text: current ?? '');
    final v = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Section'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'Groceries, Someday, Before the trip…')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('Move')),
        ],
      ),
    );
    return v == null ? null : (v.isEmpty ? '' : v);
  }

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _c ?? Listenable.merge(const []),
      builder: (context, _) {
        final c = _c!;
        final sections = c.sections;
        return Column(children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _c?.load(),
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(dl.x5, dl.x3, dl.x5, dl.x8),
                children: [
                  Text('Things to do', style: theme.textTheme.displaySmall),
                  Text(c.items.isEmpty ? 'Tick when it\'s done. It lands on Today.' : '${c.items.length} open',
                      style: theme.textTheme.bodySmall),
                  SizedBox(height: dl.x4),
                  for (final sec in sections) ...[
                    if (sec != null && sec.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: dl.x4, bottom: dl.x1),
                        child: Text(sec, style: theme.textTheme.titleSmall),
                      ),
                    for (final it in c.items.where((i) => i.section == sec)) _row(it, c),
                    if (_addingTo == sec)
                      Padding(
                        padding: EdgeInsets.only(left: 36, top: dl.x1),
                        child: TextField(
                          controller: _add,
                          focusNode: _focus,
                          autofocus: true,
                          onSubmitted: (_) => _submitAdd(),
                          decoration: const InputDecoration(hintText: 'Add one thing', isDense: true),
                        ),
                      ),
                  ],
                  if (_addingTo == null || !sections.contains(_addingTo))
                    Padding(
                      padding: EdgeInsets.only(top: dl.x3),
                      child: TextButton.icon(
                        onPressed: () => setState(() => _addingTo = ''),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ),
                  if (_addingTo == '' && !sections.contains(''))
                    Padding(
                      padding: EdgeInsets.only(left: 36, top: dl.x1),
                      child: TextField(
                        controller: _add,
                        focusNode: _focus,
                        autofocus: true,
                        onSubmitted: (_) => _submitAdd(),
                        decoration: const InputDecoration(hintText: 'Add one thing', isDense: true),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _row(ListItem it, ListsController c) {
    final theme = Theme.of(context);
    final dl = Dl.of(context);
    final key = it.keyId == null ? null : c.keyNames[it.keyId];
    final planned = c.plannedAt[it.id];
    return InkWell(
      onLongPress: () => _longPress(it),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dl.x1),
        child: Row(children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.radio_button_unchecked, size: 22),
            color: theme.colorScheme.onSurfaceVariant,
            onPressed: () => _tick(it),
            tooltip: 'Done',
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(it.title, style: theme.textTheme.bodyLarge),
              if (key != null || planned != null)
                Text(
                  [
                    if (key != null) key,
                    if (planned != null) _fmt(planned),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall!.copyWith(
                      color: planned != null ? arcColorFor(planned) : theme.colorScheme.onSurfaceVariant),
                ),
            ]),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.schedule, size: 18),
            color: theme.colorScheme.onSurfaceVariant,
            onPressed: () => _tickAt(it),
            tooltip: 'Done at…',
          ),
        ]),
      ),
    );
  }

  static String _fmt(DateTime d) {
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    final t = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (day == 0) return 'today $t';
    if (day == 1) return 'tomorrow $t';
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${wd[d.weekday - 1]} $t';
  }
}
