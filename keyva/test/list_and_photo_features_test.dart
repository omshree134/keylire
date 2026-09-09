import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:keyva/ui/screens/lists_screen.dart';
import 'package:keyva/ui/screens/today_screen.dart';
import 'package:keyva/ui/widgets/time_ribbon_timeline.dart';

void main() {
  testWidgets('adding a list item adds to list and creates planned event on timeline', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 300));

    // Type a list item in capture bar: "need to buy groceries"
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    await tester.enterText(textField, 'need to buy groceries');
    await tester.pump();

    final sendButton = find.byTooltip('Log it');
    await tester.tap(sendButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify it is in list_items table
    final listItems = await db.openListItems();
    expect(listItems.length, 1);
    expect(listItems.first.title.toLowerCase(), contains('buy groceries'));

    // Verify it is also created as a planned event on the daily timeline
    final events = await db.select(db.events).get();
    expect(events.length, 1);
    expect(events.first.status, 'planned');
    expect(events.first.listItemId, listItems.first.id);

    // Verify it is shown in TimeRibbonTimeline as planned
    final ghostText = find.descendant(
      of: find.byType(TimeRibbonTimeline),
      matching: find.text(listItems.first.title),
    );
    expect(ghostText, findsOneWidget);

    // Switch to Lists tab (index 1)
    await tester.tap(find.text('Lists'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify item is visible in ListsScreen immediately
    final listItemFinder = find.descendant(
      of: find.byType(ListsScreen),
      matching: find.text(listItems.first.title),
    );
    expect(listItemFinder, findsOneWidget);
  });

  test('photo understanding cleans OCR and auto-assigns keys', () async {
    final rawOcr = '09:41\n100%\n5G\nMeeting Notes with Project Team\nDiscussed Q3 Deliverables\n12345';
    final parsedKind = PhotoUnderstandingService.kindTest(const ['text', 'paper'], rawOcr);
    final keyHint = PhotoUnderstandingService.keyHintTest(parsedKind, const ['text'], rawOcr);
    final desc = PhotoUnderstandingService.describeTest(parsedKind, const ['text'], rawOcr);

    expect(desc, contains('Meeting Notes with Project Team'));
    expect(desc, contains('Discussed Q3 Deliverables'));
    expect(desc.startsWith('09:41'), isFalse);
    expect(desc.startsWith('100%'), isFalse);
    expect(keyHint, isNotNull);
  });
}
