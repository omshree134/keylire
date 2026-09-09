import 'package:drift/drift.dart';

import '../../data/db/database.dart';

/// The four numbers that decide whether Phases 3-4 deserve to exist:
///   1. median seconds per log        (capture friction)
///   2. logs per day (last 14 days)   (habit strength)
///   3. days since last log           (churn early-warning)
///   4. auto-assign correction rate   (matcher trustworthiness)
class DogfoodMetrics {
  DogfoodMetrics(this.db);
  final AppDatabase db;

  Future<double?> medianCaptureSeconds() async {
    final rows = await db.customSelect(
      'SELECT capture_ms FROM events '
      'WHERE capture_ms IS NOT NULL AND deleted_at IS NULL '
      'ORDER BY capture_ms',
    ).get();
    if (rows.isEmpty) return null;
    final values = rows.map((r) => r.read<int>('capture_ms')).toList();
    final mid = values.length ~/ 2;
    final median = values.length.isOdd
        ? values[mid].toDouble()
        : (values[mid - 1] + values[mid]) / 2.0;
    return median / 1000.0;
  }

  Future<double> logsPerDay({int days = 14}) async {
    final row = await db.customSelect(
      'SELECT COUNT(*) AS c FROM events '
      "WHERE deleted_at IS NULL AND ts_utc >= strftime('%s', 'now', ?)",
      variables: [Variable.withString('-$days days')],
    ).getSingle();
    return row.read<int>('c') / days;
  }

  Future<int?> daysSinceLastLog() async {
    final row = await db.customSelect(
      'SELECT MAX(ts_utc) AS m FROM events WHERE deleted_at IS NULL',
    ).getSingle();
    final raw = row.data['m'];
    if (raw == null) return null;
    DateTime? last;
    if (raw is int) {
      last = DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true);
    } else if (raw is String) {
      final parsedInt = int.tryParse(raw);
      last = parsedInt != null
          ? DateTime.fromMillisecondsSinceEpoch(parsedInt * 1000, isUtc: true)
          : DateTime.tryParse(raw);
    }
    if (last == null) return null;
    return DateTime.now().toUtc().difference(last.toUtc()).inDays;
  }

  /// done-from-planned / (done-from-planned + skipped), last 30 days.
  /// Below ~0.4 means plans are guilt, not help.
  Future<double?> plannedDoneRate() async {
    final r = await db.customSelect(
      "SELECT SUM(CASE WHEN status='done' AND metadata LIKE '%\"was_planned\":true%' THEN 1 ELSE 0 END) AS d, "
      "SUM(CASE WHEN status='skipped' THEN 1 ELSE 0 END) AS s FROM events "
      "WHERE deleted_at IS NULL AND ts_utc >= strftime('%s','now','-30 days')",
    ).getSingle();
    final d = r.readNullable<int>('d') ?? 0;
    final sk = r.readNullable<int>('s') ?? 0;
    if (d + sk == 0) return null;
    return d / (d + sk);
  }

  /// corrected auto-assignments / all auto-assignments.
  /// Above ~10-15% means the 0.85 threshold or the model needs revisiting.
  Future<double?> autoAssignCorrectionRate() async {
    final auto = await db.customSelect(
      "SELECT COUNT(*) AS c FROM events WHERE key_source IN ('auto','corrected') "
      'AND match_score IS NOT NULL AND deleted_at IS NULL',
    ).getSingle();
    final corrected = await db.customSelect(
      "SELECT COUNT(*) AS c FROM events WHERE key_source = 'corrected' "
      'AND match_score IS NOT NULL AND deleted_at IS NULL',
    ).getSingle();
    final total = auto.read<int>('c');
    if (total == 0) return null;
    return corrected.read<int>('c') / total;
  }
}
