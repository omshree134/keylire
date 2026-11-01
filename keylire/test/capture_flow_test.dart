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
import 'package:keylire/ui/app.dart';
import 'package:keylire/ui/controllers/app_state.dart';
import 'package:keylire/ui/widgets/time_ribbon_timeline.dart';

void main() {
  testWidgets('typing an event shows it in the timeline', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final settings = SettingsService(db);
    final embedder = HashingEmbeddingService();
    final matcher = KeyMatcher(db, embedder, settings);
    final vocab = TimeVocabService(db);
    final capture = CaptureService(db, matcher, settings, vocab);
    final recurrence = RecurrenceEngine(db);
    final llm = LlmClient(settings: settings);
    final dayClose =
        DayCloseService(db, llm, settings, recurrence, DayResolver());
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

    final gymVector = await embedder.embed('strength workout');
    final gymId =
        await matcher.createKeyWithSeed('gym', 'strength workout', gymVector);
    await matcher.warmUp();

    await tester.pumpWidget(KeylireApp(services: services, onboarded: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Find the capture text field
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Enter an exact-name phrase so this first capture auto-files and does
    // not leave the key picker open during the selector interaction below.
    await tester.enterText(textField, 'gym run');
    await tester.pump();

    // Tap the submit button
    final sendButton = find.byTooltip('Log it');
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify it is saved in the DB
    final events = await db.select(db.events).get();
    expect(events.length, 1);
    expect(events.first.rawText, 'gym run');

    // Verify it is rendered in TimeRibbonTimeline
    final timelineText = find.descendant(
      of: find.byType(TimeRibbonTimeline),
      matching: find.text('gym run'),
    );
    expect(timelineText, findsOneWidget);

    // A typed phrase re-ranks the selector. Tapping its suggested key keeps
    // the full sentence, files it under that key, and teaches the matcher.
    await tester.enterText(textField, 'strength workout today');
    await tester.pump(const Duration(milliseconds: 300));
    final learnedChip = find.text('gym · matches');
    expect(learnedChip, findsOneWidget);
    await tester.tap(learnedChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final learnedEvents = await db.select(db.events).get();
    expect(learnedEvents.length, 2);
    expect(learnedEvents.last.rawText, 'strength workout today');
    expect(learnedEvents.last.keyId, gymId);

    final examples = await db.allExamples();
    expect(
      examples.any(
          (e) => e.keyId == gymId && e.exampleText == 'strength workout today'),
      isTrue,
    );
  });
}
