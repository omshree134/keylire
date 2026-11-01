import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keylire/core/time/day_resolver.dart';
import 'package:keylire/data/db/database.dart';
import 'package:keylire/services/analysis/day_close_service.dart';
import 'package:keylire/services/backup/export_service.dart';
import 'package:keylire/services/capture/capture_service.dart';
import 'package:keylire/services/embeddings/hashing_embedding_service.dart';
import 'package:keylire/services/llm/llm_client.dart';
import 'package:keylire/services/matching/key_matcher.dart';
import 'package:keylire/services/metrics/dogfood_metrics.dart';
import 'package:keylire/services/photos/photo_understanding_service.dart';
import 'package:keylire/services/recurrence/recurrence_engine.dart';
import 'package:keylire/services/settings/settings_service.dart';
import 'package:keylire/services/time/time_vocab_service.dart';
import 'package:keylire/ui/controllers/app_state.dart';

void main() {
  group('Database Production Features', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    test('PRAGMA integrity check returns true on healthy database', () async {
      final healthy = await db.checkIntegrity();
      expect(healthy, isTrue);
    });

    test('searchEvents filters by text, keyId, and date range', () async {
      final gymKeyId = await db.createKey('gym');
      final workKeyId = await db.createKey('work');

      final now = DateTime.now().toUtc();

      await db.insertEvent(EventsCompanion.insert(
        rawText: 'Chest and triceps workout',
        modality: 'text',
        keyId: Value(gymKeyId),
        tsUtc: now.subtract(const Duration(days: 1)),
        tz: 'UTC',
        dayDate: '2026-10-28',
        keySource: 'picked',
        note: const Value('Felt great, increased bench weight'),
      ));

      await db.insertEvent(EventsCompanion.insert(
        rawText: 'Sprint planning meeting',
        modality: 'text',
        keyId: Value(workKeyId),
        tsUtc: now,
        tz: 'UTC',
        dayDate: '2026-10-29',
        keySource: 'auto',
        note: const Value('Discussed roadmap for Q4'),
      ));

      await db.insertEvent(EventsCompanion.insert(
        rawText: 'Leg day squats',
        modality: 'text',
        keyId: Value(gymKeyId),
        tsUtc: now.subtract(const Duration(days: 40)),
        tz: 'UTC',
        dayDate: '2026-09-15',
        keySource: 'picked',
      ));

      // 1. Text search matching rawText
      final chestResults = await db.searchEvents(query: 'triceps');
      expect(chestResults.length, 1);
      expect(chestResults.first.rawText, contains('workout'));

      // 2. Text search matching note
      final noteResults = await db.searchEvents(query: 'roadmap');
      expect(noteResults.length, 1);
      expect(noteResults.first.rawText, contains('planning'));

      // 3. Filter by keyId
      final gymResults = await db.searchEvents(keyId: gymKeyId);
      expect(gymResults.length, 2);

      // 4. Combined query and keyId
      final legGymResults =
          await db.searchEvents(query: 'squats', keyId: gymKeyId);
      expect(legGymResults.length, 1);

      // 5. Date range filter
      final recentResults =
          await db.searchEvents(fromDate: '2026-10-01', toDate: '2026-10-31');
      expect(recentResults.length, 2);
    });

    test(
        'mergeKeys atomically moves events and list items, archiving source key',
        () async {
      final oldKeyId = await db.createKey('fitness');
      final newKeyId = await db.createKey('workout');

      // Add event under old key
      final eventId = await db.insertEvent(EventsCompanion.insert(
        rawText: 'Morning run 5k',
        modality: 'text',
        keyId: Value(oldKeyId),
        tsUtc: DateTime.now().toUtc(),
        tz: 'UTC',
        dayDate: '2026-10-29',
        keySource: 'picked',
      ));

      // Add list item under old key
      final listItemId = await db.insertListItem(ListItemsCompanion.insert(
        title: 'Buy protein powder',
        keyId: Value(oldKeyId),
      ));

      // Merge oldKey into newKey
      await db.mergeKeys(fromKeyId: oldKeyId, toKeyId: newKeyId);

      // Verify event moved
      final updatedEvent = await db.eventById(eventId);
      expect(updatedEvent?.keyId, newKeyId);

      // Verify list item moved
      final updatedListItem = await (db.select(db.listItems)
            ..where((l) => l.id.equals(listItemId)))
          .getSingle();
      expect(updatedListItem.keyId, newKeyId);

      // Verify old key archived
      final oldKey = await db.keyById(oldKeyId);
      expect(oldKey?.isArchived, isTrue);

      // Active keys should now only have newKey
      final active = await db.activeKeys();
      expect(active.any((k) => k.id == oldKeyId), isFalse);
      expect(active.any((k) => k.id == newKeyId), isTrue);
    });

    test('cleanupSoftDeleted purges deleted records past the retention window',
        () async {
      final now = DateTime.now().toUtc();

      // Non-deleted event
      await db.insertEvent(EventsCompanion.insert(
        rawText: 'Active event',
        modality: 'text',
        tsUtc: now,
        tz: 'UTC',
        dayDate: '2026-10-29',
        keySource: 'picked',
      ));

      // Recently deleted event (1 day ago)
      final recentId = await db.insertEvent(EventsCompanion.insert(
        rawText: 'Recently deleted',
        modality: 'text',
        tsUtc: now,
        tz: 'UTC',
        dayDate: '2026-10-29',
        keySource: 'picked',
      ));
      await (db.update(db.events)..where((e) => e.id.equals(recentId))).write(
        EventsCompanion(
            deletedAt: Value(now.subtract(const Duration(days: 1)))),
      );

      // Old deleted event (100 days ago)
      final oldId = await db.insertEvent(EventsCompanion.insert(
        rawText: 'Old deleted event',
        modality: 'text',
        tsUtc: now,
        tz: 'UTC',
        dayDate: '2026-07-01',
        keySource: 'picked',
      ));
      await (db.update(db.events)..where((e) => e.id.equals(oldId))).write(
        EventsCompanion(
            deletedAt: Value(now.subtract(const Duration(days: 100)))),
      );

      final purgedCount = await db.cleanupSoftDeleted(daysOld: 90);
      expect(purgedCount, 1);

      // Verify old deleted event is physically gone
      final oldEvent = await db.eventById(oldId);
      expect(oldEvent, isNull);

      // Verify recently deleted event remains soft-deleted
      final recentEvent = await db.eventById(recentId);
      expect(recentEvent, isNotNull);
      expect(recentEvent?.deletedAt, isNotNull);
    });
  });

  group('LlmClient Resiliency', () {
    test('enforces timeout on slow network responses', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final settings = SettingsService(db);
      await settings.setApiKey('test_key');

      // Mock client with delay longer than timeout
      final mockClient = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return http.Response('{"choices": []}', 200);
      });

      final llm = LlmClient(
        settings: settings,
        httpClient: mockClient,
        timeout: const Duration(milliseconds: 20), // fast timeout for test
      );

      expect(
        () => llm.completeJson(
          system: 'test',
          messages: [
            {'role': 'user', 'content': 'hi'}
          ],
        ),
        throwsA(isA<LlmException>()),
      );
    });
  });

  group('Passcode Authentication & App Lock', () {
    test('passcode sets, verifies salted hash, and clears cleanly', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final settings = SettingsService(db);

      // Initially no passcode
      expect(await settings.hasPasscode(), isFalse);

      // Set 4-digit PIN
      await settings.setPasscode('4829');
      expect(await settings.hasPasscode(), isTrue);

      // Verify correct PIN
      expect(await settings.verifyPasscode('4829'), isTrue);

      // Verify wrong PIN
      expect(await settings.verifyPasscode('0000'), isFalse);
      expect(await settings.verifyPasscode('1234'), isFalse);

      // Verify plaintext PIN is never stored in settings table
      final storedHash = await db.setting('app_lock_hash');
      final storedSalt = await db.setting('app_lock_salt');
      expect(storedHash, isNotNull);
      expect(storedSalt, isNotNull);
      expect(storedHash, isNot(contains('4829')));

      // Remove passcode
      await settings.setPasscode(null);
      expect(await settings.hasPasscode(), isFalse);
      expect(await settings.verifyPasscode('4829'),
          isTrue); // no lock returns true
    });
  });

  group('Weekly Retrospective & Memories', () {
    late AppDatabase db;
    late Services services;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final settings = SettingsService(db);
      final embedder = HashingEmbeddingService();
      final matcher = KeyMatcher(db, embedder, settings);
      final vocab = TimeVocabService(db);
      final capture = CaptureService(db, matcher, settings, vocab);
      final recurrence = RecurrenceEngine(db);
      final dayClose =
          DayCloseService(db, settings, recurrence, DayResolver());
      final photos = PhotoUnderstandingService(db);

      services = Services(
        db: db,
        settings: settings,
        matcher: matcher,
        capture: capture,
        vocab: vocab,
        dayClose: dayClose,
        recurrence: recurrence,
        export: ExportService(db),
        metrics: DogfoodMetrics(db),
        photos: photos,
      );
    });

    tearDown(() => db.close());

    test('calculates weekly retrospective metrics accurately', () async {
      final gymKeyId = await db.createKey('gym');
      final workKeyId = await db.createKey('work');

      final now = DateTime.now().toUtc();
      final todayStr = DayResolver.formatDay(now.toLocal());
      final yesterdayStr = DayResolver.formatDay(
          now.toLocal().subtract(const Duration(days: 1)));

      // Add done events
      await db.insertEvent(EventsCompanion.insert(
        rawText: 'Morning workout',
        modality: 'text',
        keyId: Value(gymKeyId),
        tsUtc: now,
        tz: 'UTC',
        dayDate: todayStr,
        keySource: 'picked',
        durationMin: const Value(45),
      ));

      await db.insertEvent(EventsCompanion.insert(
        rawText: 'Deep work block',
        modality: 'text',
        keyId: Value(workKeyId),
        tsUtc: now.subtract(const Duration(days: 1)),
        tz: 'UTC',
        dayDate: yesterdayStr,
        keySource: 'picked',
        durationMin: const Value(120),
      ));

      // Add planned completed event
      await db.insertEvent(EventsCompanion.insert(
        rawText: 'Planned review',
        modality: 'text',
        keyId: Value(workKeyId),
        tsUtc: now,
        tz: 'UTC',
        dayDate: todayStr,
        keySource: 'picked',
        metadata: const Value('{"was_planned":true}'),
      ));

      // Add day summary
      await db.upsertDaySummary(DaySummariesCompanion.insert(
        dayDate: todayStr,
        summary: 'Productive day focusing on workouts and review.',
        eventCount: 3,
      ));

      final patternsController = PatternsController(services);
      final retro = await patternsController.getWeeklyRetrospective(days: 7);

      expect(retro.totalEvents, 3);
      expect(retro.activeDays, 2);
      expect(retro.plannedCount, 1);
      expect(retro.completedPlannedCount, 1);
      expect(retro.plannedCompletionRate, 1.0);
      expect(retro.topKeys.length, 2);
      expect(retro.topKeys.first.name, 'work');
      expect(retro.topKeys.first.count, 2);
      expect(retro.topKeys.first.totalMinutes, 120);
      expect(retro.daySummaries,
          contains('Productive day focusing on workouts and review.'));
    });

    test('loads flashback memories for past month and past years', () async {
      final readingKeyId = await db.createKey('reading');
      final pastMonthDate = '2026-09-30';

      // Insert event 1 month prior
      await db.insertEvent(EventsCompanion.insert(
        rawText: 'Read Chapter 4 of Designing Data-Intensive Applications',
        modality: 'text',
        keyId: Value(readingKeyId),
        tsUtc: DateTime(2026, 9, 30, 10, 0).toUtc(),
        tz: 'UTC',
        dayDate: pastMonthDate,
        keySource: 'picked',
        note: const Value('Fascinating insights into LSM-trees vs B-trees'),
      ));

      await db.upsertDaySummary(DaySummariesCompanion.insert(
        dayDate: pastMonthDate,
        summary: 'Quiet reading morning.',
        eventCount: 1,
      ));

      final todayController = TodayController(services);
      await todayController.load('2026-10-30');

      expect(todayController.memories.length, greaterThanOrEqualTo(1));
      final memory = todayController.memories
          .firstWhere((m) => m.dayDate == pastMonthDate);
      expect(memory.label, '1 month ago');
      expect(memory.events.length, 1);
      expect(memory.events.first.rawText,
          contains('Designing Data-Intensive Applications'));
      expect(memory.summary, 'Quiet reading morning.');
    });
  });
}
