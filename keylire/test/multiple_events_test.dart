import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keylire/core/time/day_resolver.dart';
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
import 'package:keylire/ui/app.dart';
import 'package:keylire/ui/controllers/app_state.dart';
import 'package:keylire/ui/widgets/time_ribbon_timeline.dart';

void main() {
  testWidgets('multiple events scroll and display correctly', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final settings = SettingsService(db);
    // Keep this UI test independent of the wall clock. In production, a Bed
    // capture at/after the evening threshold intentionally closes the day.
    await settings.setSleepEveningHour(24);
    await settings.setDayCutoffHour(0);
    final embedder = HashingEmbeddingService();
    final matcher = KeyMatcher(db, embedder, settings);
    final vocab = TimeVocabService(db);
    final capture = CaptureService(db, matcher, settings, vocab);
    final recurrence = RecurrenceEngine(db);
    final dayClose =
        DayCloseService(db, settings, recurrence, DayResolver());
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

    await tester.pumpWidget(KeylireApp(services: services, onboarded: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap 'Up'
    final upChip = find.widgetWithText(ActionChip, 'Up');
    expect(upChip, findsOneWidget);
    await tester.tap(upChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap 'Bed'
    final bedChip = find.widgetWithText(ActionChip, 'Bed');
    expect(bedChip, findsOneWidget);
    await tester.tap(bedChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final events = await db.select(db.events).get();
    expect(events.map((e) => e.rawText), containsAll(<String>['Up', 'Bed']));

    // Check that both captures reached the visible timeline.
    final todayCtrl = find.byType(TimeRibbonTimeline);
    expect(todayCtrl, findsOneWidget);
    final widget = tester.widget<TimeRibbonTimeline>(todayCtrl);
    expect(widget.events.map((e) => e.rawText),
        containsAll(<String>['Up', 'Bed']));
  });
}
