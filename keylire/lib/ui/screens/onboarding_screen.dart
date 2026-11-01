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

  static const _suggest = [
    'food',
    'gym',
    'work',
    'study',
    'walk',
    'reading',
    'coffee',
    'meeting',
    'call',
    'social',
    'health',
    'chores',
    'travel',
    'gaming',
    'meditation'
  ];

  Future<void> _finish() async {
    final s = ServicesScope.of(context);
    // Keys not picked are archived, not deleted: their seed examples keep
    // working the day the user types "biryani".
    for (final k in await s.db.activeKeys()) {
      final keep =
          _picked.contains(k.name) || k.name == 'sleep' || k.name == 'wake';
      if (!keep) {
        await s.db
            .updateKey(k.id, const KeysCompanion(isArchived: Value(true)));
      }
    }
    final sleep = await s.db.keyByName('sleep');
    final wake = await s.db.keyByName('wake');
    if (sleep != null) {
      await s.db
          .updateKey(sleep.id, KeysCompanion(usualMinuteOverride: Value(_bed)));
    }
    if (wake != null) {
      await s.db
          .updateKey(wake.id, KeysCompanion(usualMinuteOverride: Value(_up)));
    }
    await s.settings.setSleepEveningHour((_bed ~/ 60 - 3).clamp(17, 22));
    await s.settings.startTrainingMode();
    await s.db.putSetting('onboarded', 'true');
    await s.matcher.warmUp();
    widget.onDone();
  }

  void _next() {
    if (_i == 3) {
      _finish();
      return;
    }
    _page.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    _page.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
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
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _i = i),
              children: [
                _one(dl, theme),
                _two(dl, theme),
                _three(dl, theme),
                _four(dl, theme),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(dl.x6, 0, dl.x6, dl.x6),
            child: Row(
              children: [
                Text(
                  '${_i + 1} / 4',
                  style: DlType.mono(
                    context,
                    size: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: dl.x3),
                for (var j = 0; j < 4; j++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: j == _i ? 22 : 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: j == _i
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                const Spacer(),
                if (_i > 0)
                  IconButton(
                    onPressed: _back,
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back),
                  ),
                SizedBox(width: dl.x1),
                FilledButton(
                  onPressed: _next,
                  child: Text(_i == 3 ? 'Set up Keylire' : 'Next'),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _one(Dl dl, ThemeData theme) => ListView(
        padding: EdgeInsets.fromLTRB(dl.x6, dl.x6, dl.x6, dl.x6),
        children: [
          _eyebrow('CAPTURE', DlColors.dawn),
          SizedBox(height: dl.x3),
          Text('One line.\nYour day remembers.',
              style: theme.textTheme.displayLarge),
          SizedBox(height: dl.x4),
          Text(
              'Write naturally: “gym 45 min”, “call mum tonight”, or “ran 5k”. Keylire understands time, quantity, duration, and whether it is a plan or something already done.',
              style: theme.textTheme.bodyLarge!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
          SizedBox(height: dl.x6),
          _demo(theme),
          SizedBox(height: dl.x4),
          Row(children: [
            _door(theme, Icons.keyboard_alt_outlined, 'type'),
            SizedBox(width: dl.x2),
            _door(theme, Icons.mic_none, 'speak'),
            SizedBox(width: dl.x2),
            _door(theme, Icons.camera_alt_outlined, 'photo'),
          ]),
        ],
      );

  Widget _eyebrow(String text, Color color) => Row(children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 9),
        Text(text,
            style: DlType.mono(context,
                size: 11, weight: FontWeight.w600, color: color)),
      ]);

  Widget _door(ThemeData theme, IconData icon, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(Dl.radiusSmall),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(children: [
            Icon(icon, size: 19),
            const SizedBox(height: 5),
            Text(label, style: theme.textTheme.bodySmall),
          ]),
        ),
      );

  Widget _demo(ThemeData theme) {
    Widget row(String t, String line, String key, Color hue,
            {bool ghost = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            SizedBox(
                width: 48,
                child: Text(t, style: DlType.mono(context, size: 12.5))),
            Icon(ghost ? Icons.radio_button_unchecked : Icons.circle,
                size: ghost ? 10 : 8, color: hue),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(style: theme.textTheme.bodyMedium, children: [
                  TextSpan(text: '$line  '),
                  TextSpan(
                      text: key,
                      style: theme.textTheme.bodySmall!
                          .copyWith(color: hue, fontWeight: FontWeight.w600)),
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

  Widget _two(Dl dl, ThemeData theme) => ListView(
        padding: EdgeInsets.fromLTRB(dl.x6, dl.x6, dl.x6, dl.x6),
        children: [
          _eyebrow('YOUR LANGUAGE', DlColors.daylight),
          SizedBox(height: dl.x3),
          Text('Your words\nbecome keys.', style: theme.textTheme.displayLarge),
          SizedBox(height: dl.x4),
          Text(
              'Keys are your own words for the things you do. Every line gets filed under one, '
              'and that\'s how patterns appear. Pick a few to start — you\'ll add more just by typing.',
              style: theme.textTheme.bodyLarge!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
          SizedBox(height: dl.x5),
          Wrap(spacing: dl.x2, runSpacing: dl.x2, children: [
            for (final k in _suggest.where(seedLexicon.containsKey))
              FilterChip(
                label: Text(k),
                selected: _picked.contains(k),
                selectedColor: theme.colorScheme.primary,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: _picked.contains(k)
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
                onSelected: (v) =>
                    setState(() => v ? _picked.add(k) : _picked.remove(k)),
              ),
          ]),
          SizedBox(height: dl.x4),
          Container(
            padding: EdgeInsets.all(dl.x3),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Dl.radiusSmall),
            ),
            child: Row(children: [
              const Icon(Icons.touch_app_outlined, size: 20),
              SizedBox(width: dl.x3),
              Expanded(
                child: Text(
                  'Pick a few now. You can create, rename, merge, or archive keys later.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ),
            ]),
          ),
        ],
      );

  Widget _three(Dl dl, ThemeData theme) => ListView(
        padding: EdgeInsets.fromLTRB(dl.x6, dl.x6, dl.x6, dl.x6),
        children: [
          _eyebrow('LEARNING', DlColors.dusk),
          SizedBox(height: dl.x3),
          Text('It learns.\nYou stay in control.',
              style: theme.textTheme.displayLarge),
          SizedBox(height: dl.x4),
          Text(
            'For the first two weeks, Keylire asks you to confirm its key. Every correction teaches it which words, times, and routines belong together.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          SizedBox(height: dl.x5),
          Container(
            padding: EdgeInsets.all(dl.x4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Dl.radiusSmall),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.auto_awesome_outlined, size: 18),
                  SizedBox(width: dl.x2),
                  Text('A pattern is taking shape',
                      style: theme.textTheme.titleMedium),
                ]),
                SizedBox(height: dl.x3),
                Text('Gym usually happens around 18:00 on weekdays.',
                    style: theme.textTheme.bodyMedium),
                SizedBox(height: dl.x3),
                Row(children: [
                  OutlinedButton(
                      onPressed: () {}, child: const Text('Not a pattern')),
                  SizedBox(width: dl.x2),
                  FilledButton(
                      onPressed: () {}, child: const Text('Yes, use it')),
                ]),
              ],
            ),
          ),
          SizedBox(height: dl.x4),
          Text(
            'Confirmed routines help the right keys appear first. Keylire never activates a detected pattern without asking.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ],
      );

  Widget _four(Dl dl, ThemeData theme) => ListView(
        padding: EdgeInsets.fromLTRB(dl.x6, dl.x6, dl.x6, dl.x6),
        children: [
          _eyebrow('YOUR DAY', DlColors.night),
          SizedBox(height: dl.x3),
          Text('When\'s your day?', style: theme.textTheme.displayLarge),
          SizedBox(height: dl.x4),
          Text(
              'Your day runs from waking to sleeping, not midnight to midnight. A 1 a.m. snack can still belong to tonight. These times give Keylire a sensible starting point.',
              style: theme.textTheme.bodyLarge!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
          SizedBox(height: dl.x6),
          _dial('Usually up by', _up, DlColors.dawn,
              (m) => setState(() => _up = m)),
          SizedBox(height: dl.x4),
          _dial('Usually in bed by', _bed, DlColors.night,
              (m) => setState(() => _bed = m)),
          SizedBox(height: dl.x5),
          Row(children: [
            const Icon(Icons.swipe_vertical_outlined, size: 20),
            SizedBox(width: dl.x3),
            Expanded(
              child: Text(
                'On Today, swipe up for the next day and down for the previous day.',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
              ),
            ),
          ]),
        ],
      );

  Widget _dial(String label, int minute, Color hue, void Function(int) set) {
    final theme = Theme.of(context);
    final t =
        '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () async {
        final r = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60));
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
          Text(t,
              style: DlType.mono(context,
                  size: 22, weight: FontWeight.w600, color: hue)),
        ]),
      ),
    );
  }
}
