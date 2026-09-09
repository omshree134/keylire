import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter/widgets.dart' hide Key;

import '../../core/time/day_resolver.dart';
import '../../data/db/database.dart';
import '../../services/analysis/day_close_service.dart';
import '../../services/backup/export_service.dart';
import '../../services/capture/capture_service.dart';
import '../../services/matching/key_matcher.dart';
import '../../services/metrics/dogfood_metrics.dart';
import '../../services/photos/photo_understanding_service.dart';
import '../../services/recurrence/recurrence_engine.dart';
import '../../services/settings/settings_service.dart';
import '../../services/time/time_vocab_service.dart';
import '../../services/widget/widget_sync_service.dart';

class WidgetActionBus {
  static final _c = StreamController<String>.broadcast();
  static Stream<String> get stream => _c.stream;
  static void dispatch(String a) => _c.add(a);
}

class Services {
  Services({
    required this.db,
    required this.settings,
    required this.matcher,
    required this.capture,
    required this.vocab,
    required this.dayClose,
    required this.recurrence,
    required this.export,
    required this.metrics,
    required this.photos,
  });
  final AppDatabase db;
  final SettingsService settings;
  final KeyMatcher matcher;
  final CaptureService capture;
  final TimeVocabService vocab;
  final DayCloseService dayClose;
  final RecurrenceEngine recurrence;
  final ExportService export;
  final DogfoodMetrics metrics;
  final PhotoUnderstandingService photos;
}

class ServicesScope extends InheritedWidget {
  const ServicesScope({super.key, required this.services, required super.child});
  final Services services;
  static Services of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<ServicesScope>()!.services;
  @override
  bool updateShouldNotify(ServicesScope old) => false;
}

/// One event joined with its key, ready for the ribbon.
class EventView {
  EventView({
    required this.id,
    required this.local,
    required this.status,
    required this.keyId,
    required this.keyName,
    required this.rawText,
    required this.modality,
    this.durationMin,
    this.quantity,
    this.unit,
    this.note,
    this.calories,
    this.photoPath,
    this.hasPhoto = false,
    this.isAiProcessing = false,
    this.listItemId,
  });
  final int id;
  final DateTime local;
  final String status; // done | planned | pending | skipped
  final int? keyId;
  final String? keyName;
  final String rawText;
  final String modality;
  final int? durationMin;
  final double? quantity;
  final String? unit;
  final String? note;
  final int? calories;
  final String? photoPath;
  final bool hasPhoto;
  final bool isAiProcessing;
  final int? listItemId;

  bool get isGhost => status == 'planned';
  bool get isDone => status == 'done';

  /// "45 min · 5 km · ~520 kcal" for the key line.
  String get numbers {
    final parts = <String>[];
    if (durationMin != null) parts.add(_dur(durationMin!));
    if (quantity != null) parts.add('${_n(quantity!)} ${unit ?? ''}'.trim());
    if (calories != null) parts.add('~$calories kcal');
    return parts.join(' · ');
  }

  static String _dur(int m) => m >= 60
      ? (m % 60 == 0 ? '${m ~/ 60} h' : '${m ~/ 60} h ${m % 60} min')
      : '$m min';
  static String _n(double q) => q == q.roundToDouble() ? '${q.toInt()}' : q.toStringAsFixed(1);

  static EventView from(Event e, Map<int, String> names) {
    int? kcal;
    var pending = false;
    if (e.metadata != null && e.metadata!.isNotEmpty) {
      try {
        final m = jsonDecode(e.metadata!) as Map<String, dynamic>;
        if (m['calories'] != null) kcal = (m['calories'] as num).round();
        pending = m['ai_pending'] == true;
      } catch (_) {}
    }
    final p = e.photoPath;
    return EventView(
      id: e.id,
      local: e.tsUtc.toLocal(),
      status: e.status,
      keyId: e.keyId,
      keyName: e.keyId == null ? null : names[e.keyId],
      rawText: e.rawText,
      modality: e.modality,
      durationMin: e.durationMin,
      quantity: e.quantity,
      unit: e.unit,
      note: e.note,
      calories: kcal,
      photoPath: p,
      hasPhoto: p != null && p.isNotEmpty && File(p).existsSync(),
      isAiProcessing: pending,
      listItemId: e.listItemId,
    );
  }
}

class TodayController extends ChangeNotifier {
  TodayController(this._s);
  final Services _s;

  String? _customDate;
  String _todayDate = DayResolver.formatDay(DateTime.now());
  List<EventView> events = const []; // done + planned + skipped for the day, chronological
  List<EventView> pending = const []; // yesterday's leftovers for the morning review
  String? daySummary;
  List<String> flags = const [];
  bool loading = true;

  String get dayDate => _customDate ?? _todayDate;
  bool get isToday => _customDate == null || _customDate == _todayDate;
  Iterable<EventView> get done => events.where((e) => e.isDone);
  Iterable<EventView> get ghosts => events.where((e) => e.isGhost);
  int get unfiledCount => done.where((e) => e.keyId == null).length;

  Future<String> resolveActiveDay([DateTime? at]) async {
    final now = at ?? DateTime.now();
    final cutoff = await _s.settings.dayCutoffHour();
    final sleepEvening = await _s.settings.sleepEveningHour();
    final resolver = DayResolver(cutoffHour: cutoff, sleepEveningHour: sleepEvening);
    DateTime? lastSleep;
    final sleepKey = await _s.db.keyByName('sleep');
    if (sleepKey != null) {
      final base = resolver.resolveDayDate(now);
      final s = await _s.db.latestSleepOnDay(base, sleepKey.id);
      if (s != null) {
        final sl = s.tsUtc.toLocal();
        if (resolver.isQualifyingSleep(sl)) lastSleep = sl;
      }
    }
    return resolver.resolveDayDate(now, lastQualifyingSleepLocal: lastSleep);
  }

  /// Header line two: "6 entries · gym 45 min · 3 planned". Live, local.
  String get arithmetic {
    final d = done.toList();
    if (d.isEmpty && ghosts.isEmpty) return '';
    final parts = <String>[];
    if (d.isNotEmpty) parts.add(d.length == 1 ? '1 entry' : '${d.length} entries');
    final withNumbers = d.where((e) => e.numbers.isNotEmpty).toList();
    if (withNumbers.isNotEmpty) {
      final e = withNumbers.last;
      parts.add('${e.keyName ?? e.rawText} ${e.numbers.split(' · ').first}');
    }
    final g = ghosts.length;
    if (g > 0) parts.add('$g planned');
    return parts.join(' · ');
  }

  Future<void> load([String? date]) async {
    if (date != null) {
      _customDate = date;
    }
    final activeToday = await resolveActiveDay();
    _todayDate = activeToday;
    if (_customDate == _todayDate) {
      _customDate = null;
    }

    if (events.isEmpty && loading) {
      notifyListeners();
    }

    final keys = await _s.db.activeKeys();
    final names = {for (final k in keys) k.id: k.name};
    final rows = await _s.db.eventsForDay(dayDate);
    events = [for (final e in rows) if (e.status != 'pending') EventView.from(e, names)];
    pending = isToday
        ? [for (final e in await _s.db.pendingEvents()) EventView.from(e, names)]
        : const [];

    final s = await _s.db.daySummary(dayDate);
    daySummary = s?.summary;
    flags = const [];
    if (s?.flags != null) {
      try {
        flags = (jsonDecode(s!.flags!) as List).cast<String>();
      } catch (_) {}
    }
    loading = false;
    notifyListeners();
    if (isToday) WidgetSyncService.syncWidgets(db: _s.db, todayEvents: rows);
  }

  Future<void> updateEvent({
    required int id,
    required String rawText,
    int? keyId,
    DateTime? at,
    String? note,
    int? durationMin,
    double? quantity,
    String? unit,
  }) async {
    final before = await _s.db.eventById(id);
    await _s.db.updateEvent(
        id,
        EventsCompanion(
          rawText: Value(rawText),
          keyId: Value(keyId),
          note: Value(note),
          durationMin: Value(durationMin),
          quantity: Value(quantity),
          unit: Value(unit),
          tsUtc: at != null ? Value(at.toUtc()) : const Value.absent(),
        ));
    if (before != null) {
      if (keyId != null && before.keyId != keyId) {
        final name = (await _s.db.keyById(keyId))?.name ?? '$keyId';
        await _s.capture.recordCorrection(rawText, 'key',
            predicted: before.keyId == null ? null : (await _s.db.keyById(before.keyId!))?.name,
            corrected: name);
      }
      if (at != null && before.tsUtc.toLocal() != at) {
        await _s.capture.recordCorrection(rawText, 'time',
            predicted: before.tsUtc.toLocal().toIso8601String(), corrected: at.toIso8601String());
      }
    }
    _s.vocab.invalidate();
    await load();
  }

  Future<void> deleteEvent(int id) async {
    final e = await _s.db.eventById(id);
    if (e?.photoPath != null) {
      try {
        await File(e!.photoPath!).delete();
      } catch (_) {}
    }
    await _s.db.softDeleteEvent(id);
    await load();
  }

  Future<void> completeGhost(int id, {DateTime? at}) async {
    await _s.capture.completePlanned(id, at: at);
    await load();
  }

  Future<void> skip(int id) async {
    await _s.capture.skipPlanned(id);
    await load();
  }

  Future<void> reviewDidIt(EventView e) => completeGhost(e.id, at: e.local);
  Future<void> reviewToday(EventView e) async {
    await _s.capture.moveToToday(e.id);
    await load();
  }
  Future<void> reviewSkipAll() async {
    for (final e in pending) {
      await _s.capture.skipPlanned(e.id);
    }
    await load();
  }
}

/// The chip row. Due now -> usual now -> time-relevant keys -> frequent.
/// Bed and Up are dynamically placed based on learned sleep/wake habits.
class Chip {
  Chip({
    required this.keyId,
    required this.name,
    this.plannedEventId,
    this.at,
    this.minute,
    this.isBed = false,
    this.isUp = false,
  });
  final int keyId;
  final String name;
  final int? plannedEventId; // set for "due now" chips; tapping completes the ghost
  final DateTime? at;
  final int? minute; // usual minute, for the hue dot
  final bool isBed;
  final bool isUp;
}

class ChipsController extends ChangeNotifier {
  ChipsController(this._s);
  final Services _s;
  List<Chip> chips = const [];

  Future<void> load({int count = 9, DateTime? referenceTime, String? targetDayDate}) async {
    final now = referenceTime ?? DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final today = targetDayDate ?? DayResolver.formatDay(now);

    final keys = List<Key>.from(await _s.db.activeKeys());
    final names = {for (final k in keys) k.id: k.name};
    final out = <Chip>[];
    final seenKeys = <int>{};

    // 1. due now: planned events within -30..+90 min, today
    for (final e in await _s.db.plannedFrom(today)) {
      if (e.keyId == null) continue;
      final diff = e.tsUtc.toLocal().difference(now).inMinutes;
      if (diff >= -30 && diff <= 90 && seenKeys.add(e.keyId!)) {
        out.add(Chip(
            keyId: e.keyId!,
            name: names[e.keyId] ?? e.rawText,
            plannedEventId: e.id,
            at: e.tsUtc.toLocal()));
      }
    }

    // 2. Resolve learned sleep and wake parameters
    var sleepKey = keys.where((k) => k.name == 'sleep').firstOrNull;
    var wakeKey = keys.where((k) => k.name == 'wake').firstOrNull;

    if (sleepKey == null) {
      final id = await _s.db.createKey('sleep');
      sleepKey = (await _s.db.keyById(id))!;
      keys.add(sleepKey);
      names[sleepKey.id] = sleepKey.name;
    }
    if (wakeKey == null) {
      final id = await _s.db.createKey('wake');
      wakeKey = (await _s.db.keyById(id))!;
      keys.add(wakeKey);
      names[wakeKey.id] = wakeKey.name;
    }

    int sleepMinute = 22 * 60 + 30; // default 22:30
    if (sleepKey != null) {
      final learned = await _s.vocab.usualMinute(sleepKey.id);
      if (learned != null) {
        sleepMinute = learned;
      } else {
        final evH = await _s.settings.sleepEveningHour();
        sleepMinute = evH * 60 + 30;
      }
    }

    int wakeMinute = 7 * 60; // default 07:00
    if (wakeKey != null) {
      final learned = await _s.vocab.usualMinute(wakeKey.id);
      if (learned != null) {
        wakeMinute = learned;
      } else {
        final cutH = await _s.settings.dayCutoffHour();
        wakeMinute = cutH * 60 + 180; // e.g. 4:00 + 3h = 7:00 AM
      }
    }

    // Check if wake or sleep are already logged for the active day
    final doneToday = await _s.db.doneEventsForDay(today);
    final wakeLoggedToday = wakeKey != null &&
        doneToday.any((e) => (wakeKey != null && e.keyId == wakeKey.id) || e.rawText.toLowerCase() == 'up');
    final sleepLoggedToday = sleepKey != null &&
        doneToday.any((e) => (sleepKey != null && e.keyId == sleepKey.id) || e.rawText.toLowerCase() == 'bed');

    // 3. Score all active keys based on time-of-day relevance and history
    final rows = await _s.db.customSelect(
      'SELECT k.id AS id, k.usual_minute_override AS override, e.ts_utc AS ts FROM keys k '
      'LEFT JOIN events e ON e.key_id = k.id AND e.deleted_at IS NULL '
      "  AND e.status = 'done' AND e.ts_utc >= ? "
      'WHERE k.is_archived = 0',
      variables: [
        Variable.withInt(now.toUtc().subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000)
      ],
    ).get();

    final score = <int, double>{};
    final minutes = <int, List<int>>{};
    final overrides = <int, int?>{};

    for (final r in rows) {
      final id = r.read<int>('id');
      score.putIfAbsent(id, () => 0.0);
      overrides[id] = r.readNullable<int>('override');
      final ts = r.readNullable<DateTime>('ts');
      if (ts == null) continue;
      final l = ts.toLocal();
      final m = l.hour * 60 + l.minute;
      minutes.putIfAbsent(id, () => []).add(m);

      final d = _circDiff(nowMin, m);
      // Heavy weighting for matching time-of-day:
      if (d <= 60) {
        score[id] = score[id]! + 3.0;
      } else if (d <= 120) {
        score[id] = score[id]! + 1.5;
      } else if (d <= 180) {
        score[id] = score[id]! + 0.5;
      }
      score[id] = score[id]! + 0.05; // tiny recency baseline
    }

    // Give bonus to keys whose median time or manual override is close to now
    for (final k in keys) {
      score.putIfAbsent(k.id, () => 0.0);
      final override = overrides[k.id] ?? k.usualMinuteOverride;
      final ms = minutes[k.id];
      final targetMin = override ?? (ms != null && ms.length >= 2 ? _median(ms) : null);

      if (targetMin != null) {
        final d = _circDiff(nowMin, targetMin);
        if (d <= 60) {
          score[k.id] = score[k.id]! + 18.0 * (1.0 - d / 60);
        } else if (d <= 120) {
          score[k.id] = score[k.id]! + 8.0 * (1.0 - d / 120);
        } else if (d <= 240) {
          score[k.id] = score[k.id]! + 3.0 * (1.0 - d / 240);
        }
      }

      // Discovery boost for newly created keys with few examples
      if (k.exampleCount <= 2 && k.name != 'sleep' && k.name != 'wake') {
        score[k.id] = score[k.id]! + 1.5;
      }
    }

    // Dynamic scoring for Up (wake) based on learned wake schedule:
    if (wakeKey != null) {
      final dWake = _circDiff(nowMin, wakeMinute);
      if (now.hour >= 4 && now.hour <= 11) {
        // Morning window: high priority, especially if not yet logged
        score[wakeKey.id] = !wakeLoggedToday
            ? 35.0 + (180 - dWake.clamp(0, 180)) / 10.0
            : 1.0;
      } else {
        // Daytime / Evening / Night: Up drops to low priority
        score[wakeKey.id] = wakeLoggedToday ? 0.05 : 0.6;
      }
    }

    // Dynamic scoring for Bed (sleep) based on learned sleep schedule:
    if (sleepKey != null) {
      final dSleep = _circDiff(nowMin, sleepMinute);
      if (now.hour >= 20 || now.hour < 4) {
        // Bedtime window: high priority, especially if approaching bedtime
        score[sleepKey.id] = !sleepLoggedToday
            ? 35.0 + (180 - dSleep.clamp(0, 180)) / 10.0
            : 1.0;
      } else if (now.hour >= 13 && now.hour < 15) {
        // Midday nap possibility
        score[sleepKey.id] = 1.5;
      } else {
        // Morning / Daytime: Bed drops to low priority
        score[sleepKey.id] = 0.05;
      }
    }

    // 4. Rank keys by time score
    final ranked = score.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (final e in ranked) {
      if (out.length >= count) break;
      if (!seenKeys.add(e.key)) continue;
      final rawName = names[e.key];
      if (rawName == null) continue;

      final isBed = rawName == 'sleep';
      final isUp = rawName == 'wake';
      final displayName = isBed ? 'Bed' : (isUp ? 'Up' : rawName);
      final ms = minutes[e.key];
      final med = overrides[e.key] ?? (ms == null || ms.length < 2 ? null : _median(ms));

      out.add(Chip(
        keyId: e.key,
        name: displayName,
        minute: isBed || isUp ? null : med,
        isBed: isBed,
        isUp: isUp,
      ));
    }

    // Ensure Bed and Up are available in the chips row (even if ranked later during the day)
    if (wakeKey != null && seenKeys.add(wakeKey.id)) {
      out.add(Chip(keyId: wakeKey.id, name: 'Up', isUp: true));
    }
    if (sleepKey != null && seenKeys.add(sleepKey.id)) {
      out.add(Chip(keyId: sleepKey.id, name: 'Bed', isBed: true));
    }

    chips = out;
    notifyListeners();
  }

  static int _circDiff(int a, int b) {
    var d = (a - b).abs();
    if (d > 720) d = 1440 - d;
    return d;
  }

  static int _median(List<int> xs) {
    final s = [...xs]..sort();
    return s[s.length ~/ 2];
  }
}

class ListsController extends ChangeNotifier {
  ListsController(this._s);
  final Services _s;
  List<ListItem> items = const [];
  Map<int, String> keyNames = const {};
  Map<int, DateTime> plannedAt = const {}; // itemId -> local time if promoted

  Future<void> load() async {
    items = await _s.db.openListItems();
    final keys = await _s.db.activeKeys();
    keyNames = {for (final k in keys) k.id: k.name};
    final planned = <int, DateTime>{};
    for (final it in items) {
      if (it.plannedEventId != null) {
        final e = await _s.db.eventById(it.plannedEventId!);
        if (e != null && e.status == 'planned') planned[it.id] = e.tsUtc.toLocal();
      }
    }
    plannedAt = planned;
    notifyListeners();
  }

  List<String?> get sections {
    final s = <String?>[];
    for (final it in items) {
      if (!s.contains(it.section)) s.add(it.section);
    }
    return s;
  }

  Future<void> add(String title, {String? section}) async {
    await _s.capture.addListItem(title, section: section);
    await load();
  }

  Future<void> tick(int id, {DateTime? at}) async {
    await _s.capture.completeListItem(id, at: at);
    await load();
  }

  Future<void> promote(int id, DateTime when) async {
    await _s.capture.promoteListItem(id, when);
    await load();
  }

  Future<void> remove(int id) async {
    await _s.db.updateListItem(id, ListItemsCompanion(deletedAt: Value(DateTime.now().toUtc())));
    await load();
  }
}

class PatternsController extends ChangeNotifier {
  PatternsController(this._s);
  final Services _s;

  List<({int id, String name})> keys = const [];
  int? selectedKeyId;
  Map<String, int> heat = const {};
  int count7d = 0, count30d = 0, streak = 0;
  int? usualMinute;
  bool usualIsOverride = false;
  int plannedCount = 0, doneOfPlanned = 0;
  List<({String day, double value})> quantitySeries = const [];
  String? quantityUnit;
  int totalMinutes30d = 0;

  Future<void> load() async {
    final ks = await _s.db.activeKeys();
    keys = [for (final k in ks) (id: k.id, name: k.name)];
    if (keys.isNotEmpty) {
      selectedKeyId ??= keys.first.id;
      await select(selectedKeyId!);
    } else {
      notifyListeners();
    }
  }

  Future<void> select(int keyId) async {
    selectedKeyId = keyId;
    final rows = await _s.db.customSelect(
      'SELECT day_date, status, quantity, unit, duration_min, ts_utc, metadata FROM events '
      "WHERE key_id = ?1 AND deleted_at IS NULL AND ts_utc >= strftime('%s','now','-84 days')",
      variables: [Variable.withInt(keyId)],
    ).get();
    final map = <String, int>{};
    final qty = <String, double>{};
    String? unit;
    var planned = 0, doneP = 0, mins = 0;
    final since30 = DateTime.now().subtract(const Duration(days: 30));
    for (final r in rows) {
      final status = r.read<String>('status');
      final day = r.read<String>('day_date');
      final ts = DateTime.fromMillisecondsSinceEpoch(r.read<int>('ts_utc') * 1000, isUtc: true);
      if (status == 'done') {
        map[day] = (map[day] ?? 0) + 1;
        final q = r.readNullable<double>('quantity');
        if (q != null) {
          qty[day] = (qty[day] ?? 0) + q;
          unit ??= r.readNullable<String>('unit');
        }
        final d = r.readNullable<int>('duration_min');
        if (d != null && ts.isAfter(since30)) mins += d;
      }
      final wasPlanned = (r.readNullable<String>('metadata') ?? '').contains('"was_planned":true');
      if (status == 'skipped') planned++;
      if (status == 'done' && wasPlanned) {
        planned++;
        doneP++;
      }
    }
    heat = map;
    quantitySeries = [for (final e in (qty.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) (day: e.key, value: e.value)];
    quantityUnit = unit;
    totalMinutes30d = mins;
    plannedCount = planned;
    doneOfPlanned = doneP;
    count7d = _countSince(map, 7);
    count30d = _countSince(map, 30);
    streak = _streak(map);
    final k = await _s.db.keyById(keyId);
    usualIsOverride = k?.usualMinuteOverride != null;
    usualMinute = await _s.vocab.usualMinute(keyId);
    notifyListeners();
  }

  Future<void> setUsualOverride(int? minute) async {
    if (selectedKeyId == null) return;
    await _s.db.updateKey(selectedKeyId!, KeysCompanion(usualMinuteOverride: Value(minute)));
    await select(selectedKeyId!);
  }

  static int _countSince(Map<String, int> map, int days) {
    var t = 0;
    for (var i = 0; i < days; i++) {
      t += map[DayResolver.formatDay(DateTime.now().subtract(Duration(days: i)))] ?? 0;
    }
    return t;
  }

  static int _streak(Map<String, int> map) {
    var s = 0;
    for (var i = 0; i < 365; i++) {
      final d = DayResolver.formatDay(DateTime.now().subtract(Duration(days: i)));
      if ((map[d] ?? 0) > 0) {
        s++;
      } else if (i > 0) {
        break;
      }
    }
    return s;
  }
}
