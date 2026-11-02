import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart'; // dart run build_runner build

@DriftDatabase(tables: [
  Keys,
  Events,
  ListItems,
  Corrections,
  KeyExamples,
  DaySummaries,
  KeyAnalyses,
  PeriodSummaries,
  Recurrences,
  RecurrenceSuppressions,
  FutureEntries,
  Plans,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  /// False if this SQLite build has no FTS5; searchEvents then uses LIKE.
  bool ftsAvailable = false;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedSettings();
          await _ensureFts();
          await _ensureIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(keys, keys.usualMinuteOverride);
            await m.addColumn(keys, keys.notesAffinity);
            await m.addColumn(keys, keys.notesAdded);
            await m.addColumn(keys, keys.notesIgnored);
            await m.addColumn(events, events.status);
            await m.addColumn(events, events.durationMin);
            await m.addColumn(events, events.quantity);
            await m.addColumn(events, events.unit);
            await m.addColumn(events, events.note);
            await m.addColumn(events, events.listItemId);
            await m.createTable(listItems);
            await m.createTable(corrections);
            // v1 future_entries become planned events at their hint time
            // (or 09:00). tz falls back to the device zone name.
            await customStatement('''
              INSERT INTO events (key_id, ts_utc, tz, day_date, raw_text, modality,
                                  key_source, status, created_at)
              SELECT key_id,
                     CAST(strftime('%s', entry_date || ' ' ||
                          COALESCE(time_hint, '09:00') || ':00') AS INTEGER),
                     'local', entry_date, title, 'text',
                     CASE WHEN key_id IS NULL THEN 'unfiled' ELSE 'picked' END,
                     'planned', created_at
              FROM future_entries
            ''');
            await customStatement("DELETE FROM future_entries");
            await putSetting('schema_version', '2');
          }
          if (from < 3) {
            await _ensureFts();
            await putSetting('schema_version', '3');
          }
          if (from < 4) {
            await _ensureIndexes();
            await putSetting('schema_version', '4');
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // The widget's headless isolate writes to this same file.
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA busy_timeout = 3000');
          // Existing DBs that already migrated still need the flag set.
          if (!details.wasCreated &&
              details.versionBefore == details.versionNow) {
            await _probeFts();
          }
        },
      );

  Future<void> _seedSettings() async {
    final defaults = <String, String>{
      'schema_version': '4',
      'llm_text_enabled': 'false',
      'photo_cloud_enabled': 'false',
      'day_cutoff_hour': '4',
      'sleep_evening_hour': '20',
      'training_mode_until': '',
      'auto_assign_threshold': '0.72',
      'picker_threshold': '0.45',
      'monthly_budget_usd_cents': '300',
      'budget_month': '',
      'budget_spent_usd_microcents': '0',
      'quiet_days_before_nudge': '3',
      'notifications_enabled': 'false',
      'how_to_seen': 'false',
      'embedder_id': '',
    };
    await batch((b) {
      for (final e in defaults.entries) {
        b.insert(settings, SettingsCompanion.insert(k: e.key, v: e.value),
            mode: InsertMode.insertOrIgnore);
      }
    });
  }

  // ---------------------------------------------------------------- events

  Future<int> insertEvent(EventsCompanion e) => into(events).insert(e);

  Future<Event?> eventById(int id) =>
      (select(events)..where((e) => e.id.equals(id))).getSingleOrNull();

  /// Everything on a day that is not deleted, chronological. Includes
  /// planned/pending/skipped; callers filter by status.
  Future<List<Event>> eventsForDay(String dayDate) => (select(events)
        ..where((e) => e.dayDate.equals(dayDate) & e.deletedAt.isNull())
        ..orderBy([(e) => OrderingTerm.asc(e.tsUtc)]))
      .get();

  Future<List<Event>> doneEventsForDay(String dayDate) => (select(events)
        ..where((e) =>
            e.dayDate.equals(dayDate) &
            e.deletedAt.isNull() &
            e.status.equals('done'))
        ..orderBy([(e) => OrderingTerm.asc(e.tsUtc)]))
      .get();

  /// Planned events from [fromDay] onwards (for the key bar and lists).
  Future<List<Event>> plannedFrom(String fromDay) => (select(events)
        ..where((e) =>
            e.dayDate.isBiggerOrEqualValue(fromDay) &
            e.deletedAt.isNull() &
            e.status.equals('planned'))
        ..orderBy([(e) => OrderingTerm.asc(e.tsUtc)]))
      .get();

  Future<List<Event>> pendingEvents() => (select(events)
        ..where((e) => e.deletedAt.isNull() & e.status.equals('pending'))
        ..orderBy([(e) => OrderingTerm.asc(e.tsUtc)]))
      .get();

  Future<List<Event>> unfiledEvents() => (select(events)
        ..where((e) => e.keyId.isNull() & e.deletedAt.isNull())
        ..orderBy([(e) => OrderingTerm.desc(e.tsUtc)]))
      .get();

  Future<void> updateEvent(int id, EventsCompanion patch) =>
      (update(events)..where((e) => e.id.equals(id)))
          .write(patch.copyWith(editedAt: Value(DateTime.now().toUtc())));

  Future<void> softDeleteEvent(int id) =>
      (update(events)..where((e) => e.id.equals(id)))
          .write(EventsCompanion(deletedAt: Value(DateTime.now().toUtc())));

  Future<void> assignKey(int eventId, int keyId, String keySource,
          {double? score}) =>
      updateEvent(
          eventId,
          EventsCompanion(
              keyId: Value(keyId),
              keySource: Value(keySource),
              matchScore: Value(score)));

  Future<Event?> latestSleepOnDay(String dayDate, int sleepKeyId) =>
      (select(events)
            ..where((e) =>
                e.dayDate.equals(dayDate) &
                e.keyId.equals(sleepKeyId) &
                e.status.equals('done') &
                e.deletedAt.isNull())
            ..orderBy([(e) => OrderingTerm.desc(e.tsUtc)])
            ..limit(1))
          .getSingleOrNull();

  /// Done events for a key over the last [days] days. Used by the time
  /// vocabulary ("when is morning for gym?") and by Patterns.
  Future<List<Event>> recentDoneForKey(int keyId, {int days = 60}) =>
      (select(events)
            ..where((e) =>
                e.keyId.equals(keyId) &
                e.status.equals('done') &
                e.deletedAt.isNull() &
                e.tsUtc.isBiggerOrEqualValue(
                    DateTime.now().toUtc().subtract(Duration(days: days))))
            ..orderBy([(e) => OrderingTerm.asc(e.tsUtc)]))
          .get();

  Future<List<Event>> recentDone({int days = 60}) => (select(events)
        ..where((e) =>
            e.status.equals('done') &
            e.deletedAt.isNull() &
            e.tsUtc.isBiggerOrEqualValue(
                DateTime.now().toUtc().subtract(Duration(days: days)))))
      .get();

  // ------------------------------------------------------------------ fts

  /// External-content FTS5 over events(raw_text, note), kept in sync by
  /// triggers. Rebuilt once after creation so existing rows are indexed.
  Future<void> _ensureFts() async {
    try {
      await customStatement('''
        CREATE VIRTUAL TABLE IF NOT EXISTS events_fts USING fts5(
          raw_text, note,
          content='events', content_rowid='id',
          tokenize='unicode61 remove_diacritics 2'
        )''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS events_fts_ai AFTER INSERT ON events BEGIN
          INSERT INTO events_fts(rowid, raw_text, note)
          VALUES (new.id, new.raw_text, new.note);
        END''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS events_fts_ad AFTER DELETE ON events BEGIN
          INSERT INTO events_fts(events_fts, rowid, raw_text, note)
          VALUES ('delete', old.id, old.raw_text, old.note);
        END''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS events_fts_au AFTER UPDATE ON events BEGIN
          INSERT INTO events_fts(events_fts, rowid, raw_text, note)
          VALUES ('delete', old.id, old.raw_text, old.note);
          INSERT INTO events_fts(rowid, raw_text, note)
          VALUES (new.id, new.raw_text, new.note);
        END''');
      await customStatement("INSERT INTO events_fts(events_fts) VALUES ('rebuild')");
      ftsAvailable = true;
    } catch (_) {
      ftsAvailable = false; // no FTS5 in this build; LIKE fallback stays
    }
  }

  Future<void> _probeFts() async {
    try {
      await customSelect('SELECT count(*) FROM events_fts').getSingle();
      ftsAvailable = true;
    } catch (_) {
      ftsAvailable = false;
    }
  }

  /// Call after bulk operations that bypass triggers' assumptions (restore).
  Future<void> rebuildSearchIndex() async {
    if (!ftsAvailable) return;
    try {
      await customStatement("INSERT INTO events_fts(events_fts) VALUES ('rebuild')");
    } catch (_) {}
  }

  /// Every hot query filters on these. Composite order matters: equality
  /// columns first, then the range/sort column.
  Future<void> _ensureIndexes() async {
    const stmts = [
      // eventsForDay / doneEventsForDay / latestSleepOnDay / counts
      'CREATE INDEX IF NOT EXISTS idx_events_day_ts ON events(day_date, ts_utc)',
      // plannedFrom / pendingEvents / closeMissedDays
      'CREATE INDEX IF NOT EXISTS idx_events_status_day ON events(status, day_date, ts_utc)',
      // recentDoneForKey / Patterns.select / chip ranking join
      'CREATE INDEX IF NOT EXISTS idx_events_key_status_ts ON events(key_id, status, ts_utc)',
      // recentDone / widget sync / recurrence scan (time-bounded scans)
      'CREATE INDEX IF NOT EXISTS idx_events_ts ON events(ts_utc)',
      // KeyMatcher.warmUp per key, mergeKeys
      'CREATE INDEX IF NOT EXISTS idx_key_examples_key ON key_examples(key_id)',
      // openListItems
      'CREATE INDEX IF NOT EXISTS idx_list_items_open ON list_items(deleted_at, done_event_id, section, sort_order)',
      // ChipsController routines, scanForProposals overlap checks
      'CREATE INDEX IF NOT EXISTS idx_recurrences_key_dow ON recurrences(key_id, day_of_week, status)',
    ];
    for (final s in stmts) {
      await customStatement(s);
    }
  }

  /// "dent fri" -> '"dent"* "fri"*' : every term is a prefix, all must match.
  static String _ftsQuery(String raw) {
    final terms = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => '"$t"*');
    return terms.join(' ');
  }

  /// Search events across rawText and notes with optional key or date range filters.
  Future<List<Event>> searchEvents({
    String? query,
    int? keyId,
    String? fromDate,
    String? toDate,
    int limit = 100,
  }) async {
    final q = query?.trim() ?? '';
    final ftsQ = _ftsQuery(q);
    final useFts = ftsAvailable && ftsQ.isNotEmpty;

    if (!useFts) {
      return _searchLike(
        query: q,
        keyId: keyId,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
      );
    }

    final where = <String>['e.deleted_at IS NULL', 'events_fts MATCH ?'];
    final vars = <Variable>[Variable.withString(ftsQ)];
    if (keyId != null) {
      where.add('e.key_id = ?');
      vars.add(Variable.withInt(keyId));
    }
    if (fromDate != null) {
      where.add('e.day_date >= ?');
      vars.add(Variable.withString(fromDate));
    }
    if (toDate != null) {
      where.add('e.day_date <= ?');
      vars.add(Variable.withString(toDate));
    }
    vars.add(Variable.withInt(limit));

    try {
      final rows = await customSelect(
        'SELECT e.* FROM events e JOIN events_fts ON events_fts.rowid = e.id '
        'WHERE ${where.join(' AND ')} '
        'ORDER BY bm25(events_fts), e.ts_utc DESC LIMIT ?',
        variables: vars,
        readsFrom: {events},
      ).get();
      return rows.map((r) => events.map(r.data)).toList();
    } catch (_) {
      // Malformed MATCH or FTS hiccup: degrade, never fail the screen.
      return _searchLike(
        query: q,
        keyId: keyId,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
      );
    }
  }

  Future<List<Event>> _searchLike({
    required String query,
    int? keyId,
    String? fromDate,
    String? toDate,
    required int limit,
  }) {
    final statement = select(events)
      ..where((e) {
        var expr = e.deletedAt.isNull();
        if (keyId != null) expr = expr & e.keyId.equals(keyId);
        if (fromDate != null) {
          expr = expr & e.dayDate.isBiggerOrEqualValue(fromDate);
        }
        if (toDate != null) {
          expr = expr & e.dayDate.isSmallerOrEqualValue(toDate);
        }
        if (query.isNotEmpty) {
          final term = '%${query.toLowerCase()}%';
          expr = expr &
              (e.rawText.lower().like(term) |
                  (e.note.isNotNull() & e.note.lower().like(term)));
        }
        return expr;
      })
      ..orderBy([(e) => OrderingTerm.desc(e.tsUtc)])
      ..limit(limit);
    return statement.get();
  }

  /// Clean up soft-deleted events older than [daysOld] days.
  Future<int> cleanupSoftDeleted({int daysOld = 90}) async {
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: daysOld));
    return (delete(events)
          ..where((e) =>
              e.deletedAt.isNotNull() & e.deletedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  // ------------------------------------------------------------------ keys

  Future<List<Key>> activeKeys() =>
      (select(keys)..where((k) => k.isArchived.equals(false))).get();

  Future<int> createKey(String name) =>
      into(keys).insert(KeysCompanion.insert(name: name));

  Future<Key?> keyByName(String name) =>
      (select(keys)..where((k) => k.name.equals(name))).getSingleOrNull();

  Future<Key?> keyById(int id) =>
      (select(keys)..where((k) => k.id.equals(id))).getSingleOrNull();

  Future<void> updateKey(int id, KeysCompanion patch) =>
      (update(keys)..where((k) => k.id.equals(id))).write(patch);

  /// Atomically merges all events, examples, and list items from [fromKeyId]
  /// into [toKeyId], then archives [fromKeyId].
  Future<void> mergeKeys({required int fromKeyId, required int toKeyId}) async {
    await transaction(() async {
      await (update(events)..where((e) => e.keyId.equals(fromKeyId)))
          .write(EventsCompanion(keyId: Value(toKeyId)));
      await (update(keyExamples)..where((k) => k.keyId.equals(fromKeyId)))
          .write(KeyExamplesCompanion(keyId: Value(toKeyId)));
      await (update(listItems)..where((l) => l.keyId.equals(fromKeyId)))
          .write(ListItemsCompanion(keyId: Value(toKeyId)));
      await updateKey(fromKeyId, const KeysCompanion(isArchived: Value(true)));
    });
  }

  /// Verifies SQLite database integrity.
  Future<bool> checkIntegrity() async {
    try {
      final res = await customSelect('PRAGMA integrity_check;').getSingle();
      final val = res.data.values.firstOrNull;
      return val == 'ok';
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------ list items

  Future<List<ListItem>> openListItems() => (select(listItems)
        ..where((l) => l.deletedAt.isNull() & l.doneEventId.isNull())
        ..orderBy([
          (l) => OrderingTerm.asc(l.section),
          (l) => OrderingTerm.asc(l.sortOrder),
          (l) => OrderingTerm.asc(l.createdAt),
        ]))
      .get();

  Future<int> insertListItem(ListItemsCompanion row) =>
      into(listItems).insert(row);

  Future<void> updateListItem(int id, ListItemsCompanion patch) =>
      (update(listItems)..where((l) => l.id.equals(id))).write(patch);

  // ----------------------------------------------------------- corrections

  Future<int> insertCorrection(CorrectionsCompanion row) =>
      into(corrections).insert(row);

  Future<List<Correction>> allCorrections() => (select(corrections)
        ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
      .get();

  // -------------------------------------------------------------- examples

  Future<List<KeyExample>> allExamples() => select(keyExamples).get();

  Future<int> insertExample(KeyExamplesCompanion ex) async {
    final id = await into(keyExamples).insert(ex);
    await customUpdate(
      'UPDATE keys SET example_count = example_count + 1 WHERE id = ?',
      variables: [Variable.withInt(ex.keyId.value)],
      updates: {keys},
    );
    return id;
  }

  // ------------------------------------------------------------- summaries

  Future<void> upsertDaySummary(DaySummariesCompanion row) =>
      into(daySummaries).insertOnConflictUpdate(row);

  Future<DaySummary?> daySummary(String dayDate) => (select(daySummaries)
        ..where((d) => d.dayDate.equals(dayDate)))
      .getSingleOrNull();

  Future<void> upsertKeyAnalysis(KeyAnalysesCompanion row) =>
      into(keyAnalyses).insertOnConflictUpdate(row);

  Future<List<KeyAnalyse>> analysesForKeys(List<int> keyIds) =>
      (select(keyAnalyses)..where((a) => a.keyId.isIn(keyIds))).get();

  // ---------------------------------------------------------------- future

  Future<List<FutureEntry>> futureForDate(String date) =>
      (select(futureEntries)..where((f) => f.entryDate.equals(date))).get();

  Future<int> insertFutureEntry(FutureEntriesCompanion row) =>
      into(futureEntries).insert(row);

  // -------------------------------------------------------------- settings

  final Map<String, String?> _settingsCache = {};

  Future<String?> setting(String key) async {
    if (_settingsCache.containsKey(key)) return _settingsCache[key];
    final row = await (select(settings)..where((s) => s.k.equals(key)))
        .getSingleOrNull();
    return _settingsCache[key] = row?.v;
  }

  Future<void> putSetting(String key, String value) async {
    _settingsCache[key] = value;
    await into(settings).insertOnConflictUpdate(
        SettingsCompanion(k: Value(key), v: Value(value)));
  }

  Future<void> deleteSetting(String key) async {
    _settingsCache.remove(key);
    await (delete(settings)..where((s) => s.k.equals(key))).go();
  }

  void clearSettingsCache() => _settingsCache.clear();
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'daylog.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
