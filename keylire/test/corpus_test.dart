// Run:   flutter test test/corpus_test.dart
// Update baseline after an intentional improvement:
//        UPDATE_BASELINE=1 flutter test test/corpus_test.dart
//
// Each line of test/corpus/phrases.jsonl is a real thing someone would type.
// Fields present in a line are checked; absent fields are not. The test
// prints a scorecard per field and fails if any field scores below the
// number recorded in test/corpus/baseline.json - so the parser can only
// get better. Corrections exported from the app (Settings > Developer >
// Export corrections) are appended to phrases.jsonl to grow it.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keylire/core/parse/entry_parser.dart';

void main() {
  // Fixed clock so "tonight"/"in 20 min"/weekday maths are deterministic:
  // Wednesday 9 Sep 2026, 14:32.
  final now = DateTime(2026, 9, 9, 14, 32);
  final parser = EntryParser(clock: () => now);

  final lines = File('test/corpus/phrases.jsonl')
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .map((l) => jsonDecode(l) as Map<String, dynamic>)
      .toList();

  final fields = ['tense', 'day', 'weekday', 'hour', 'minute', 'window', 'qty', 'unit', 'dur', 'note', 'match', 'rel'];
  final hits = {for (final f in fields) f: 0};
  final total = {for (final f in fields) f: 0};
  final failures = <String>[];

  for (final c in lines) {
    final p = parser.parse(c['in'] as String);

    void check(String f, bool present, Object? got, Object? want, bool ok) {
      if (!present) return;
      total[f] = total[f]! + 1;
      if (ok) {
        hits[f] = hits[f]! + 1;
      } else {
        failures.add('  ${c['in']}  [$f] got=$got want=$want');
      }
    }

    final tenseName = {Tense.done: 'done', Tense.planned: 'planned', Tense.listItem: 'list'}[p.tense];
    check('tense', c.containsKey('tense'), tenseName, c['tense'], tenseName == c['tense']);
    check('day', c.containsKey('day'), p.dayOffset, c['day'], p.dayOffset == c['day']);
    check('weekday', c.containsKey('weekday'), p.weekday, c['weekday'], p.weekday == c['weekday']);
    check('hour', c.containsKey('hour'), p.exactLocal?.hour, c['hour'], p.exactLocal?.hour == c['hour']);
    check('minute', c.containsKey('minute'), p.exactLocal?.minute, c['minute'], p.exactLocal?.minute == c['minute']);
    check('window', c.containsKey('window'), p.window?.label, c['window'], p.window?.label == c['window']);
    check('qty', c.containsKey('qty'), p.quantity, c['qty'], p.quantity == (c['qty'] as num?)?.toDouble());
    check('unit', c.containsKey('unit'), p.unit, c['unit'], p.unit == c['unit']);
    check('dur', c.containsKey('dur'), p.durationMin, c['dur'], p.durationMin == c['dur']);
    check('note', c.containsKey('note'), p.noteSignal, c['note'], p.noteSignal == c['note']);
    check('match', c.containsKey('match'), p.matchText, c['match'],
        c['match'] != null && p.matchText.contains(c['match'] as String));
    if (c.containsKey('rel')) {
      final got = p.exactLocal?.difference(now).inMinutes;
      check('rel', true, got, c['rel'], got == c['rel']);
    }
  }

  final score = <String, double>{
    for (final f in fields)
      if (total[f]! > 0) f: hits[f]! / total[f]!
  };

  final buf = StringBuffer('\nCorpus scorecard (${lines.length} lines)\n');
  for (final e in score.entries) {
    buf.writeln('  ${e.key.padRight(8)} ${(e.value * 100).toStringAsFixed(1).padLeft(5)}%   (${hits[e.key]}/${total[e.key]})');
  }
  if (failures.isNotEmpty) {
    buf.writeln('Misses:');
    failures.forEach(buf.writeln);
  }
  // ignore: avoid_print
  print(buf);

  final baselineFile = File('test/corpus/baseline.json');
  if (Platform.environment['UPDATE_BASELINE'] == '1' || !baselineFile.existsSync()) {
    baselineFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(score));
  }
  final baseline = (jsonDecode(baselineFile.readAsStringSync()) as Map).cast<String, num>();

  test('no field regresses below baseline', () {
    for (final e in baseline.entries) {
      final now_ = score[e.key] ?? 0;
      expect(now_ + 1e-9, greaterThanOrEqualTo(e.value.toDouble()),
          reason: '${e.key} fell from ${e.value} to $now_');
    }
  });
}
