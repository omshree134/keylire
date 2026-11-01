/// Turns one typed/spoken/captioned line into structured intent.
///
///   "ran 5k this morning"              -> done, today, window morning, 5 km
///   "gym 45 min"                       -> done, now, duration 45
///   "will feed the dog tomorrow morning" -> planned, +1 day, window morning
///   "call mom at 8 tonight"            -> planned, today 20:00
///   "need to buy a lamp"               -> list item
///   "meeting with dave about the roadmap" -> done, now, noteSignal
///
/// The parser knows nothing about keys. It removes the time words so the
/// matcher sees "feed the dog", not "feed the dog tomorrow morning".
/// Windows ("morning") are left unresolved: TimeVocabService turns them into
/// a minute using the user's own history.
class EntryParser {
  EntryParser({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;

  ParsedEntry parse(String raw) {
    final now = _clock();
    var text = ' ${raw.trim().toLowerCase().replaceAll('~', ' ').replaceAll(RegExp(r'\s+'), ' ')} ';
    final consumed = <String>[];

    // ---- 1. relative "in N units" -------------------------------------
    DateTime? exact;
    final inRel = RegExp(r' in (\d+|an?|half an?) (hours?|hrs?|h|minutes?|mins?|m) ');
    final inM = inRel.firstMatch(text);
    if (inM != null) {
      final n = _num(inM.group(1)!);
      final unit = inM.group(2)!;
      final minutes = unit.startsWith('h') ? (n * 60).round() : n.round();
      exact = now.add(Duration(minutes: minutes));
      consumed.add(inM.group(0)!);
      text = text.replaceFirst(inM.group(0)!, ' ');
    }

    // ---- 2. day words ---------------------------------------------------
    var dayOffset = 0;
    int? weekday;
    bool pastMarker = false, futureMarker = false;
    final dayRules = <RegExp, void Function(RegExpMatch)>{
      RegExp(r' day after tomorrow '): (_) => dayOffset = 2,
      RegExp(r' (tomorrow|tmrw|tmr|kal) '): (_) => dayOffset = 1,
      RegExp(r' (yesterday|yday) '): (_) {
        dayOffset = -1;
        pastMarker = true;
      },
      RegExp(r' (next|this|on|coming)? ?(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|tues|wed|thu|thurs|fri|sat|sun) '):
          (m) => weekday = _weekday(m.group(2)!),
    };
    for (final e in dayRules.entries) {
      final m = e.key.firstMatch(text);
      if (m != null) {
        e.value(m);
        consumed.add(m.group(0)!);
        text = text.replaceFirst(m.group(0)!, ' ');
      }
    }

    // ---- 3. explicit clock ----------------------------------------------
    TimeWindow? window;
    var deictic = false; // "this evening", "tonight", "shaam ko" point at a time
    if (exact == null) {
      final r = _clockOf(text);
      if (r != null) {
        exact = DateTime(now.year, now.month, now.day, r.hour, r.minute);
        text = text.replaceFirst(r.matched, ' ');
        consumed.add(r.matched);
      }
    }

    // ---- 4. named windows -----------------------------------------------
    if (exact == null) {
      final w = _windowOf(text);
      if (w != null) {
        window = w.window;
        deictic = w.deictic;
        text = text.replaceFirst(w.matched, ' ');
        consumed.add(w.matched);
      }
    }

    // ---- 5. duration & quantity -----------------------------------------
    int? durationMin;
    double? quantity;
    String? unit;
    final dur = RegExp(
        r' (?:for )?(\d+(?:\.\d+)?|an?|half an?) ?(hours?|hrs?|h|minutes?|mins?|min)\b ?');
    final dm = dur.firstMatch(text);
    if (dm != null) {
      final n = _num(dm.group(1)!);
      final u = dm.group(2)!;
      durationMin = u.startsWith('h') ? (n * 60).round() : n.round();
      text = text.replaceFirst(dm.group(0)!, ' ');
    }
    final qty = RegExp(
        r' (\d+(?:\.\d+)?) ?(km|k|kms|m|mi|miles?|steps?|pages?|pg|kcal|cal|calories|l|litres?|liters?|ml|glass(?:es)?|cups?|reps?|sets?|kg|kgs|lbs?|rs|₹|\$|inr|rupees?|words?|chapters?|episodes?|eps?|laps?|floors?)\b ?');
    final qm = qty.firstMatch(text);
    if (qm != null) {
      quantity = double.parse(qm.group(1)!);
      unit = _normUnit(qm.group(2)!);
      text = text.replaceFirst(qm.group(0)!, ' ');
    }

    // ---- 6. tense markers -----------------------------------------------
    final futureRe = RegExp(
        r"\b(will|i'?ll|gonna|going to|need to|have to|gotta|plan to|planning to|remind me|todo|to do|want to|wanna)\b");
    final pastRe = RegExp(r'\b(did|done|finished|had|went|ate|slept|woke|completed|just)\b');
    if (futureRe.hasMatch(text)) futureMarker = true;
    if (pastRe.hasMatch(text)) pastMarker = true;

    final nowMinute = now.hour * 60 + now.minute;
    final futureTime = (exact != null && exact.isAfter(now.add(const Duration(minutes: 5)))) ||
        (deictic && window != null && dayOffset == 0 && window.defaultMinute % 1440 > nowMinute);
    final futureDay = dayOffset > 0 || (weekday != null && weekday != now.weekday);

    // A quantity with no future marker is a report ("read 30 pages before
    // bed" at 2pm is still something that happened).
    final reported = (quantity != null || durationMin != null) && !futureMarker && exact == null;

    Tense tense;
    if ((pastMarker || reported) && !futureDay) {
      tense = Tense.done;
    } else if (futureDay || futureTime) {
      tense = Tense.planned;
    } else if (futureMarker && window != null) {
      tense = Tense.planned; // "will do laundry tonight"
    } else if (futureMarker) {
      tense = Tense.listItem; // "need to buy a lamp" - no when
    } else {
      tense = Tense.done;
    }

    // ---- 7. note signal -------------------------------------------------
    final noteSignal = RegExp(
            r'\b(with|about|re|regarding|decided|discussed|said|agreed|feedback|notes?|meeting|interview|doctor|call)\b')
        .hasMatch(text);

    // ---- 8. clean text for matching -------------------------------------
    var matchText = text
        .replaceAll(futureRe, ' ')
        .replaceAll(RegExp(r"\b(i|i'?m|i've|just|at|around|on|the|a|an|my|to|for|and|then|also)\b"), ' ')
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (matchText.isEmpty) matchText = raw.trim().toLowerCase();

    return ParsedEntry(
      raw: raw.trim(),
      matchText: matchText,
      tense: tense,
      exactLocal: exact,
      window: window,
      dayOffset: dayOffset,
      weekday: weekday,
      durationMin: durationMin,
      quantity: quantity,
      unit: unit,
      noteSignal: noteSignal,
      consumed: consumed,
    );
  }

  // ------------------------------------------------------------ helpers

  static double _num(String s) {
    if (s == 'a' || s == 'an') return 1;
    if (s.startsWith('half')) return 0.5;
    return double.parse(s);
  }

  static int _weekday(String s) => const {
        'mon': 1, 'monday': 1, 'tue': 2, 'tues': 2, 'tuesday': 2,
        'wed': 3, 'wednesday': 3, 'thu': 4, 'thurs': 4, 'thursday': 4,
        'fri': 5, 'friday': 5, 'sat': 6, 'saturday': 6, 'sun': 7, 'sunday': 7,
      }[s]!;

  static String _normUnit(String u) => const {
        'k': 'km', 'kms': 'km', 'mi': 'mi', 'mile': 'mi', 'miles': 'mi',
        'step': 'steps', 'page': 'pages', 'pg': 'pages',
        'cal': 'kcal', 'calories': 'kcal', 'litre': 'l', 'litres': 'l',
        'liter': 'l', 'liters': 'l', 'glass': 'glasses', 'cup': 'cups',
        'rep': 'reps', 'set': 'sets', 'kgs': 'kg', 'lb': 'lbs',
        'rs': '₹', 'inr': '₹', 'rupee': '₹', 'rupees': '₹',
        'word': 'words', 'chapter': 'chapters', 'episode': 'episodes',
        'ep': 'episodes', 'eps': 'episodes', 'lap': 'laps', 'floor': 'floors',
      }[u] ?? u;

  static _Clock? _clockOf(String t) {
    if (RegExp(r' (at )?noon ').hasMatch(t)) {
      return _Clock(12, 0, RegExp(r' (at )?noon ').firstMatch(t)!.group(0)!);
    }
    if (RegExp(r' (at )?midnight ').hasMatch(t)) {
      return _Clock(0, 0, RegExp(r' (at )?midnight ').firstMatch(t)!.group(0)!);
    }
    // 12-hour with am/pm: "at 6 pm", "6:30pm", "7 am"
    final ampm = RegExp(r' (?:at |around |by |from )?(\d{1,2})(?::(\d{2}))? ?([ap])\.?m\.? ');
    var m = ampm.firstMatch(t);
    if (m != null) {
      var h = int.parse(m.group(1)!);
      final mi = int.parse(m.group(2) ?? '0');
      if (h < 1 || h > 12 || mi > 59) return null;
      if (m.group(3) == 'p' && h < 12) h += 12;
      if (m.group(3) == 'a' && h == 12) h = 0;
      return _Clock(h, mi, m.group(0)!);
    }
    // 24h / colon: "at 18:30", "14:45", "at 9:30"
    final colon = RegExp(r' (?:at |around |by )?([01]?\d|2[0-3]):([0-5]\d) ');
    m = colon.firstMatch(t);
    if (m != null) {
      var h = int.parse(m.group(1)!);
      final mi = int.parse(m.group(2)!);
      if (h < 7 && RegExp(r'\b(dinner|gym|evening|night|tonight)\b').hasMatch(t)) h += 12;
      if (h == 12 && RegExp(r'\b(bed|slept|sleep|night|midnight)\b').hasMatch(t)) h = 0;
      return _Clock(h, mi, m.group(0)!);
    }
    // "at 8", "around 9", "8 baje"
    final bare = RegExp(r' (?:at |around |by )(\d{1,2}) | (\d{1,2}) baje ');
    m = bare.firstMatch(t);
    if (m != null) {
      var h = int.parse((m.group(1) ?? m.group(2))!);
      if (h < 1 || h > 12) return null;
      if (RegExp(r'\b(woke|wake|up|morning|breakfast|subah|am)\b').hasMatch(t)) {
        // keep am
      } else if (RegExp(r'\b(sleep|slept|bed|dinner|night|tonight|evening|shaam|raat|pm)\b').hasMatch(t)) {
        if (h < 12) h += 12;
      } else if (h <= 6) {
        h += 12; // "gym at 5" is 17:00 for most people
      }
      return _Clock(h, 0, m.group(0)!);
    }
    return null;
  }

  static _Win? _windowOf(String t) {
    // (phrase, window, deictic). Deictic phrases point at a specific time
    // from the speaker's position ("this evening", "tonight"); bare words
    // describe ("evening walk"). Longer phrases first.
    const table = <(String, TimeWindow, bool)>[
      ('early morning', TimeWindow.earlyMorning, false),
      ('this morning', TimeWindow.morning, true),
      ('in the morning', TimeWindow.morning, false),
      ('subah ko', TimeWindow.morning, true),
      ('subah', TimeWindow.morning, false),
      ('morning', TimeWindow.morning, false),
      ('at lunch', TimeWindow.midday, true),
      ('lunchtime', TimeWindow.midday, false),
      ('midday', TimeWindow.midday, false),
      ('this afternoon', TimeWindow.afternoon, true),
      ('in the afternoon', TimeWindow.afternoon, false),
      ('dopahar ko', TimeWindow.afternoon, true),
      ('dopahar', TimeWindow.afternoon, false),
      ('afternoon', TimeWindow.afternoon, false),
      ('after work', TimeWindow.afterWork, true),
      ('after office', TimeWindow.afterWork, true),
      ('after college', TimeWindow.afterWork, true),
      ('this evening', TimeWindow.evening, true),
      ('in the evening', TimeWindow.evening, false),
      ('shaam ko', TimeWindow.evening, true),
      ('shaam', TimeWindow.evening, false),
      ('evening', TimeWindow.evening, false),
      ('tonight', TimeWindow.night, true),
      ('tonite', TimeWindow.night, true),
      ('at night', TimeWindow.night, false),
      ('raat ko', TimeWindow.night, true),
      ('raat', TimeWindow.night, false),
      ('night', TimeWindow.night, false),
      ('before bed', TimeWindow.beforeBed, true),
      ('before sleeping', TimeWindow.beforeBed, true),
    ];
    for (final (phrase, w, d) in table) {
      final m = RegExp(' $phrase ').firstMatch(t);
      if (m != null) return _Win(w, m.group(0)!, d);
    }
    return null;
  }
}

enum Tense { done, planned, listItem }

/// Named parts of the day. Resolved to a minute per user, per key, by
/// TimeVocabService. Ranges are the search bands for learning.
enum TimeWindow {
  earlyMorning(300, 480, 360),
  morning(300, 690, 480),
  midday(660, 840, 780),
  afternoon(840, 1020, 900),
  afterWork(1020, 1260, 1080),
  evening(1020, 1260, 1110),
  night(1260, 1560, 1290),
  beforeBed(1260, 1560, 1350);

  const TimeWindow(this.fromMinute, this.toMinute, this.defaultMinute);
  final int fromMinute; // may exceed 1440 (past midnight)
  final int toMinute;
  final int defaultMinute;

  String get label => const {
        TimeWindow.earlyMorning: 'early morning',
        TimeWindow.morning: 'morning',
        TimeWindow.midday: 'midday',
        TimeWindow.afternoon: 'afternoon',
        TimeWindow.afterWork: 'after work',
        TimeWindow.evening: 'evening',
        TimeWindow.night: 'night',
        TimeWindow.beforeBed: 'before bed',
      }[this]!;
}

class ParsedEntry {
  const ParsedEntry({
    required this.raw,
    required this.matchText,
    required this.tense,
    this.exactLocal,
    this.window,
    this.dayOffset = 0,
    this.weekday,
    this.durationMin,
    this.quantity,
    this.unit,
    this.noteSignal = false,
    this.consumed = const [],
  });

  final String raw;
  final String matchText;
  final Tense tense;
  final DateTime? exactLocal; // date part is today; caller shifts by day
  final TimeWindow? window;
  final int dayOffset;
  final int? weekday; // 1 = Monday .. 7 = Sunday
  final int? durationMin;
  final double? quantity;
  final String? unit;
  final bool noteSignal;
  final List<String> consumed;

  bool get hasWhen => exactLocal != null || window != null || dayOffset != 0 || weekday != null;

  /// The calendar day this entry targets, given [now].
  DateTime targetDay(DateTime now) {
    var d = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
    if (weekday != null) {
      var delta = (weekday! - now.weekday) % 7;
      if (delta == 0 && tense == Tense.planned && exactLocal != null && !exactLocal!.isAfter(now)) {
        delta = 7;
      }
      d = DateTime(now.year, now.month, now.day).add(Duration(days: delta));
    }
    return d;
  }
}

class _Clock {
  _Clock(this.hour, this.minute, this.matched);
  final int hour, minute;
  final String matched;
}

class _Win {
  _Win(this.window, this.matched, this.deictic);
  final TimeWindow window;
  final String matched;
  final bool deictic;
}
