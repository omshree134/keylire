import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'core/config/ai_config.dart';
import 'core/config/seed_lexicon.dart';
import 'core/time/day_resolver.dart';
import 'data/db/database.dart';
import 'services/analysis/day_close_service.dart';
import 'services/backup/export_service.dart';
import 'services/capture/capture_service.dart';
import 'services/embeddings/embedding_service.dart';
import 'services/embeddings/switchable_embedding_service.dart';
import 'services/llm/llm_client.dart';
import 'services/matching/key_matcher.dart';
import 'services/metrics/dogfood_metrics.dart';
import 'services/photos/photo_understanding_service.dart';
import 'services/recurrence/recurrence_engine.dart';
import 'services/settings/settings_service.dart';
import 'services/time/time_vocab_service.dart';
import 'ui/app.dart';
import 'ui/controllers/app_state.dart';
import 'widget/widget_background.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(keyvaWidgetBackground);

  final db = AppDatabase();
  final settings = SettingsService(db);
  final embedder = SwitchableEmbeddingService();
  final matcher = KeyMatcher(db, embedder, settings);
  final vocab = TimeVocabService(db);
  final capture = CaptureService(db, matcher, settings, vocab);
  final recurrence = RecurrenceEngine(db);
  final llm = LlmClient(settings: settings); // dormant unless a key is entered
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

  runApp(KeyvaApp(services: services));

  Future.microtask(() async {
    final upgraded = await embedder.upgradeTo(OnnxEmbeddingService(), AiConfig.onnxEmbedderId);
    if (!upgraded) {
      debugPrint('Keyva: ONNX model missing - matcher is running the dev hashing embedder.');
    }
    if (await settings.embedderId() != embedder.id) {
      await _reembed(db, embedder);
      await settings.setEmbedderId(embedder.id);
    }
    if ((await db.activeKeys()).isEmpty) {
      for (final e in seedLexicon.entries) {
        int? keyId;
        for (final phrase in e.value) {
          keyId = await matcher.createKeyWithSeed(e.key, phrase, await embedder.embed(phrase));
        }
        if (keyId != null && const {'meeting', 'doctor', 'call', 'idea', 'interview', 'therapy', 'class', 'health', 'work'}.contains(e.key)) {
          await db.updateKey(keyId, const KeysCompanion(notesAffinity: Value(true)));
        }
      }
      // Bed / Up need these two to exist.
      for (final n in ['sleep', 'wake']) {
        if (await db.keyByName(n) == null) await db.createKey(n);
      }
    }
    await matcher.warmUp();
    try {
      await dayClose.closeMissedDays();
    } catch (_) {}
    // iOS: AppIntent taps queue URIs in the shared defaults; run them now.
    try {
      final pending = await HomeWidget.getWidgetData<List<dynamic>?>('kv_pending');
      if (pending != null && pending.isNotEmpty) {
        for (final u in pending) {
          await keyvaWidgetBackground(Uri.tryParse('$u'));
        }
        await HomeWidget.saveWidgetData<List<String>>('kv_pending', const []);
      }
    } catch (_) {}
  });
}

Future<void> _reembed(AppDatabase db, EmbeddingService e) async {
  for (final ex in await db.allExamples()) {
    final v = await e.embed(ex.exampleText);
    await (db.update(db.keyExamples)..where((k) => k.id.equals(ex.id)))
        .write(KeyExamplesCompanion(vector: Value(VectorCodec.encode(v))));
  }
}
