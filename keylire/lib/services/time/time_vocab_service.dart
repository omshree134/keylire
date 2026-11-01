import '../../core/parse/entry_parser.dart';
import '../../data/db/database.dart';

/// Resolves a named window ("morning", "after work") to a minute-of-day for
/// THIS user, and if possible for THIS key.
///
/// Order:
///   1. key override the user set by hand (Patterns > usual time)
///   2. median of this key's done events inside the window, last 60 days, n >= 2
///   3. median of ALL done events inside the window, n >= 3
///   4. the window's default
///
/// No table, no training step: it is a query over events, cached for the
/// session and invalidated on every write. The "learning" is that the
/// user's real times are the data.
class TimeVocabService {
  TimeVocabService(this.db);
  final AppDatabase db;

  Map<int, List<int>>? _minutesByKey; // keyId -> minute-of-day list
  List<int>? _allMinutes;

  void invalidate() {
    _minutesByKey = null;
    _allMinutes = null;
  }

  Future<int> resolve(TimeWindow w, {int? keyId}) async {
    if (keyId != null) {
      final k = await db.keyById(keyId);
      final o = k?.usualMinuteOverride;
      if (o != null && _inWindow(o, w)) return o;
    }
    await _load();
    if (keyId != null) {
      final own = (_minutesByKey![keyId] ?? const [])
          .where((m) => _inWindow(m, w))
          .toList();
      if (own.length >= 2) return _median(own);
    }
    final all = _allMinutes!.where((m) => _inWindow(m, w)).toList();
    if (all.length >= 3) return _median(all);
    return w.defaultMinute % 1440;
  }

  /// The key's usual minute regardless of window: override, else median of
  /// its last 60 days, else null. Used for chip ranking and ghosts.
  Future<int?> usualMinute(int keyId) async {
    final k = await db.keyById(keyId);
    if (k?.usualMinuteOverride != null) return k!.usualMinuteOverride;
    await _load();
    final own = _minutesByKey![keyId];
    if (own == null || own.length < 3) return null;
    return _median(own);
  }

  Future<void> _load() async {
    if (_minutesByKey != null) return;
    final rows = await db.recentDone(days: 60);
    final byKey = <int, List<int>>{};
    final all = <int>[];
    for (final e in rows) {
      final l = e.tsUtc.toLocal();
      final m = l.hour * 60 + l.minute;
      all.add(m);
      if (e.keyId != null) byKey.putIfAbsent(e.keyId!, () => []).add(m);
    }
    _minutesByKey = byKey;
    _allMinutes = all;
  }

  static bool _inWindow(int minute, TimeWindow w) {
    // Windows past midnight (night: 21:00-02:00) wrap.
    final m2 = minute < 300 ? minute + 1440 : minute;
    return m2 >= w.fromMinute && m2 <= w.toMinute;
  }

  static int _median(List<int> xs) {
    final s = [...xs]..sort();
    return s[s.length ~/ 2];
  }
}
