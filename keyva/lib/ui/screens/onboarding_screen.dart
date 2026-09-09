import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../core/config/seed_lexicon.dart';
import '../../data/db/database.dart';
import '../controllers/app_state.dart';
import '../theme/daylog_theme.dart';

/// Write one line → your words become keys → when's your day.
/// Twenty seconds. The word "key" is explained here and never again.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _i = 0;
  final _picked = <String>{'sleep', 'wake', 'food', 'gym', 'work'};
  int _bed = 23 * 60, _up = 7 * 60;

  static const _suggest = ['food', 'gym', 'work', 'study', 'walk', 'reading', 'coffee', 'meeting', 'call', 'social', 'health', 'chores', 'travel', 'gaming', 'meditation'];

  Future<void> _finish() async {
    final s = ServicesScope.of(context);
    // Keys not picked are archived, not deleted: their seed examples keep
    // working the day the user types "biryani".
    for (final k in await s.db.activeKeys()) {
      final keep = _picked.contains(k.name) || k.name == 'sleep' || k.name == 'wake';
      if (!keep) await s.db.updateKey(k.id, const KeysCompanion(isArchived: Value(true)));
    }
    final sleep = await s.db.keyByName('sleep');
    final wake = await s.db.keyByName('wake');
    if (sleep != null) await s.db.updateKey(sleep.id, KeysCompanion(usualMinuteOverride: Value(_bed)));
    if (wake != null) await s.db.updateKey(wake.id, KeysCompanion(usualMinuteOverride: Value(_up)));
    await s.settings.setSleepEveningHour((_bed ~/ 60 - 3).clamp(17, 22));
    await s.settings.startTrainingMode();
    await s.db.putSetting('onboarded', 'true');
    await s.matcher.warmUp();
    widget.onDone();
  }

  void _next() {
    if (_i == 2) {
      _finish();
      return;
    }
    _page.nextPage(duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _i = i),
              children: [_one(dl, theme), _two(dl, theme), _three(dl, theme)],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(dl.x6, 0, dl.x6, dl.x6),
            child: Row(children: [
              for (var j = 0; j < 3; j++)
                Container(
                  width: 6, height: 6, margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: j == _i ? theme.colorScheme.primary : theme.colorScheme.outline),
                ),
              const Spacer(),
              FilledButton(onPressed: _next, child: Text(_i == 2 ? 'Start' : 'Next')),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _one(Dl dl, ThemeData theme) => Padding(
        padding: EdgeInsets.all(dl.x6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('One line.\nThat\'s a log.', style: theme.textTheme.displayLarge),
          SizedBox(height: dl.x4),
          Text('"gym 45 min" · "call mom tonight" · "ran 5k"\n\nKeyva reads the time, the number, and whether it already happened. '
              'Tap Up when you wake, Bed when you sleep. The rest is one line at a time.',
              style: theme.textTheme.bodyLarge!.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
          SizedBox(height: dl.x6),
          _demo(theme),
        ]),
      );

  Widget _demo(ThemeData theme) {
    Widget row(String t, String line, String key, Color hue, {bool ghost = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            SizedBox(width: 48, child: Text(t, style: DlType.mono(context, size: 12.5))),
            Icon(ghost ? Icons.radio_button_unchecked : Icons.circle, size: ghost ? 10 : 8, color: hue),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(style: theme.textTheme.bodyMedium, children: [
                  TextSpan(text: '$line  '),
                  TextSpan(text: key, style: theme.textTheme.bodySmall!.copyWith(color: hue, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        );
    return Column(children: [
      row('07:10', 'Up', 'wake', DlColors.dawn),
      row('09:30', 'standup', 'meeting', DlColors.daylight),
      row('18:00', 'gym · 45 min', 'gym', DlColors.dusk),
      row('~20:30', 'call mom', 'call · planned', DlColors.dusk, ghost: true),
    ]);
  }

  Widget _two(Dl dl, ThemeData theme) => Padding(
        padding: EdgeInsets.all(dl.x6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Spacer(),
          Text('Your words\nbecome keys.', style: theme.textTheme.displayLarge),
          SizedBox(height: dl.x4),
          Text('Keys are your own words for the things you do. Every line gets filed under one, '
              'and that\'s how patterns appear. Pick a few to start — you\'ll add more just by typing.',
              style: theme.textTheme.bodyLarge!.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
          SizedBox(height: dl.x5),
          Wrap(spacing: dl.x2, runSpacing: dl.x2, children: [
            for (final k in _suggest.where(seedLexicon.containsKey))
              FilterChip(
                label: Text(k),
                selected: _picked.contains(k),
                onSelected: (v) => setState(() => v ? _picked.add(k) : _picked.remove(k)),
              ),
          ]),
          const Spacer(flex: 2),
        ]),
      );

  Widget _three(Dl dl, ThemeData theme) => Padding(
        padding: EdgeInsets.all(dl.x6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Spacer(),
          Text('When\'s your day?', style: theme.textTheme.displayLarge),
          SizedBox(height: dl.x4),
          Text('Your day runs from waking to sleeping, not midnight to midnight. A 1 a.m. snack belongs to tonight.',
              style: theme.textTheme.bodyLarge!.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
          SizedBox(height: dl.x6),
          _dial('Usually up by', _up, DlColors.dawn, (m) => setState(() => _up = m)),
          SizedBox(height: dl.x4),
          _dial('Usually in bed by', _bed, DlColors.night, (m) => setState(() => _bed = m)),
          const Spacer(flex: 2),
        ]),
      );

  Widget _dial(String label, int minute, Color hue, void Function(int) set) {
    final theme = Theme.of(context);
    final t = '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () async {
        final r = await showTimePicker(context: context, initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60));
        if (r != null) set(r.hour * 60 + r.minute);
      },
      borderRadius: BorderRadius.circular(Dl.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(Icons.circle, size: 8, color: hue),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyLarge),
          const Spacer(),
          Text(t, style: DlType.mono(context, size: 22, weight: FontWeight.w600, color: hue)),
        ]),
      ),
    );
  }
}
