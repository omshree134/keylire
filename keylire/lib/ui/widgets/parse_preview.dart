import 'package:flutter/material.dart';

import '../../core/parse/entry_parser.dart';
import '../theme/daylog_theme.dart';

/// What the parser will do with the current line, before it is saved.
class ParsePreviewData {
  const ParsePreviewData({
    required this.parsed,
    required this.resolvedLocal,
    this.keyGuess,
    this.overrideTime,
  });
  final ParsedEntry parsed;

  /// Where it would land if saved now (window already resolved to a minute).
  final DateTime resolvedLocal;
  final String? keyGuess;
  final DateTime? overrideTime;

  DateTime get effective => overrideTime ?? resolvedLocal;
}

class ParsePreview extends StatelessWidget {
  const ParsePreview({
    super.key,
    required this.data,
    required this.onPickTime,
    required this.onClearTime,
  });
  final ParsePreviewData data;
  final VoidCallback onPickTime;
  final VoidCallback onClearTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dl = Dl.of(context);
    final p = data.parsed;
    final at = data.effective;
    final hue = arcColorFor(at);
    final soft = theme.colorScheme.onSurfaceVariant;

    final tense = switch (p.tense) {
      Tense.done => 'Done',
      Tense.planned => 'Planned',
      Tense.listItem => 'To list',
    };

    final tokens = <Widget>[
      _tok(context, tense, color: hue, strong: true),
      if (p.tense != Tense.listItem)
        InkWell(
          onTap: onPickTime,
          borderRadius: BorderRadius.circular(4),
          child: _tok(context, _whenLabel(p, at, data.overrideTime != null),
              color: hue, underline: true),
        ),
      if (data.overrideTime != null)
        InkWell(
          onTap: onClearTime,
          child: Icon(Icons.close, size: 13, color: soft),
        ),
      if (p.quantity != null)
        _tok(context, '${_n(p.quantity!)} ${p.unit ?? ''}'.trim(), mono: true),
      if (p.durationMin != null)
        _tok(context, '${p.durationMin} min', mono: true),
      if (data.keyGuess != null)
        _tok(context, '${data.keyGuess}?', color: soft),
      if (p.noteSignal) Icon(Icons.notes, size: 13, color: soft),
    ];

    return Padding(
      padding: EdgeInsets.only(left: 80, bottom: dl.x1),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < tokens.length; i++) ...[
              if (i > 0)
                Text('  ·  ',
                    style: theme.textTheme.bodySmall!.copyWith(color: soft)),
              tokens[i],
            ],
          ],
        ),
      ),
    );
  }

  static String _whenLabel(ParsedEntry p, DateTime at, bool pinned) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final diff = day.difference(today).inDays;
    final hhmm =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    final dayWord = diff == 0
        ? ''
        : diff == 1
            ? 'tomorrow '
            : diff == -1
                ? 'yesterday '
                : '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][at.weekday - 1]} ';
    if (pinned) return '$dayWord$hhmm';
    if (p.exactLocal != null) return '$dayWord$hhmm';
    if (p.window != null) return '$dayWord${p.window!.label} ~$hhmm';
    if (p.tense == Tense.done && p.dayOffset == 0 && p.weekday == null) {
      return 'now';
    }
    return '$dayWord$hhmm';
  }

  static String _n(double q) =>
      q == q.roundToDouble() ? '${q.toInt()}' : q.toStringAsFixed(1);

  Widget _tok(BuildContext context, String t,
      {Color? color,
      bool strong = false,
      bool mono = false,
      bool underline = false}) {
    final theme = Theme.of(context);
    final base = mono
        ? DlType.mono(context, size: 11.5, color: color)
        : theme.textTheme.bodySmall!.copyWith(
            color: color ?? theme.colorScheme.onSurfaceVariant,
            fontWeight: strong ? FontWeight.w600 : null,
          );
    return Text(t,
        style: base.copyWith(
          decoration: underline ? TextDecoration.underline : null,
          decorationColor: color,
          decorationStyle: TextDecorationStyle.dotted,
        ));
  }
}

