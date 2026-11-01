import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keylire/data/db/database.dart';
import 'package:keylire/services/analysis/day_close_service.dart';
import 'package:keylire/services/backup/export_service.dart';
import 'package:keylire/services/capture/capture_service.dart';
import 'package:keylire/services/embeddings/hashing_embedding_service.dart';
import 'package:keylire/services/matching/key_matcher.dart';
import 'package:keylire/services/metrics/dogfood_metrics.dart';
import 'package:keylire/services/photos/photo_understanding_service.dart';
import 'package:keylire/services/recurrence/recurrence_engine.dart';
import 'package:keylire/services/settings/settings_service.dart';
import 'package:keylire/services/time/time_vocab_service.dart';
import 'package:keylire/core/time/day_resolver.dart';
import 'package:keylire/ui/controllers/app_state.dart';

void main() {
  late AppDatabase db;
  late SettingsService settings;
  late HashingEmbeddingService embedder;
  late KeyMatcher matcher;
  late TimeVocabService vocab;
  late CaptureService capture;
  late Services services;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = SettingsService(db);
    embedder = HashingEmbeddingService();
    matcher = KeyMatcher(db, embedder, settings);
    vocab = TimeVocabService(db);
    capture = CaptureService(db, matcher, settings, vocab);
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

    // Create sleep and wake keys
    await db.createKey('sleep');
    await db.createKey('wake');
    await db.createKey('breakfast');
    await db.createKey('lunch');
    await db.createKey('dinner');
    await matcher.warmUp();
  });

  tearDown(() async {
    await db.close();
  });

  test('suggestKeyName extracts clean activity names without stop words', () {
    expect(capture.suggestKeyName('went for swimming'), 'swimming');
    expect(capture.suggestKeyName('doing yoga 30 min'), 'yoga');
    expect(
        capture.suggestKeyName('played badminton with friends'), 'badminton');
    expect(capture.suggestKeyName('reading a book'), 'book');
    expect(capture.suggestKeyName('woke up early'), 'wake');
    expect(capture.suggestKeyName('going to sleep'), 'sleep');
    expect(capture.suggestKeyName('math exam revision'), 'math');
  });

  test('ChipsController ranks Up high in morning and Bed high at night',
      () async {
    final chipsCtrl = ChipsController(services);

    // 1. Morning at 07:30 AM (before wake logged)
    final morningTime = DateTime(2026, 9, 9, 7, 30);
    await chipsCtrl.load(referenceTime: morningTime);
    expect(chipsCtrl.chips.isNotEmpty, isTrue);
    // Up should be at the front
    expect(chipsCtrl.chips.first.name, 'Up');

    // 2. Night at 22:45 PM
    final nightTime = DateTime(2026, 9, 9, 22, 45);
    await chipsCtrl.load(referenceTime: nightTime);
    expect(chipsCtrl.chips.isNotEmpty, isTrue);
    // Bed should be at the front
    expect(chipsCtrl.chips.first.name, 'Bed');
  });

  test('ChipsController shows keys relevant to midday at 13:00', () async {
    // Log some midday lunch events
    final lunchKey = (await db.keyByName('lunch'))!;
    for (var i = 1; i <= 5; i++) {
      await db.insertEvent(EventsCompanion.insert(
        keyId: Value(lunchKey.id),
        tsUtc: DateTime(2026, 9, i, 13, 0).toUtc(),
        tz: 'local',
        dayDate: '2026-09-0$i',
        rawText: 'lunch',
        modality: 'text',
        keySource: 'picked',
        status: const Value('done'),
      ));
    }

    final chipsCtrl = ChipsController(services);
    final middayTime = DateTime(2026, 9, 9, 13, 0);
    await chipsCtrl.load(referenceTime: middayTime);

    // Lunch should be near the front, while Up and Bed are not first
    expect(chipsCtrl.chips.any((c) => c.name == 'lunch'), isTrue);
    final lunchIndex = chipsCtrl.chips.indexWhere((c) => c.name == 'lunch');
    final bedIndex = chipsCtrl.chips.indexWhere((c) => c.name == 'Bed');
    final upIndex = chipsCtrl.chips.indexWhere((c) => c.name == 'Up');

    expect(lunchIndex, lessThan(bedIndex));
    expect(lunchIndex, lessThan(upIndex));
  });

  test('ChipsController promotes keys matching the typed phrase', () async {
    final vector = await embedder.embed('strength workout');
    await matcher.createKeyWithSeed('gym', 'strength workout', vector);
    await matcher.warmUp();

    final chipsCtrl = ChipsController(services);
    await chipsCtrl.load(
      referenceTime: DateTime(2026, 9, 9, 16),
      query: 'strength workout today',
    );

    final gym = chipsCtrl.chips.firstWhere((c) => c.name == 'gym');
    expect(gym.reason, ChipReason.phrase);
    expect(gym.selectorLabel, 'gym · matches');
  });

  test('ChipsController surfaces a confirmed routine near its window',
      () async {
    final lunchKey = (await db.keyByName('lunch'))!;
    final at = DateTime(2026, 9, 9, 13); // Wednesday
    await db.into(db.recurrences).insert(RecurrencesCompanion.insert(
          keyId: lunchKey.id,
          dayOfWeek: at.weekday - 1,
          windowStart: '12:00',
          windowEnd: '14:00',
          status: 'confirmed',
          confidence: 0.75,
        ));

    final chipsCtrl = ChipsController(services);
    await chipsCtrl.load(referenceTime: at);

    final lunch = chipsCtrl.chips.firstWhere((c) => c.name == 'lunch');
    expect(lunch.reason, ChipReason.routine);
    expect(lunch.selectorLabel, 'lunch · routine now');
  });

  test('TodayController asks before activating a detected pattern', () async {
    final lunchKey = (await db.keyByName('lunch'))!;
    final recurrenceId = await db.into(db.recurrences).insert(
          RecurrencesCompanion.insert(
            keyId: lunchKey.id,
            dayOfWeek: 2,
            windowStart: '12:00',
            windowEnd: '14:00',
            status: 'proposed',
            confidence: 0.6,
            hitCount: const Value(3),
          ),
        );

    final today = TodayController(services);
    await today.load('2026-09-09');

    expect(today.patternProposals, hasLength(1));
    expect(today.patternProposals.single.keyName, 'lunch');
    expect(today.patternProposals.single.evidence,
        '3 times on Wednesdays · 12:00–14:00');

    await today.confirmPattern(recurrenceId);
    expect(today.patternProposals, isEmpty);
    final confirmed = await (db.select(db.recurrences)
          ..where((row) => row.id.equals(recurrenceId)))
        .getSingle();
    expect(confirmed.status, 'confirmed');
  });

  test('rejecting a pattern suppresses the same future proposal', () async {
    final dinnerKey = (await db.keyByName('dinner'))!;
    final recurrenceId = await db.into(db.recurrences).insert(
          RecurrencesCompanion.insert(
            keyId: dinnerKey.id,
            dayOfWeek: 4,
            windowStart: '19:00',
            windowEnd: '21:00',
            status: 'proposed',
            confidence: 0.5,
            hitCount: const Value(3),
          ),
        );

    final today = TodayController(services);
    await today.load('2026-09-11');
    await today.dismissPattern(recurrenceId);

    expect(await db.select(db.recurrences).get(), isEmpty);
    final suppressions = await db.select(db.recurrenceSuppressions).get();
    expect(suppressions, hasLength(1));
    expect(suppressions.single.keyId, dinnerKey.id);
  });

  test('Learning mode new key creation seeds matcher and becomes searchable',
      () async {
    final m = await matcher.match('played tennis with alex');
    expect(m.top.where((k) => k.keyName == 'tennis').isEmpty, isTrue);

    final eventId = await db.insertEvent(EventsCompanion.insert(
      tsUtc: DateTime.now().toUtc(),
      tz: 'local',
      dayDate: '2026-09-09',
      rawText: 'played tennis with alex',
      modality: 'text',
      keySource: 'unfiled',
      status: const Value('done'),
    ));

    final newKeyId = await capture.resolveNewKey(
        eventId, m, 'tennis', 'played tennis with alex');
    expect(newKeyId, isPositive);

    // Now tennis should match
    final m2 = await matcher.match('tennis practice');
    expect(m2.top.isNotEmpty, isTrue);
    expect(m2.top.first.keyName, 'tennis');
  });
}
