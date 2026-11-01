import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/parse/entry_parser.dart';
import '../../core/time/day_resolver.dart';
import '../../data/db/database.dart';
import '../matching/key_matcher.dart';
import '../settings/settings_service.dart';
import '../nutrition/nutrition_service.dart';
import '../time/time_vocab_service.dart';

/// The single entry point for all five capture doors. No network, ever.
///
///   parse   -> tense, when, quantity, note signal        (EntryParser)
///   match   -> key candidates                             (KeyMatcher, on-device)
///   resolve -> exact time from window + user history      (TimeVocabService)
///   write   -> done / planned event, or list item
///
/// The event is stored BEFORE any picker appears; dismissing the picker
/// leaves it unfiled, never lost.
class CaptureService {
  CaptureService(this.db, this.matcher, this.settings, this.vocab,
      {EntryParser? parser,
      this.sleepKeyName = 'sleep',
      this.wakeKeyName = 'wake'})
      : parser = parser ?? EntryParser();

  final AppDatabase db;
  final KeyMatcher matcher;
  final SettingsService settings;
  final TimeVocabService vocab;
  final EntryParser parser;
  final String sleepKeyName;
  final String wakeKeyName;

  static const _noteKeys = {
    'meeting',
    'doctor',
    'call',
    'idea',
    'interview',
    'therapy',
    'class'
  };

  Future<CaptureOutcome> capture({
    required String rawText,
    required String modality,
    int? captureMs,
    int? forcedKeyId,
    DateTime? overrideTime,
    String? photoPath,
    String? thumbPath,
    String? targetDayDate,
    Map<String, dynamic>? extraMetadata,
  }) async {
    final text = rawText.trim();
    final now = DateTime.now();
    final parsed = parser.parse(text);

    // ---- list item: no when, explicit intent --------------------------
    if (parsed.tense == Tense.listItem && forcedKeyId == null) {
      final id =
          await addListItem(parsed.matchText.isEmpty ? text : parsed.matchText);
      return CaptureOutcome.listed(id);
    }

    // ---- key ------------------------------------------------------------
    MatchResult? match;
    int? keyId = forcedKeyId;
    var keySource = forcedKeyId != null ? 'picked' : 'unfiled';
    double? score;
    if (keyId == null && modality != 'photo') {
      match = await matcher.match(parsed.matchText);
      if (match.decision == MatchDecision.autoAssign) {
        keyId = match.top.first.keyId;
        keySource = 'auto';
        score = match.top.first.score;
      } else if (match.top.isNotEmpty) {
        score = match.top.first.score;
      }
    }
    // For "when", a good picker candidate is still useful for resolving
    // "morning" - use it without committing to it.
    final whenKeyId = keyId ?? match?.top.firstOrNull?.keyId;

    // ---- when -----------------------------------------------------------
    final local = overrideTime ?? await _resolveWhen(parsed, now, whenKeyId);
    final status = parsed.tense == Tense.planned ||
            local.isAfter(now.add(const Duration(minutes: 5)))
        ? 'planned'
        : 'done';
    final dayDate = targetDayDate ?? await _dayDateFor(local);

    final meta = <String, dynamic>{
      if (parsed.window != null) 'window': parsed.window!.label,
      if (modality == 'photo') 'ai_pending': true,
      ...?extraMetadata,
      ...?await NutritionService(db).matchText(text),
    };

    final id = await db.insertEvent(EventsCompanion.insert(
      keyId: Value(keyId),
      tsUtc: local.toUtc(),
      tz: local.timeZoneName,
      dayDate: dayDate,
      rawText: text,
      modality: modality,
      keySource: keySource,
      matchScore: Value(score),
      captureMs: Value(captureMs),
      photoPath: Value(photoPath),
      thumbPath: Value(thumbPath),
      status: Value(status),
      durationMin: Value(parsed.durationMin),
      quantity: Value(parsed.quantity),
      unit: Value(parsed.unit),
      metadata: Value(meta.isEmpty ? null : jsonEncode(meta)),
    ));
    vocab.invalidate();

    final wantsNote = parsed.noteSignal || await _keyWantsNote(keyId);

    if (keySource == 'auto') {
      return CaptureOutcome.autoAssigned(id, match!.top.first, match,
          planned: status == 'planned', at: local, wantsNote: wantsNote);
    }
    if (forcedKeyId != null || modality == 'photo') {
      return CaptureOutcome.saved(id,
          planned: status == 'planned', at: local, wantsNote: wantsNote);
    }
    return CaptureOutcome.needsPick(id, match!,
        suggestedKeyName: suggestKeyName(parsed.matchText),
        planned: status == 'planned',
        at: local,
        wantsNote: wantsNote);
  }

  /// Bed / Up: fixed chips, no matching. Up also nudges the day open.
  Future<CaptureOutcome> bed({int? captureMs}) =>
      _fixed(sleepKeyName, 'Bed', captureMs);
  Future<CaptureOutcome> up({int? captureMs}) =>
      _fixed(wakeKeyName, 'Up', captureMs);

  Future<CaptureOutcome> _fixed(String keyName, String label, int? ms) async {
    var k = await db.keyByName(keyName);
    k ??= await db.keyById(await db.createKey(keyName));
    return capture(
        rawText: label, modality: 'widget', forcedKeyId: k!.id, captureMs: ms);
  }

  // ---------------------------------------------------- planned lifecycle

  /// Ghost tapped, or list item ticked with a time. [at] defaults to now.
  Future<void> completePlanned(int eventId, {DateTime? at}) async {
    final e = await db.eventById(eventId);
    if (e == null) return;
    final local = at ?? DateTime.now();
    final meta = <String, dynamic>{};
    if (e.metadata != null && e.metadata!.isNotEmpty) {
      try {
        meta.addAll(jsonDecode(e.metadata!) as Map<String, dynamic>);
      } catch (_) {}
    }
    meta['was_planned'] = true; // feeds planned-vs-done in Patterns
    await db.updateEvent(
        eventId,
        EventsCompanion(
          status: const Value('done'),
          tsUtc: Value(local.toUtc()),
          tz: Value(local.timeZoneName),
          dayDate: Value(await _dayDateFor(local)),
          metadata: Value(jsonEncode(meta)),
        ));
    if (e.listItemId != null) {
      await db.updateListItem(
          e.listItemId!, ListItemsCompanion(doneEventId: Value(eventId)));
    }
    vocab.invalidate();
  }

  Future<void> skipPlanned(int eventId) =>
      db.updateEvent(eventId, const EventsCompanion(status: Value('skipped')));

  /// Morning review: "Today" moves a pending item to today, same hour.
  Future<void> moveToToday(int eventId) async {
    final e = await db.eventById(eventId);
    if (e == null) return;
    final old = e.tsUtc.toLocal();
    final now = DateTime.now();
    var local = DateTime(now.year, now.month, now.day, old.hour, old.minute);
    if (local.isBefore(now)) local = now.add(const Duration(hours: 1));
    await db.updateEvent(
        eventId,
        EventsCompanion(
          status: const Value('planned'),
          tsUtc: Value(local.toUtc()),
          dayDate: Value(await _dayDateFor(local)),
        ));
  }

  /// Day close: planned items whose time has passed become pending for the
  /// morning review. Returns how many.
  Future<int> markPending(String dayDate) async {
    final rows = await db.eventsForDay(dayDate);
    var n = 0;
    for (final e in rows.where((e) => e.status == 'planned')) {
      await db.updateEvent(
          e.id, const EventsCompanion(status: Value('pending')));
      n++;
    }
    return n;
  }

  // ------------------------------------------------------------- lists

  Future<int> addListItem(String title,
      {String? section, int? keyId, DateTime? plannedWhen}) async {
    final parsed = parser.parse(title);
    final guessedKey = keyId ?? await _guessKeyId(parsed.matchText);
    final cleanTitle =
        _titleCase(parsed.matchText.isEmpty ? title.trim() : parsed.matchText);
    final now = DateTime.now();
    DateTime local;
    if (plannedWhen != null) {
      local = plannedWhen;
    } else if (parsed.hasWhen) {
      local = await _resolveWhen(parsed, now, guessedKey);
    } else {
      final u = guessedKey == null ? null : await vocab.usualMinute(guessedKey);
      final m = u ?? ((now.hour * 60 + now.minute) + 120).clamp(540, 1260);
      local = DateTime(now.year, now.month, now.day, m ~/ 60, m % 60);
      if (local.isBefore(now)) local = now.add(const Duration(hours: 1));
    }

    final itemId = await db.insertListItem(ListItemsCompanion.insert(
      title: cleanTitle,
      section: Value(section),
      keyId: Value(guessedKey),
    ));

    final eventId = await db.insertEvent(EventsCompanion.insert(
      keyId: Value(guessedKey),
      tsUtc: local.toUtc(),
      tz: local.timeZoneName,
      dayDate: await _dayDateFor(local),
      rawText: cleanTitle,
      modality: 'list',
      keySource: guessedKey == null ? 'unfiled' : 'picked',
      status: const Value('planned'),
      listItemId: Value(itemId),
    ));

    await db.updateListItem(
        itemId, ListItemsCompanion(plannedEventId: Value(eventId)));
    vocab.invalidate();
    return itemId;
  }

  /// Tick: creates a done event at [at] (default now) and links it.
  Future<int> completeListItem(int itemId, {DateTime? at}) async {
    final item = await (db.select(db.listItems)
          ..where((l) => l.id.equals(itemId)))
        .getSingle();
    final local = at ?? DateTime.now();
    int eventId;
    if (item.plannedEventId != null) {
      eventId = item.plannedEventId!;
      await completePlanned(eventId, at: local);
    } else {
      eventId = await db.insertEvent(EventsCompanion.insert(
        keyId: Value(item.keyId),
        tsUtc: local.toUtc(),
        tz: local.timeZoneName,
        dayDate: await _dayDateFor(local),
        rawText: item.title,
        modality: 'list',
        keySource: item.keyId == null ? 'unfiled' : 'picked',
        status: const Value('done'),
        listItemId: Value(item.id),
      ));
      await db.updateListItem(
          itemId, ListItemsCompanion(doneEventId: Value(eventId)));
    }
    vocab.invalidate();
    return eventId;
  }

  Future<void> uncompleteListItem(int itemId) async {
    final item = await (db.select(db.listItems)
          ..where((l) => l.id.equals(itemId)))
        .getSingle();
    if (item.doneEventId != null) await db.softDeleteEvent(item.doneEventId!);
    await db.updateListItem(
        itemId, const ListItemsCompanion(doneEventId: Value(null)));
  }

  /// Give a list item a time: it becomes a planned event (ghost) and stays
  /// in the list until done.
  Future<int> promoteListItem(int itemId, DateTime localWhen) async {
    final item = await (db.select(db.listItems)
          ..where((l) => l.id.equals(itemId)))
        .getSingle();
    if (item.plannedEventId != null) {
      await db.updateEvent(
        item.plannedEventId!,
        EventsCompanion(
          tsUtc: Value(localWhen.toUtc()),
          dayDate: Value(await _dayDateFor(localWhen)),
        ),
      );
      return item.plannedEventId!;
    }
    final id = await db.insertEvent(EventsCompanion.insert(
      keyId: Value(item.keyId),
      tsUtc: localWhen.toUtc(),
      tz: localWhen.timeZoneName,
      dayDate: await _dayDateFor(localWhen),
      rawText: item.title,
      modality: 'list',
      keySource: item.keyId == null ? 'unfiled' : 'picked',
      status: const Value('planned'),
      listItemId: Value(item.id),
    ));
    await db.updateListItem(
        itemId, ListItemsCompanion(plannedEventId: Value(id)));
    return id;
  }

  // ------------------------------------------------------ picker outcomes

  Future<void> resolvePick(
      int eventId, MatchResult match, int chosenKeyId, String rawText) async {
    final wasTop = match.top.isNotEmpty && match.top.first.keyId == chosenKeyId;
    await db.assignKey(eventId, chosenKeyId, wasTop ? 'picked' : 'corrected',
        score: match.top.firstOrNull?.score);
    await matcher.recordOutcome(
        keyId: chosenKeyId,
        inputText: parser.parse(rawText).matchText,
        inputVector: match.inputVector,
        corrected: !wasTop);
    if (!wasTop) {
      await recordCorrection(rawText, 'key',
          predicted: match.top.firstOrNull?.keyName,
          corrected: (await db.keyById(chosenKeyId))?.name ?? '$chosenKeyId');
    }
    await _maybeRetime(eventId, chosenKeyId);
  }

  Future<int> resolveNewKey(
      int eventId, MatchResult match, String name, String rawText) async {
    final clean = name.trim().toLowerCase();
    final keyId = await matcher.createKeyWithSeed(
        clean, parser.parse(rawText).matchText, match.inputVector);
    if (_noteKeys.contains(clean)) {
      await db.updateKey(
          keyId, const KeysCompanion(notesAffinity: Value(true)));
    }
    await db.assignKey(eventId, keyId, 'new');
    await recordCorrection(rawText, 'key',
        predicted: match.top.firstOrNull?.keyName, corrected: clean);
    return keyId;
  }

  Future<void> undoAutoAssign(
      int eventId, MatchResult match, int newKeyId, String rawText) async {
    await db.assignKey(eventId, newKeyId, 'corrected',
        score: match.top.firstOrNull?.score);
    await matcher.recordOutcome(
        keyId: newKeyId,
        inputText: parser.parse(rawText).matchText,
        inputVector: match.inputVector,
        corrected: true);
    await recordCorrection(rawText, 'key',
        predicted: match.top.firstOrNull?.keyName,
        corrected: (await db.keyById(newKeyId))?.name ?? '$newKeyId');
  }

  /// A planned event resolved through a window with no key guess used the
  /// global default; once the key is known, re-resolve to that key's time.
  Future<void> _maybeRetime(int eventId, int keyId) async {
    final e = await db.eventById(eventId);
    if (e == null || e.status != 'planned' || e.metadata == null) return;
    final meta = jsonDecode(e.metadata!) as Map<String, dynamic>;
    final wl = meta['window'] as String?;
    if (wl == null) return;
    final w = TimeWindow.values.where((x) => x.label == wl).firstOrNull;
    if (w == null) return;
    final minute = await vocab.resolve(w, keyId: keyId);
    final old = e.tsUtc.toLocal();
    final local =
        DateTime(old.year, old.month, old.day, minute ~/ 60, minute % 60);
    await db.updateEvent(eventId, EventsCompanion(tsUtc: Value(local.toUtc())));
  }

  // ---------------------------------------------------------------- notes

  Future<void> setNote(int eventId, String? note) async {
    final e = await db.eventById(eventId);
    await db.updateEvent(eventId, EventsCompanion(note: Value(note)));
    if (e?.keyId != null && note != null && note.trim().isNotEmpty) {
      final k = await db.keyById(e!.keyId!);
      final added = (k?.notesAdded ?? 0) + 1;
      await db.updateKey(
          e.keyId!,
          KeysCompanion(
              notesAdded: Value(added),
              notesAffinity: Value(added >= 2 || (k?.notesAffinity ?? false))));
    }
  }

  Future<void> noteIgnored(int? keyId) async {
    if (keyId == null) return;
    final k = await db.keyById(keyId);
    if (k == null) return;
    final ignored = k.notesIgnored + 1;
    await db.updateKey(
        keyId,
        KeysCompanion(
            notesIgnored: Value(ignored),
            notesAffinity: Value(ignored >= 5 ? false : k.notesAffinity)));
  }

  // ---------------------------------------------------------- corrections

  Future<void> recordCorrection(String rawText, String field,
          {String? predicted, required String corrected}) =>
      db.insertCorrection(CorrectionsCompanion.insert(
          rawText: rawText,
          field: field,
          predicted: Value(predicted),
          corrected: corrected));

  // ------------------------------------------------------------- helpers

  Future<DateTime> _resolveWhen(ParsedEntry p, DateTime now, int? keyId) async {
    final day = p.targetDay(now);
    if (p.exactLocal != null) {
      return DateTime(day.year, day.month, day.day, p.exactLocal!.hour,
          p.exactLocal!.minute);
    }
    if (p.window != null) {
      final m = await vocab.resolve(p.window!, keyId: keyId);
      var t = DateTime(day.year, day.month, day.day, m ~/ 60, m % 60);
      // "tonight" spoken at 23:30 with a learned 21:00 -> keep it future.
      if (p.tense == Tense.planned && p.dayOffset == 0 && t.isBefore(now)) {
        t = now.add(const Duration(minutes: 30));
      }
      return t;
    }
    if (p.dayOffset != 0 || p.weekday != null) {
      // A day but no time: planned items get the key's usual time or 09:00;
      // done items get noon so they sit mid-ribbon.
      if (p.tense == Tense.planned) {
        final u = keyId == null ? null : await vocab.usualMinute(keyId);
        final m = u ?? 540;
        return DateTime(day.year, day.month, day.day, m ~/ 60, m % 60);
      }
      return DateTime(day.year, day.month, day.day, 12);
    }
    return now;
  }

  Future<String> _dayDateFor(DateTime local) async {
    final resolver = DayResolver(
      cutoffHour: await settings.dayCutoffHour(),
      sleepEveningHour: await settings.sleepEveningHour(),
    );
    DateTime? lastSleep;
    final sleepKey = await db.keyByName(sleepKeyName);
    if (sleepKey != null) {
      final base = resolver.resolveDayDate(local);
      final s = await db.latestSleepOnDay(base, sleepKey.id);
      if (s != null) {
        final sl = s.tsUtc.toLocal();
        if (resolver.isQualifyingSleep(sl)) lastSleep = sl;
      }
    }
    return resolver.resolveDayDate(local, lastQualifyingSleepLocal: lastSleep);
  }

  Future<int?> _guessKeyId(String matchText) async {
    if (matchText.trim().isEmpty) return null;
    final m = await matcher.match(matchText);
    final t = m.top.firstOrNull;
    if (t == null) return null;
    return t.score >= await settings.pickerThreshold() ? t.keyId : null;
  }

  Future<bool> _keyWantsNote(int? keyId) async {
    if (keyId == null) return false;
    return (await db.keyById(keyId))?.notesAffinity ?? false;
  }

  static const _stopWords = {
    'went',
    'did',
    'done',
    'doing',
    'do',
    'had',
    'have',
    'having',
    'got',
    'get',
    'getting',
    'played',
    'playing',
    'play',
    'watched',
    'watching',
    'watch',
    'read',
    'reading',
    'bought',
    'buy',
    'buying',
    'finished',
    'completed',
    'started',
    'starting',
    'start',
    'took',
    'taking',
    'take',
    'made',
    'making',
    'make',
    'worked',
    'working',
    'called',
    'calling',
    'talked',
    'talking',
    'spoke',
    'speaking',
    'listened',
    'listening',
    'listen',
    'ate',
    'eating',
    'eat',
    'drank',
    'drinking',
    'drink',
    'met',
    'meet',
    'go',
    'going',
    'gone',
    'came',
    'come',
    'coming',
    'with',
    'for',
    'about',
    'some',
    'the',
    'a',
    'an',
    'my',
    'to',
    'in',
    'on',
    'at',
    'by',
    'from',
    'and',
    'then',
    'also',
    'just',
    'more',
    'new',
    'good',
    'bad',
    'little',
    'lot',
    'of',
    'into',
    'out',
    'up',
    'down',
    'over',
    'under',
    'again',
    'further',
    'once',
    'here',
    'there',
    'when',
    'where',
    'why',
    'how',
    'all',
    'any',
    'both',
    'each',
    'few',
    'such',
    'no',
    'nor',
    'not',
    'only',
    'own',
    'same',
    'so',
    'than',
    'too',
    'very',
    'can',
    'will',
    'should',
    'now',
    'today',
    'yesterday',
    'tomorrow',
    'tonight',
    'morning',
    'afternoon',
    'evening',
    'night',
    'hour',
    'hours',
    'min',
    'mins',
    'minutes',
    'time'
  };

  String suggestKeyName(String matchText) {
    final lower = matchText.toLowerCase().trim();
    if (RegExp(r'\b(woke|wake|waking|awake)\b').hasMatch(lower)) return 'wake';
    if (RegExp(r'\b(slept|sleep|sleeping|nap|bed|bedtime)\b').hasMatch(lower)) {
      return 'sleep';
    }

    final words = lower
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !RegExp(r'^\d+$').hasMatch(w))
        .toList();

    if (words.isEmpty) return 'general';

    final filtered = words.where((w) => !_stopWords.contains(w)).toList();
    if (filtered.isNotEmpty) return filtered.first;

    // If all words were filtered, take the longest word
    words.sort((a, b) => b.length.compareTo(a.length));
    return words.first;
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class CaptureOutcome {
  CaptureOutcome._(this.eventId, this.state,
      {this.autoKey,
      this.match,
      this.suggestedKeyName,
      this.planned = false,
      this.at,
      this.wantsNote = false});

  final int eventId; // event id, or list item id for [listed]
  final CaptureState state;
  final KeyScore? autoKey;
  final MatchResult? match;
  final String? suggestedKeyName;
  final bool planned;
  final DateTime? at;
  final bool wantsNote;

  factory CaptureOutcome.saved(int id,
          {bool planned = false, DateTime? at, bool wantsNote = false}) =>
      CaptureOutcome._(id, CaptureState.saved,
          planned: planned, at: at, wantsNote: wantsNote);
  factory CaptureOutcome.autoAssigned(int id, KeyScore key, MatchResult m,
          {bool planned = false, DateTime? at, bool wantsNote = false}) =>
      CaptureOutcome._(id, CaptureState.autoAssigned,
          autoKey: key,
          match: m,
          planned: planned,
          at: at,
          wantsNote: wantsNote);
  factory CaptureOutcome.needsPick(int id, MatchResult m,
          {String? suggestedKeyName,
          bool planned = false,
          DateTime? at,
          bool wantsNote = false}) =>
      CaptureOutcome._(id, CaptureState.needsPick,
          match: m,
          suggestedKeyName: suggestedKeyName,
          planned: planned,
          at: at,
          wantsNote: wantsNote);
  factory CaptureOutcome.listed(int itemId) =>
      CaptureOutcome._(itemId, CaptureState.listed);
}

enum CaptureState { saved, autoAssigned, needsPick, listed }
