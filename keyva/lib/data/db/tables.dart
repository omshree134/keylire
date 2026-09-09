// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

/// The user's own words for the things they do. Never renamed silently.
class Keys extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Cached centroid, float32 LE. Fallback only; the matcher is kNN.
  BlobColumn get vector => blob().nullable()();
  IntColumn get exampleCount => integer().withDefault(const Constant(0))();

  /// v2. User said "actually gym is at 07:00". Minute-of-day, or null =
  /// learn from history.
  IntColumn get usualMinuteOverride => integer().nullable()();

  /// v2. Whether entries under this key tend to want a note. Seeded for
  /// meeting/doctor/call/idea; learned from notesAdded vs notesIgnored.
  BoolColumn get notesAffinity => boolean().withDefault(const Constant(false))();
  IntColumn get notesAdded => integer().withDefault(const Constant(0))();
  IntColumn get notesIgnored => integer().withDefault(const Constant(0))();
}

/// One object, three tenses. status decides where it sits on the ribbon:
///   done     - happened; above the fold.
///   planned  - will happen at tsUtc; a ghost below the fold.
///   pending  - was planned, day closed, not done; shown in morning review.
///   skipped  - user or day close said no. Kept for planned-vs-done stats.
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get keyId => integer().nullable().references(Keys, #id)();

  /// UTC + IANA zone at capture. Local is derived. For planned events this
  /// is the intended time; on completion it is rewritten to the actual.
  DateTimeColumn get tsUtc => dateTime()();
  TextColumn get tz => text()();

  /// Sleep-to-sleep day, yyyy-MM-dd. Stamped at write, rewritten only when
  /// a planned event completes (its real time may differ).
  TextColumn get dayDate => text()();

  TextColumn get rawText => text()();
  TextColumn get modality =>
      text().check(modality.isIn(const ['text', 'voice', 'photo', 'widget', 'list']))();
  TextColumn get photoPath => text().nullable()();
  TextColumn get thumbPath => text().nullable()();

  /// JSON bag for things that do not deserve a column yet: {calories, place,
  /// window, photo_labels, ocr, ai_pending}.
  TextColumn get metadata => text().nullable()();

  TextColumn get keySource => text().check(keySource
      .isIn(const ['auto', 'picked', 'new', 'corrected', 'unfiled']))();
  RealColumn get matchScore => real().nullable()();
  IntColumn get captureMs => integer().nullable()();

  // ---- v2 ----
  TextColumn get status => text()
      .withDefault(const Constant('done'))
      .check(status.isIn(const ['done', 'planned', 'pending', 'skipped']))();

  /// Parsed from the line: "gym 45 min" -> durationMin 45;
  /// "ran 5 km" -> quantity 5, unit km. Both may be present.
  IntColumn get durationMin => integer().nullable()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();

  /// Long-form text under the line. Hidden unless present.
  TextColumn get note => text().nullable()();

  /// Set when this event was created by ticking a list item.
  IntColumn get listItemId => integer().nullable()();

  DateTimeColumn get editedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Undated intentions. One list, sections inside it. Ticking creates an
/// event and stores its id so un-ticking is a soft delete, never data loss.
class ListItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get section => text().nullable()(); // heading; null = top
  IntColumn get keyId => integer().nullable().references(Keys, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get doneEventId => integer().nullable()();
  IntColumn get plannedEventId => integer().nullable()(); // promoted to a time
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Ground truth from real use. Every time the user overrides what the
/// parser or matcher decided, the original line and the right answer land
/// here. Exported into the phrase corpus; drives the scorecard.
class Corrections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawText => text()();
  TextColumn get field =>
      text().check(field.isIn(const ['key', 'time', 'tense', 'quantity', 'duration']))();
  TextColumn get predicted => text().nullable()();
  TextColumn get corrected => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Every confirmation/correction becomes a kNN anchor.
class KeyExamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get keyId => integer().references(Keys, #id)();
  TextColumn get exampleText => text()();
  BlobColumn get vector => blob()();
  TextColumn get source =>
      text().check(source.isIn(const ['confirmed', 'corrected', 'seed']))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class DaySummaries extends Table {
  TextColumn get dayDate => text()();
  TextColumn get summary => text()();
  TextColumn get flags => text().nullable()();
  IntColumn get eventCount => integer()();
  DateTimeColumn get closedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {dayDate};
}

class KeyAnalyses extends Table {
  IntColumn get keyId => integer().references(Keys, #id)();
  TextColumn get analysis => text()();
  TextColumn get stats => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {keyId};
}

/// ISO week, Monday start.
class PeriodSummaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get period => text().check(period.isIn(const ['week', 'month']))();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
  TextColumn get summary => text()();
  @override
  List<Set<Column>> get uniqueKeys => [{period, startDate}];
}

class Recurrences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get keyId => integer().references(Keys, #id)();
  IntColumn get dayOfWeek => integer().check(dayOfWeek.isBetweenValues(0, 6))();
  TextColumn get windowStart => text()();
  TextColumn get windowEnd => text()();
  TextColumn get status =>
      text().check(status.isIn(const ['proposed', 'confirmed', 'suggestion']))();
  RealColumn get confidence => real()();
  IntColumn get hitCount => integer().withDefault(const Constant(0))();
  IntColumn get consecutiveMisses => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class RecurrenceSuppressions extends Table {
  IntColumn get keyId => integer().references(Keys, #id)();
  IntColumn get dayOfWeek => integer()();
  TextColumn get windowStart => text()();
  TextColumn get windowEnd => text()();
  DateTimeColumn get suppressedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {keyId, dayOfWeek, windowStart};
}

/// v1 table. Rows are migrated into events(status=planned) at upgrade;
/// kept so old backups still restore.
class FutureEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entryDate => text()();
  IntColumn get keyId => integer().nullable().references(Keys, #id)();
  TextColumn get title => text()();
  TextColumn get timeHint => text().nullable()();
  TextColumn get source => text()();
  TextColumn get metadata => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Plans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get planDate => text().unique()();
  TextColumn get draft => text()();
  TextColumn get finalPlan => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Settings extends Table {
  TextColumn get k => text()();
  TextColumn get v => text()();
  @override
  Set<Column> get primaryKey => {k};
}
