import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';

import 'core/config/ai_config.dart';
import 'core/config/seed_lexicon.dart';
import 'core/time/day_resolver.dart';
import 'data/db/database.dart';
import 'services/analysis/day_close_service.dart';
import 'services/backup/export_service.dart';
import 'services/capture/capture_service.dart';
import 'services/cloud/byok_provider.dart';
import 'services/cloud/cloud_capture_service.dart';
import 'services/cloud/cloud_gate.dart';
import 'services/cloud/hosted_provider.dart';
import 'services/embeddings/embedding_service.dart';
import 'services/embeddings/isolate_embedding_service.dart';
import 'services/embeddings/switchable_embedding_service.dart';
import 'services/entitlements/entitlements_service.dart';
import 'services/entitlements/revenuecat_entitlements.dart';
import 'services/matching/key_matcher.dart';
import 'services/metrics/dogfood_metrics.dart';
import 'services/photos/photo_understanding_service.dart';
import 'services/photos/platform_image_captioner.dart';
import 'services/recurrence/recurrence_engine.dart';
import 'services/reminders/reminder_service.dart';
import 'services/settings/settings_service.dart';
import 'services/time/time_vocab_service.dart';
import 'ui/app.dart';
import 'ui/controllers/app_state.dart';
import 'widget/widget_background.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Production-grade global error boundaries
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint(
        'Keylire FlutterError: ${details.exceptionAsString()}\n${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Keylire PlatformDispatcher Error: $error\n$stack');
    return true; // Handled to protect against unhandled platform crashes
  };

  HomeWidget.registerInteractivityCallback(keylireWidgetBackground);

  final db = AppDatabase();
  final settings = SettingsService(db);
  final embedder = SwitchableEmbeddingService();
  final matcher = KeyMatcher(db, embedder, settings);
  final vocab = TimeVocabService(db);
  final capture = CaptureService(db, matcher, settings, vocab);
  final recurrence = RecurrenceEngine(db);
  final EntitlementsService entitlements =
      AiConfig.revenueCatAndroidKey.isEmpty && AiConfig.revenueCatIosKey.isEmpty
          ? LocalEntitlements(db)
          : RevenueCatEntitlements(db,
              tokenEndpoint: '${AiConfig.hostedBaseUrl}/v1/token',
              entitlementId: AiConfig.premiumEntitlementId);
  final cloudGate = CloudGate(
    settings: settings,
    hosted: HostedProvider(entitlements, baseUrl: AiConfig.hostedBaseUrl),
    byok: ByokProvider(settings),
  );
  final dayClose =
      DayCloseService(db, settings, recurrence, DayResolver(), cloud: cloudGate);
  final cloudCapture = CloudCaptureService(db, capture, matcher, cloudGate);
  final photos =
      PhotoUnderstandingService(db, captioner: MlKitGenAiCaptioner());
  final reminders = ReminderService(db, settings, capture, vocab);

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
    cloudGate: cloudGate,
    cloudCapture: cloudCapture,
    entitlements: entitlements,
    reminders: reminders,
  );

  runApp(KeylireApp(services: services));

  Future.microtask(() async {
    await settings.migrateLegacyCloudSettings();
    if (entitlements is RevenueCatEntitlements) {
      await entitlements.configure(
          androidKey: AiConfig.revenueCatAndroidKey,
          iosKey: AiConfig.revenueCatIosKey);
    }
    final upgraded = await embedder.upgradeTo(
        IsolateEmbeddingService(), AiConfig.onnxEmbedderId);
    if (!upgraded) {
      debugPrint(
          'Keylire: ONNX model missing - matcher is running the dev hashing embedder.');
    }
    if (await settings.embedderId() != embedder.id) {
      await _reembed(db, embedder);
      await settings.setEmbedderId(embedder.id);
    }
    if ((await db.select(db.keys).get()).isEmpty) {
      for (final e in seedLexicon.entries) {
        int? keyId;
        for (final phrase in e.value) {
          keyId = await matcher.createKeyWithSeed(
              e.key, phrase, await embedder.embed(phrase));
        }
        if (keyId != null &&
            const {
              'meeting',
              'doctor',
              'call',
              'idea',
              'interview',
              'therapy',
              'class',
              'health',
              'work'
            }.contains(e.key)) {
          await db.updateKey(
              keyId, const KeysCompanion(notesAffinity: Value(true)));
        }
      }
      // Bed / Up need these two to exist.
      for (final n in ['sleep', 'wake']) {
        if (await db.keyByName(n) == null) await db.createKey(n);
      }
    }
    await matcher.warmUp();
    try {
      await reminders.init(onForegroundResponse: (r) {
        unawaited(_handleReminderTap(r, capture, reminders));
      });
      await reminders.syncNow();
    } catch (e, st) {
      debugPrint('Keylire: reminders init error: $e\n$st');
    }
    try {
      await dayClose.closeMissedDays();
    } catch (e, st) {
      debugPrint('Keylire: closeMissedDays error: $e\n$st');
    }
    try {
      await db.cleanupSoftDeleted();
    } catch (e, st) {
      debugPrint('Keylire: cleanupSoftDeleted error: $e\n$st');
    }
    // iOS: AppIntent taps queue URIs in the shared defaults; run them now.
    try {
      final pending =
          await HomeWidget.getWidgetData<List<dynamic>?>('kv_pending');
      if (pending != null && pending.isNotEmpty) {
        for (final u in pending) {
          await keylireWidgetBackground(Uri.tryParse('$u'));
        }
        await HomeWidget.saveWidgetData<List<String>>('kv_pending', const []);
      }
    } catch (e, st) {
      debugPrint('Keylire: HomeWidget pending events error: $e\n$st');
    }
  });
}

Future<void> _reembed(AppDatabase db, EmbeddingService e) async {
  for (final ex in await db.allExamples()) {
    final v = await e.embed(ex.exampleText);
    await (db.update(db.keyExamples)..where((k) => k.id.equals(ex.id)))
        .write(KeyExamplesCompanion(vector: Value(VectorCodec.encode(v))));
  }
}

Future<void> _handleReminderTap(NotificationResponse r, CaptureService capture,
    ReminderService reminders) async {
  if (r.payload == null) return;
  final p = jsonDecode(r.payload!) as Map<String, dynamic>;
  if (p['kind'] == 'plan' && p['eventId'] is int) {
    final id = p['eventId'] as int;
    if (r.actionId == 'done') await capture.completePlanned(id);
    if (r.actionId == 'skip') await capture.skipPlanned(id);
  }
  WidgetActionBus.dispatch('keylire://reminder/${p['kind']}');
  reminders.sync();
}
