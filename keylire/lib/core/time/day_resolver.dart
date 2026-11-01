/// Sleep-to-sleep day assignment with the two hardening rules:
///   1. 4am fallback - an event at 01:30 belongs to yesterday's day.
///   2. Nap rule - a "sleep" event only closes the day if logged at/after
///      the evening threshold (default 20:00) or in the 00:00-cutoff window.
///
/// day_date is stamped ONCE at capture and never rewritten. If the cutoff
/// rule ever changes, history stays as assigned - that is deliberate.
class DayResolver {
  DayResolver({this.cutoffHour = 4, this.sleepEveningHour = 20});

  final int cutoffHour;
  final int sleepEveningHour;

  /// yyyy-MM-dd the event belongs to, from LOCAL wall-clock time.
  ///
  /// [lastQualifyingSleepLocal] = local timestamp of the most recent
  /// qualifying sleep event already logged on the candidate day (or null).
  /// If the day was closed by sleep and this event comes after it but
  /// before the 4am fallback, it rolls forward to the next day.
  String resolveDayDate(DateTime local, {DateTime? lastQualifyingSleepLocal}) {
    var day = _baseDay(local);
    final sleep = lastQualifyingSleepLocal;
    if (sleep != null && _baseDay(sleep) == day && !local.isBefore(sleep)) {
      day = day.add(const Duration(days: 1));
    }
    return formatDay(day);
  }

  /// True if a sleep event at this local time closes the day
  /// (i.e. it is not a nap).
  bool isQualifyingSleep(DateTime local) =>
      local.hour >= sleepEveningHour || local.hour < cutoffHour;

  DateTime _baseDay(DateTime local) {
    final anchor = local.subtract(Duration(hours: cutoffHour));
    return DateTime(anchor.year, anchor.month, anchor.day);
  }

  static String formatDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// ISO day-of-week mapped to 0..6 with Monday = 0 (matches the schema).
  static int dowOf(DateTime local) => local.weekday - 1;
}
