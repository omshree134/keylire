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
import 'package:keyva/ui/widgets/time_ribbon_timeline.dart';

void main() {
  testWidgets('multiple events scroll and display correctly', (tester) async {
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

    // Tap 'Up'
    final upChip = find.text('Up');
    expect(upChip, findsOneWidget);
    await tester.tap(upChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap 'Bed'
    final bedChip = find.text('Bed');
    expect(bedChip, findsOneWidget);
    await tester.tap(bedChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final events = await db.select(db.events).get();
    print('DB Events: ${events.map((e) => "${e.rawText} (${e.dayDate}, ${e.status})").toList()}');

    // Check what is in the TodayController
    final todayCtrl = find.byType(TimeRibbonTimeline);
    print('TimeRibbonTimeline found: ${todayCtrl.evaluate().length}');
    if (todayCtrl.evaluate().isNotEmpty) {
      final widget = tester.widget<TimeRibbonTimeline>(todayCtrl);
      print('Timeline events count: ${widget.events.length}');
      for (final e in widget.events) {
        print(' - ${e.rawText}: status=${e.status}, local=${e.local}');
      }
    }
  });
}
