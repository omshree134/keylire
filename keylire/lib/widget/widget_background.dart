import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/config/ai_config.dart';
import '../data/db/database.dart';
import '../services/capture/capture_service.dart';
import '../services/embeddings/embedding_service.dart';
import '../services/embeddings/switchable_embedding_service.dart';
import '../services/matching/key_matcher.dart';
import '../services/photos/photo_understanding_service.dart';
import '../services/settings/settings_service.dart';
import '../services/time/time_vocab_service.dart';
import '../services/widget/widget_sync_service.dart';

/// Runs in a headless Flutter engine when a widget action fires - the app
/// is not opened. Same parser, same matcher, same database file. The only
/// thing the background path can't do is show a picker: below the
/// auto-assign threshold the entry is saved unfiled and Today shows
/// "tap to file" the next time the app opens.
///
/// URIs (from KeylireWidgetProvider / QuickCaptureActivity):
/// ```text
///   keylire://widget/bed
///   keylire://widget/up
///   keylire://widget/chip?id=<keyId>&name=<name>
///   keylire://widget/ghost?id=<eventId>
///   keylire://widget/text?line=<text>&modality=text|voice
///   keylire://widget/photo?path=<cachePath>&line=<optional caption>
/// ```
@pragma('vm:entry-point')
Future<void> keylireWidgetBackground(Uri? uri) async {
  if (uri == null) return;
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  try {
    final settings = SettingsService(db);
    final embedder = SwitchableEmbeddingService();
    await embedder.upgradeTo(OnnxEmbeddingService(), AiConfig.onnxEmbedderId);
    final matcher = KeyMatcher(db, embedder, settings);
    final vocab = TimeVocabService(db);
    final capture = CaptureService(db, matcher, settings, vocab);
    final q = uri.queryParameters;

    switch (uri.host + uri.path) {
      case 'widget/bed':
        await capture.bed(captureMs: 400);
      case 'widget/up':
        await capture.up(captureMs: 400);
      case 'widget/chip':
        final id = int.tryParse(q['id'] ?? '');
        if (id != null) {
          await capture.capture(rawText: q['name'] ?? '', modality: 'widget', forcedKeyId: id, captureMs: 500);
        }
      case 'widget/ghost':
        final id = int.tryParse(q['id'] ?? '');
        if (id != null) await capture.completePlanned(id);
      case 'widget/text':
        final line = (q['line'] ?? '').trim();
        if (line.isNotEmpty) {
          await capture.capture(rawText: line, modality: q['modality'] == 'voice' ? 'voice' : 'text', captureMs: 2500);
        }
      case 'widget/photo':
        await _photo(db, capture, matcher, q['path'], q['line']);
    }

    final today = await _todayEvents(db);
    await WidgetSyncService.syncWidgets(db: db, todayEvents: today);
  } finally {
    await db.close();
  }
}

Future<void> _photo(AppDatabase db, CaptureService capture, KeyMatcher matcher, String? cachePath, String? caption) async {
  if (cachePath == null) return;
  final src = File(cachePath);
  if (!await src.exists()) return;
  final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'photos'));
  if (!await dir.exists()) await dir.create(recursive: true);
  final dest = await src.copy(p.join(dir.path, p.basename(cachePath)));
  try {
    await src.delete();
  } catch (_) {}

  final typed = (caption ?? '').trim();
  final out = await capture.capture(
      rawText: typed.isNotEmpty ? typed : 'Photo', modality: 'photo', captureMs: 3000, photoPath: dest.path);

  final photos = PhotoUnderstandingService(db);
  try {
    final u = await photos.understand(dest);
    await photos.applyToEvent(out.eventId, u, keepUserText: typed.isNotEmpty);
    final line = typed.isNotEmpty ? typed : u.description;
    final m = await matcher.match(u.keyHint ?? line);
    if (m.decision == MatchDecision.autoAssign) {
      await capture.resolvePick(out.eventId, m, m.top.first.keyId, line);
    }
  } finally {
    photos.dispose();
  }
}

Future<List<Event>> _todayEvents(AppDatabase db) async {
  final rows = await db.customSelect(
    "SELECT day_date FROM events WHERE deleted_at IS NULL AND status='done' ORDER BY ts_utc DESC LIMIT 1",
  ).getSingleOrNull();
  final day = rows?.read<String>('day_date');
  if (day == null) return const [];
  return db.eventsForDay(day);
}
