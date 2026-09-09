import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:home_widget/home_widget.dart';

import '../../core/time/day_resolver.dart';
import '../../data/db/database.dart';

/// Feeds the home-screen widget. Called after every write, from the app
/// and from the headless isolate. Keys written:
///   kv_count      int     done entries today
///   kv_last_line  string  newest done entry's text
///   kv_last_time  string  "14:32"
///   kv_chips      json    [{id, name} | {ghostId, name, at}]
/// Ranking matches the in-app bar: due now → usual now → frequent.
class WidgetSyncService {
  static const androidProvider = 'KeyvaWidgetProvider';
  static const iosName = 'KeyvaWidget';

  static Future<void> syncWidgets({
    required AppDatabase db,
    required List<Event> todayEvents,
  }) async {
    try {
      final now = DateTime.now();
      final today = DayResolver.formatDay(now);
      final done = todayEvents.where((e) => e.status == 'done' && e.deletedAt == null).toList()
        ..sort((a, b) => a.tsUtc.compareTo(b.tsUtc));
      final keys = await db.activeKeys();
      final names = {for (final k in keys) k.id: k.name};

      String? lastLine, lastTime;
      if (done.isNotEmpty) {
        final l = done.last;
        final t = l.tsUtc.toLocal();
        lastLine = l.rawText;
        lastTime = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }

      final chips = <Map<String, dynamic>>[];
      final seen = <int>{};

      // due now
      for (final e in await db.plannedFrom(today)) {
        final diff = e.tsUtc.toLocal().difference(now).inMinutes;
        if (diff < -30 || diff > 120) continue;
        if (e.keyId != null && !seen.add(e.keyId!)) continue;
        final t = e.tsUtc.toLocal();
        chips.add({
          'ghostId': e.id,
          'name': e.keyId != null ? names[e.keyId] ?? e.rawText : e.rawText,
          'at': '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        });
        if (chips.length >= 2) break;
      }

      // usual now → frequent
      final nowMin = now.hour * 60 + now.minute;
      final rows = await db.customSelect(
        'SELECT key_id AS id, ts_utc AS ts FROM events '
        "WHERE deleted_at IS NULL AND status='done' AND key_id IS NOT NULL AND ts_utc >= ?",
        variables: [Variable.withInt(now.toUtc().subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000)],
      ).get();
      final score = <int, double>{};
      for (final r in rows) {
        final id = r.read<int>('id');
        final l = r.read<DateTime>('ts').toLocal();
        var d = (nowMin - (l.hour * 60 + l.minute)).abs();
        if (d > 720) d = 1440 - d;
        score[id] = (score[id] ?? 0) + 1 + (d <= 150 ? (150 - d) / 30 : 0);
      }
      final ranked = score.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final e in ranked) {
        if (chips.length >= 4) break;
        final name = names[e.key];
        if (name == null || name == 'sleep' || name == 'wake' || !seen.add(e.key)) continue;
        chips.add({'id': e.key, 'name': name});
      }
      if (chips.isEmpty) {
        for (final k in keys.where((k) => k.name != 'sleep' && k.name != 'wake').take(3)) {
          chips.add({'id': k.id, 'name': k.name});
        }
      }

      await HomeWidget.saveWidgetData<int>('kv_count', done.length);
      await HomeWidget.saveWidgetData<String>('kv_last_line', lastLine ?? '');
      await HomeWidget.saveWidgetData<String>('kv_last_time', lastTime ?? '');
      await HomeWidget.saveWidgetData<String>('kv_chips', jsonEncode(chips));
      await HomeWidget.updateWidget(androidName: androidProvider, iOSName: iosName);
    } catch (_) {
      // Widgets are optional; never let them break a capture.
    }
  }
}
