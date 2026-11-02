import 'package:drift/drift.dart';

import '../../data/db/database.dart';

/// Recurrence detection and lifecycle.
///
/// Propose:   same key, same day-of-week (Mon=0), timestamps clustered
///            within a 180-min band (+-90), on >= 3 DISTINCT dates in the
///            lookback window.
/// Confirm:   user action (status proposed -> confirmed).
/// Downgrade: 2 consecutive misses -> 'suggestion' (never deleted).
/// Suppress:  user delete writes a suppression row; future proposals are
///            blocked by (key, dow) + WINDOW OVERLAP - not exact-time
///            equality - so a deleted 10:00 pattern also blocks 10:05.
class RecurrenceEngine {
  RecurrenceEngine(this.db, {this.lookbackWeeks = 8, this.minHits = 3});

  final AppDatabase db;
  final int lookbackWeeks;
  final int minHits;

  /// At most once per calendar day. Day close still calls scanForProposals
  /// directly; this is for the UI paths that used to call it on every load.
  Future<void> scanIfDue() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (await db.setting('recurrence_scan_day') == today) return;
    await scanForProposals();
    await db.putSetting('recurrence_scan_day', today);
  }

  /// Full scan across active keys. Run at day close (cheap: pure SQL + Dart).
  Future<List<Recurrence>> scanForProposals() async {
    final proposals = <Recurrence>[];
    final since = DateTime.now().toUtc().subtract(
        Duration(days: lookbackWeeks * 7));

    final rows = await (db.select(db.events)
          ..where((e) =>
              e.deletedAt.isNull() &
              e.keyId.isNotNull() &
              e.status.equals('done') &
              e.tsUtc.isBiggerOrEqualValue(since)))
        .get();

    // Bucket by (keyId, dow) using LOCAL wall-clock derived per-event.
    final buckets = <String, List<_Occurrence>>{};
    for (final e in rows) {
      final local = e.tsUtc.toLocal();
      // Bucket by the logbook day's weekday so a 01:00 Tuesday entry counts
      // as Monday - consistent with evaluateDay().
      final dow = DateTime.parse(e.dayDate).weekday - 1;
      final minutes = local.hour * 60 + local.minute;
      buckets
          .putIfAbsent('${e.keyId}|$dow', () => [])
          .add(_Occurrence(e.dayDate, minutes));
    }

    for (final entry in buckets.entries) {
      final parts = entry.key.split('|');
      final keyId = int.parse(parts[0]);
      final dow = int.parse(parts[1]);
      final cluster = _bestCluster(entry.value);
      if (cluster == null) continue;

      final start = (cluster.center - 90).clamp(0, 1439);
      final end = (cluster.center + 90).clamp(0, 1439);

      if (await _isSuppressed(keyId, dow, start, end)) continue;
      if (await _overlapsExisting(keyId, dow, start, end)) continue;

      final weeksObserved = lookbackWeeks;
      final confidence =
          (cluster.distinctDates / weeksObserved).clamp(0.0, 1.0);

      final id = await db.into(db.recurrences).insert(
            RecurrencesCompanion.insert(
              keyId: keyId,
              dayOfWeek: dow,
              windowStart: _hhmm(start),
              windowEnd: _hhmm(end),
              status: 'proposed',
              confidence: confidence,
              hitCount: Value(cluster.distinctDates),
            ),
          );
      final row = await (db.select(db.recurrences)
            ..where((r) => r.id.equals(id)))
          .getSingle();
      proposals.add(row);
    }
    return proposals;
  }

  /// Called from day close for the day just closed: update hit/miss counters
  /// on confirmed recurrences of that weekday. 2 consecutive misses ->
  /// downgrade to 'suggestion' (never delete).
  Future<void> evaluateDay(String dayDate, int dow) async {
    final confirmed = await (db.select(db.recurrences)
          ..where((r) =>
              r.dayOfWeek.equals(dow) & r.status.equals('confirmed')))
        .get();
    if (confirmed.isEmpty) return;

    final dayEvents = await db.doneEventsForDay(dayDate);
    for (final rec in confirmed) {
      final start = _minutes(rec.windowStart);
      final end = _minutes(rec.windowEnd);
      final hit = dayEvents.any((e) {
        if (e.keyId != rec.keyId) return false;
        final local = e.tsUtc.toLocal();
        final m = local.hour * 60 + local.minute;
        return m >= start && m <= end;
      });

      if (hit) {
        await (db.update(db.recurrences)..where((r) => r.id.equals(rec.id)))
            .write(RecurrencesCompanion(
          hitCount: Value(rec.hitCount + 1),
          consecutiveMisses: const Value(0),
        ));
      } else {
        final misses = rec.consecutiveMisses + 1;
        await (db.update(db.recurrences)..where((r) => r.id.equals(rec.id)))
            .write(RecurrencesCompanion(
          consecutiveMisses: Value(misses),
          status: Value(misses >= 2 ? 'suggestion' : rec.status),
        ));
      }
    }
  }

  Future<void> confirm(int recurrenceId) =>
      (db.update(db.recurrences)..where((r) => r.id.equals(recurrenceId)))
          .write(const RecurrencesCompanion(
              status: Value('confirmed'), consecutiveMisses: Value(0)));

  /// User deletes a recurrence: remove it AND write the suppression row.
  /// The loop-killer - never re-propose what the user has thrown out.
  Future<void> deleteAndSuppress(Recurrence rec) async {
    await db.into(db.recurrenceSuppressions).insert(
          RecurrenceSuppressionsCompanion.insert(
            keyId: rec.keyId,
            dayOfWeek: rec.dayOfWeek,
            windowStart: rec.windowStart,
            windowEnd: rec.windowEnd,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await (db.delete(db.recurrences)..where((r) => r.id.equals(rec.id))).go();
  }

  // ------------------------------------------------------------- internals

  Future<bool> _isSuppressed(int keyId, int dow, int start, int end) async {
    final rows = await (db.select(db.recurrenceSuppressions)
          ..where((s) => s.keyId.equals(keyId) & s.dayOfWeek.equals(dow)))
        .get();
    return rows.any((s) =>
        _overlap(start, end, _minutes(s.windowStart), _minutes(s.windowEnd)));
  }

  Future<bool> _overlapsExisting(int keyId, int dow, int start, int end) async {
    final rows = await (db.select(db.recurrences)
          ..where((r) => r.keyId.equals(keyId) & r.dayOfWeek.equals(dow)))
        .get();
    return rows.any((r) =>
        _overlap(start, end, _minutes(r.windowStart), _minutes(r.windowEnd)));
  }

  /// Largest set of occurrences on distinct dates whose times fit inside a
  /// 180-minute sliding band. O(n log n); n is tiny. Note: bands do not wrap
  /// past midnight in v1 (a 23:30 +- 90min pattern splits) - acceptable and
  /// documented.
  _Cluster? _bestCluster(List<_Occurrence> occs) {
    if (occs.length < minHits) return null;
    occs.sort((a, b) => a.minutes.compareTo(b.minutes));
    _Cluster? best;
    var lo = 0;
    for (var hi = 0; hi < occs.length; hi++) {
      while (occs[hi].minutes - occs[lo].minutes > 180) {
        lo++;
      }
      final window = occs.sublist(lo, hi + 1);
      final dates = window.map((o) => o.dayDate).toSet();
      if (dates.length >= minHits &&
          (best == null || dates.length > best.distinctDates)) {
        final mid = window[window.length ~/ 2].minutes;
        best = _Cluster(mid, dates.length);
      }
    }
    return best;
  }

  static bool _overlap(int s1, int e1, int s2, int e2) => s1 <= e2 && s2 <= e1;

  static int _minutes(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static String _hhmm(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';
}

class _Occurrence {
  _Occurrence(this.dayDate, this.minutes);
  final String dayDate;
  final int minutes;
}

class _Cluster {
  _Cluster(this.center, this.distinctDates);
  final int center;
  final int distinctDates;
}
