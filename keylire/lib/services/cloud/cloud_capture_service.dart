import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;

import '../../core/parse/entry_parser.dart';
import '../../data/db/database.dart';
import '../capture/capture_service.dart';
import '../matching/key_matcher.dart';
import '../photos/photo_understanding_service.dart';
import 'cloud_gate.dart';
import 'cloud_provider.dart';

/// Cloud-assisted capture. The model turns a photo or a long note into a
/// list of short Keylire-style lines; each line then goes through the same
/// EntryParser + KeyMatcher as anything typed. The model proposes, the local
/// pipeline disposes. If it returns garbage, nothing is written.
class CloudCaptureService {
  CloudCaptureService(this.db, this.capture, this.matcher, this.gate);
  final AppDatabase db;
  final CaptureService capture;
  final KeyMatcher matcher;
  final CloudGate gate;

  static const int maxEntries = 12;

  static const _schema = '''
Output ONLY valid JSON:
{
  "entries": [
    {
      "line": "short log line in the user's own style, e.g. 'ran 5 km' or 'coffee with priya'",
      "time": "HH:MM 24h or null if not stated/visible",
      "day_offset": 0,
      "tense": "done" | "planned" | "list",
      "quantity": number or null,
      "unit": "km|kcal|steps|pages|reps|sets|min|₹|\$|..." or null,
      "duration_min": integer or null,
      "note": "extra detail worth keeping, or null"
    }
  ],
  "summary": "one line describing what this was"
}
Rules: never invent events; one entry per distinct activity; keep "line"
under 60 characters; put prices/totals in quantity+unit; day_offset is
-1 for yesterday, 1 for tomorrow, else 0.''';

  static const _photoSystem = '''
You turn a photo into entries for a personal day-log. Photos are usually:
a receipt, a workout/fitness screenshot, a meal, a book page, a timetable,
a handwritten note, a screenshot of a message or calendar.
$_schema''';

  static const _textSystem = '''
You split a long note or voice transcript into separate day-log entries,
preserving the order they happened in. Short Hindi/English mixed phrases
are normal; keep the user's words.
$_schema''';

  // ---------------------------------------------------------------- photo

  /// Null when the feature is off, the provider is missing, or the model
  /// returned nothing usable.
  Future<CloudExtraction?> extractFromPhoto(
    File image, {
    String? userCaption,
    PhotoUnderstanding? local,
  }) async {
    final p = await gate.providerFor(CloudFeature.photoExtract);
    if (p == null) return null;

    final hints = <String>[
      if (userCaption != null && userCaption.trim().isNotEmpty)
        'User caption: "${userCaption.trim()}"',
      if (local != null) 'On-device guess: kind=${local.kind}, labels=${local.labels.join(', ')}',
      if (local?.text != null) 'On-device OCR (may be noisy):\n${local!.text!.substring(0, local.text!.length.clamp(0, 800))}',
      'Local time now: ${_hhmm(DateTime.now())}',
    ];

    final out = await p.completeVisionJson(
      system: _photoSystem,
      prompt: hints.join('\n'),
      imageBytes: await image.readAsBytes(),
    );
    return CloudExtraction.parse(out, source: 'cloud_vision', provider: p.id);
  }

  // ----------------------------------------------------------------- text

  /// Cheap heuristic for "is this a brain dump?" Called before capture.
  bool looksLikeMultiple(String text) {
    final t = text.trim();
    if (t.length < 60) return false;
    final seps = RegExp(r'[,;\n]|\b(then|and then|after that|later|phir|uske baad)\b')
        .allMatches(t)
        .length;
    return seps >= 2;
  }

  Future<CloudExtraction?> splitText(String text) async {
    final p = await gate.providerFor(CloudFeature.textSplit);
    if (p == null) return null;
    final out = await p.completeJson(
      system: _textSystem,
      user: 'Local time now: ${_hhmm(DateTime.now())}\n\nText:\n$text',
    );
    return CloudExtraction.parse(out, source: 'cloud_text', provider: p.id);
  }

  // ---------------------------------------------------------------- apply

  /// Writes the extraction. [sourceEventId] is the photo/raw event already
  /// saved by the local path:
  ///   - exactly one entry  -> that event is updated in place (keeps photo)
  ///   - several entries    -> siblings are created, source keeps the photo
  ///                           and gets its text set to the summary
  /// Returns the ids of every event that now carries extracted data.
  Future<List<int>> apply(CloudExtraction x,
      {required int sourceEventId, String? targetDayDate}) async {
    if (x.entries.isEmpty) return const [];
    final src = await db.eventById(sourceEventId);
    if (src == null || src.deletedAt != null) return const [];

    final ids = <int>[];
    final single = x.entries.length == 1;

    for (var i = 0; i < x.entries.length; i++) {
      final e = x.entries[i];
      final line = _composeLine(e);
      final when = _resolveTime(e, src.tsUtc.toLocal());

      int id;
      if (single) {
        id = sourceEventId;
        await db.updateEvent(id, EventsCompanion(
          rawText: Value(line),
          tsUtc: when == null ? const Value.absent() : Value(when.toUtc()),
          dayDate: when == null
              ? const Value.absent()
              : Value(await capture.activeDayDate(when)),
          status: Value(e.tense == 'planned' ? 'planned' : src.status),
        ));
        await _reassignKey(id, line);
      } else {
        final out = await capture.capture(
          rawText: line,
          modality: src.modality,
          overrideTime: when,
          targetDayDate: when == null ? targetDayDate : null,
          extraMetadata: {'from_event': sourceEventId, 'source': x.source},
        );
        id = out.eventId;
        // Unfiled from capture (picker would have opened) -> try harder.
        final saved = await db.eventById(id);
        if (saved?.keyId == null) await _reassignKey(id, line);
      }

      // Structured numbers the parser may have missed.
      final saved = await db.eventById(id);
      if (saved != null) {
        await db.updateEvent(id, EventsCompanion(
          quantity: saved.quantity == null && e.quantity != null
              ? Value(e.quantity) : const Value.absent(),
          unit: saved.unit == null && e.unit != null
              ? Value(e.unit) : const Value.absent(),
          durationMin: saved.durationMin == null && e.durationMin != null
              ? Value(e.durationMin) : const Value.absent(),
          note: (saved.note == null || saved.note!.isEmpty) && e.note != null
              ? Value(e.note) : const Value.absent(),
        ));
      }
      ids.add(id);
    }

    if (!single) {
      final meta = _meta(src.metadata)
        ..['cloud_children'] = ids
        ..['cloud_source'] = x.source;
      await db.updateEvent(sourceEventId, EventsCompanion(
        rawText: src.editedAt == null && x.summary.isNotEmpty
            ? Value(x.summary) : const Value.absent(),
        metadata: Value(jsonEncode(meta)),
      ));
    } else {
      final meta = _meta(src.metadata)..['cloud_source'] = x.source;
      await db.updateEvent(sourceEventId,
          EventsCompanion(metadata: Value(jsonEncode(meta))));
    }
    return ids;
  }

  // -------------------------------------------------------------- helpers

  /// Rebuild a line the parser will read the same way the model meant it.
  String _composeLine(CloudEntry e) {
    var s = e.line.trim();
    if (e.quantity != null && e.unit != null &&
        !RegExp(r'\d').hasMatch(s)) {
      final q = e.quantity! == e.quantity!.roundToDouble()
          ? '${e.quantity!.toInt()}' : e.quantity!.toStringAsFixed(1);
      s = '$s $q ${e.unit}';
    }
    if (e.durationMin != null && !RegExp(r'\b(min|hour|hr)').hasMatch(s)) {
      s = '$s ${e.durationMin} min';
    }
    if (e.tense == 'planned' && !RegExp(r'\b(will|plan|tomorrow|tonight)\b').hasMatch(s)) {
      s = 'will $s';
    }
    if (e.tense == 'list') s = 'need to $s';
    return s;
  }

  DateTime? _resolveTime(CloudEntry e, DateTime anchor) {
    final base = DateTime(anchor.year, anchor.month, anchor.day)
        .add(Duration(days: e.dayOffset));
    if (e.time == null) return e.dayOffset == 0 ? null : DateTime(base.year, base.month, base.day, 12);
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(e.time!);
    if (m == null) return null;
    final h = int.parse(m.group(1)!), mi = int.parse(m.group(2)!);
    if (h > 23 || mi > 59) return null;
    return DateTime(base.year, base.month, base.day, h, mi);
  }

  Future<void> _reassignKey(int eventId, String line) async {
    final parsed = EntryParser().parse(line);
    final m = await matcher.match(parsed.matchText);
    if (m.top.isEmpty) return;
    // Cloud lines are clean enough that the picker threshold is sufficient.
    if (m.decision == MatchDecision.newKey) return;
    await db.assignKey(eventId, m.top.first.keyId,
        m.decision == MatchDecision.autoAssign ? 'auto' : 'picked',
        score: m.top.first.score);
  }

  static Map<String, dynamic> _meta(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try { return Map<String, dynamic>.from(jsonDecode(raw) as Map); } catch (_) { return {}; }
  }

  static String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class CloudEntry {
  CloudEntry({
    required this.line,
    this.time,
    this.dayOffset = 0,
    this.tense = 'done',
    this.quantity,
    this.unit,
    this.durationMin,
    this.note,
  });
  final String line;
  final String? time;
  final int dayOffset;
  final String tense;
  final double? quantity;
  final String? unit;
  final int? durationMin;
  final String? note;
}

class CloudExtraction {
  CloudExtraction({required this.entries, required this.summary,
      required this.source, required this.provider});
  final List<CloudEntry> entries;
  final String summary;
  final String source;
  final String provider;

  /// Defensive parse: anything malformed is dropped, never thrown.
  static CloudExtraction? parse(Map<String, dynamic> out,
      {required String source, required String provider}) {
    final raw = out['entries'];
    if (raw is! List) return null;
    final entries = <CloudEntry>[];
    for (final r in raw.take(CloudCaptureService.maxEntries)) {
      if (r is! Map) continue;
      final line = (r['line'] as String?)?.trim();
      if (line == null || line.isEmpty || line.length > 120) continue;
      final tense = r['tense'];
      entries.add(CloudEntry(
        line: line,
        time: r['time'] is String ? r['time'] as String : null,
        dayOffset: (r['day_offset'] as num?)?.toInt().clamp(-7, 7) ?? 0,
        tense: const {'done', 'planned', 'list'}.contains(tense) ? tense as String : 'done',
        quantity: (r['quantity'] as num?)?.toDouble(),
        unit: (r['unit'] as String?)?.trim(),
        durationMin: (r['duration_min'] as num?)?.toInt(),
        note: (r['note'] as String?)?.trim(),
      ));
    }
    if (entries.isEmpty) return null;
    return CloudExtraction(
      entries: entries,
      summary: ((out['summary'] as String?) ?? '').trim(),
      source: source,
      provider: provider,
    );
  }
}

