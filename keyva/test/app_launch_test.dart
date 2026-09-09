import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:keyva/core/time/day_resolver.dart';
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
import 'package:keyva/ui/app.dart';
import 'package:keyva/ui/controllers/app_state.dart';
import 'package:keyva/ui/screens/onboarding_screen.dart';
import 'package:keyva/ui/screens/today_screen.dart';

void main() {
  testWidgets('KeyvaApp pumps without throwing', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final settings = SettingsService(db);
    final embedder = HashingEmbeddingService();
    final matcher = KeyMatcher(db, embedder, settings);
    final vocab = TimeVocabService(db);
    final capture = CaptureService(db, matcher, settings, vocab);
    final recurrence = RecurrenceEngine(db);
    final llm = LlmClient(settings: settings);
    final dayClose = DayCloseService(db, llm, settings, recurrence, DayResolver());
    final photos = PhotoUnderstandingService(db);

    final services = Services(
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

    await tester.pumpWidget(KeyvaApp(services: services));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.textContaining('One line'), findsOneWidget);
  });

  testWidgets('KeyvaApp pumps to TodayScreen when onboarded is true', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final settings = SettingsService(db);
    final embedder = HashingEmbeddingService();
    final matcher = KeyMatcher(db, embedder, settings);
    final vocab = TimeVocabService(db);
    final capture = CaptureService(db, matcher, settings, vocab);
    final recurrence = RecurrenceEngine(db);
    final llm = LlmClient(settings: settings);
    final dayClose = DayCloseService(db, llm, settings, recurrence, DayResolver());
    final photos = PhotoUnderstandingService(db);

    final services = Services(
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

    await tester.pumpWidget(KeyvaApp(services: services, onboarded: true));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });
}
