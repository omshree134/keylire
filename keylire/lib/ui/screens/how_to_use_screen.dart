import 'package:flutter/material.dart';

import '../theme/daylog_theme.dart';

/// A short, reusable field guide shown once after onboarding and available
/// permanently from Settings.
class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key, this.firstRun = false, this.onDone});

  final bool firstRun;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !firstRun,
        title: Text(firstRun ? 'A minute with Keylire' : 'How Keylire works'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(dl.x5, dl.x3, dl.x5, dl.x8),
          children: [
            Text('Your day, in keys.', style: theme.textTheme.displaySmall),
            SizedBox(height: dl.x2),
            Text(
              'Keylire is a private, time-aware logbook. Write what happened, '
              'or what you plan to do. Keylire files each line under one of your '
              'keys and learns your routine from the corrections you make.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            SizedBox(height: dl.x6),
            _DayStrip(theme: theme),
            SizedBox(height: dl.x6),
            _GuideCard(
              number: '01',
              color: DlColors.dawn,
              title: 'Log in one line',
              body:
                  'Type “gym 45 min”, “call mum tonight”, or “coffee”. Use the mic or camera when that is quicker. Tap Up when you wake and Bed when you sleep.',
              footer:
                  'A future time becomes a plan; a past or current action becomes a log.',
            ),
            SizedBox(height: dl.x3),
            _GuideCard(
              number: '02',
              color: DlColors.daylight,
              title: 'Teach the key',
              body:
                  'A key is your own category: work, food, study, walk, or anything else. Confirm Keylire’s choice while training. Your words, time, and corrections improve which keys appear first in the selector.',
              footer:
                  'A wrong guess is useful—pick the right key and Keylire remembers.',
            ),
            SizedBox(height: dl.x3),
            _GuideCard(
              number: '03',
              color: DlColors.dusk,
              title: 'Move through days',
              body:
                  'On Today, swipe up to move to the next day and swipe down to move to the previous day. The arrows beside the day ring do the same thing.',
              footer:
                  'Your day runs from waking to sleeping, not strictly midnight to midnight.',
            ),
            SizedBox(height: dl.x3),
            _GuideCard(
              number: '04',
              color: DlColors.night,
              title: 'Let routines emerge',
              body:
                  'Patterns appear only after Keylire sees repeated behavior. Confirm or reject a suggested pattern before it becomes part of your routine. Lists keep plans and reusable items separate from what already happened.',
              footer: 'Keylire suggests; you decide.',
            ),
            SizedBox(height: dl.x6),
            Container(
              padding: EdgeInsets.all(dl.x4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(Dl.radiusSmall),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline,
                      size: 20, color: theme.colorScheme.primary),
                  SizedBox(width: dl.x3),
                  Expanded(
                    child: Text(
                      'Your journal stays on this device. App updates keep it. Uninstalling or clearing app data removes it, so save an encrypted backup first. The current backup contains your journal data; keep original photos separately.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: dl.x6),
            if (firstRun)
              FilledButton.icon(
                onPressed: onDone,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Start using Keylire'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Example day with wake, work, gym, and sleep keys',
      child: Row(
        children: [
          Text('07:10', style: DlType.mono(context, size: 11)),
          const SizedBox(width: 10),
          for (final color in [
            DlColors.dawn,
            DlColors.daylight,
            DlColors.dusk,
            DlColors.night,
          ]) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const SizedBox(width: 6),
          Text('23:20', style: DlType.mono(context, size: 11)),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.number,
    required this.color,
    required this.title,
    required this.body,
    required this.footer,
  });

  final String number;
  final Color color;
  final String title;
  final String body;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(dl.x4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Dl.radiusSmall),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Text(number,
                style: DlType.mono(context,
                    size: 10, weight: FontWeight.w600, color: color)),
          ),
          SizedBox(width: dl.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                SizedBox(height: dl.x2),
                Text(body,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
                SizedBox(height: dl.x2),
                Text(footer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
