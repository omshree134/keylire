import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
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
import 'package:keylire/ui/app.dart';
import 'package:keylire/ui/controllers/app_state.dart';
import 'package:keylire/ui/screens/how_to_use_screen.dart';
import 'package:keylire/ui/screens/onboarding_screen.dart';
import 'package:keylire/ui/screens/today_screen.dart';
import 'package:keylire/services/nutrition/nutrition_service.dart';
import 'package:keylire/ui/widgets/edit_entry_sheet.dart';

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
  testWidgets('edit nutrition, remember it, then reuse it through text', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final services = _services(db);
    final foodId = await db.createKey('food');
    await services.capture.capture(rawText: 'My oats', modality: 'text', forcedKeyId: foodId);
    final row = (await db.select(db.events).get()).single;
    final view = EventView.from(row, {foodId: 'food'});
    await tester.pumpWidget(ServicesScope(services: services, child: MaterialApp(
      home: Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () => showEditEntrySheet(context, view), child: const Text('Edit')))))));
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add nutrition'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Calories (kcal)'), '450');
    await tester.enterText(find.widgetWithText(TextField, 'Protein (g)'), '25');
    await tester.ensureVisible(find.text('Remember as my meal'));
    await tester.tap(find.text('Remember as my meal'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final updated = await db.eventById(row.id);
    expect(NutritionService.metadata(updated!.metadata)['calories'], 450);
    expect((await NutritionService(db).matchText('2 servings of my oats'))!['protein'], 50);
  });

  testWidgets('KeylireApp pumps without throwing', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final services = _services(db);

    await tester.pumpWidget(KeylireApp(services: services));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.textContaining('One line'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your words'), findsOneWidget);
    final selectedKey = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'food'),
    );
    final onboardingTheme = Theme.of(
      tester.element(find.widgetWithText(FilterChip, 'food')),
    );
    expect(selectedKey.selected, isTrue);
    expect(
        selectedKey.labelStyle?.color, onboardingTheme.colorScheme.onPrimary);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('It learns'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text("When's your day?"), findsOneWidget);
    expect(find.text('Set up Keylire'), findsOneWidget);
  });

  testWidgets('KeylireApp pumps to TodayScreen when onboarded is true',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final services = _services(db);

    await tester.pumpWidget(KeylireApp(services: services, onboarded: true));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('an onboarded user sees the guide once', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final services = _services(db);
    await db.putSetting('onboarded', 'true');

    await tester.pumpWidget(KeylireApp(services: services));
    await tester.pumpAndSettle();

    expect(find.byType(HowToUseScreen), findsOneWidget);
    expect(find.text('Your day, in keys.'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, -1600), 2000);
    await tester.pumpAndSettle();
    expect(find.text('Start using Keylire'), findsOneWidget);
    await tester.tap(find.text('Start using Keylire'));
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(await services.settings.hasSeenHowTo(), isTrue);
  });
}
