import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/time/day_resolver.dart';
import '../../data/db/database.dart';
import '../cloud/cloud_gate.dart';
import '../cloud/cloud_provider.dart';
import '../recurrence/recurrence_engine.dart';
import '../settings/settings_service.dart';
import 'local_day_narrator.dart';

/// Day close. Order of operations, every time:
///   1. Empty day -> nothing (no row, no nag).
///   2. Recurrence bookkeeping (deterministic, always).
///   3. LOCAL narrative + per-key stats are written. This is the product.
///   4. Only if the user entered a key AND enabled text analysis: one LLM
///      call may replace the summary/flags and add prose key analyses.
///      Any failure leaves the local result in place.
class DayCloseService {
  DayCloseService(this.db, this.settings, this.recurrence, this.resolver,
      {CloudGate? cloud})
      : cloud = cloud ?? CloudGate.disabled(settings),
        narrator = LocalDayNarrator(db);

  final AppDatabase db;
  final SettingsService settings;
  final RecurrenceEngine recurrence;
  final DayResolver resolver;
  final CloudGate cloud;
  final LocalDayNarrator narrator;

  static const int maxAnalysisChars = 240;
  static const int maxFlags = 5;

  static const String _system = '''
You are the daily analysis engine of a personal day-logging app. You receive
one user's day of logged events plus context. You write concise, factual,
non-judgmental analysis. You never invent events that were not logged. You
never give medical advice. Output ONLY valid JSON matching the schema below.

OUTPUT SCHEMA:
{
  "day_summary": "2-4 sentences narrating the day; note sequence and timing",
  "key_updates": [{"key": "...", "analysis": "max 2 sentences"}],
  "flags": ["0-5 short observations; empty array if nothing genuine"]
}''';

  /// Close every past day that has events but no summary (up to [maxDays]
  /// back). Call at startup and from the background scheduler - replaces the
  /// old "close yesterday only", which silently skipped days when the app
  /// was not opened.
  Future<void> closeMissedDays({int maxDays = 14}) async {
    final today = resolver.resolveDayDate(DateTime.now());
    final floor = DayResolver.formatDay(
        DateTime.parse(today).subtract(Duration(days: maxDays)));
    final rows = await db.customSelect(
      'SELECT DISTINCT day_date FROM events '
      "WHERE deleted_at IS NULL AND status IN ('done','planned') AND day_date < ? AND day_date >= ? "
      'AND day_date NOT IN (SELECT day_date FROM day_summaries) '
      'ORDER BY day_date',
      variables: [Variable.withString(today), Variable.withString(floor)],
    ).get();
    for (final r in rows) {
      await closeDay(r.read<String>('day_date'));
    }
  }

  /// Idempotent: safe to call again to refresh a day's summary.
  Future<void> closeDay(String dayDate) async {
    // Planned items whose day has ended wait for the morning review.
    for (final e in (await db.eventsForDay(dayDate)).where((e) => e.status == 'planned')) {
      await db.updateEvent(e.id, const EventsCompanion(status: Value('pending')));
    }
    final events = await db.doneEventsForDay(dayDate);
    if (events.isEmpty) return;

    final dow = DayResolver.dowOf(DateTime.parse(dayDate));
    await recurrence.evaluateDay(dayDate, dow);
    await recurrence.scanForProposals();

    // ---- local result: always written ------------------------------------
    final local = await narrator.narrate(dayDate, events);
    final keys = await db.activeKeys();
    final keyName = {for (final k in keys) k.id: k.name};

    await db.upsertDaySummary(DaySummariesCompanion(
      dayDate: Value(dayDate),
      summary: Value(local.summary),
      flags: Value(jsonEncode(local.flags)),
      eventCount: Value(events.length),
    ));
    final now = DateTime.now().toUtc();
    for (final entry in local.keyStats.entries) {
      await db.upsertKeyAnalysis(KeyAnalysesCompanion(
        keyId: Value(entry.key),
        analysis: Value(LocalDayNarrator.describeKey(
            keyName[entry.key] ?? '?', entry.value)),
        stats: Value(jsonEncode(entry.value.toJson())),
        updatedAt: Value(now),
      ));
    }

    // ---- optional cloud enrichment -------------------------------------
    final provider = await cloud.providerFor(CloudFeature.dayClose);
    if (provider == null) return;

    Map<String, dynamic> out;
    try {
      out = await provider.completeJson(
        system: _system,
        user: await _buildPayload(dayDate, events, local),
        temperature: 0.3,
      );
    } catch (_) {
      return; // budget, network, parse - the local summary stands.
    }

    final summary = (out['day_summary'] as String?)?.trim();
    if (summary != null && summary.isNotEmpty) {
      final flags = ((out['flags'] as List?) ?? const [])
          .whereType<String>()
          .take(maxFlags)
          .toList();
      await db.upsertDaySummary(DaySummariesCompanion(
        dayDate: Value(dayDate),
        summary: Value(summary),
        flags: Value(jsonEncode(flags.isEmpty ? local.flags : flags)),
        eventCount: Value(events.length),
      ));
    }

    final byName = {for (final k in keys) k.name: k.id};
    for (final u in (out['key_updates'] as List?) ?? const []) {
      if (u is! Map) continue;
      final keyId = byName[u['key']];
      if (keyId == null) continue;
      var analysis = ((u['analysis'] as String?) ?? '').trim();
      if (analysis.isEmpty) continue;
      if (analysis.length > maxAnalysisChars) {
        analysis = analysis.substring(0, maxAnalysisChars);
      }
      await db.upsertKeyAnalysis(KeyAnalysesCompanion(
        keyId: Value(keyId),
        analysis: Value(analysis),
        stats: Value(jsonEncode(local.keyStats[keyId]?.toJson() ?? {})),
        updatedAt: Value(now),
      ));
    }
  }

  Future<String> _buildPayload(
      String dayDate, List<Event> events, LocalNarrative local) async {
    final keys = await db.activeKeys();
    final keyName = {for (final k in keys) k.id: k.name};

    final lines = events.map((e) {
      final l = e.tsUtc.toLocal();
      final hh = l.hour.toString().padLeft(2, '0');
      final mm = l.minute.toString().padLeft(2, '0');
      final name = e.keyId == null ? 'unfiled' : (keyName[e.keyId] ?? '?');
      final nums = [
        if (e.durationMin != null) '${e.durationMin} min',
        if (e.quantity != null) '${e.quantity} ${e.unit ?? ''}'.trim(),
      ].join(', ');
      return '- $hh:$mm [$name] ${e.rawText}${nums.isEmpty ? '' : ' ($nums)'}';
    }).join('\n');

    final d = DateTime.parse(dayDate);
    final yesterday = DayResolver.formatDay(d.subtract(const Duration(days: 1)));
    final tomorrow = DayResolver.formatDay(d.add(const Duration(days: 1)));
    final ySummary = (await db.daySummary(yesterday))?.summary ?? 'none';

    final planned = (await db.plannedFrom(tomorrow))
        .where((e) => e.dayDate == tomorrow)
        .toList();
    final futureLines = planned.isEmpty
        ? 'none'
        : planned.map((e) {
            final l = e.tsUtc.toLocal();
            final name = e.keyId == null ? 'unfiled' : (keyName[e.keyId] ?? '?');
            return '- ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')} [$name] ${e.rawText}';
          }).join('\n');

    final presentIds = events.map((e) => e.keyId).whereType<int>().toSet().toList();
    final analyses = await db.analysesForKeys(presentIds);
    final analysisLines = analyses.isEmpty
        ? 'none'
        : analyses.map((a) {
            var t = a.analysis;
            if (t.length > maxAnalysisChars) t = t.substring(0, maxAnalysisChars);
            return '- ${keyName[a.keyId] ?? '?'}: $t | stats: ${a.stats ?? '{}'}';
          }).join('\n');

    return '''
DATE: $dayDate (${_dowName(d.weekday)})

TODAY'S EVENTS (chronological):
$lines

COMPUTED FACTS (trust these over your own arithmetic):
- ${local.summary}
${local.flags.map((f) => '- $f').join('\n')}

YESTERDAY'S SUMMARY:
$ySummary

TOMORROW'S KNOWN ENTRIES:
$futureLines

RUNNING KEY ANALYSES (only keys that appeared today):
$analysisLines

TASKS:
1. "day_summary": 2-4 sentences narrating the day; sequence and timing, not
   just contents.
2. "key_updates": for each key that appeared today, an updated running
   analysis (max 2 sentences). Preserve useful history.
3. "flags": short observations worth surfacing. Use COMPUTED FACTS as the
   ground truth. Empty array if nothing genuine. Do not manufacture insights.''';
  }

  static String _dowName(int weekday) => const [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'
      ][weekday - 1];
}
