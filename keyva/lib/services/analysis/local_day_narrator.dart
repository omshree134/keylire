import 'package:drift/drift.dart';

import '../../core/time/day_resolver.dart';
import '../../data/db/database.dart';

/// The default day-close analysis. Runs on every device, needs no model,
/// costs nothing, and never leaves the phone.
///
/// It is not trying to sound like an LLM. It states what the data shows:
/// span of the day, its sequence, what dominated, and how it compares to
/// the user's own recent baseline. Flags are the same categories the LLM
/// prompt asked for - streaks, timing drift, returns, firsts - computed
/// exactly instead of guessed.
class LocalDayNarrator {
  LocalDayNarrator(this.db, {this.lookbackDays = 35});

  final AppDatabase db;
  final int lookbackDays;

  static const int maxFlags = 5;

  Future<LocalNarrative> narrate(String dayDate, List<Event> events) async {
    final keys = await db.activeKeys();
    final name = {for (final k in keys) k.id: k.name};

    final day = DateTime.parse(dayDate);
    final since = DayResolver.formatDay(day.subtract(Duration(days: lookbackDays)));

    final history = await (db.select(db.events)
          ..where((e) =>
              e.deletedAt.isNull() &
              e.keyId.isNotNull() &
              e.status.equals('done') &
              e.dayDate.isBiggerOrEqualValue(since) &
              e.dayDate.isSmallerThanValue(dayDate)))
        .get();

    // ---- index history ------------------------------------------------
    final histDaysByKey = <int, Set<String>>{};
    final histMinutesByKey = <int, List<int>>{};
    final histDays = <String>{};
    for (final e in history) {
      histDays.add(e.dayDate);
      histDaysByKey.putIfAbsent(e.keyId!, () => {}).add(e.dayDate);
      histMinutesByKey.putIfAbsent(e.keyId!, () => []).add(_minuteOf(e));
    }

    // ---- today ----------------------------------------------------------
    final filed = events.where((e) => e.keyId != null).toList();
    final unfiled = events.length - filed.length;
    final countByKey = <int, int>{};
    final firstMinuteByKey = <int, int>{};
    final order = <int>[];
    for (final e in filed) {
      final k = e.keyId!;
      countByKey[k] = (countByKey[k] ?? 0) + 1;
      firstMinuteByKey.putIfAbsent(k, () => _minuteOf(e));
      if (!order.contains(k)) order.add(k);
    }

    // ---- summary --------------------------------------------------------
    final s = StringBuffer();
    final first = _hhmm(events.first.tsUtc.toLocal());
    final last = _hhmm(events.last.tsUtc.toLocal());
    if (events.length == 1) {
      s.write('One entry at $first.');
    } else {
      s.write('${events.length} entries between $first and $last.');
    }

    if (order.isNotEmpty) {
      final seq = order.take(5).map((k) => name[k] ?? '?').join(' → ');
      final more = order.length > 5 ? ' and ${order.length - 5} more' : '';
      s.write(' The day ran $seq$more.');
    }

    // Numbers are content: name the biggest one.
    final withQty = filed.where((e) => e.quantity != null || e.durationMin != null).toList();
    if (withQty.isNotEmpty) {
      final byKey = <int, ({double q, String u})>{};
      for (final e in withQty) {
        final k = e.keyId!;
        if (e.quantity != null) {
          final prev = byKey[k];
          byKey[k] = (q: (prev?.q ?? 0) + e.quantity!, u: e.unit ?? '');
        } else if (e.durationMin != null) {
          final prev = byKey[k];
          byKey[k] = (q: (prev?.q ?? 0) + e.durationMin!, u: 'min');
        }
      }
      final parts = byKey.entries.take(2).map((x) {
        final q = x.value.q == x.value.q.roundToDouble() ? '${x.value.q.toInt()}' : x.value.q.toStringAsFixed(1);
        return '${name[x.key]} $q ${x.value.u}'.trim();
      });
      s.write(' ${parts.join(', ')}.');
    }

    if (filed.length >= 4) {
      final top = countByKey.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (top.value >= 2 && top.value * 3 >= filed.length) {
        s.write(' Mostly ${name[top.key]} (${top.value} of ${filed.length}).');
      }
    }

    // Baseline: entries per logged day over the last 7 logged days.
    final recentDays = histDays.toList()..sort();
    final baselineDays = recentDays.reversed.take(7).toList();
    if (baselineDays.length >= 3) {
      final n = history.where((e) => baselineDays.contains(e.dayDate)).length;
      final avg = n / baselineDays.length;
      if (events.length >= avg * 1.5 + 1) {
        s.write(' Busier than your recent ${avg.toStringAsFixed(0)}/day.');
      } else if (events.length <= avg * 0.5 && avg >= 4) {
        s.write(' Quieter than your recent ${avg.toStringAsFixed(0)}/day.');
      }
    }

    // ---- flags (priority order, capped) -------------------------------
    final flags = <String>[];
    final stats = <int, KeyStats>{};

    for (final k in order) {
      final n = name[k] ?? '?';
      final days = {...?histDaysByKey[k], dayDate};

      final streak = _streakEndingAt(days, day);
      final count7 = _countWithin(days, day, 7);
      final count30 = _countWithin(days, day, 30);
      final hist = histMinutesByKey[k] ?? const [];
      final usual = hist.length >= 3 ? _median(hist) : null;

      stats[k] = KeyStats(
        count7d: count7,
        count30d: count30,
        streak: streak,
        usualMinute: usual,
        firstEver: !histDaysByKey.containsKey(k),
      );

      if (streak >= 3) flags.add('$n: $streak days running');

      if (usual != null) {
        final diff = firstMinuteByKey[k]! - usual;
        if (diff.abs() >= 90) {
          final h = (diff.abs() / 60).toStringAsFixed(diff.abs() % 60 == 0 ? 0 : 1);
          flags.add('$n ${h}h ${diff > 0 ? 'later' : 'earlier'} than usual (~${_hhmmOfMinute(usual)})');
        }
      }
    }

    for (final k in order) {
      final n = name[k] ?? '?';
      final prior = histDaysByKey[k];
      if (prior == null) {
        flags.add('First time logging $n');
      } else {
        final lastSeen = DateTime.parse((prior.toList()..sort()).last);
        final gap = day.difference(lastSeen).inDays;
        if (gap >= 7) flags.add('$n is back after $gap days');
      }
    }

    if (unfiled > 0) {
      flags.add(unfiled == 1 ? '1 unfiled entry' : '$unfiled unfiled entries');
    }

    return LocalNarrative(
      summary: s.toString(),
      flags: flags.take(maxFlags).toList(),
      keyStats: stats,
    );
  }

  /// One-line per-key text for the Patterns screen, from stats alone.
  static String describeKey(String keyName, KeyStats st) {
    final parts = <String>[];
    parts.add(st.count7d == 1
        ? 'Once this week'
        : '${st.count7d}× this week, ${st.count30d}× this month');
    if (st.usualMinute != null) {
      parts.add('usually around ${_hhmmOfMinute(st.usualMinute!)}');
    }
    if (st.streak >= 2) parts.add('${st.streak}-day streak');
    return '${parts.join(', ')}.';
  }

  // ------------------------------------------------------------ helpers

  static int _minuteOf(Event e) {
    final l = e.tsUtc.toLocal();
    return l.hour * 60 + l.minute;
  }

  static int _median(List<int> xs) {
    final s = [...xs]..sort();
    return s[s.length ~/ 2];
  }

  static int _streakEndingAt(Set<String> days, DateTime day) {
    var streak = 0;
    var d = day;
    while (days.contains(DayResolver.formatDay(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _countWithin(Set<String> days, DateTime day, int window) {
    final from = DayResolver.formatDay(day.subtract(Duration(days: window - 1)));
    final to = DayResolver.formatDay(day);
    return days.where((d) => d.compareTo(from) >= 0 && d.compareTo(to) <= 0).length;
  }

  static String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _hhmmOfMinute(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

class LocalNarrative {
  LocalNarrative({required this.summary, required this.flags, required this.keyStats});
  final String summary;
  final List<String> flags;
  final Map<int, KeyStats> keyStats;
}

class KeyStats {
  KeyStats({
    required this.count7d,
    required this.count30d,
    required this.streak,
    this.usualMinute,
    this.firstEver = false,
  });
  final int count7d;
  final int count30d;
  final int streak;
  final int? usualMinute;
  final bool firstEver;

  Map<String, dynamic> toJson() => {
        'count_7d': count7d,
        'count_30d': count30d,
        'streak': streak,
        if (usualMinute != null) 'usual_minute': usualMinute,
      };
}
