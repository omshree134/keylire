import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../data/db/database.dart';
import '../capture/capture_service.dart';
import '../embeddings/hashing_embedding_service.dart';
import '../matching/key_matcher.dart';
import '../settings/settings_service.dart';
import '../time/time_vocab_service.dart';

/// Local notifications for the planned tense.
///   - one per planned event in the next 7 days, Done/Skip actions
///   - morning digest (one-shot, fresh content, rescheduled on every sync)
///   - evening nudge (daily), skipped when today is already well logged
/// Everything is cancelled and rescheduled on [sync]; the set is small.
class ReminderService {
  ReminderService(this.db, this.settings, this.capture, this.vocab);
  final AppDatabase db;
  final SettingsService settings;
  final CaptureService capture;
  final TimeVocabService vocab;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Timer? _debounce;

  static const _chPlans = 'plans';
  static const _chNudges = 'nudges';
  static const _idMorning = 1;
  static const _idEvening = 2;
  static const _planBase = 100000;
  static const horizonDays = 7;
  static const eveningSkipAfterEntries = 5;

  /// [onForegroundResponse] fires when the user taps a notification or an
  /// action while the app is alive. Background actions are handled by
  /// [reminderActionBackground] and never reach the UI.
  Future<void> init({
    required void Function(NotificationResponse r) onForegroundResponse,
  }) async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory('plan', actions: [
              DarwinNotificationAction.plain('done', 'Done'),
              DarwinNotificationAction.plain('skip', 'Skip'),
            ]),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: reminderActionBackground,
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final ok = await android.requestNotificationsPermission() ?? true;
      if (await android.canScheduleExactNotifications() == false) {
        await android.requestExactAlarmsPermission();
      }
      return ok;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, badge: false, sound: true) ??
        true;
  }

  /// Debounced; safe to call after every write.
  void sync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => unawaited(syncNow()));
  }

  Future<void> syncNow() async {
    if (!_ready) return;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final req in pending) {
        if (req.id == _idMorning || req.id == _idEvening || req.id >= _planBase) {
          await _plugin.cancel(req.id);
        }
      }
      if (!await settings.notificationsEnabled()) return;
      await _schedulePlans();
      await _scheduleMorning();
      await _scheduleEvening();
    } catch (e) {
      debugPrint('Keylire reminders: $e');
    }
  }

  // ----------------------------------------------------------------- plans

  Future<void> _schedulePlans() async {
    final now = DateTime.now();
    final today = await capture.activeDayDate(now);
    final keys = {for (final k in await db.activeKeys()) k.id: k.name};
    final horizon = now.add(const Duration(days: horizonDays));

    for (final e in await db.plannedFrom(today)) {
      final at = e.tsUtc.toLocal();
      if (!at.isAfter(now) || at.isAfter(horizon)) continue;
      final key = e.keyId == null ? null : keys[e.keyId];
      final hhmm = _hhmm(at);
      await _plugin.zonedSchedule(
        _planBase + e.id,
        e.rawText,
        key == null ? 'Planned for $hhmm' : '$key · planned for $hhmm',
        tz.TZDateTime.from(at, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _chPlans,
            'Planned entries',
            channelDescription: 'Reminders for things you planned',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            color: const Color(0xFF7A4F78),
            actions: const [
              AndroidNotificationAction('done', 'Done',
                  showsUserInterface: false),
              AndroidNotificationAction('skip', 'Skip',
                  showsUserInterface: false),
            ],
          ),
          iOS: const DarwinNotificationDetails(categoryIdentifier: 'plan'),
        ),
        androidScheduleMode: await _mode(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({'kind': 'plan', 'eventId': e.id}),
      );
    }
  }

  // --------------------------------------------------------------- nudges

  Future<void> _scheduleMorning() async {
    if (!await settings.nudgeMorning()) return;
    final wake = await _wakeMinute();
    final now = DateTime.now();
    var at = DateTime(
        now.year, now.month, now.day, (wake + 30) ~/ 60, (wake + 30) % 60);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));

    final day = await capture.activeDayDate(at);
    final plans = (await db.plannedFrom(day))
        .where((e) => e.dayDate == day)
        .toList()
      ..sort((a, b) => a.tsUtc.compareTo(b.tsUtc));
    final pending = await db.pendingEvents();

    String title, body;
    if (plans.isEmpty && pending.isEmpty) {
      title = 'Good morning';
      body = 'Tap Up when you\'re up. Nothing planned yet today.';
    } else {
      final n = plans.length;
      title = n == 0 ? 'Good morning' : '$n ${n == 1 ? 'plan' : 'plans'} today';
      final parts =
          plans.take(3).map((e) => '${e.rawText} ${_hhmm(e.tsUtc.toLocal())}');
      body = [
        if (parts.isNotEmpty) parts.join(' · '),
        if (pending.isNotEmpty) '${pending.length} from yesterday to review',
      ].join('\n');
    }

    await _plugin.zonedSchedule(
      _idMorning,
      title,
      body,
      tz.TZDateTime.from(at, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(_chNudges, 'Daily nudges',
            channelDescription: 'Morning digest and evening check-in',
            importance: Importance.defaultImportance,
            color: const Color(0xFF7A4F78),
            styleInformation: BigTextStyleInformation(body)),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: await _mode(inexactOk: true),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'kind': 'morning'}),
    );
  }

  Future<void> _scheduleEvening() async {
    if (!await settings.nudgeEvening()) return;
    final today = await capture.activeDayDate();
    if ((await db.doneEventsForDay(today)).length >= eveningSkipAfterEntries) {
      return;
    }

    final bed = await _bedMinute();
    final m = (bed - 60).clamp(0, 1439);
    final now = DateTime.now();
    var at = DateTime(now.year, now.month, now.day, m ~/ 60, m % 60);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      _idEvening,
      'Anything to log?',
      'A line or two before bed keeps the day whole.',
      tz.TZDateTime.from(at, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(_chNudges, 'Daily nudges',
            channelDescription: 'Morning digest and evening check-in',
            color: Color(0xFF7A4F78),
            importance: Importance.low),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: await _mode(inexactOk: true),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'kind': 'evening'}),
    );
  }

  // -------------------------------------------------------------- helpers

  Future<int> _wakeMinute() async {
    final k = await db.keyByName('wake');
    final learned = k == null ? null : await vocab.usualMinute(k.id);
    return learned ?? (await settings.dayCutoffHour()) * 60 + 180;
  }

  Future<int> _bedMinute() async {
    final k = await db.keyByName('sleep');
    final learned = k == null ? null : await vocab.usualMinute(k.id);
    return learned ?? (await settings.sleepEveningHour()) * 60 + 30;
  }

  Future<AndroidScheduleMode> _mode({bool inexactOk = false}) async {
    if (inexactOk) return AndroidScheduleMode.inexactAllowWhileIdle;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final exact = await android?.canScheduleExactNotifications() ?? true;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void dispose() => _debounce?.cancel();
}

/// Runs in a background isolate when the user taps Done/Skip on a plan
/// notification without opening the app. Same pattern as the widget
/// isolate: own DB handle, do the write, close.
@pragma('vm:entry-point')
Future<void> reminderActionBackground(NotificationResponse r) async {
  if (r.payload == null) return;
  Map<String, dynamic> p;
  try {
    p = jsonDecode(r.payload!) as Map<String, dynamic>;
  } catch (_) {
    return;
  }
  if (p['kind'] != 'plan') return;
  final id = p['eventId'] as int?;
  if (id == null) return;

  final db = AppDatabase();
  try {
    final settings = SettingsService(db);
    final vocab = TimeVocabService(db);
    // Matcher isn't needed for complete/skip; pass a throwaway.
    final capture =
        CaptureService(db, _NoMatcher(db, settings), settings, vocab);
    switch (r.actionId) {
      case 'done':
        await capture.completePlanned(id);
      case 'skip':
        await capture.skipPlanned(id);
    }
  } finally {
    await db.close();
  }
}

class _NoMatcher extends KeyMatcher {
  _NoMatcher(AppDatabase db, SettingsService s)
      : super(db, HashingEmbeddingService(), s);
}

