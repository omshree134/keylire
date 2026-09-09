import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/data/db/database.dart';
import 'package:keyva/services/analysis/day_close_service.dart';
import 'package:keyva/services/backup/export_service.dart';
import 'package:keyva/services/capture/capture_service.dart';
import 'package:keyva/services/embeddings/hashing_embedding_service.dart';
import 'package:keyva/services/llm/llm_client.dart';
import 'package:keyva/services/matching/key_matcher.dart';
import 'package:keyva/services/metrics/dogfood_metrics.dart';
import 'package:keyva/services/photos/photo_understanding_service.dart';
import 'package:keyva/services/recurrence/recurrence_engine.dart';
import 'package:keyva/services/settings/settings_service.dart';
import 'package:keyva/services/time/time_vocab_service.dart';
import 'package:keyva/core/time/day_resolver.dart';
import 'package:keyva/ui/controllers/app_state.dart';

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
    final llm = LlmClient(settings: settings);
    final dayClose = DayCloseService(db, llm, settings, recurrence, DayResolver());
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
    expect(capture.suggestKeyName('played badminton with friends'), 'badminton');
    expect(capture.suggestKeyName('reading a book'), 'book');
    expect(capture.suggestKeyName('woke up early'), 'wake');
    expect(capture.suggestKeyName('going to sleep'), 'sleep');
    expect(capture.suggestKeyName('math exam revision'), 'math');
  });

  test('ChipsController ranks Up high in morning and Bed high at night', () async {
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

  test('Learning mode new key creation seeds matcher and becomes searchable', () async {
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

    final newKeyId = await capture.resolveNewKey(eventId, m, 'tennis', 'played tennis with alex');
    expect(newKeyId, isPositive);

    // Now tennis should match
    final m2 = await matcher.match('tennis practice');
    expect(m2.top.isNotEmpty, isTrue);
    expect(m2.top.first.keyName, 'tennis');
  });
}
