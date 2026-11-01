import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:keylire/ui/screens/search_screen.dart';
import 'package:keylire/ui/theme/daylog_theme.dart';

Services _services(AppDatabase db) {
  final settings = SettingsService(db);
  final embedder = HashingEmbeddingService();
  final matcher = KeyMatcher(db, embedder, settings);
  final vocab = TimeVocabService(db);
  final recurrence = RecurrenceEngine(db);
  final llm = LlmClient(settings: settings);
  return Services(
    db: db,
    settings: settings,
    matcher: matcher,
    capture: CaptureService(db, matcher, settings, vocab),
    vocab: vocab,
    dayClose: DayCloseService(db, llm, settings, recurrence, DayResolver()),
    recurrence: recurrence,
    export: ExportService(db),
    metrics: DogfoodMetrics(db),
    photos: PhotoUnderstandingService(db),
  );
}

void main() {
  testWidgets('SearchScreen finds entries and displays key filters',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final services = _services(db);

    final doctorKeyId = await db.createKey('doctor');
    await db.insertEvent(EventsCompanion.insert(
      rawText: 'Dr Smith annual checkup',
      modality: 'text',
      keyId: Value(doctorKeyId),
      tsUtc: DateTime.now().toUtc(),
      tz: 'UTC',
      dayDate: '2026-10-30',
      keySource: 'picked',
      note: const Value('Blood pressure 120/80 normal'),
    ));

    await tester.pumpWidget(
      ServicesScope(
        services: services,
        child: MaterialApp(
          theme: daylogTheme(Brightness.light),
          home: const SearchScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify search field and filter chip for 'doctor' are present
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('doctor'), findsOneWidget);

    // Type query 'checkup'
    await tester.enterText(find.byType(TextField), 'checkup');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Verify search result appears
    expect(find.text('Dr Smith annual checkup'), findsOneWidget);
    expect(find.textContaining('Blood pressure'), findsOneWidget);
  });
}

