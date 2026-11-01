// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $KeysTable extends Keys with TableInfo<$KeysTable, Key> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _vectorMeta = const VerificationMeta('vector');
  @override
  late final GeneratedColumn<Uint8List> vector = GeneratedColumn<Uint8List>(
      'vector', aliasedName, true,
      type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _exampleCountMeta =
      const VerificationMeta('exampleCount');
  @override
  late final GeneratedColumn<int> exampleCount = GeneratedColumn<int>(
      'example_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _usualMinuteOverrideMeta =
      const VerificationMeta('usualMinuteOverride');
  @override
  late final GeneratedColumn<int> usualMinuteOverride = GeneratedColumn<int>(
      'usual_minute_override', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notesAffinityMeta =
      const VerificationMeta('notesAffinity');
  @override
  late final GeneratedColumn<bool> notesAffinity = GeneratedColumn<bool>(
      'notes_affinity', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notes_affinity" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notesAddedMeta =
      const VerificationMeta('notesAdded');
  @override
  late final GeneratedColumn<int> notesAdded = GeneratedColumn<int>(
      'notes_added', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _notesIgnoredMeta =
      const VerificationMeta('notesIgnored');
  @override
  late final GeneratedColumn<int> notesIgnored = GeneratedColumn<int>(
      'notes_ignored', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        createdAt,
        isArchived,
        vector,
        exampleCount,
        usualMinuteOverride,
        notesAffinity,
        notesAdded,
        notesIgnored
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'keys';
  @override
  VerificationContext validateIntegrity(Insertable<Key> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('vector')) {
      context.handle(_vectorMeta,
          vector.isAcceptableOrUnknown(data['vector']!, _vectorMeta));
    }
    if (data.containsKey('example_count')) {
      context.handle(
          _exampleCountMeta,
          exampleCount.isAcceptableOrUnknown(
              data['example_count']!, _exampleCountMeta));
    }
    if (data.containsKey('usual_minute_override')) {
      context.handle(
          _usualMinuteOverrideMeta,
          usualMinuteOverride.isAcceptableOrUnknown(
              data['usual_minute_override']!, _usualMinuteOverrideMeta));
    }
    if (data.containsKey('notes_affinity')) {
      context.handle(
          _notesAffinityMeta,
          notesAffinity.isAcceptableOrUnknown(
              data['notes_affinity']!, _notesAffinityMeta));
    }
    if (data.containsKey('notes_added')) {
      context.handle(
          _notesAddedMeta,
          notesAdded.isAcceptableOrUnknown(
              data['notes_added']!, _notesAddedMeta));
    }
    if (data.containsKey('notes_ignored')) {
      context.handle(
          _notesIgnoredMeta,
          notesIgnored.isAcceptableOrUnknown(
              data['notes_ignored']!, _notesIgnoredMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Key map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Key(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      vector: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}vector']),
      exampleCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}example_count'])!,
      usualMinuteOverride: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}usual_minute_override']),
      notesAffinity: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}notes_affinity'])!,
      notesAdded: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notes_added'])!,
      notesIgnored: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notes_ignored'])!,
    );
  }

  @override
  $KeysTable createAlias(String alias) {
    return $KeysTable(attachedDatabase, alias);
  }
}

class Key extends DataClass implements Insertable<Key> {
  final int id;
  final String name;
  final DateTime createdAt;
  final bool isArchived;

  /// Cached centroid, float32 LE. Fallback only; the matcher is kNN.
  final Uint8List? vector;
  final int exampleCount;

  /// v2. User said "actually gym is at 07:00". Minute-of-day, or null =
  /// learn from history.
  final int? usualMinuteOverride;

  /// v2. Whether entries under this key tend to want a note. Seeded for
  /// meeting/doctor/call/idea; learned from notesAdded vs notesIgnored.
  final bool notesAffinity;
  final int notesAdded;
  final int notesIgnored;
  const Key(
      {required this.id,
      required this.name,
      required this.createdAt,
      required this.isArchived,
      this.vector,
      required this.exampleCount,
      this.usualMinuteOverride,
      required this.notesAffinity,
      required this.notesAdded,
      required this.notesIgnored});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || vector != null) {
      map['vector'] = Variable<Uint8List>(vector);
    }
    map['example_count'] = Variable<int>(exampleCount);
    if (!nullToAbsent || usualMinuteOverride != null) {
      map['usual_minute_override'] = Variable<int>(usualMinuteOverride);
    }
    map['notes_affinity'] = Variable<bool>(notesAffinity);
    map['notes_added'] = Variable<int>(notesAdded);
    map['notes_ignored'] = Variable<int>(notesIgnored);
    return map;
  }

  KeysCompanion toCompanion(bool nullToAbsent) {
    return KeysCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      isArchived: Value(isArchived),
      vector:
          vector == null && nullToAbsent ? const Value.absent() : Value(vector),
      exampleCount: Value(exampleCount),
      usualMinuteOverride: usualMinuteOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(usualMinuteOverride),
      notesAffinity: Value(notesAffinity),
      notesAdded: Value(notesAdded),
      notesIgnored: Value(notesIgnored),
    );
  }

  factory Key.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Key(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      vector: serializer.fromJson<Uint8List?>(json['vector']),
      exampleCount: serializer.fromJson<int>(json['exampleCount']),
      usualMinuteOverride:
          serializer.fromJson<int?>(json['usualMinuteOverride']),
      notesAffinity: serializer.fromJson<bool>(json['notesAffinity']),
      notesAdded: serializer.fromJson<int>(json['notesAdded']),
      notesIgnored: serializer.fromJson<int>(json['notesIgnored']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isArchived': serializer.toJson<bool>(isArchived),
      'vector': serializer.toJson<Uint8List?>(vector),
      'exampleCount': serializer.toJson<int>(exampleCount),
      'usualMinuteOverride': serializer.toJson<int?>(usualMinuteOverride),
      'notesAffinity': serializer.toJson<bool>(notesAffinity),
      'notesAdded': serializer.toJson<int>(notesAdded),
      'notesIgnored': serializer.toJson<int>(notesIgnored),
    };
  }

  Key copyWith(
          {int? id,
          String? name,
          DateTime? createdAt,
          bool? isArchived,
          Value<Uint8List?> vector = const Value.absent(),
          int? exampleCount,
          Value<int?> usualMinuteOverride = const Value.absent(),
          bool? notesAffinity,
          int? notesAdded,
          int? notesIgnored}) =>
      Key(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        isArchived: isArchived ?? this.isArchived,
        vector: vector.present ? vector.value : this.vector,
        exampleCount: exampleCount ?? this.exampleCount,
        usualMinuteOverride: usualMinuteOverride.present
            ? usualMinuteOverride.value
            : this.usualMinuteOverride,
        notesAffinity: notesAffinity ?? this.notesAffinity,
        notesAdded: notesAdded ?? this.notesAdded,
        notesIgnored: notesIgnored ?? this.notesIgnored,
      );
  Key copyWithCompanion(KeysCompanion data) {
    return Key(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      vector: data.vector.present ? data.vector.value : this.vector,
      exampleCount: data.exampleCount.present
          ? data.exampleCount.value
          : this.exampleCount,
      usualMinuteOverride: data.usualMinuteOverride.present
          ? data.usualMinuteOverride.value
          : this.usualMinuteOverride,
      notesAffinity: data.notesAffinity.present
          ? data.notesAffinity.value
          : this.notesAffinity,
      notesAdded:
          data.notesAdded.present ? data.notesAdded.value : this.notesAdded,
      notesIgnored: data.notesIgnored.present
          ? data.notesIgnored.value
          : this.notesIgnored,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Key(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('vector: $vector, ')
          ..write('exampleCount: $exampleCount, ')
          ..write('usualMinuteOverride: $usualMinuteOverride, ')
          ..write('notesAffinity: $notesAffinity, ')
          ..write('notesAdded: $notesAdded, ')
          ..write('notesIgnored: $notesIgnored')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      createdAt,
      isArchived,
      $driftBlobEquality.hash(vector),
      exampleCount,
      usualMinuteOverride,
      notesAffinity,
      notesAdded,
      notesIgnored);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Key &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.isArchived == this.isArchived &&
          $driftBlobEquality.equals(other.vector, this.vector) &&
          other.exampleCount == this.exampleCount &&
          other.usualMinuteOverride == this.usualMinuteOverride &&
          other.notesAffinity == this.notesAffinity &&
          other.notesAdded == this.notesAdded &&
          other.notesIgnored == this.notesIgnored);
}

class KeysCompanion extends UpdateCompanion<Key> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<bool> isArchived;
  final Value<Uint8List?> vector;
  final Value<int> exampleCount;
  final Value<int?> usualMinuteOverride;
  final Value<bool> notesAffinity;
  final Value<int> notesAdded;
  final Value<int> notesIgnored;
  const KeysCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.vector = const Value.absent(),
    this.exampleCount = const Value.absent(),
    this.usualMinuteOverride = const Value.absent(),
    this.notesAffinity = const Value.absent(),
    this.notesAdded = const Value.absent(),
    this.notesIgnored = const Value.absent(),
  });
  KeysCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.vector = const Value.absent(),
    this.exampleCount = const Value.absent(),
    this.usualMinuteOverride = const Value.absent(),
    this.notesAffinity = const Value.absent(),
    this.notesAdded = const Value.absent(),
    this.notesIgnored = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Key> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<bool>? isArchived,
    Expression<Uint8List>? vector,
    Expression<int>? exampleCount,
    Expression<int>? usualMinuteOverride,
    Expression<bool>? notesAffinity,
    Expression<int>? notesAdded,
    Expression<int>? notesIgnored,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (isArchived != null) 'is_archived': isArchived,
      if (vector != null) 'vector': vector,
      if (exampleCount != null) 'example_count': exampleCount,
      if (usualMinuteOverride != null)
        'usual_minute_override': usualMinuteOverride,
      if (notesAffinity != null) 'notes_affinity': notesAffinity,
      if (notesAdded != null) 'notes_added': notesAdded,
      if (notesIgnored != null) 'notes_ignored': notesIgnored,
    });
  }

  KeysCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<DateTime>? createdAt,
      Value<bool>? isArchived,
      Value<Uint8List?>? vector,
      Value<int>? exampleCount,
      Value<int?>? usualMinuteOverride,
      Value<bool>? notesAffinity,
      Value<int>? notesAdded,
      Value<int>? notesIgnored}) {
    return KeysCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      vector: vector ?? this.vector,
      exampleCount: exampleCount ?? this.exampleCount,
      usualMinuteOverride: usualMinuteOverride ?? this.usualMinuteOverride,
      notesAffinity: notesAffinity ?? this.notesAffinity,
      notesAdded: notesAdded ?? this.notesAdded,
      notesIgnored: notesIgnored ?? this.notesIgnored,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (vector.present) {
      map['vector'] = Variable<Uint8List>(vector.value);
    }
    if (exampleCount.present) {
      map['example_count'] = Variable<int>(exampleCount.value);
    }
    if (usualMinuteOverride.present) {
      map['usual_minute_override'] = Variable<int>(usualMinuteOverride.value);
    }
    if (notesAffinity.present) {
      map['notes_affinity'] = Variable<bool>(notesAffinity.value);
    }
    if (notesAdded.present) {
      map['notes_added'] = Variable<int>(notesAdded.value);
    }
    if (notesIgnored.present) {
      map['notes_ignored'] = Variable<int>(notesIgnored.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeysCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('vector: $vector, ')
          ..write('exampleCount: $exampleCount, ')
          ..write('usualMinuteOverride: $usualMinuteOverride, ')
          ..write('notesAffinity: $notesAffinity, ')
          ..write('notesAdded: $notesAdded, ')
          ..write('notesIgnored: $notesIgnored')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<int> keyId = GeneratedColumn<int>(
      'key_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES keys (id)'));
  static const VerificationMeta _tsUtcMeta = const VerificationMeta('tsUtc');
  @override
  late final GeneratedColumn<DateTime> tsUtc = GeneratedColumn<DateTime>(
      'ts_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _tzMeta = const VerificationMeta('tz');
  @override
  late final GeneratedColumn<String> tz = GeneratedColumn<String>(
      'tz', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayDateMeta =
      const VerificationMeta('dayDate');
  @override
  late final GeneratedColumn<String> dayDate = GeneratedColumn<String>(
      'day_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rawTextMeta =
      const VerificationMeta('rawText');
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
      'raw_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modalityMeta =
      const VerificationMeta('modality');
  @override
  late final GeneratedColumn<String> modality = GeneratedColumn<String>(
      'modality', aliasedName, false,
      check: () =>
          modality.isIn(const ['text', 'voice', 'photo', 'widget', 'list']),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thumbPathMeta =
      const VerificationMeta('thumbPath');
  @override
  late final GeneratedColumn<String> thumbPath = GeneratedColumn<String>(
      'thumb_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _keySourceMeta =
      const VerificationMeta('keySource');
  @override
  late final GeneratedColumn<String> keySource = GeneratedColumn<String>(
      'key_source', aliasedName, false,
      check: () => keySource
          .isIn(const ['auto', 'picked', 'new', 'corrected', 'unfiled']),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _matchScoreMeta =
      const VerificationMeta('matchScore');
  @override
  late final GeneratedColumn<double> matchScore = GeneratedColumn<double>(
      'match_score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _captureMsMeta =
      const VerificationMeta('captureMs');
  @override
  late final GeneratedColumn<int> captureMs = GeneratedColumn<int>(
      'capture_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      check: () => status.isIn(const ['done', 'planned', 'pending', 'skipped']),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('done'));
  static const VerificationMeta _durationMinMeta =
      const VerificationMeta('durationMin');
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
      'duration_min', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _listItemIdMeta =
      const VerificationMeta('listItemId');
  @override
  late final GeneratedColumn<int> listItemId = GeneratedColumn<int>(
      'list_item_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _editedAtMeta =
      const VerificationMeta('editedAt');
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
      'edited_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        keyId,
        tsUtc,
        tz,
        dayDate,
        rawText,
        modality,
        photoPath,
        thumbPath,
        metadata,
        keySource,
        matchScore,
        captureMs,
        status,
        durationMin,
        quantity,
        unit,
        note,
        listItemId,
        editedAt,
        deletedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(Insertable<Event> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key_id')) {
      context.handle(
          _keyIdMeta, keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta));
    }
    if (data.containsKey('ts_utc')) {
      context.handle(
          _tsUtcMeta, tsUtc.isAcceptableOrUnknown(data['ts_utc']!, _tsUtcMeta));
    } else if (isInserting) {
      context.missing(_tsUtcMeta);
    }
    if (data.containsKey('tz')) {
      context.handle(_tzMeta, tz.isAcceptableOrUnknown(data['tz']!, _tzMeta));
    } else if (isInserting) {
      context.missing(_tzMeta);
    }
    if (data.containsKey('day_date')) {
      context.handle(_dayDateMeta,
          dayDate.isAcceptableOrUnknown(data['day_date']!, _dayDateMeta));
    } else if (isInserting) {
      context.missing(_dayDateMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(_rawTextMeta,
          rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta));
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('modality')) {
      context.handle(_modalityMeta,
          modality.isAcceptableOrUnknown(data['modality']!, _modalityMeta));
    } else if (isInserting) {
      context.missing(_modalityMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    }
    if (data.containsKey('thumb_path')) {
      context.handle(_thumbPathMeta,
          thumbPath.isAcceptableOrUnknown(data['thumb_path']!, _thumbPathMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('key_source')) {
      context.handle(_keySourceMeta,
          keySource.isAcceptableOrUnknown(data['key_source']!, _keySourceMeta));
    } else if (isInserting) {
      context.missing(_keySourceMeta);
    }
    if (data.containsKey('match_score')) {
      context.handle(
          _matchScoreMeta,
          matchScore.isAcceptableOrUnknown(
              data['match_score']!, _matchScoreMeta));
    }
    if (data.containsKey('capture_ms')) {
      context.handle(_captureMsMeta,
          captureMs.isAcceptableOrUnknown(data['capture_ms']!, _captureMsMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('duration_min')) {
      context.handle(
          _durationMinMeta,
          durationMin.isAcceptableOrUnknown(
              data['duration_min']!, _durationMinMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('list_item_id')) {
      context.handle(
          _listItemIdMeta,
          listItemId.isAcceptableOrUnknown(
              data['list_item_id']!, _listItemIdMeta));
    }
    if (data.containsKey('edited_at')) {
      context.handle(_editedAtMeta,
          editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      keyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}key_id']),
      tsUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ts_utc'])!,
      tz: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tz'])!,
      dayDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_date'])!,
      rawText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_text'])!,
      modality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}modality'])!,
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path']),
      thumbPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumb_path']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
      keySource: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key_source'])!,
      matchScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}match_score']),
      captureMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}capture_ms']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      durationMin: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_min']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      listItemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}list_item_id']),
      editedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}edited_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final int id;
  final int? keyId;

  /// UTC + IANA zone at capture. Local is derived. For planned events this
  /// is the intended time; on completion it is rewritten to the actual.
  final DateTime tsUtc;
  final String tz;

  /// Sleep-to-sleep day, yyyy-MM-dd. Stamped at write, rewritten only when
  /// a planned event completes (its real time may differ).
  final String dayDate;
  final String rawText;
  final String modality;
  final String? photoPath;
  final String? thumbPath;

  /// JSON bag for things that do not deserve a column yet: {calories, place,
  /// window, photo_labels, ocr, ai_pending}.
  final String? metadata;
  final String keySource;
  final double? matchScore;
  final int? captureMs;
  final String status;

  /// Parsed from the line: "gym 45 min" -> durationMin 45;
  /// "ran 5 km" -> quantity 5, unit km. Both may be present.
  final int? durationMin;
  final double? quantity;
  final String? unit;

  /// Long-form text under the line. Hidden unless present.
  final String? note;

  /// Set when this event was created by ticking a list item.
  final int? listItemId;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  const Event(
      {required this.id,
      this.keyId,
      required this.tsUtc,
      required this.tz,
      required this.dayDate,
      required this.rawText,
      required this.modality,
      this.photoPath,
      this.thumbPath,
      this.metadata,
      required this.keySource,
      this.matchScore,
      this.captureMs,
      required this.status,
      this.durationMin,
      this.quantity,
      this.unit,
      this.note,
      this.listItemId,
      this.editedAt,
      this.deletedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || keyId != null) {
      map['key_id'] = Variable<int>(keyId);
    }
    map['ts_utc'] = Variable<DateTime>(tsUtc);
    map['tz'] = Variable<String>(tz);
    map['day_date'] = Variable<String>(dayDate);
    map['raw_text'] = Variable<String>(rawText);
    map['modality'] = Variable<String>(modality);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || thumbPath != null) {
      map['thumb_path'] = Variable<String>(thumbPath);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['key_source'] = Variable<String>(keySource);
    if (!nullToAbsent || matchScore != null) {
      map['match_score'] = Variable<double>(matchScore);
    }
    if (!nullToAbsent || captureMs != null) {
      map['capture_ms'] = Variable<int>(captureMs);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || durationMin != null) {
      map['duration_min'] = Variable<int>(durationMin);
    }
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || listItemId != null) {
      map['list_item_id'] = Variable<int>(listItemId);
    }
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<DateTime>(editedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      keyId:
          keyId == null && nullToAbsent ? const Value.absent() : Value(keyId),
      tsUtc: Value(tsUtc),
      tz: Value(tz),
      dayDate: Value(dayDate),
      rawText: Value(rawText),
      modality: Value(modality),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      thumbPath: thumbPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbPath),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      keySource: Value(keySource),
      matchScore: matchScore == null && nullToAbsent
          ? const Value.absent()
          : Value(matchScore),
      captureMs: captureMs == null && nullToAbsent
          ? const Value.absent()
          : Value(captureMs),
      status: Value(status),
      durationMin: durationMin == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMin),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      listItemId: listItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(listItemId),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Event.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<int>(json['id']),
      keyId: serializer.fromJson<int?>(json['keyId']),
      tsUtc: serializer.fromJson<DateTime>(json['tsUtc']),
      tz: serializer.fromJson<String>(json['tz']),
      dayDate: serializer.fromJson<String>(json['dayDate']),
      rawText: serializer.fromJson<String>(json['rawText']),
      modality: serializer.fromJson<String>(json['modality']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      thumbPath: serializer.fromJson<String?>(json['thumbPath']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      keySource: serializer.fromJson<String>(json['keySource']),
      matchScore: serializer.fromJson<double?>(json['matchScore']),
      captureMs: serializer.fromJson<int?>(json['captureMs']),
      status: serializer.fromJson<String>(json['status']),
      durationMin: serializer.fromJson<int?>(json['durationMin']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      note: serializer.fromJson<String?>(json['note']),
      listItemId: serializer.fromJson<int?>(json['listItemId']),
      editedAt: serializer.fromJson<DateTime?>(json['editedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'keyId': serializer.toJson<int?>(keyId),
      'tsUtc': serializer.toJson<DateTime>(tsUtc),
      'tz': serializer.toJson<String>(tz),
      'dayDate': serializer.toJson<String>(dayDate),
      'rawText': serializer.toJson<String>(rawText),
      'modality': serializer.toJson<String>(modality),
      'photoPath': serializer.toJson<String?>(photoPath),
      'thumbPath': serializer.toJson<String?>(thumbPath),
      'metadata': serializer.toJson<String?>(metadata),
      'keySource': serializer.toJson<String>(keySource),
      'matchScore': serializer.toJson<double?>(matchScore),
      'captureMs': serializer.toJson<int?>(captureMs),
      'status': serializer.toJson<String>(status),
      'durationMin': serializer.toJson<int?>(durationMin),
      'quantity': serializer.toJson<double?>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'note': serializer.toJson<String?>(note),
      'listItemId': serializer.toJson<int?>(listItemId),
      'editedAt': serializer.toJson<DateTime?>(editedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Event copyWith(
          {int? id,
          Value<int?> keyId = const Value.absent(),
          DateTime? tsUtc,
          String? tz,
          String? dayDate,
          String? rawText,
          String? modality,
          Value<String?> photoPath = const Value.absent(),
          Value<String?> thumbPath = const Value.absent(),
          Value<String?> metadata = const Value.absent(),
          String? keySource,
          Value<double?> matchScore = const Value.absent(),
          Value<int?> captureMs = const Value.absent(),
          String? status,
          Value<int?> durationMin = const Value.absent(),
          Value<double?> quantity = const Value.absent(),
          Value<String?> unit = const Value.absent(),
          Value<String?> note = const Value.absent(),
          Value<int?> listItemId = const Value.absent(),
          Value<DateTime?> editedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          DateTime? createdAt}) =>
      Event(
        id: id ?? this.id,
        keyId: keyId.present ? keyId.value : this.keyId,
        tsUtc: tsUtc ?? this.tsUtc,
        tz: tz ?? this.tz,
        dayDate: dayDate ?? this.dayDate,
        rawText: rawText ?? this.rawText,
        modality: modality ?? this.modality,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
        thumbPath: thumbPath.present ? thumbPath.value : this.thumbPath,
        metadata: metadata.present ? metadata.value : this.metadata,
        keySource: keySource ?? this.keySource,
        matchScore: matchScore.present ? matchScore.value : this.matchScore,
        captureMs: captureMs.present ? captureMs.value : this.captureMs,
        status: status ?? this.status,
        durationMin: durationMin.present ? durationMin.value : this.durationMin,
        quantity: quantity.present ? quantity.value : this.quantity,
        unit: unit.present ? unit.value : this.unit,
        note: note.present ? note.value : this.note,
        listItemId: listItemId.present ? listItemId.value : this.listItemId,
        editedAt: editedAt.present ? editedAt.value : this.editedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      tsUtc: data.tsUtc.present ? data.tsUtc.value : this.tsUtc,
      tz: data.tz.present ? data.tz.value : this.tz,
      dayDate: data.dayDate.present ? data.dayDate.value : this.dayDate,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      modality: data.modality.present ? data.modality.value : this.modality,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      thumbPath: data.thumbPath.present ? data.thumbPath.value : this.thumbPath,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      keySource: data.keySource.present ? data.keySource.value : this.keySource,
      matchScore:
          data.matchScore.present ? data.matchScore.value : this.matchScore,
      captureMs: data.captureMs.present ? data.captureMs.value : this.captureMs,
      status: data.status.present ? data.status.value : this.status,
      durationMin:
          data.durationMin.present ? data.durationMin.value : this.durationMin,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      note: data.note.present ? data.note.value : this.note,
      listItemId:
          data.listItemId.present ? data.listItemId.value : this.listItemId,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('keyId: $keyId, ')
          ..write('tsUtc: $tsUtc, ')
          ..write('tz: $tz, ')
          ..write('dayDate: $dayDate, ')
          ..write('rawText: $rawText, ')
          ..write('modality: $modality, ')
          ..write('photoPath: $photoPath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('metadata: $metadata, ')
          ..write('keySource: $keySource, ')
          ..write('matchScore: $matchScore, ')
          ..write('captureMs: $captureMs, ')
          ..write('status: $status, ')
          ..write('durationMin: $durationMin, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('note: $note, ')
          ..write('listItemId: $listItemId, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        keyId,
        tsUtc,
        tz,
        dayDate,
        rawText,
        modality,
        photoPath,
        thumbPath,
        metadata,
        keySource,
        matchScore,
        captureMs,
        status,
        durationMin,
        quantity,
        unit,
        note,
        listItemId,
        editedAt,
        deletedAt,
        createdAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.keyId == this.keyId &&
          other.tsUtc == this.tsUtc &&
          other.tz == this.tz &&
          other.dayDate == this.dayDate &&
          other.rawText == this.rawText &&
          other.modality == this.modality &&
          other.photoPath == this.photoPath &&
          other.thumbPath == this.thumbPath &&
          other.metadata == this.metadata &&
          other.keySource == this.keySource &&
          other.matchScore == this.matchScore &&
          other.captureMs == this.captureMs &&
          other.status == this.status &&
          other.durationMin == this.durationMin &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.note == this.note &&
          other.listItemId == this.listItemId &&
          other.editedAt == this.editedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<int> id;
  final Value<int?> keyId;
  final Value<DateTime> tsUtc;
  final Value<String> tz;
  final Value<String> dayDate;
  final Value<String> rawText;
  final Value<String> modality;
  final Value<String?> photoPath;
  final Value<String?> thumbPath;
  final Value<String?> metadata;
  final Value<String> keySource;
  final Value<double?> matchScore;
  final Value<int?> captureMs;
  final Value<String> status;
  final Value<int?> durationMin;
  final Value<double?> quantity;
  final Value<String?> unit;
  final Value<String?> note;
  final Value<int?> listItemId;
  final Value<DateTime?> editedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.keyId = const Value.absent(),
    this.tsUtc = const Value.absent(),
    this.tz = const Value.absent(),
    this.dayDate = const Value.absent(),
    this.rawText = const Value.absent(),
    this.modality = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.metadata = const Value.absent(),
    this.keySource = const Value.absent(),
    this.matchScore = const Value.absent(),
    this.captureMs = const Value.absent(),
    this.status = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.note = const Value.absent(),
    this.listItemId = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    this.keyId = const Value.absent(),
    required DateTime tsUtc,
    required String tz,
    required String dayDate,
    required String rawText,
    required String modality,
    this.photoPath = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.metadata = const Value.absent(),
    required String keySource,
    this.matchScore = const Value.absent(),
    this.captureMs = const Value.absent(),
    this.status = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.note = const Value.absent(),
    this.listItemId = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : tsUtc = Value(tsUtc),
        tz = Value(tz),
        dayDate = Value(dayDate),
        rawText = Value(rawText),
        modality = Value(modality),
        keySource = Value(keySource);
  static Insertable<Event> custom({
    Expression<int>? id,
    Expression<int>? keyId,
    Expression<DateTime>? tsUtc,
    Expression<String>? tz,
    Expression<String>? dayDate,
    Expression<String>? rawText,
    Expression<String>? modality,
    Expression<String>? photoPath,
    Expression<String>? thumbPath,
    Expression<String>? metadata,
    Expression<String>? keySource,
    Expression<double>? matchScore,
    Expression<int>? captureMs,
    Expression<String>? status,
    Expression<int>? durationMin,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<String>? note,
    Expression<int>? listItemId,
    Expression<DateTime>? editedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (keyId != null) 'key_id': keyId,
      if (tsUtc != null) 'ts_utc': tsUtc,
      if (tz != null) 'tz': tz,
      if (dayDate != null) 'day_date': dayDate,
      if (rawText != null) 'raw_text': rawText,
      if (modality != null) 'modality': modality,
      if (photoPath != null) 'photo_path': photoPath,
      if (thumbPath != null) 'thumb_path': thumbPath,
      if (metadata != null) 'metadata': metadata,
      if (keySource != null) 'key_source': keySource,
      if (matchScore != null) 'match_score': matchScore,
      if (captureMs != null) 'capture_ms': captureMs,
      if (status != null) 'status': status,
      if (durationMin != null) 'duration_min': durationMin,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (note != null) 'note': note,
      if (listItemId != null) 'list_item_id': listItemId,
      if (editedAt != null) 'edited_at': editedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EventsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? keyId,
      Value<DateTime>? tsUtc,
      Value<String>? tz,
      Value<String>? dayDate,
      Value<String>? rawText,
      Value<String>? modality,
      Value<String?>? photoPath,
      Value<String?>? thumbPath,
      Value<String?>? metadata,
      Value<String>? keySource,
      Value<double?>? matchScore,
      Value<int?>? captureMs,
      Value<String>? status,
      Value<int?>? durationMin,
      Value<double?>? quantity,
      Value<String?>? unit,
      Value<String?>? note,
      Value<int?>? listItemId,
      Value<DateTime?>? editedAt,
      Value<DateTime?>? deletedAt,
      Value<DateTime>? createdAt}) {
    return EventsCompanion(
      id: id ?? this.id,
      keyId: keyId ?? this.keyId,
      tsUtc: tsUtc ?? this.tsUtc,
      tz: tz ?? this.tz,
      dayDate: dayDate ?? this.dayDate,
      rawText: rawText ?? this.rawText,
      modality: modality ?? this.modality,
      photoPath: photoPath ?? this.photoPath,
      thumbPath: thumbPath ?? this.thumbPath,
      metadata: metadata ?? this.metadata,
      keySource: keySource ?? this.keySource,
      matchScore: matchScore ?? this.matchScore,
      captureMs: captureMs ?? this.captureMs,
      status: status ?? this.status,
      durationMin: durationMin ?? this.durationMin,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      listItemId: listItemId ?? this.listItemId,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (keyId.present) {
      map['key_id'] = Variable<int>(keyId.value);
    }
    if (tsUtc.present) {
      map['ts_utc'] = Variable<DateTime>(tsUtc.value);
    }
    if (tz.present) {
      map['tz'] = Variable<String>(tz.value);
    }
    if (dayDate.present) {
      map['day_date'] = Variable<String>(dayDate.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (modality.present) {
      map['modality'] = Variable<String>(modality.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (thumbPath.present) {
      map['thumb_path'] = Variable<String>(thumbPath.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (keySource.present) {
      map['key_source'] = Variable<String>(keySource.value);
    }
    if (matchScore.present) {
      map['match_score'] = Variable<double>(matchScore.value);
    }
    if (captureMs.present) {
      map['capture_ms'] = Variable<int>(captureMs.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (listItemId.present) {
      map['list_item_id'] = Variable<int>(listItemId.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('keyId: $keyId, ')
          ..write('tsUtc: $tsUtc, ')
          ..write('tz: $tz, ')
          ..write('dayDate: $dayDate, ')
          ..write('rawText: $rawText, ')
          ..write('modality: $modality, ')
          ..write('photoPath: $photoPath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('metadata: $metadata, ')
          ..write('keySource: $keySource, ')
          ..write('matchScore: $matchScore, ')
          ..write('captureMs: $captureMs, ')
          ..write('status: $status, ')
          ..write('durationMin: $durationMin, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('note: $note, ')
          ..write('listItemId: $listItemId, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ListItemsTable extends ListItems
    with TableInfo<$ListItemsTable, ListItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sectionMeta =
      const VerificationMeta('section');
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
      'section', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<int> keyId = GeneratedColumn<int>(
      'key_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES keys (id)'));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _doneEventIdMeta =
      const VerificationMeta('doneEventId');
  @override
  late final GeneratedColumn<int> doneEventId = GeneratedColumn<int>(
      'done_event_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _plannedEventIdMeta =
      const VerificationMeta('plannedEventId');
  @override
  late final GeneratedColumn<int> plannedEventId = GeneratedColumn<int>(
      'planned_event_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        section,
        keyId,
        sortOrder,
        doneEventId,
        plannedEventId,
        createdAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'list_items';
  @override
  VerificationContext validateIntegrity(Insertable<ListItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('section')) {
      context.handle(_sectionMeta,
          section.isAcceptableOrUnknown(data['section']!, _sectionMeta));
    }
    if (data.containsKey('key_id')) {
      context.handle(
          _keyIdMeta, keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('done_event_id')) {
      context.handle(
          _doneEventIdMeta,
          doneEventId.isAcceptableOrUnknown(
              data['done_event_id']!, _doneEventIdMeta));
    }
    if (data.containsKey('planned_event_id')) {
      context.handle(
          _plannedEventIdMeta,
          plannedEventId.isAcceptableOrUnknown(
              data['planned_event_id']!, _plannedEventIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      section: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section']),
      keyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}key_id']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      doneEventId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}done_event_id']),
      plannedEventId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}planned_event_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $ListItemsTable createAlias(String alias) {
    return $ListItemsTable(attachedDatabase, alias);
  }
}

class ListItem extends DataClass implements Insertable<ListItem> {
  final int id;
  final String title;
  final String? section;
  final int? keyId;
  final int sortOrder;
  final int? doneEventId;
  final int? plannedEventId;
  final DateTime createdAt;
  final DateTime? deletedAt;
  const ListItem(
      {required this.id,
      required this.title,
      this.section,
      this.keyId,
      required this.sortOrder,
      this.doneEventId,
      this.plannedEventId,
      required this.createdAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || section != null) {
      map['section'] = Variable<String>(section);
    }
    if (!nullToAbsent || keyId != null) {
      map['key_id'] = Variable<int>(keyId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || doneEventId != null) {
      map['done_event_id'] = Variable<int>(doneEventId);
    }
    if (!nullToAbsent || plannedEventId != null) {
      map['planned_event_id'] = Variable<int>(plannedEventId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ListItemsCompanion toCompanion(bool nullToAbsent) {
    return ListItemsCompanion(
      id: Value(id),
      title: Value(title),
      section: section == null && nullToAbsent
          ? const Value.absent()
          : Value(section),
      keyId:
          keyId == null && nullToAbsent ? const Value.absent() : Value(keyId),
      sortOrder: Value(sortOrder),
      doneEventId: doneEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(doneEventId),
      plannedEventId: plannedEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedEventId),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ListItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListItem(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      section: serializer.fromJson<String?>(json['section']),
      keyId: serializer.fromJson<int?>(json['keyId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      doneEventId: serializer.fromJson<int?>(json['doneEventId']),
      plannedEventId: serializer.fromJson<int?>(json['plannedEventId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'section': serializer.toJson<String?>(section),
      'keyId': serializer.toJson<int?>(keyId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'doneEventId': serializer.toJson<int?>(doneEventId),
      'plannedEventId': serializer.toJson<int?>(plannedEventId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ListItem copyWith(
          {int? id,
          String? title,
          Value<String?> section = const Value.absent(),
          Value<int?> keyId = const Value.absent(),
          int? sortOrder,
          Value<int?> doneEventId = const Value.absent(),
          Value<int?> plannedEventId = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      ListItem(
        id: id ?? this.id,
        title: title ?? this.title,
        section: section.present ? section.value : this.section,
        keyId: keyId.present ? keyId.value : this.keyId,
        sortOrder: sortOrder ?? this.sortOrder,
        doneEventId: doneEventId.present ? doneEventId.value : this.doneEventId,
        plannedEventId:
            plannedEventId.present ? plannedEventId.value : this.plannedEventId,
        createdAt: createdAt ?? this.createdAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  ListItem copyWithCompanion(ListItemsCompanion data) {
    return ListItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      section: data.section.present ? data.section.value : this.section,
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      doneEventId:
          data.doneEventId.present ? data.doneEventId.value : this.doneEventId,
      plannedEventId: data.plannedEventId.present
          ? data.plannedEventId.value
          : this.plannedEventId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('section: $section, ')
          ..write('keyId: $keyId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('doneEventId: $doneEventId, ')
          ..write('plannedEventId: $plannedEventId, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, section, keyId, sortOrder,
      doneEventId, plannedEventId, createdAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.section == this.section &&
          other.keyId == this.keyId &&
          other.sortOrder == this.sortOrder &&
          other.doneEventId == this.doneEventId &&
          other.plannedEventId == this.plannedEventId &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt);
}

class ListItemsCompanion extends UpdateCompanion<ListItem> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> section;
  final Value<int?> keyId;
  final Value<int> sortOrder;
  final Value<int?> doneEventId;
  final Value<int?> plannedEventId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  const ListItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.section = const Value.absent(),
    this.keyId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.doneEventId = const Value.absent(),
    this.plannedEventId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  ListItemsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.section = const Value.absent(),
    this.keyId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.doneEventId = const Value.absent(),
    this.plannedEventId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<ListItem> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? section,
    Expression<int>? keyId,
    Expression<int>? sortOrder,
    Expression<int>? doneEventId,
    Expression<int>? plannedEventId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (section != null) 'section': section,
      if (keyId != null) 'key_id': keyId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (doneEventId != null) 'done_event_id': doneEventId,
      if (plannedEventId != null) 'planned_event_id': plannedEventId,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  ListItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String?>? section,
      Value<int?>? keyId,
      Value<int>? sortOrder,
      Value<int?>? doneEventId,
      Value<int?>? plannedEventId,
      Value<DateTime>? createdAt,
      Value<DateTime?>? deletedAt}) {
    return ListItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      section: section ?? this.section,
      keyId: keyId ?? this.keyId,
      sortOrder: sortOrder ?? this.sortOrder,
      doneEventId: doneEventId ?? this.doneEventId,
      plannedEventId: plannedEventId ?? this.plannedEventId,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (keyId.present) {
      map['key_id'] = Variable<int>(keyId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (doneEventId.present) {
      map['done_event_id'] = Variable<int>(doneEventId.value);
    }
    if (plannedEventId.present) {
      map['planned_event_id'] = Variable<int>(plannedEventId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('section: $section, ')
          ..write('keyId: $keyId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('doneEventId: $doneEventId, ')
          ..write('plannedEventId: $plannedEventId, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $CorrectionsTable extends Corrections
    with TableInfo<$CorrectionsTable, Correction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CorrectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _rawTextMeta =
      const VerificationMeta('rawText');
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
      'raw_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
      'field', aliasedName, false,
      check: () =>
          field.isIn(const ['key', 'time', 'tense', 'quantity', 'duration']),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _predictedMeta =
      const VerificationMeta('predicted');
  @override
  late final GeneratedColumn<String> predicted = GeneratedColumn<String>(
      'predicted', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _correctedMeta =
      const VerificationMeta('corrected');
  @override
  late final GeneratedColumn<String> corrected = GeneratedColumn<String>(
      'corrected', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, rawText, field, predicted, corrected, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'corrections';
  @override
  VerificationContext validateIntegrity(Insertable<Correction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('raw_text')) {
      context.handle(_rawTextMeta,
          rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta));
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
          _fieldMeta, field.isAcceptableOrUnknown(data['field']!, _fieldMeta));
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('predicted')) {
      context.handle(_predictedMeta,
          predicted.isAcceptableOrUnknown(data['predicted']!, _predictedMeta));
    }
    if (data.containsKey('corrected')) {
      context.handle(_correctedMeta,
          corrected.isAcceptableOrUnknown(data['corrected']!, _correctedMeta));
    } else if (isInserting) {
      context.missing(_correctedMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Correction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Correction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      rawText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_text'])!,
      field: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field'])!,
      predicted: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}predicted']),
      corrected: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}corrected'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CorrectionsTable createAlias(String alias) {
    return $CorrectionsTable(attachedDatabase, alias);
  }
}

class Correction extends DataClass implements Insertable<Correction> {
  final int id;
  final String rawText;
  final String field;
  final String? predicted;
  final String corrected;
  final DateTime createdAt;
  const Correction(
      {required this.id,
      required this.rawText,
      required this.field,
      this.predicted,
      required this.corrected,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['raw_text'] = Variable<String>(rawText);
    map['field'] = Variable<String>(field);
    if (!nullToAbsent || predicted != null) {
      map['predicted'] = Variable<String>(predicted);
    }
    map['corrected'] = Variable<String>(corrected);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CorrectionsCompanion toCompanion(bool nullToAbsent) {
    return CorrectionsCompanion(
      id: Value(id),
      rawText: Value(rawText),
      field: Value(field),
      predicted: predicted == null && nullToAbsent
          ? const Value.absent()
          : Value(predicted),
      corrected: Value(corrected),
      createdAt: Value(createdAt),
    );
  }

  factory Correction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Correction(
      id: serializer.fromJson<int>(json['id']),
      rawText: serializer.fromJson<String>(json['rawText']),
      field: serializer.fromJson<String>(json['field']),
      predicted: serializer.fromJson<String?>(json['predicted']),
      corrected: serializer.fromJson<String>(json['corrected']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rawText': serializer.toJson<String>(rawText),
      'field': serializer.toJson<String>(field),
      'predicted': serializer.toJson<String?>(predicted),
      'corrected': serializer.toJson<String>(corrected),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Correction copyWith(
          {int? id,
          String? rawText,
          String? field,
          Value<String?> predicted = const Value.absent(),
          String? corrected,
          DateTime? createdAt}) =>
      Correction(
        id: id ?? this.id,
        rawText: rawText ?? this.rawText,
        field: field ?? this.field,
        predicted: predicted.present ? predicted.value : this.predicted,
        corrected: corrected ?? this.corrected,
        createdAt: createdAt ?? this.createdAt,
      );
  Correction copyWithCompanion(CorrectionsCompanion data) {
    return Correction(
      id: data.id.present ? data.id.value : this.id,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      field: data.field.present ? data.field.value : this.field,
      predicted: data.predicted.present ? data.predicted.value : this.predicted,
      corrected: data.corrected.present ? data.corrected.value : this.corrected,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Correction(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('field: $field, ')
          ..write('predicted: $predicted, ')
          ..write('corrected: $corrected, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, rawText, field, predicted, corrected, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Correction &&
          other.id == this.id &&
          other.rawText == this.rawText &&
          other.field == this.field &&
          other.predicted == this.predicted &&
          other.corrected == this.corrected &&
          other.createdAt == this.createdAt);
}

class CorrectionsCompanion extends UpdateCompanion<Correction> {
  final Value<int> id;
  final Value<String> rawText;
  final Value<String> field;
  final Value<String?> predicted;
  final Value<String> corrected;
  final Value<DateTime> createdAt;
  const CorrectionsCompanion({
    this.id = const Value.absent(),
    this.rawText = const Value.absent(),
    this.field = const Value.absent(),
    this.predicted = const Value.absent(),
    this.corrected = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CorrectionsCompanion.insert({
    this.id = const Value.absent(),
    required String rawText,
    required String field,
    this.predicted = const Value.absent(),
    required String corrected,
    this.createdAt = const Value.absent(),
  })  : rawText = Value(rawText),
        field = Value(field),
        corrected = Value(corrected);
  static Insertable<Correction> custom({
    Expression<int>? id,
    Expression<String>? rawText,
    Expression<String>? field,
    Expression<String>? predicted,
    Expression<String>? corrected,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawText != null) 'raw_text': rawText,
      if (field != null) 'field': field,
      if (predicted != null) 'predicted': predicted,
      if (corrected != null) 'corrected': corrected,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CorrectionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? rawText,
      Value<String>? field,
      Value<String?>? predicted,
      Value<String>? corrected,
      Value<DateTime>? createdAt}) {
    return CorrectionsCompanion(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      field: field ?? this.field,
      predicted: predicted ?? this.predicted,
      corrected: corrected ?? this.corrected,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (predicted.present) {
      map['predicted'] = Variable<String>(predicted.value);
    }
    if (corrected.present) {
      map['corrected'] = Variable<String>(corrected.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CorrectionsCompanion(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('field: $field, ')
          ..write('predicted: $predicted, ')
          ..write('corrected: $corrected, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $KeyExamplesTable extends KeyExamples
    with TableInfo<$KeyExamplesTable, KeyExample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyExamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<int> keyId = GeneratedColumn<int>(
      'key_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES keys (id)'));
  static const VerificationMeta _exampleTextMeta =
      const VerificationMeta('exampleText');
  @override
  late final GeneratedColumn<String> exampleText = GeneratedColumn<String>(
      'example_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vectorMeta = const VerificationMeta('vector');
  @override
  late final GeneratedColumn<Uint8List> vector = GeneratedColumn<Uint8List>(
      'vector', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      check: () => source.isIn(const ['confirmed', 'corrected', 'seed']),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, keyId, exampleText, vector, source, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_examples';
  @override
  VerificationContext validateIntegrity(Insertable<KeyExample> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key_id')) {
      context.handle(
          _keyIdMeta, keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta));
    } else if (isInserting) {
      context.missing(_keyIdMeta);
    }
    if (data.containsKey('example_text')) {
      context.handle(
          _exampleTextMeta,
          exampleText.isAcceptableOrUnknown(
              data['example_text']!, _exampleTextMeta));
    } else if (isInserting) {
      context.missing(_exampleTextMeta);
    }
    if (data.containsKey('vector')) {
      context.handle(_vectorMeta,
          vector.isAcceptableOrUnknown(data['vector']!, _vectorMeta));
    } else if (isInserting) {
      context.missing(_vectorMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KeyExample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyExample(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      keyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}key_id'])!,
      exampleText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example_text'])!,
      vector: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}vector'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $KeyExamplesTable createAlias(String alias) {
    return $KeyExamplesTable(attachedDatabase, alias);
  }
}

class KeyExample extends DataClass implements Insertable<KeyExample> {
  final int id;
  final int keyId;
  final String exampleText;
  final Uint8List vector;
  final String source;
  final DateTime createdAt;
  const KeyExample(
      {required this.id,
      required this.keyId,
      required this.exampleText,
      required this.vector,
      required this.source,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key_id'] = Variable<int>(keyId);
    map['example_text'] = Variable<String>(exampleText);
    map['vector'] = Variable<Uint8List>(vector);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  KeyExamplesCompanion toCompanion(bool nullToAbsent) {
    return KeyExamplesCompanion(
      id: Value(id),
      keyId: Value(keyId),
      exampleText: Value(exampleText),
      vector: Value(vector),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory KeyExample.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyExample(
      id: serializer.fromJson<int>(json['id']),
      keyId: serializer.fromJson<int>(json['keyId']),
      exampleText: serializer.fromJson<String>(json['exampleText']),
      vector: serializer.fromJson<Uint8List>(json['vector']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'keyId': serializer.toJson<int>(keyId),
      'exampleText': serializer.toJson<String>(exampleText),
      'vector': serializer.toJson<Uint8List>(vector),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  KeyExample copyWith(
          {int? id,
          int? keyId,
          String? exampleText,
          Uint8List? vector,
          String? source,
          DateTime? createdAt}) =>
      KeyExample(
        id: id ?? this.id,
        keyId: keyId ?? this.keyId,
        exampleText: exampleText ?? this.exampleText,
        vector: vector ?? this.vector,
        source: source ?? this.source,
        createdAt: createdAt ?? this.createdAt,
      );
  KeyExample copyWithCompanion(KeyExamplesCompanion data) {
    return KeyExample(
      id: data.id.present ? data.id.value : this.id,
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      exampleText:
          data.exampleText.present ? data.exampleText.value : this.exampleText,
      vector: data.vector.present ? data.vector.value : this.vector,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyExample(')
          ..write('id: $id, ')
          ..write('keyId: $keyId, ')
          ..write('exampleText: $exampleText, ')
          ..write('vector: $vector, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, keyId, exampleText,
      $driftBlobEquality.hash(vector), source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyExample &&
          other.id == this.id &&
          other.keyId == this.keyId &&
          other.exampleText == this.exampleText &&
          $driftBlobEquality.equals(other.vector, this.vector) &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class KeyExamplesCompanion extends UpdateCompanion<KeyExample> {
  final Value<int> id;
  final Value<int> keyId;
  final Value<String> exampleText;
  final Value<Uint8List> vector;
  final Value<String> source;
  final Value<DateTime> createdAt;
  const KeyExamplesCompanion({
    this.id = const Value.absent(),
    this.keyId = const Value.absent(),
    this.exampleText = const Value.absent(),
    this.vector = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  KeyExamplesCompanion.insert({
    this.id = const Value.absent(),
    required int keyId,
    required String exampleText,
    required Uint8List vector,
    required String source,
    this.createdAt = const Value.absent(),
  })  : keyId = Value(keyId),
        exampleText = Value(exampleText),
        vector = Value(vector),
        source = Value(source);
  static Insertable<KeyExample> custom({
    Expression<int>? id,
    Expression<int>? keyId,
    Expression<String>? exampleText,
    Expression<Uint8List>? vector,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (keyId != null) 'key_id': keyId,
      if (exampleText != null) 'example_text': exampleText,
      if (vector != null) 'vector': vector,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  KeyExamplesCompanion copyWith(
      {Value<int>? id,
      Value<int>? keyId,
      Value<String>? exampleText,
      Value<Uint8List>? vector,
      Value<String>? source,
      Value<DateTime>? createdAt}) {
    return KeyExamplesCompanion(
      id: id ?? this.id,
      keyId: keyId ?? this.keyId,
      exampleText: exampleText ?? this.exampleText,
      vector: vector ?? this.vector,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (keyId.present) {
      map['key_id'] = Variable<int>(keyId.value);
    }
    if (exampleText.present) {
      map['example_text'] = Variable<String>(exampleText.value);
    }
    if (vector.present) {
      map['vector'] = Variable<Uint8List>(vector.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyExamplesCompanion(')
          ..write('id: $id, ')
          ..write('keyId: $keyId, ')
          ..write('exampleText: $exampleText, ')
          ..write('vector: $vector, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DaySummariesTable extends DaySummaries
    with TableInfo<$DaySummariesTable, DaySummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DaySummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayDateMeta =
      const VerificationMeta('dayDate');
  @override
  late final GeneratedColumn<String> dayDate = GeneratedColumn<String>(
      'day_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _flagsMeta = const VerificationMeta('flags');
  @override
  late final GeneratedColumn<String> flags = GeneratedColumn<String>(
      'flags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _eventCountMeta =
      const VerificationMeta('eventCount');
  @override
  late final GeneratedColumn<int> eventCount = GeneratedColumn<int>(
      'event_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _closedAtMeta =
      const VerificationMeta('closedAt');
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
      'closed_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [dayDate, summary, flags, eventCount, closedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_summaries';
  @override
  VerificationContext validateIntegrity(Insertable<DaySummary> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day_date')) {
      context.handle(_dayDateMeta,
          dayDate.isAcceptableOrUnknown(data['day_date']!, _dayDateMeta));
    } else if (isInserting) {
      context.missing(_dayDateMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('flags')) {
      context.handle(
          _flagsMeta, flags.isAcceptableOrUnknown(data['flags']!, _flagsMeta));
    }
    if (data.containsKey('event_count')) {
      context.handle(
          _eventCountMeta,
          eventCount.isAcceptableOrUnknown(
              data['event_count']!, _eventCountMeta));
    } else if (isInserting) {
      context.missing(_eventCountMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(_closedAtMeta,
          closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dayDate};
  @override
  DaySummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DaySummary(
      dayDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_date'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])!,
      flags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}flags']),
      eventCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}event_count'])!,
      closedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}closed_at'])!,
    );
  }

  @override
  $DaySummariesTable createAlias(String alias) {
    return $DaySummariesTable(attachedDatabase, alias);
  }
}

class DaySummary extends DataClass implements Insertable<DaySummary> {
  final String dayDate;
  final String summary;
  final String? flags;
  final int eventCount;
  final DateTime closedAt;
  const DaySummary(
      {required this.dayDate,
      required this.summary,
      this.flags,
      required this.eventCount,
      required this.closedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day_date'] = Variable<String>(dayDate);
    map['summary'] = Variable<String>(summary);
    if (!nullToAbsent || flags != null) {
      map['flags'] = Variable<String>(flags);
    }
    map['event_count'] = Variable<int>(eventCount);
    map['closed_at'] = Variable<DateTime>(closedAt);
    return map;
  }

  DaySummariesCompanion toCompanion(bool nullToAbsent) {
    return DaySummariesCompanion(
      dayDate: Value(dayDate),
      summary: Value(summary),
      flags:
          flags == null && nullToAbsent ? const Value.absent() : Value(flags),
      eventCount: Value(eventCount),
      closedAt: Value(closedAt),
    );
  }

  factory DaySummary.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DaySummary(
      dayDate: serializer.fromJson<String>(json['dayDate']),
      summary: serializer.fromJson<String>(json['summary']),
      flags: serializer.fromJson<String?>(json['flags']),
      eventCount: serializer.fromJson<int>(json['eventCount']),
      closedAt: serializer.fromJson<DateTime>(json['closedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dayDate': serializer.toJson<String>(dayDate),
      'summary': serializer.toJson<String>(summary),
      'flags': serializer.toJson<String?>(flags),
      'eventCount': serializer.toJson<int>(eventCount),
      'closedAt': serializer.toJson<DateTime>(closedAt),
    };
  }

  DaySummary copyWith(
          {String? dayDate,
          String? summary,
          Value<String?> flags = const Value.absent(),
          int? eventCount,
          DateTime? closedAt}) =>
      DaySummary(
        dayDate: dayDate ?? this.dayDate,
        summary: summary ?? this.summary,
        flags: flags.present ? flags.value : this.flags,
        eventCount: eventCount ?? this.eventCount,
        closedAt: closedAt ?? this.closedAt,
      );
  DaySummary copyWithCompanion(DaySummariesCompanion data) {
    return DaySummary(
      dayDate: data.dayDate.present ? data.dayDate.value : this.dayDate,
      summary: data.summary.present ? data.summary.value : this.summary,
      flags: data.flags.present ? data.flags.value : this.flags,
      eventCount:
          data.eventCount.present ? data.eventCount.value : this.eventCount,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DaySummary(')
          ..write('dayDate: $dayDate, ')
          ..write('summary: $summary, ')
          ..write('flags: $flags, ')
          ..write('eventCount: $eventCount, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(dayDate, summary, flags, eventCount, closedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DaySummary &&
          other.dayDate == this.dayDate &&
          other.summary == this.summary &&
          other.flags == this.flags &&
          other.eventCount == this.eventCount &&
          other.closedAt == this.closedAt);
}

class DaySummariesCompanion extends UpdateCompanion<DaySummary> {
  final Value<String> dayDate;
  final Value<String> summary;
  final Value<String?> flags;
  final Value<int> eventCount;
  final Value<DateTime> closedAt;
  final Value<int> rowid;
  const DaySummariesCompanion({
    this.dayDate = const Value.absent(),
    this.summary = const Value.absent(),
    this.flags = const Value.absent(),
    this.eventCount = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DaySummariesCompanion.insert({
    required String dayDate,
    required String summary,
    this.flags = const Value.absent(),
    required int eventCount,
    this.closedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : dayDate = Value(dayDate),
        summary = Value(summary),
        eventCount = Value(eventCount);
  static Insertable<DaySummary> custom({
    Expression<String>? dayDate,
    Expression<String>? summary,
    Expression<String>? flags,
    Expression<int>? eventCount,
    Expression<DateTime>? closedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dayDate != null) 'day_date': dayDate,
      if (summary != null) 'summary': summary,
      if (flags != null) 'flags': flags,
      if (eventCount != null) 'event_count': eventCount,
      if (closedAt != null) 'closed_at': closedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DaySummariesCompanion copyWith(
      {Value<String>? dayDate,
      Value<String>? summary,
      Value<String?>? flags,
      Value<int>? eventCount,
      Value<DateTime>? closedAt,
      Value<int>? rowid}) {
    return DaySummariesCompanion(
      dayDate: dayDate ?? this.dayDate,
      summary: summary ?? this.summary,
      flags: flags ?? this.flags,
      eventCount: eventCount ?? this.eventCount,
      closedAt: closedAt ?? this.closedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dayDate.present) {
      map['day_date'] = Variable<String>(dayDate.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (flags.present) {
      map['flags'] = Variable<String>(flags.value);
    }
    if (eventCount.present) {
      map['event_count'] = Variable<int>(eventCount.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DaySummariesCompanion(')
          ..write('dayDate: $dayDate, ')
          ..write('summary: $summary, ')
          ..write('flags: $flags, ')
          ..write('eventCount: $eventCount, ')
          ..write('closedAt: $closedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyAnalysesTable extends KeyAnalyses
    with TableInfo<$KeyAnalysesTable, KeyAnalyse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyAnalysesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<int> keyId = GeneratedColumn<int>(
      'key_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES keys (id)'));
  static const VerificationMeta _analysisMeta =
      const VerificationMeta('analysis');
  @override
  late final GeneratedColumn<String> analysis = GeneratedColumn<String>(
      'analysis', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statsMeta = const VerificationMeta('stats');
  @override
  late final GeneratedColumn<String> stats = GeneratedColumn<String>(
      'stats', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [keyId, analysis, stats, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_analyses';
  @override
  VerificationContext validateIntegrity(Insertable<KeyAnalyse> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key_id')) {
      context.handle(
          _keyIdMeta, keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta));
    }
    if (data.containsKey('analysis')) {
      context.handle(_analysisMeta,
          analysis.isAcceptableOrUnknown(data['analysis']!, _analysisMeta));
    } else if (isInserting) {
      context.missing(_analysisMeta);
    }
    if (data.containsKey('stats')) {
      context.handle(
          _statsMeta, stats.isAcceptableOrUnknown(data['stats']!, _statsMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {keyId};
  @override
  KeyAnalyse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyAnalyse(
      keyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}key_id'])!,
      analysis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}analysis'])!,
      stats: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stats']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $KeyAnalysesTable createAlias(String alias) {
    return $KeyAnalysesTable(attachedDatabase, alias);
  }
}

class KeyAnalyse extends DataClass implements Insertable<KeyAnalyse> {
  final int keyId;
  final String analysis;
  final String? stats;
  final DateTime updatedAt;
  const KeyAnalyse(
      {required this.keyId,
      required this.analysis,
      this.stats,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key_id'] = Variable<int>(keyId);
    map['analysis'] = Variable<String>(analysis);
    if (!nullToAbsent || stats != null) {
      map['stats'] = Variable<String>(stats);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  KeyAnalysesCompanion toCompanion(bool nullToAbsent) {
    return KeyAnalysesCompanion(
      keyId: Value(keyId),
      analysis: Value(analysis),
      stats:
          stats == null && nullToAbsent ? const Value.absent() : Value(stats),
      updatedAt: Value(updatedAt),
    );
  }

  factory KeyAnalyse.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyAnalyse(
      keyId: serializer.fromJson<int>(json['keyId']),
      analysis: serializer.fromJson<String>(json['analysis']),
      stats: serializer.fromJson<String?>(json['stats']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'keyId': serializer.toJson<int>(keyId),
      'analysis': serializer.toJson<String>(analysis),
      'stats': serializer.toJson<String?>(stats),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  KeyAnalyse copyWith(
          {int? keyId,
          String? analysis,
          Value<String?> stats = const Value.absent(),
          DateTime? updatedAt}) =>
      KeyAnalyse(
        keyId: keyId ?? this.keyId,
        analysis: analysis ?? this.analysis,
        stats: stats.present ? stats.value : this.stats,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  KeyAnalyse copyWithCompanion(KeyAnalysesCompanion data) {
    return KeyAnalyse(
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      analysis: data.analysis.present ? data.analysis.value : this.analysis,
      stats: data.stats.present ? data.stats.value : this.stats,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyAnalyse(')
          ..write('keyId: $keyId, ')
          ..write('analysis: $analysis, ')
          ..write('stats: $stats, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(keyId, analysis, stats, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyAnalyse &&
          other.keyId == this.keyId &&
          other.analysis == this.analysis &&
          other.stats == this.stats &&
          other.updatedAt == this.updatedAt);
}

class KeyAnalysesCompanion extends UpdateCompanion<KeyAnalyse> {
  final Value<int> keyId;
  final Value<String> analysis;
  final Value<String?> stats;
  final Value<DateTime> updatedAt;
  const KeyAnalysesCompanion({
    this.keyId = const Value.absent(),
    this.analysis = const Value.absent(),
    this.stats = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  KeyAnalysesCompanion.insert({
    this.keyId = const Value.absent(),
    required String analysis,
    this.stats = const Value.absent(),
    required DateTime updatedAt,
  })  : analysis = Value(analysis),
        updatedAt = Value(updatedAt);
  static Insertable<KeyAnalyse> custom({
    Expression<int>? keyId,
    Expression<String>? analysis,
    Expression<String>? stats,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (keyId != null) 'key_id': keyId,
      if (analysis != null) 'analysis': analysis,
      if (stats != null) 'stats': stats,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  KeyAnalysesCompanion copyWith(
      {Value<int>? keyId,
      Value<String>? analysis,
      Value<String?>? stats,
      Value<DateTime>? updatedAt}) {
    return KeyAnalysesCompanion(
      keyId: keyId ?? this.keyId,
      analysis: analysis ?? this.analysis,
      stats: stats ?? this.stats,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (keyId.present) {
      map['key_id'] = Variable<int>(keyId.value);
    }
    if (analysis.present) {
      map['analysis'] = Variable<String>(analysis.value);
    }
    if (stats.present) {
      map['stats'] = Variable<String>(stats.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyAnalysesCompanion(')
          ..write('keyId: $keyId, ')
          ..write('analysis: $analysis, ')
          ..write('stats: $stats, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PeriodSummariesTable extends PeriodSummaries
    with TableInfo<$PeriodSummariesTable, PeriodSummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodSummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
      'period', aliasedName, false,
      check: () => period.isIn(const ['week', 'month']),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
      'start_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
      'end_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, period, startDate, endDate, summary];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'period_summaries';
  @override
  VerificationContext validateIntegrity(Insertable<PeriodSummary> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('period')) {
      context.handle(_periodMeta,
          period.isAcceptableOrUnknown(data['period']!, _periodMeta));
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {period, startDate},
      ];
  @override
  PeriodSummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodSummary(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      period: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}period'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_date'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])!,
    );
  }

  @override
  $PeriodSummariesTable createAlias(String alias) {
    return $PeriodSummariesTable(attachedDatabase, alias);
  }
}

class PeriodSummary extends DataClass implements Insertable<PeriodSummary> {
  final int id;
  final String period;
  final String startDate;
  final String endDate;
  final String summary;
  const PeriodSummary(
      {required this.id,
      required this.period,
      required this.startDate,
      required this.endDate,
      required this.summary});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['period'] = Variable<String>(period);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['summary'] = Variable<String>(summary);
    return map;
  }

  PeriodSummariesCompanion toCompanion(bool nullToAbsent) {
    return PeriodSummariesCompanion(
      id: Value(id),
      period: Value(period),
      startDate: Value(startDate),
      endDate: Value(endDate),
      summary: Value(summary),
    );
  }

  factory PeriodSummary.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodSummary(
      id: serializer.fromJson<int>(json['id']),
      period: serializer.fromJson<String>(json['period']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      summary: serializer.fromJson<String>(json['summary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'period': serializer.toJson<String>(period),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'summary': serializer.toJson<String>(summary),
    };
  }

  PeriodSummary copyWith(
          {int? id,
          String? period,
          String? startDate,
          String? endDate,
          String? summary}) =>
      PeriodSummary(
        id: id ?? this.id,
        period: period ?? this.period,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        summary: summary ?? this.summary,
      );
  PeriodSummary copyWithCompanion(PeriodSummariesCompanion data) {
    return PeriodSummary(
      id: data.id.present ? data.id.value : this.id,
      period: data.period.present ? data.period.value : this.period,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      summary: data.summary.present ? data.summary.value : this.summary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodSummary(')
          ..write('id: $id, ')
          ..write('period: $period, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, period, startDate, endDate, summary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodSummary &&
          other.id == this.id &&
          other.period == this.period &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.summary == this.summary);
}

class PeriodSummariesCompanion extends UpdateCompanion<PeriodSummary> {
  final Value<int> id;
  final Value<String> period;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<String> summary;
  const PeriodSummariesCompanion({
    this.id = const Value.absent(),
    this.period = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.summary = const Value.absent(),
  });
  PeriodSummariesCompanion.insert({
    this.id = const Value.absent(),
    required String period,
    required String startDate,
    required String endDate,
    required String summary,
  })  : period = Value(period),
        startDate = Value(startDate),
        endDate = Value(endDate),
        summary = Value(summary);
  static Insertable<PeriodSummary> custom({
    Expression<int>? id,
    Expression<String>? period,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? summary,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (period != null) 'period': period,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (summary != null) 'summary': summary,
    });
  }

  PeriodSummariesCompanion copyWith(
      {Value<int>? id,
      Value<String>? period,
      Value<String>? startDate,
      Value<String>? endDate,
      Value<String>? summary}) {
    return PeriodSummariesCompanion(
      id: id ?? this.id,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      summary: summary ?? this.summary,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodSummariesCompanion(')
          ..write('id: $id, ')
          ..write('period: $period, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }
}

class $RecurrencesTable extends Recurrences
    with TableInfo<$RecurrencesTable, Recurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<int> keyId = GeneratedColumn<int>(
      'key_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES keys (id)'));
  static const VerificationMeta _dayOfWeekMeta =
      const VerificationMeta('dayOfWeek');
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
      'day_of_week', aliasedName, false,
      check: () => ComparableExpr(dayOfWeek).isBetweenValues(0, 6),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _windowStartMeta =
      const VerificationMeta('windowStart');
  @override
  late final GeneratedColumn<String> windowStart = GeneratedColumn<String>(
      'window_start', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _windowEndMeta =
      const VerificationMeta('windowEnd');
  @override
  late final GeneratedColumn<String> windowEnd = GeneratedColumn<String>(
      'window_end', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      check: () => status.isIn(const ['proposed', 'confirmed', 'suggestion']),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
      'confidence', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _hitCountMeta =
      const VerificationMeta('hitCount');
  @override
  late final GeneratedColumn<int> hitCount = GeneratedColumn<int>(
      'hit_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _consecutiveMissesMeta =
      const VerificationMeta('consecutiveMisses');
  @override
  late final GeneratedColumn<int> consecutiveMisses = GeneratedColumn<int>(
      'consecutive_misses', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        keyId,
        dayOfWeek,
        windowStart,
        windowEnd,
        status,
        confidence,
        hitCount,
        consecutiveMisses,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrences';
  @override
  VerificationContext validateIntegrity(Insertable<Recurrence> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key_id')) {
      context.handle(
          _keyIdMeta, keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta));
    } else if (isInserting) {
      context.missing(_keyIdMeta);
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
          _dayOfWeekMeta,
          dayOfWeek.isAcceptableOrUnknown(
              data['day_of_week']!, _dayOfWeekMeta));
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('window_start')) {
      context.handle(
          _windowStartMeta,
          windowStart.isAcceptableOrUnknown(
              data['window_start']!, _windowStartMeta));
    } else if (isInserting) {
      context.missing(_windowStartMeta);
    }
    if (data.containsKey('window_end')) {
      context.handle(_windowEndMeta,
          windowEnd.isAcceptableOrUnknown(data['window_end']!, _windowEndMeta));
    } else if (isInserting) {
      context.missing(_windowEndMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('hit_count')) {
      context.handle(_hitCountMeta,
          hitCount.isAcceptableOrUnknown(data['hit_count']!, _hitCountMeta));
    }
    if (data.containsKey('consecutive_misses')) {
      context.handle(
          _consecutiveMissesMeta,
          consecutiveMisses.isAcceptableOrUnknown(
              data['consecutive_misses']!, _consecutiveMissesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recurrence(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      keyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}key_id'])!,
      dayOfWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_of_week'])!,
      windowStart: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}window_start'])!,
      windowEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}window_end'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}confidence'])!,
      hitCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hit_count'])!,
      consecutiveMisses: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}consecutive_misses'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RecurrencesTable createAlias(String alias) {
    return $RecurrencesTable(attachedDatabase, alias);
  }
}

class Recurrence extends DataClass implements Insertable<Recurrence> {
  final int id;
  final int keyId;
  final int dayOfWeek;
  final String windowStart;
  final String windowEnd;
  final String status;
  final double confidence;
  final int hitCount;
  final int consecutiveMisses;
  final DateTime createdAt;
  const Recurrence(
      {required this.id,
      required this.keyId,
      required this.dayOfWeek,
      required this.windowStart,
      required this.windowEnd,
      required this.status,
      required this.confidence,
      required this.hitCount,
      required this.consecutiveMisses,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key_id'] = Variable<int>(keyId);
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['window_start'] = Variable<String>(windowStart);
    map['window_end'] = Variable<String>(windowEnd);
    map['status'] = Variable<String>(status);
    map['confidence'] = Variable<double>(confidence);
    map['hit_count'] = Variable<int>(hitCount);
    map['consecutive_misses'] = Variable<int>(consecutiveMisses);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RecurrencesCompanion toCompanion(bool nullToAbsent) {
    return RecurrencesCompanion(
      id: Value(id),
      keyId: Value(keyId),
      dayOfWeek: Value(dayOfWeek),
      windowStart: Value(windowStart),
      windowEnd: Value(windowEnd),
      status: Value(status),
      confidence: Value(confidence),
      hitCount: Value(hitCount),
      consecutiveMisses: Value(consecutiveMisses),
      createdAt: Value(createdAt),
    );
  }

  factory Recurrence.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recurrence(
      id: serializer.fromJson<int>(json['id']),
      keyId: serializer.fromJson<int>(json['keyId']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      windowStart: serializer.fromJson<String>(json['windowStart']),
      windowEnd: serializer.fromJson<String>(json['windowEnd']),
      status: serializer.fromJson<String>(json['status']),
      confidence: serializer.fromJson<double>(json['confidence']),
      hitCount: serializer.fromJson<int>(json['hitCount']),
      consecutiveMisses: serializer.fromJson<int>(json['consecutiveMisses']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'keyId': serializer.toJson<int>(keyId),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'windowStart': serializer.toJson<String>(windowStart),
      'windowEnd': serializer.toJson<String>(windowEnd),
      'status': serializer.toJson<String>(status),
      'confidence': serializer.toJson<double>(confidence),
      'hitCount': serializer.toJson<int>(hitCount),
      'consecutiveMisses': serializer.toJson<int>(consecutiveMisses),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Recurrence copyWith(
          {int? id,
          int? keyId,
          int? dayOfWeek,
          String? windowStart,
          String? windowEnd,
          String? status,
          double? confidence,
          int? hitCount,
          int? consecutiveMisses,
          DateTime? createdAt}) =>
      Recurrence(
        id: id ?? this.id,
        keyId: keyId ?? this.keyId,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        windowStart: windowStart ?? this.windowStart,
        windowEnd: windowEnd ?? this.windowEnd,
        status: status ?? this.status,
        confidence: confidence ?? this.confidence,
        hitCount: hitCount ?? this.hitCount,
        consecutiveMisses: consecutiveMisses ?? this.consecutiveMisses,
        createdAt: createdAt ?? this.createdAt,
      );
  Recurrence copyWithCompanion(RecurrencesCompanion data) {
    return Recurrence(
      id: data.id.present ? data.id.value : this.id,
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      windowStart:
          data.windowStart.present ? data.windowStart.value : this.windowStart,
      windowEnd: data.windowEnd.present ? data.windowEnd.value : this.windowEnd,
      status: data.status.present ? data.status.value : this.status,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      hitCount: data.hitCount.present ? data.hitCount.value : this.hitCount,
      consecutiveMisses: data.consecutiveMisses.present
          ? data.consecutiveMisses.value
          : this.consecutiveMisses,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recurrence(')
          ..write('id: $id, ')
          ..write('keyId: $keyId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('windowStart: $windowStart, ')
          ..write('windowEnd: $windowEnd, ')
          ..write('status: $status, ')
          ..write('confidence: $confidence, ')
          ..write('hitCount: $hitCount, ')
          ..write('consecutiveMisses: $consecutiveMisses, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, keyId, dayOfWeek, windowStart, windowEnd,
      status, confidence, hitCount, consecutiveMisses, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recurrence &&
          other.id == this.id &&
          other.keyId == this.keyId &&
          other.dayOfWeek == this.dayOfWeek &&
          other.windowStart == this.windowStart &&
          other.windowEnd == this.windowEnd &&
          other.status == this.status &&
          other.confidence == this.confidence &&
          other.hitCount == this.hitCount &&
          other.consecutiveMisses == this.consecutiveMisses &&
          other.createdAt == this.createdAt);
}

class RecurrencesCompanion extends UpdateCompanion<Recurrence> {
  final Value<int> id;
  final Value<int> keyId;
  final Value<int> dayOfWeek;
  final Value<String> windowStart;
  final Value<String> windowEnd;
  final Value<String> status;
  final Value<double> confidence;
  final Value<int> hitCount;
  final Value<int> consecutiveMisses;
  final Value<DateTime> createdAt;
  const RecurrencesCompanion({
    this.id = const Value.absent(),
    this.keyId = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.windowStart = const Value.absent(),
    this.windowEnd = const Value.absent(),
    this.status = const Value.absent(),
    this.confidence = const Value.absent(),
    this.hitCount = const Value.absent(),
    this.consecutiveMisses = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RecurrencesCompanion.insert({
    this.id = const Value.absent(),
    required int keyId,
    required int dayOfWeek,
    required String windowStart,
    required String windowEnd,
    required String status,
    required double confidence,
    this.hitCount = const Value.absent(),
    this.consecutiveMisses = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : keyId = Value(keyId),
        dayOfWeek = Value(dayOfWeek),
        windowStart = Value(windowStart),
        windowEnd = Value(windowEnd),
        status = Value(status),
        confidence = Value(confidence);
  static Insertable<Recurrence> custom({
    Expression<int>? id,
    Expression<int>? keyId,
    Expression<int>? dayOfWeek,
    Expression<String>? windowStart,
    Expression<String>? windowEnd,
    Expression<String>? status,
    Expression<double>? confidence,
    Expression<int>? hitCount,
    Expression<int>? consecutiveMisses,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (keyId != null) 'key_id': keyId,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (windowStart != null) 'window_start': windowStart,
      if (windowEnd != null) 'window_end': windowEnd,
      if (status != null) 'status': status,
      if (confidence != null) 'confidence': confidence,
      if (hitCount != null) 'hit_count': hitCount,
      if (consecutiveMisses != null) 'consecutive_misses': consecutiveMisses,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RecurrencesCompanion copyWith(
      {Value<int>? id,
      Value<int>? keyId,
      Value<int>? dayOfWeek,
      Value<String>? windowStart,
      Value<String>? windowEnd,
      Value<String>? status,
      Value<double>? confidence,
      Value<int>? hitCount,
      Value<int>? consecutiveMisses,
      Value<DateTime>? createdAt}) {
    return RecurrencesCompanion(
      id: id ?? this.id,
      keyId: keyId ?? this.keyId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      hitCount: hitCount ?? this.hitCount,
      consecutiveMisses: consecutiveMisses ?? this.consecutiveMisses,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (keyId.present) {
      map['key_id'] = Variable<int>(keyId.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (windowStart.present) {
      map['window_start'] = Variable<String>(windowStart.value);
    }
    if (windowEnd.present) {
      map['window_end'] = Variable<String>(windowEnd.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (hitCount.present) {
      map['hit_count'] = Variable<int>(hitCount.value);
    }
    if (consecutiveMisses.present) {
      map['consecutive_misses'] = Variable<int>(consecutiveMisses.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurrencesCompanion(')
          ..write('id: $id, ')
          ..write('keyId: $keyId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('windowStart: $windowStart, ')
          ..write('windowEnd: $windowEnd, ')
          ..write('status: $status, ')
          ..write('confidence: $confidence, ')
          ..write('hitCount: $hitCount, ')
          ..write('consecutiveMisses: $consecutiveMisses, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RecurrenceSuppressionsTable extends RecurrenceSuppressions
    with TableInfo<$RecurrenceSuppressionsTable, RecurrenceSuppression> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurrenceSuppressionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<int> keyId = GeneratedColumn<int>(
      'key_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES keys (id)'));
  static const VerificationMeta _dayOfWeekMeta =
      const VerificationMeta('dayOfWeek');
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
      'day_of_week', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _windowStartMeta =
      const VerificationMeta('windowStart');
  @override
  late final GeneratedColumn<String> windowStart = GeneratedColumn<String>(
      'window_start', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _windowEndMeta =
      const VerificationMeta('windowEnd');
  @override
  late final GeneratedColumn<String> windowEnd = GeneratedColumn<String>(
      'window_end', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _suppressedAtMeta =
      const VerificationMeta('suppressedAt');
  @override
  late final GeneratedColumn<DateTime> suppressedAt = GeneratedColumn<DateTime>(
      'suppressed_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [keyId, dayOfWeek, windowStart, windowEnd, suppressedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrence_suppressions';
  @override
  VerificationContext validateIntegrity(
      Insertable<RecurrenceSuppression> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key_id')) {
      context.handle(
          _keyIdMeta, keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta));
    } else if (isInserting) {
      context.missing(_keyIdMeta);
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
          _dayOfWeekMeta,
          dayOfWeek.isAcceptableOrUnknown(
              data['day_of_week']!, _dayOfWeekMeta));
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('window_start')) {
      context.handle(
          _windowStartMeta,
          windowStart.isAcceptableOrUnknown(
              data['window_start']!, _windowStartMeta));
    } else if (isInserting) {
      context.missing(_windowStartMeta);
    }
    if (data.containsKey('window_end')) {
      context.handle(_windowEndMeta,
          windowEnd.isAcceptableOrUnknown(data['window_end']!, _windowEndMeta));
    } else if (isInserting) {
      context.missing(_windowEndMeta);
    }
    if (data.containsKey('suppressed_at')) {
      context.handle(
          _suppressedAtMeta,
          suppressedAt.isAcceptableOrUnknown(
              data['suppressed_at']!, _suppressedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {keyId, dayOfWeek, windowStart};
  @override
  RecurrenceSuppression map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurrenceSuppression(
      keyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}key_id'])!,
      dayOfWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_of_week'])!,
      windowStart: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}window_start'])!,
      windowEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}window_end'])!,
      suppressedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}suppressed_at'])!,
    );
  }

  @override
  $RecurrenceSuppressionsTable createAlias(String alias) {
    return $RecurrenceSuppressionsTable(attachedDatabase, alias);
  }
}

class RecurrenceSuppression extends DataClass
    implements Insertable<RecurrenceSuppression> {
  final int keyId;
  final int dayOfWeek;
  final String windowStart;
  final String windowEnd;
  final DateTime suppressedAt;
  const RecurrenceSuppression(
      {required this.keyId,
      required this.dayOfWeek,
      required this.windowStart,
      required this.windowEnd,
      required this.suppressedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key_id'] = Variable<int>(keyId);
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['window_start'] = Variable<String>(windowStart);
    map['window_end'] = Variable<String>(windowEnd);
    map['suppressed_at'] = Variable<DateTime>(suppressedAt);
    return map;
  }

  RecurrenceSuppressionsCompanion toCompanion(bool nullToAbsent) {
    return RecurrenceSuppressionsCompanion(
      keyId: Value(keyId),
      dayOfWeek: Value(dayOfWeek),
      windowStart: Value(windowStart),
      windowEnd: Value(windowEnd),
      suppressedAt: Value(suppressedAt),
    );
  }

  factory RecurrenceSuppression.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurrenceSuppression(
      keyId: serializer.fromJson<int>(json['keyId']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      windowStart: serializer.fromJson<String>(json['windowStart']),
      windowEnd: serializer.fromJson<String>(json['windowEnd']),
      suppressedAt: serializer.fromJson<DateTime>(json['suppressedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'keyId': serializer.toJson<int>(keyId),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'windowStart': serializer.toJson<String>(windowStart),
      'windowEnd': serializer.toJson<String>(windowEnd),
      'suppressedAt': serializer.toJson<DateTime>(suppressedAt),
    };
  }

  RecurrenceSuppression copyWith(
          {int? keyId,
          int? dayOfWeek,
          String? windowStart,
          String? windowEnd,
          DateTime? suppressedAt}) =>
      RecurrenceSuppression(
        keyId: keyId ?? this.keyId,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        windowStart: windowStart ?? this.windowStart,
        windowEnd: windowEnd ?? this.windowEnd,
        suppressedAt: suppressedAt ?? this.suppressedAt,
      );
  RecurrenceSuppression copyWithCompanion(
      RecurrenceSuppressionsCompanion data) {
    return RecurrenceSuppression(
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      windowStart:
          data.windowStart.present ? data.windowStart.value : this.windowStart,
      windowEnd: data.windowEnd.present ? data.windowEnd.value : this.windowEnd,
      suppressedAt: data.suppressedAt.present
          ? data.suppressedAt.value
          : this.suppressedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceSuppression(')
          ..write('keyId: $keyId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('windowStart: $windowStart, ')
          ..write('windowEnd: $windowEnd, ')
          ..write('suppressedAt: $suppressedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(keyId, dayOfWeek, windowStart, windowEnd, suppressedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurrenceSuppression &&
          other.keyId == this.keyId &&
          other.dayOfWeek == this.dayOfWeek &&
          other.windowStart == this.windowStart &&
          other.windowEnd == this.windowEnd &&
          other.suppressedAt == this.suppressedAt);
}

class RecurrenceSuppressionsCompanion
    extends UpdateCompanion<RecurrenceSuppression> {
  final Value<int> keyId;
  final Value<int> dayOfWeek;
  final Value<String> windowStart;
  final Value<String> windowEnd;
  final Value<DateTime> suppressedAt;
  final Value<int> rowid;
  const RecurrenceSuppressionsCompanion({
    this.keyId = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.windowStart = const Value.absent(),
    this.windowEnd = const Value.absent(),
    this.suppressedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurrenceSuppressionsCompanion.insert({
    required int keyId,
    required int dayOfWeek,
    required String windowStart,
    required String windowEnd,
    this.suppressedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : keyId = Value(keyId),
        dayOfWeek = Value(dayOfWeek),
        windowStart = Value(windowStart),
        windowEnd = Value(windowEnd);
  static Insertable<RecurrenceSuppression> custom({
    Expression<int>? keyId,
    Expression<int>? dayOfWeek,
    Expression<String>? windowStart,
    Expression<String>? windowEnd,
    Expression<DateTime>? suppressedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (keyId != null) 'key_id': keyId,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (windowStart != null) 'window_start': windowStart,
      if (windowEnd != null) 'window_end': windowEnd,
      if (suppressedAt != null) 'suppressed_at': suppressedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurrenceSuppressionsCompanion copyWith(
      {Value<int>? keyId,
      Value<int>? dayOfWeek,
      Value<String>? windowStart,
      Value<String>? windowEnd,
      Value<DateTime>? suppressedAt,
      Value<int>? rowid}) {
    return RecurrenceSuppressionsCompanion(
      keyId: keyId ?? this.keyId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      suppressedAt: suppressedAt ?? this.suppressedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (keyId.present) {
      map['key_id'] = Variable<int>(keyId.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (windowStart.present) {
      map['window_start'] = Variable<String>(windowStart.value);
    }
    if (windowEnd.present) {
      map['window_end'] = Variable<String>(windowEnd.value);
    }
    if (suppressedAt.present) {
      map['suppressed_at'] = Variable<DateTime>(suppressedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceSuppressionsCompanion(')
          ..write('keyId: $keyId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('windowStart: $windowStart, ')
          ..write('windowEnd: $windowEnd, ')
          ..write('suppressedAt: $suppressedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FutureEntriesTable extends FutureEntries
    with TableInfo<$FutureEntriesTable, FutureEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FutureEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entryDateMeta =
      const VerificationMeta('entryDate');
  @override
  late final GeneratedColumn<String> entryDate = GeneratedColumn<String>(
      'entry_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<int> keyId = GeneratedColumn<int>(
      'key_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES keys (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timeHintMeta =
      const VerificationMeta('timeHint');
  @override
  late final GeneratedColumn<String> timeHint = GeneratedColumn<String>(
      'time_hint', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, entryDate, keyId, title, timeHint, source, metadata, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'future_entries';
  @override
  VerificationContext validateIntegrity(Insertable<FutureEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_date')) {
      context.handle(_entryDateMeta,
          entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta));
    } else if (isInserting) {
      context.missing(_entryDateMeta);
    }
    if (data.containsKey('key_id')) {
      context.handle(
          _keyIdMeta, keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('time_hint')) {
      context.handle(_timeHintMeta,
          timeHint.isAcceptableOrUnknown(data['time_hint']!, _timeHintMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FutureEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FutureEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_date'])!,
      keyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}key_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      timeHint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time_hint']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FutureEntriesTable createAlias(String alias) {
    return $FutureEntriesTable(attachedDatabase, alias);
  }
}

class FutureEntry extends DataClass implements Insertable<FutureEntry> {
  final int id;
  final String entryDate;
  final int? keyId;
  final String title;
  final String? timeHint;
  final String source;
  final String? metadata;
  final DateTime createdAt;
  const FutureEntry(
      {required this.id,
      required this.entryDate,
      this.keyId,
      required this.title,
      this.timeHint,
      required this.source,
      this.metadata,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_date'] = Variable<String>(entryDate);
    if (!nullToAbsent || keyId != null) {
      map['key_id'] = Variable<int>(keyId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || timeHint != null) {
      map['time_hint'] = Variable<String>(timeHint);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FutureEntriesCompanion toCompanion(bool nullToAbsent) {
    return FutureEntriesCompanion(
      id: Value(id),
      entryDate: Value(entryDate),
      keyId:
          keyId == null && nullToAbsent ? const Value.absent() : Value(keyId),
      title: Value(title),
      timeHint: timeHint == null && nullToAbsent
          ? const Value.absent()
          : Value(timeHint),
      source: Value(source),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
    );
  }

  factory FutureEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FutureEntry(
      id: serializer.fromJson<int>(json['id']),
      entryDate: serializer.fromJson<String>(json['entryDate']),
      keyId: serializer.fromJson<int?>(json['keyId']),
      title: serializer.fromJson<String>(json['title']),
      timeHint: serializer.fromJson<String?>(json['timeHint']),
      source: serializer.fromJson<String>(json['source']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryDate': serializer.toJson<String>(entryDate),
      'keyId': serializer.toJson<int?>(keyId),
      'title': serializer.toJson<String>(title),
      'timeHint': serializer.toJson<String?>(timeHint),
      'source': serializer.toJson<String>(source),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FutureEntry copyWith(
          {int? id,
          String? entryDate,
          Value<int?> keyId = const Value.absent(),
          String? title,
          Value<String?> timeHint = const Value.absent(),
          String? source,
          Value<String?> metadata = const Value.absent(),
          DateTime? createdAt}) =>
      FutureEntry(
        id: id ?? this.id,
        entryDate: entryDate ?? this.entryDate,
        keyId: keyId.present ? keyId.value : this.keyId,
        title: title ?? this.title,
        timeHint: timeHint.present ? timeHint.value : this.timeHint,
        source: source ?? this.source,
        metadata: metadata.present ? metadata.value : this.metadata,
        createdAt: createdAt ?? this.createdAt,
      );
  FutureEntry copyWithCompanion(FutureEntriesCompanion data) {
    return FutureEntry(
      id: data.id.present ? data.id.value : this.id,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      title: data.title.present ? data.title.value : this.title,
      timeHint: data.timeHint.present ? data.timeHint.value : this.timeHint,
      source: data.source.present ? data.source.value : this.source,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FutureEntry(')
          ..write('id: $id, ')
          ..write('entryDate: $entryDate, ')
          ..write('keyId: $keyId, ')
          ..write('title: $title, ')
          ..write('timeHint: $timeHint, ')
          ..write('source: $source, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, entryDate, keyId, title, timeHint, source, metadata, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FutureEntry &&
          other.id == this.id &&
          other.entryDate == this.entryDate &&
          other.keyId == this.keyId &&
          other.title == this.title &&
          other.timeHint == this.timeHint &&
          other.source == this.source &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt);
}

class FutureEntriesCompanion extends UpdateCompanion<FutureEntry> {
  final Value<int> id;
  final Value<String> entryDate;
  final Value<int?> keyId;
  final Value<String> title;
  final Value<String?> timeHint;
  final Value<String> source;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  const FutureEntriesCompanion({
    this.id = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.keyId = const Value.absent(),
    this.title = const Value.absent(),
    this.timeHint = const Value.absent(),
    this.source = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FutureEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String entryDate,
    this.keyId = const Value.absent(),
    required String title,
    this.timeHint = const Value.absent(),
    required String source,
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : entryDate = Value(entryDate),
        title = Value(title),
        source = Value(source);
  static Insertable<FutureEntry> custom({
    Expression<int>? id,
    Expression<String>? entryDate,
    Expression<int>? keyId,
    Expression<String>? title,
    Expression<String>? timeHint,
    Expression<String>? source,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryDate != null) 'entry_date': entryDate,
      if (keyId != null) 'key_id': keyId,
      if (title != null) 'title': title,
      if (timeHint != null) 'time_hint': timeHint,
      if (source != null) 'source': source,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FutureEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? entryDate,
      Value<int?>? keyId,
      Value<String>? title,
      Value<String?>? timeHint,
      Value<String>? source,
      Value<String?>? metadata,
      Value<DateTime>? createdAt}) {
    return FutureEntriesCompanion(
      id: id ?? this.id,
      entryDate: entryDate ?? this.entryDate,
      keyId: keyId ?? this.keyId,
      title: title ?? this.title,
      timeHint: timeHint ?? this.timeHint,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<String>(entryDate.value);
    }
    if (keyId.present) {
      map['key_id'] = Variable<int>(keyId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (timeHint.present) {
      map['time_hint'] = Variable<String>(timeHint.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FutureEntriesCompanion(')
          ..write('id: $id, ')
          ..write('entryDate: $entryDate, ')
          ..write('keyId: $keyId, ')
          ..write('title: $title, ')
          ..write('timeHint: $timeHint, ')
          ..write('source: $source, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PlansTable extends Plans with TableInfo<$PlansTable, Plan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _planDateMeta =
      const VerificationMeta('planDate');
  @override
  late final GeneratedColumn<String> planDate = GeneratedColumn<String>(
      'plan_date', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _draftMeta = const VerificationMeta('draft');
  @override
  late final GeneratedColumn<String> draft = GeneratedColumn<String>(
      'draft', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _finalPlanMeta =
      const VerificationMeta('finalPlan');
  @override
  late final GeneratedColumn<String> finalPlan = GeneratedColumn<String>(
      'final_plan', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, planDate, draft, finalPlan, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  VerificationContext validateIntegrity(Insertable<Plan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_date')) {
      context.handle(_planDateMeta,
          planDate.isAcceptableOrUnknown(data['plan_date']!, _planDateMeta));
    } else if (isInserting) {
      context.missing(_planDateMeta);
    }
    if (data.containsKey('draft')) {
      context.handle(
          _draftMeta, draft.isAcceptableOrUnknown(data['draft']!, _draftMeta));
    } else if (isInserting) {
      context.missing(_draftMeta);
    }
    if (data.containsKey('final_plan')) {
      context.handle(_finalPlanMeta,
          finalPlan.isAcceptableOrUnknown(data['final_plan']!, _finalPlanMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Plan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Plan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      planDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_date'])!,
      draft: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}draft'])!,
      finalPlan: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}final_plan']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }
}

class Plan extends DataClass implements Insertable<Plan> {
  final int id;
  final String planDate;
  final String draft;
  final String? finalPlan;
  final DateTime createdAt;
  const Plan(
      {required this.id,
      required this.planDate,
      required this.draft,
      this.finalPlan,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_date'] = Variable<String>(planDate);
    map['draft'] = Variable<String>(draft);
    if (!nullToAbsent || finalPlan != null) {
      map['final_plan'] = Variable<String>(finalPlan);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      planDate: Value(planDate),
      draft: Value(draft),
      finalPlan: finalPlan == null && nullToAbsent
          ? const Value.absent()
          : Value(finalPlan),
      createdAt: Value(createdAt),
    );
  }

  factory Plan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Plan(
      id: serializer.fromJson<int>(json['id']),
      planDate: serializer.fromJson<String>(json['planDate']),
      draft: serializer.fromJson<String>(json['draft']),
      finalPlan: serializer.fromJson<String?>(json['finalPlan']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planDate': serializer.toJson<String>(planDate),
      'draft': serializer.toJson<String>(draft),
      'finalPlan': serializer.toJson<String?>(finalPlan),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Plan copyWith(
          {int? id,
          String? planDate,
          String? draft,
          Value<String?> finalPlan = const Value.absent(),
          DateTime? createdAt}) =>
      Plan(
        id: id ?? this.id,
        planDate: planDate ?? this.planDate,
        draft: draft ?? this.draft,
        finalPlan: finalPlan.present ? finalPlan.value : this.finalPlan,
        createdAt: createdAt ?? this.createdAt,
      );
  Plan copyWithCompanion(PlansCompanion data) {
    return Plan(
      id: data.id.present ? data.id.value : this.id,
      planDate: data.planDate.present ? data.planDate.value : this.planDate,
      draft: data.draft.present ? data.draft.value : this.draft,
      finalPlan: data.finalPlan.present ? data.finalPlan.value : this.finalPlan,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plan(')
          ..write('id: $id, ')
          ..write('planDate: $planDate, ')
          ..write('draft: $draft, ')
          ..write('finalPlan: $finalPlan, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planDate, draft, finalPlan, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plan &&
          other.id == this.id &&
          other.planDate == this.planDate &&
          other.draft == this.draft &&
          other.finalPlan == this.finalPlan &&
          other.createdAt == this.createdAt);
}

class PlansCompanion extends UpdateCompanion<Plan> {
  final Value<int> id;
  final Value<String> planDate;
  final Value<String> draft;
  final Value<String?> finalPlan;
  final Value<DateTime> createdAt;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.planDate = const Value.absent(),
    this.draft = const Value.absent(),
    this.finalPlan = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PlansCompanion.insert({
    this.id = const Value.absent(),
    required String planDate,
    required String draft,
    this.finalPlan = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : planDate = Value(planDate),
        draft = Value(draft);
  static Insertable<Plan> custom({
    Expression<int>? id,
    Expression<String>? planDate,
    Expression<String>? draft,
    Expression<String>? finalPlan,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planDate != null) 'plan_date': planDate,
      if (draft != null) 'draft': draft,
      if (finalPlan != null) 'final_plan': finalPlan,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PlansCompanion copyWith(
      {Value<int>? id,
      Value<String>? planDate,
      Value<String>? draft,
      Value<String?>? finalPlan,
      Value<DateTime>? createdAt}) {
    return PlansCompanion(
      id: id ?? this.id,
      planDate: planDate ?? this.planDate,
      draft: draft ?? this.draft,
      finalPlan: finalPlan ?? this.finalPlan,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planDate.present) {
      map['plan_date'] = Variable<String>(planDate.value);
    }
    if (draft.present) {
      map['draft'] = Variable<String>(draft.value);
    }
    if (finalPlan.present) {
      map['final_plan'] = Variable<String>(finalPlan.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlansCompanion(')
          ..write('id: $id, ')
          ..write('planDate: $planDate, ')
          ..write('draft: $draft, ')
          ..write('finalPlan: $finalPlan, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kMeta = const VerificationMeta('k');
  @override
  late final GeneratedColumn<String> k = GeneratedColumn<String>(
      'k', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vMeta = const VerificationMeta('v');
  @override
  late final GeneratedColumn<String> v = GeneratedColumn<String>(
      'v', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [k, v];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('k')) {
      context.handle(_kMeta, k.isAcceptableOrUnknown(data['k']!, _kMeta));
    } else if (isInserting) {
      context.missing(_kMeta);
    }
    if (data.containsKey('v')) {
      context.handle(_vMeta, v.isAcceptableOrUnknown(data['v']!, _vMeta));
    } else if (isInserting) {
      context.missing(_vMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {k};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      k: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}k'])!,
      v: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}v'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String k;
  final String v;
  const Setting({required this.k, required this.v});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['k'] = Variable<String>(k);
    map['v'] = Variable<String>(v);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      k: Value(k),
      v: Value(v),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      k: serializer.fromJson<String>(json['k']),
      v: serializer.fromJson<String>(json['v']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'k': serializer.toJson<String>(k),
      'v': serializer.toJson<String>(v),
    };
  }

  Setting copyWith({String? k, String? v}) => Setting(
        k: k ?? this.k,
        v: v ?? this.v,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      k: data.k.present ? data.k.value : this.k,
      v: data.v.present ? data.v.value : this.v,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('k: $k, ')
          ..write('v: $v')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(k, v);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.k == this.k && other.v == this.v);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> k;
  final Value<String> v;
  final Value<int> rowid;
  const SettingsCompanion({
    this.k = const Value.absent(),
    this.v = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String k,
    required String v,
    this.rowid = const Value.absent(),
  })  : k = Value(k),
        v = Value(v);
  static Insertable<Setting> custom({
    Expression<String>? k,
    Expression<String>? v,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (k != null) 'k': k,
      if (v != null) 'v': v,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? k, Value<String>? v, Value<int>? rowid}) {
    return SettingsCompanion(
      k: k ?? this.k,
      v: v ?? this.v,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (k.present) {
      map['k'] = Variable<String>(k.value);
    }
    if (v.present) {
      map['v'] = Variable<String>(v.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('k: $k, ')
          ..write('v: $v, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KeysTable keys = $KeysTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $ListItemsTable listItems = $ListItemsTable(this);
  late final $CorrectionsTable corrections = $CorrectionsTable(this);
  late final $KeyExamplesTable keyExamples = $KeyExamplesTable(this);
  late final $DaySummariesTable daySummaries = $DaySummariesTable(this);
  late final $KeyAnalysesTable keyAnalyses = $KeyAnalysesTable(this);
  late final $PeriodSummariesTable periodSummaries =
      $PeriodSummariesTable(this);
  late final $RecurrencesTable recurrences = $RecurrencesTable(this);
  late final $RecurrenceSuppressionsTable recurrenceSuppressions =
      $RecurrenceSuppressionsTable(this);
  late final $FutureEntriesTable futureEntries = $FutureEntriesTable(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        keys,
        events,
        listItems,
        corrections,
        keyExamples,
        daySummaries,
        keyAnalyses,
        periodSummaries,
        recurrences,
        recurrenceSuppressions,
        futureEntries,
        plans,
        settings
      ];
}

typedef $$KeysTableCreateCompanionBuilder = KeysCompanion Function({
  Value<int> id,
  required String name,
  Value<DateTime> createdAt,
  Value<bool> isArchived,
  Value<Uint8List?> vector,
  Value<int> exampleCount,
  Value<int?> usualMinuteOverride,
  Value<bool> notesAffinity,
  Value<int> notesAdded,
  Value<int> notesIgnored,
});
typedef $$KeysTableUpdateCompanionBuilder = KeysCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<bool> isArchived,
  Value<Uint8List?> vector,
  Value<int> exampleCount,
  Value<int?> usualMinuteOverride,
  Value<bool> notesAffinity,
  Value<int> notesAdded,
  Value<int> notesIgnored,
});

final class $$KeysTableReferences
    extends BaseReferences<_$AppDatabase, $KeysTable, Key> {
  $$KeysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EventsTable, List<Event>> _eventsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.events,
          aliasName: $_aliasNameGenerator(db.keys.id, db.events.keyId));

  $$EventsTableProcessedTableManager get eventsRefs {
    final manager = $$EventsTableTableManager($_db, $_db.events)
        .filter((f) => f.keyId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ListItemsTable, List<ListItem>>
      _listItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.listItems,
              aliasName: $_aliasNameGenerator(db.keys.id, db.listItems.keyId));

  $$ListItemsTableProcessedTableManager get listItemsRefs {
    final manager = $$ListItemsTableTableManager($_db, $_db.listItems)
        .filter((f) => f.keyId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_listItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$KeyExamplesTable, List<KeyExample>>
      _keyExamplesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.keyExamples,
          aliasName: $_aliasNameGenerator(db.keys.id, db.keyExamples.keyId));

  $$KeyExamplesTableProcessedTableManager get keyExamplesRefs {
    final manager = $$KeyExamplesTableTableManager($_db, $_db.keyExamples)
        .filter((f) => f.keyId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_keyExamplesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$KeyAnalysesTable, List<KeyAnalyse>>
      _keyAnalysesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.keyAnalyses,
          aliasName: $_aliasNameGenerator(db.keys.id, db.keyAnalyses.keyId));

  $$KeyAnalysesTableProcessedTableManager get keyAnalysesRefs {
    final manager = $$KeyAnalysesTableTableManager($_db, $_db.keyAnalyses)
        .filter((f) => f.keyId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_keyAnalysesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecurrencesTable, List<Recurrence>>
      _recurrencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.recurrences,
          aliasName: $_aliasNameGenerator(db.keys.id, db.recurrences.keyId));

  $$RecurrencesTableProcessedTableManager get recurrencesRefs {
    final manager = $$RecurrencesTableTableManager($_db, $_db.recurrences)
        .filter((f) => f.keyId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recurrencesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecurrenceSuppressionsTable,
      List<RecurrenceSuppression>> _recurrenceSuppressionsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.recurrenceSuppressions,
          aliasName: $_aliasNameGenerator(
              db.keys.id, db.recurrenceSuppressions.keyId));

  $$RecurrenceSuppressionsTableProcessedTableManager
      get recurrenceSuppressionsRefs {
    final manager = $$RecurrenceSuppressionsTableTableManager(
            $_db, $_db.recurrenceSuppressions)
        .filter((f) => f.keyId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_recurrenceSuppressionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$FutureEntriesTable, List<FutureEntry>>
      _futureEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.futureEntries,
              aliasName:
                  $_aliasNameGenerator(db.keys.id, db.futureEntries.keyId));

  $$FutureEntriesTableProcessedTableManager get futureEntriesRefs {
    final manager = $$FutureEntriesTableTableManager($_db, $_db.futureEntries)
        .filter((f) => f.keyId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_futureEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$KeysTableFilterComposer extends Composer<_$AppDatabase, $KeysTable> {
  $$KeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get vector => $composableBuilder(
      column: $table.vector, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get exampleCount => $composableBuilder(
      column: $table.exampleCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usualMinuteOverride => $composableBuilder(
      column: $table.usualMinuteOverride,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notesAffinity => $composableBuilder(
      column: $table.notesAffinity, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notesAdded => $composableBuilder(
      column: $table.notesAdded, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notesIgnored => $composableBuilder(
      column: $table.notesIgnored, builder: (column) => ColumnFilters(column));

  Expression<bool> eventsRefs(
      Expression<bool> Function($$EventsTableFilterComposer f) f) {
    final $$EventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.keyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableFilterComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> listItemsRefs(
      Expression<bool> Function($$ListItemsTableFilterComposer f) f) {
    final $$ListItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.listItems,
        getReferencedColumn: (t) => t.keyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ListItemsTableFilterComposer(
              $db: $db,
              $table: $db.listItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> keyExamplesRefs(
      Expression<bool> Function($$KeyExamplesTableFilterComposer f) f) {
    final $$KeyExamplesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.keyExamples,
        getReferencedColumn: (t) => t.keyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeyExamplesTableFilterComposer(
              $db: $db,
              $table: $db.keyExamples,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> keyAnalysesRefs(
      Expression<bool> Function($$KeyAnalysesTableFilterComposer f) f) {
    final $$KeyAnalysesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.keyAnalyses,
        getReferencedColumn: (t) => t.keyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeyAnalysesTableFilterComposer(
              $db: $db,
              $table: $db.keyAnalyses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recurrencesRefs(
      Expression<bool> Function($$RecurrencesTableFilterComposer f) f) {
    final $$RecurrencesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recurrences,
        getReferencedColumn: (t) => t.keyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurrencesTableFilterComposer(
              $db: $db,
              $table: $db.recurrences,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recurrenceSuppressionsRefs(
      Expression<bool> Function($$RecurrenceSuppressionsTableFilterComposer f)
          f) {
    final $$RecurrenceSuppressionsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recurrenceSuppressions,
            getReferencedColumn: (t) => t.keyId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecurrenceSuppressionsTableFilterComposer(
                  $db: $db,
                  $table: $db.recurrenceSuppressions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> futureEntriesRefs(
      Expression<bool> Function($$FutureEntriesTableFilterComposer f) f) {
    final $$FutureEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.futureEntries,
        getReferencedColumn: (t) => t.keyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FutureEntriesTableFilterComposer(
              $db: $db,
              $table: $db.futureEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$KeysTableOrderingComposer extends Composer<_$AppDatabase, $KeysTable> {
  $$KeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get vector => $composableBuilder(
      column: $table.vector, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get exampleCount => $composableBuilder(
      column: $table.exampleCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usualMinuteOverride => $composableBuilder(
      column: $table.usualMinuteOverride,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notesAffinity => $composableBuilder(
      column: $table.notesAffinity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notesAdded => $composableBuilder(
      column: $table.notesAdded, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notesIgnored => $composableBuilder(
      column: $table.notesIgnored,
      builder: (column) => ColumnOrderings(column));
}

class $$KeysTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeysTable> {
  $$KeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<Uint8List> get vector =>
      $composableBuilder(column: $table.vector, builder: (column) => column);

  GeneratedColumn<int> get exampleCount => $composableBuilder(
      column: $table.exampleCount, builder: (column) => column);

  GeneratedColumn<int> get usualMinuteOverride => $composableBuilder(
      column: $table.usualMinuteOverride, builder: (column) => column);

  GeneratedColumn<bool> get notesAffinity => $composableBuilder(
      column: $table.notesAffinity, builder: (column) => column);

  GeneratedColumn<int> get notesAdded => $composableBuilder(
      column: $table.notesAdded, builder: (column) => column);

  GeneratedColumn<int> get notesIgnored => $composableBuilder(
      column: $table.notesIgnored, builder: (column) => column);

  Expression<T> eventsRefs<T extends Object>(
      Expression<T> Function($$EventsTableAnnotationComposer a) f) {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.keyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableAnnotationComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> listItemsRefs<T extends Object>(
      Expression<T> Function($$ListItemsTableAnnotationComposer a) f) {
    final $$ListItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.listItems,
        getReferencedColumn: (t) => t.keyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ListItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.listItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> keyExamplesRefs<T extends Object>(
      Expression<T> Function($$KeyExamplesTableAnnotationComposer a) f) {
    final $$KeyExamplesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.keyExamples,
        getReferencedColumn: (t) => t.keyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeyExamplesTableAnnotationComposer(
              $db: $db,
              $table: $db.keyExamples,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> keyAnalysesRefs<T extends Object>(
      Expression<T> Function($$KeyAnalysesTableAnnotationComposer a) f) {
    final $$KeyAnalysesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.keyAnalyses,
        getReferencedColumn: (t) => t.keyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeyAnalysesTableAnnotationComposer(
              $db: $db,
              $table: $db.keyAnalyses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> recurrencesRefs<T extends Object>(
      Expression<T> Function($$RecurrencesTableAnnotationComposer a) f) {
    final $$RecurrencesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recurrences,
        getReferencedColumn: (t) => t.keyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurrencesTableAnnotationComposer(
              $db: $db,
              $table: $db.recurrences,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> recurrenceSuppressionsRefs<T extends Object>(
      Expression<T> Function($$RecurrenceSuppressionsTableAnnotationComposer a)
          f) {
    final $$RecurrenceSuppressionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recurrenceSuppressions,
            getReferencedColumn: (t) => t.keyId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecurrenceSuppressionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.recurrenceSuppressions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> futureEntriesRefs<T extends Object>(
      Expression<T> Function($$FutureEntriesTableAnnotationComposer a) f) {
    final $$FutureEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.futureEntries,
        getReferencedColumn: (t) => t.keyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FutureEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.futureEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$KeysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KeysTable,
    Key,
    $$KeysTableFilterComposer,
    $$KeysTableOrderingComposer,
    $$KeysTableAnnotationComposer,
    $$KeysTableCreateCompanionBuilder,
    $$KeysTableUpdateCompanionBuilder,
    (Key, $$KeysTableReferences),
    Key,
    PrefetchHooks Function(
        {bool eventsRefs,
        bool listItemsRefs,
        bool keyExamplesRefs,
        bool keyAnalysesRefs,
        bool recurrencesRefs,
        bool recurrenceSuppressionsRefs,
        bool futureEntriesRefs})> {
  $$KeysTableTableManager(_$AppDatabase db, $KeysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<Uint8List?> vector = const Value.absent(),
            Value<int> exampleCount = const Value.absent(),
            Value<int?> usualMinuteOverride = const Value.absent(),
            Value<bool> notesAffinity = const Value.absent(),
            Value<int> notesAdded = const Value.absent(),
            Value<int> notesIgnored = const Value.absent(),
          }) =>
              KeysCompanion(
            id: id,
            name: name,
            createdAt: createdAt,
            isArchived: isArchived,
            vector: vector,
            exampleCount: exampleCount,
            usualMinuteOverride: usualMinuteOverride,
            notesAffinity: notesAffinity,
            notesAdded: notesAdded,
            notesIgnored: notesIgnored,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<Uint8List?> vector = const Value.absent(),
            Value<int> exampleCount = const Value.absent(),
            Value<int?> usualMinuteOverride = const Value.absent(),
            Value<bool> notesAffinity = const Value.absent(),
            Value<int> notesAdded = const Value.absent(),
            Value<int> notesIgnored = const Value.absent(),
          }) =>
              KeysCompanion.insert(
            id: id,
            name: name,
            createdAt: createdAt,
            isArchived: isArchived,
            vector: vector,
            exampleCount: exampleCount,
            usualMinuteOverride: usualMinuteOverride,
            notesAffinity: notesAffinity,
            notesAdded: notesAdded,
            notesIgnored: notesIgnored,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$KeysTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {eventsRefs = false,
              listItemsRefs = false,
              keyExamplesRefs = false,
              keyAnalysesRefs = false,
              recurrencesRefs = false,
              recurrenceSuppressionsRefs = false,
              futureEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (eventsRefs) db.events,
                if (listItemsRefs) db.listItems,
                if (keyExamplesRefs) db.keyExamples,
                if (keyAnalysesRefs) db.keyAnalyses,
                if (recurrencesRefs) db.recurrences,
                if (recurrenceSuppressionsRefs) db.recurrenceSuppressions,
                if (futureEntriesRefs) db.futureEntries
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (eventsRefs)
                    await $_getPrefetchedData<Key, $KeysTable, Event>(
                        currentTable: table,
                        referencedTable:
                            $$KeysTableReferences._eventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$KeysTableReferences(db, table, p0).eventsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.keyId == item.id),
                        typedResults: items),
                  if (listItemsRefs)
                    await $_getPrefetchedData<Key, $KeysTable, ListItem>(
                        currentTable: table,
                        referencedTable:
                            $$KeysTableReferences._listItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$KeysTableReferences(db, table, p0).listItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.keyId == item.id),
                        typedResults: items),
                  if (keyExamplesRefs)
                    await $_getPrefetchedData<Key, $KeysTable, KeyExample>(
                        currentTable: table,
                        referencedTable:
                            $$KeysTableReferences._keyExamplesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$KeysTableReferences(db, table, p0)
                                .keyExamplesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.keyId == item.id),
                        typedResults: items),
                  if (keyAnalysesRefs)
                    await $_getPrefetchedData<Key, $KeysTable, KeyAnalyse>(
                        currentTable: table,
                        referencedTable:
                            $$KeysTableReferences._keyAnalysesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$KeysTableReferences(db, table, p0)
                                .keyAnalysesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.keyId == item.id),
                        typedResults: items),
                  if (recurrencesRefs)
                    await $_getPrefetchedData<Key, $KeysTable, Recurrence>(
                        currentTable: table,
                        referencedTable:
                            $$KeysTableReferences._recurrencesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$KeysTableReferences(db, table, p0)
                                .recurrencesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.keyId == item.id),
                        typedResults: items),
                  if (recurrenceSuppressionsRefs)
                    await $_getPrefetchedData<Key, $KeysTable,
                            RecurrenceSuppression>(
                        currentTable: table,
                        referencedTable: $$KeysTableReferences
                            ._recurrenceSuppressionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$KeysTableReferences(db, table, p0)
                                .recurrenceSuppressionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.keyId == item.id),
                        typedResults: items),
                  if (futureEntriesRefs)
                    await $_getPrefetchedData<Key, $KeysTable, FutureEntry>(
                        currentTable: table,
                        referencedTable:
                            $$KeysTableReferences._futureEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$KeysTableReferences(db, table, p0)
                                .futureEntriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.keyId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$KeysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KeysTable,
    Key,
    $$KeysTableFilterComposer,
    $$KeysTableOrderingComposer,
    $$KeysTableAnnotationComposer,
    $$KeysTableCreateCompanionBuilder,
    $$KeysTableUpdateCompanionBuilder,
    (Key, $$KeysTableReferences),
    Key,
    PrefetchHooks Function(
        {bool eventsRefs,
        bool listItemsRefs,
        bool keyExamplesRefs,
        bool keyAnalysesRefs,
        bool recurrencesRefs,
        bool recurrenceSuppressionsRefs,
        bool futureEntriesRefs})>;
typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  Value<int?> keyId,
  required DateTime tsUtc,
  required String tz,
  required String dayDate,
  required String rawText,
  required String modality,
  Value<String?> photoPath,
  Value<String?> thumbPath,
  Value<String?> metadata,
  required String keySource,
  Value<double?> matchScore,
  Value<int?> captureMs,
  Value<String> status,
  Value<int?> durationMin,
  Value<double?> quantity,
  Value<String?> unit,
  Value<String?> note,
  Value<int?> listItemId,
  Value<DateTime?> editedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> createdAt,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  Value<int?> keyId,
  Value<DateTime> tsUtc,
  Value<String> tz,
  Value<String> dayDate,
  Value<String> rawText,
  Value<String> modality,
  Value<String?> photoPath,
  Value<String?> thumbPath,
  Value<String?> metadata,
  Value<String> keySource,
  Value<double?> matchScore,
  Value<int?> captureMs,
  Value<String> status,
  Value<int?> durationMin,
  Value<double?> quantity,
  Value<String?> unit,
  Value<String?> note,
  Value<int?> listItemId,
  Value<DateTime?> editedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> createdAt,
});

final class $$EventsTableReferences
    extends BaseReferences<_$AppDatabase, $EventsTable, Event> {
  $$EventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KeysTable _keyIdTable(_$AppDatabase db) =>
      db.keys.createAlias($_aliasNameGenerator(db.events.keyId, db.keys.id));

  $$KeysTableProcessedTableManager? get keyId {
    final $_column = $_itemColumn<int>('key_id');
    if ($_column == null) return null;
    final manager = $$KeysTableTableManager($_db, $_db.keys)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_keyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get tsUtc => $composableBuilder(
      column: $table.tsUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tz => $composableBuilder(
      column: $table.tz, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dayDate => $composableBuilder(
      column: $table.dayDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawText => $composableBuilder(
      column: $table.rawText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modality => $composableBuilder(
      column: $table.modality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbPath => $composableBuilder(
      column: $table.thumbPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keySource => $composableBuilder(
      column: $table.keySource, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get matchScore => $composableBuilder(
      column: $table.matchScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get captureMs => $composableBuilder(
      column: $table.captureMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMin => $composableBuilder(
      column: $table.durationMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get listItemId => $composableBuilder(
      column: $table.listItemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get editedAt => $composableBuilder(
      column: $table.editedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$KeysTableFilterComposer get keyId {
    final $$KeysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableFilterComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get tsUtc => $composableBuilder(
      column: $table.tsUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tz => $composableBuilder(
      column: $table.tz, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dayDate => $composableBuilder(
      column: $table.dayDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawText => $composableBuilder(
      column: $table.rawText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modality => $composableBuilder(
      column: $table.modality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbPath => $composableBuilder(
      column: $table.thumbPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keySource => $composableBuilder(
      column: $table.keySource, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get matchScore => $composableBuilder(
      column: $table.matchScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get captureMs => $composableBuilder(
      column: $table.captureMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMin => $composableBuilder(
      column: $table.durationMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get listItemId => $composableBuilder(
      column: $table.listItemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get editedAt => $composableBuilder(
      column: $table.editedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$KeysTableOrderingComposer get keyId {
    final $$KeysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableOrderingComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get tsUtc =>
      $composableBuilder(column: $table.tsUtc, builder: (column) => column);

  GeneratedColumn<String> get tz =>
      $composableBuilder(column: $table.tz, builder: (column) => column);

  GeneratedColumn<String> get dayDate =>
      $composableBuilder(column: $table.dayDate, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get modality =>
      $composableBuilder(column: $table.modality, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get thumbPath =>
      $composableBuilder(column: $table.thumbPath, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get keySource =>
      $composableBuilder(column: $table.keySource, builder: (column) => column);

  GeneratedColumn<double> get matchScore => $composableBuilder(
      column: $table.matchScore, builder: (column) => column);

  GeneratedColumn<int> get captureMs =>
      $composableBuilder(column: $table.captureMs, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get durationMin => $composableBuilder(
      column: $table.durationMin, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get listItemId => $composableBuilder(
      column: $table.listItemId, builder: (column) => column);

  GeneratedColumn<DateTime> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$KeysTableAnnotationComposer get keyId {
    final $$KeysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableAnnotationComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, $$EventsTableReferences),
    Event,
    PrefetchHooks Function({bool keyId})> {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> keyId = const Value.absent(),
            Value<DateTime> tsUtc = const Value.absent(),
            Value<String> tz = const Value.absent(),
            Value<String> dayDate = const Value.absent(),
            Value<String> rawText = const Value.absent(),
            Value<String> modality = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<String?> thumbPath = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<String> keySource = const Value.absent(),
            Value<double?> matchScore = const Value.absent(),
            Value<int?> captureMs = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> durationMin = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int?> listItemId = const Value.absent(),
            Value<DateTime?> editedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              EventsCompanion(
            id: id,
            keyId: keyId,
            tsUtc: tsUtc,
            tz: tz,
            dayDate: dayDate,
            rawText: rawText,
            modality: modality,
            photoPath: photoPath,
            thumbPath: thumbPath,
            metadata: metadata,
            keySource: keySource,
            matchScore: matchScore,
            captureMs: captureMs,
            status: status,
            durationMin: durationMin,
            quantity: quantity,
            unit: unit,
            note: note,
            listItemId: listItemId,
            editedAt: editedAt,
            deletedAt: deletedAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> keyId = const Value.absent(),
            required DateTime tsUtc,
            required String tz,
            required String dayDate,
            required String rawText,
            required String modality,
            Value<String?> photoPath = const Value.absent(),
            Value<String?> thumbPath = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            required String keySource,
            Value<double?> matchScore = const Value.absent(),
            Value<int?> captureMs = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> durationMin = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int?> listItemId = const Value.absent(),
            Value<DateTime?> editedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              EventsCompanion.insert(
            id: id,
            keyId: keyId,
            tsUtc: tsUtc,
            tz: tz,
            dayDate: dayDate,
            rawText: rawText,
            modality: modality,
            photoPath: photoPath,
            thumbPath: thumbPath,
            metadata: metadata,
            keySource: keySource,
            matchScore: matchScore,
            captureMs: captureMs,
            status: status,
            durationMin: durationMin,
            quantity: quantity,
            unit: unit,
            note: note,
            listItemId: listItemId,
            editedAt: editedAt,
            deletedAt: deletedAt,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$EventsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({keyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (keyId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.keyId,
                    referencedTable: $$EventsTableReferences._keyIdTable(db),
                    referencedColumn:
                        $$EventsTableReferences._keyIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$EventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, $$EventsTableReferences),
    Event,
    PrefetchHooks Function({bool keyId})>;
typedef $$ListItemsTableCreateCompanionBuilder = ListItemsCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> section,
  Value<int?> keyId,
  Value<int> sortOrder,
  Value<int?> doneEventId,
  Value<int?> plannedEventId,
  Value<DateTime> createdAt,
  Value<DateTime?> deletedAt,
});
typedef $$ListItemsTableUpdateCompanionBuilder = ListItemsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> section,
  Value<int?> keyId,
  Value<int> sortOrder,
  Value<int?> doneEventId,
  Value<int?> plannedEventId,
  Value<DateTime> createdAt,
  Value<DateTime?> deletedAt,
});

final class $$ListItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ListItemsTable, ListItem> {
  $$ListItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KeysTable _keyIdTable(_$AppDatabase db) =>
      db.keys.createAlias($_aliasNameGenerator(db.listItems.keyId, db.keys.id));

  $$KeysTableProcessedTableManager? get keyId {
    final $_column = $_itemColumn<int>('key_id');
    if ($_column == null) return null;
    final manager = $$KeysTableTableManager($_db, $_db.keys)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_keyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ListItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ListItemsTable> {
  $$ListItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get section => $composableBuilder(
      column: $table.section, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get doneEventId => $composableBuilder(
      column: $table.doneEventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannedEventId => $composableBuilder(
      column: $table.plannedEventId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$KeysTableFilterComposer get keyId {
    final $$KeysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableFilterComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ListItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ListItemsTable> {
  $$ListItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get section => $composableBuilder(
      column: $table.section, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get doneEventId => $composableBuilder(
      column: $table.doneEventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannedEventId => $composableBuilder(
      column: $table.plannedEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$KeysTableOrderingComposer get keyId {
    final $$KeysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableOrderingComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ListItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListItemsTable> {
  $$ListItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get doneEventId => $composableBuilder(
      column: $table.doneEventId, builder: (column) => column);

  GeneratedColumn<int> get plannedEventId => $composableBuilder(
      column: $table.plannedEventId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$KeysTableAnnotationComposer get keyId {
    final $$KeysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableAnnotationComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ListItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ListItemsTable,
    ListItem,
    $$ListItemsTableFilterComposer,
    $$ListItemsTableOrderingComposer,
    $$ListItemsTableAnnotationComposer,
    $$ListItemsTableCreateCompanionBuilder,
    $$ListItemsTableUpdateCompanionBuilder,
    (ListItem, $$ListItemsTableReferences),
    ListItem,
    PrefetchHooks Function({bool keyId})> {
  $$ListItemsTableTableManager(_$AppDatabase db, $ListItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> section = const Value.absent(),
            Value<int?> keyId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> doneEventId = const Value.absent(),
            Value<int?> plannedEventId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              ListItemsCompanion(
            id: id,
            title: title,
            section: section,
            keyId: keyId,
            sortOrder: sortOrder,
            doneEventId: doneEventId,
            plannedEventId: plannedEventId,
            createdAt: createdAt,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String?> section = const Value.absent(),
            Value<int?> keyId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> doneEventId = const Value.absent(),
            Value<int?> plannedEventId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              ListItemsCompanion.insert(
            id: id,
            title: title,
            section: section,
            keyId: keyId,
            sortOrder: sortOrder,
            doneEventId: doneEventId,
            plannedEventId: plannedEventId,
            createdAt: createdAt,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ListItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({keyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (keyId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.keyId,
                    referencedTable: $$ListItemsTableReferences._keyIdTable(db),
                    referencedColumn:
                        $$ListItemsTableReferences._keyIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ListItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ListItemsTable,
    ListItem,
    $$ListItemsTableFilterComposer,
    $$ListItemsTableOrderingComposer,
    $$ListItemsTableAnnotationComposer,
    $$ListItemsTableCreateCompanionBuilder,
    $$ListItemsTableUpdateCompanionBuilder,
    (ListItem, $$ListItemsTableReferences),
    ListItem,
    PrefetchHooks Function({bool keyId})>;
typedef $$CorrectionsTableCreateCompanionBuilder = CorrectionsCompanion
    Function({
  Value<int> id,
  required String rawText,
  required String field,
  Value<String?> predicted,
  required String corrected,
  Value<DateTime> createdAt,
});
typedef $$CorrectionsTableUpdateCompanionBuilder = CorrectionsCompanion
    Function({
  Value<int> id,
  Value<String> rawText,
  Value<String> field,
  Value<String?> predicted,
  Value<String> corrected,
  Value<DateTime> createdAt,
});

class $$CorrectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CorrectionsTable> {
  $$CorrectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawText => $composableBuilder(
      column: $table.rawText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get field => $composableBuilder(
      column: $table.field, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get predicted => $composableBuilder(
      column: $table.predicted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get corrected => $composableBuilder(
      column: $table.corrected, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CorrectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CorrectionsTable> {
  $$CorrectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawText => $composableBuilder(
      column: $table.rawText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get field => $composableBuilder(
      column: $table.field, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get predicted => $composableBuilder(
      column: $table.predicted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get corrected => $composableBuilder(
      column: $table.corrected, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CorrectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CorrectionsTable> {
  $$CorrectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get predicted =>
      $composableBuilder(column: $table.predicted, builder: (column) => column);

  GeneratedColumn<String> get corrected =>
      $composableBuilder(column: $table.corrected, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CorrectionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CorrectionsTable,
    Correction,
    $$CorrectionsTableFilterComposer,
    $$CorrectionsTableOrderingComposer,
    $$CorrectionsTableAnnotationComposer,
    $$CorrectionsTableCreateCompanionBuilder,
    $$CorrectionsTableUpdateCompanionBuilder,
    (Correction, BaseReferences<_$AppDatabase, $CorrectionsTable, Correction>),
    Correction,
    PrefetchHooks Function()> {
  $$CorrectionsTableTableManager(_$AppDatabase db, $CorrectionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CorrectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CorrectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CorrectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> rawText = const Value.absent(),
            Value<String> field = const Value.absent(),
            Value<String?> predicted = const Value.absent(),
            Value<String> corrected = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CorrectionsCompanion(
            id: id,
            rawText: rawText,
            field: field,
            predicted: predicted,
            corrected: corrected,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String rawText,
            required String field,
            Value<String?> predicted = const Value.absent(),
            required String corrected,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CorrectionsCompanion.insert(
            id: id,
            rawText: rawText,
            field: field,
            predicted: predicted,
            corrected: corrected,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CorrectionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CorrectionsTable,
    Correction,
    $$CorrectionsTableFilterComposer,
    $$CorrectionsTableOrderingComposer,
    $$CorrectionsTableAnnotationComposer,
    $$CorrectionsTableCreateCompanionBuilder,
    $$CorrectionsTableUpdateCompanionBuilder,
    (Correction, BaseReferences<_$AppDatabase, $CorrectionsTable, Correction>),
    Correction,
    PrefetchHooks Function()>;
typedef $$KeyExamplesTableCreateCompanionBuilder = KeyExamplesCompanion
    Function({
  Value<int> id,
  required int keyId,
  required String exampleText,
  required Uint8List vector,
  required String source,
  Value<DateTime> createdAt,
});
typedef $$KeyExamplesTableUpdateCompanionBuilder = KeyExamplesCompanion
    Function({
  Value<int> id,
  Value<int> keyId,
  Value<String> exampleText,
  Value<Uint8List> vector,
  Value<String> source,
  Value<DateTime> createdAt,
});

final class $$KeyExamplesTableReferences
    extends BaseReferences<_$AppDatabase, $KeyExamplesTable, KeyExample> {
  $$KeyExamplesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KeysTable _keyIdTable(_$AppDatabase db) => db.keys
      .createAlias($_aliasNameGenerator(db.keyExamples.keyId, db.keys.id));

  $$KeysTableProcessedTableManager get keyId {
    final $_column = $_itemColumn<int>('key_id')!;

    final manager = $$KeysTableTableManager($_db, $_db.keys)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_keyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$KeyExamplesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyExamplesTable> {
  $$KeyExamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exampleText => $composableBuilder(
      column: $table.exampleText, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get vector => $composableBuilder(
      column: $table.vector, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$KeysTableFilterComposer get keyId {
    final $$KeysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableFilterComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$KeyExamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyExamplesTable> {
  $$KeyExamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exampleText => $composableBuilder(
      column: $table.exampleText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get vector => $composableBuilder(
      column: $table.vector, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$KeysTableOrderingComposer get keyId {
    final $$KeysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableOrderingComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$KeyExamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyExamplesTable> {
  $$KeyExamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exampleText => $composableBuilder(
      column: $table.exampleText, builder: (column) => column);

  GeneratedColumn<Uint8List> get vector =>
      $composableBuilder(column: $table.vector, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$KeysTableAnnotationComposer get keyId {
    final $$KeysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableAnnotationComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$KeyExamplesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KeyExamplesTable,
    KeyExample,
    $$KeyExamplesTableFilterComposer,
    $$KeyExamplesTableOrderingComposer,
    $$KeyExamplesTableAnnotationComposer,
    $$KeyExamplesTableCreateCompanionBuilder,
    $$KeyExamplesTableUpdateCompanionBuilder,
    (KeyExample, $$KeyExamplesTableReferences),
    KeyExample,
    PrefetchHooks Function({bool keyId})> {
  $$KeyExamplesTableTableManager(_$AppDatabase db, $KeyExamplesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyExamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyExamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyExamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> keyId = const Value.absent(),
            Value<String> exampleText = const Value.absent(),
            Value<Uint8List> vector = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              KeyExamplesCompanion(
            id: id,
            keyId: keyId,
            exampleText: exampleText,
            vector: vector,
            source: source,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int keyId,
            required String exampleText,
            required Uint8List vector,
            required String source,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              KeyExamplesCompanion.insert(
            id: id,
            keyId: keyId,
            exampleText: exampleText,
            vector: vector,
            source: source,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$KeyExamplesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({keyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (keyId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.keyId,
                    referencedTable:
                        $$KeyExamplesTableReferences._keyIdTable(db),
                    referencedColumn:
                        $$KeyExamplesTableReferences._keyIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$KeyExamplesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KeyExamplesTable,
    KeyExample,
    $$KeyExamplesTableFilterComposer,
    $$KeyExamplesTableOrderingComposer,
    $$KeyExamplesTableAnnotationComposer,
    $$KeyExamplesTableCreateCompanionBuilder,
    $$KeyExamplesTableUpdateCompanionBuilder,
    (KeyExample, $$KeyExamplesTableReferences),
    KeyExample,
    PrefetchHooks Function({bool keyId})>;
typedef $$DaySummariesTableCreateCompanionBuilder = DaySummariesCompanion
    Function({
  required String dayDate,
  required String summary,
  Value<String?> flags,
  required int eventCount,
  Value<DateTime> closedAt,
  Value<int> rowid,
});
typedef $$DaySummariesTableUpdateCompanionBuilder = DaySummariesCompanion
    Function({
  Value<String> dayDate,
  Value<String> summary,
  Value<String?> flags,
  Value<int> eventCount,
  Value<DateTime> closedAt,
  Value<int> rowid,
});

class $$DaySummariesTableFilterComposer
    extends Composer<_$AppDatabase, $DaySummariesTable> {
  $$DaySummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dayDate => $composableBuilder(
      column: $table.dayDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get flags => $composableBuilder(
      column: $table.flags, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get eventCount => $composableBuilder(
      column: $table.eventCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnFilters(column));
}

class $$DaySummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $DaySummariesTable> {
  $$DaySummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dayDate => $composableBuilder(
      column: $table.dayDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get flags => $composableBuilder(
      column: $table.flags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get eventCount => $composableBuilder(
      column: $table.eventCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnOrderings(column));
}

class $$DaySummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DaySummariesTable> {
  $$DaySummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dayDate =>
      $composableBuilder(column: $table.dayDate, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get flags =>
      $composableBuilder(column: $table.flags, builder: (column) => column);

  GeneratedColumn<int> get eventCount => $composableBuilder(
      column: $table.eventCount, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);
}

class $$DaySummariesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DaySummariesTable,
    DaySummary,
    $$DaySummariesTableFilterComposer,
    $$DaySummariesTableOrderingComposer,
    $$DaySummariesTableAnnotationComposer,
    $$DaySummariesTableCreateCompanionBuilder,
    $$DaySummariesTableUpdateCompanionBuilder,
    (DaySummary, BaseReferences<_$AppDatabase, $DaySummariesTable, DaySummary>),
    DaySummary,
    PrefetchHooks Function()> {
  $$DaySummariesTableTableManager(_$AppDatabase db, $DaySummariesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DaySummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DaySummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DaySummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> dayDate = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<String?> flags = const Value.absent(),
            Value<int> eventCount = const Value.absent(),
            Value<DateTime> closedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DaySummariesCompanion(
            dayDate: dayDate,
            summary: summary,
            flags: flags,
            eventCount: eventCount,
            closedAt: closedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String dayDate,
            required String summary,
            Value<String?> flags = const Value.absent(),
            required int eventCount,
            Value<DateTime> closedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DaySummariesCompanion.insert(
            dayDate: dayDate,
            summary: summary,
            flags: flags,
            eventCount: eventCount,
            closedAt: closedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DaySummariesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DaySummariesTable,
    DaySummary,
    $$DaySummariesTableFilterComposer,
    $$DaySummariesTableOrderingComposer,
    $$DaySummariesTableAnnotationComposer,
    $$DaySummariesTableCreateCompanionBuilder,
    $$DaySummariesTableUpdateCompanionBuilder,
    (DaySummary, BaseReferences<_$AppDatabase, $DaySummariesTable, DaySummary>),
    DaySummary,
    PrefetchHooks Function()>;
typedef $$KeyAnalysesTableCreateCompanionBuilder = KeyAnalysesCompanion
    Function({
  Value<int> keyId,
  required String analysis,
  Value<String?> stats,
  required DateTime updatedAt,
});
typedef $$KeyAnalysesTableUpdateCompanionBuilder = KeyAnalysesCompanion
    Function({
  Value<int> keyId,
  Value<String> analysis,
  Value<String?> stats,
  Value<DateTime> updatedAt,
});

final class $$KeyAnalysesTableReferences
    extends BaseReferences<_$AppDatabase, $KeyAnalysesTable, KeyAnalyse> {
  $$KeyAnalysesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KeysTable _keyIdTable(_$AppDatabase db) => db.keys
      .createAlias($_aliasNameGenerator(db.keyAnalyses.keyId, db.keys.id));

  $$KeysTableProcessedTableManager get keyId {
    final $_column = $_itemColumn<int>('key_id')!;

    final manager = $$KeysTableTableManager($_db, $_db.keys)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_keyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$KeyAnalysesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyAnalysesTable> {
  $$KeyAnalysesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get analysis => $composableBuilder(
      column: $table.analysis, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stats => $composableBuilder(
      column: $table.stats, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$KeysTableFilterComposer get keyId {
    final $$KeysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableFilterComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$KeyAnalysesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyAnalysesTable> {
  $$KeyAnalysesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get analysis => $composableBuilder(
      column: $table.analysis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stats => $composableBuilder(
      column: $table.stats, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$KeysTableOrderingComposer get keyId {
    final $$KeysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableOrderingComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$KeyAnalysesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyAnalysesTable> {
  $$KeyAnalysesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get analysis =>
      $composableBuilder(column: $table.analysis, builder: (column) => column);

  GeneratedColumn<String> get stats =>
      $composableBuilder(column: $table.stats, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$KeysTableAnnotationComposer get keyId {
    final $$KeysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableAnnotationComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$KeyAnalysesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KeyAnalysesTable,
    KeyAnalyse,
    $$KeyAnalysesTableFilterComposer,
    $$KeyAnalysesTableOrderingComposer,
    $$KeyAnalysesTableAnnotationComposer,
    $$KeyAnalysesTableCreateCompanionBuilder,
    $$KeyAnalysesTableUpdateCompanionBuilder,
    (KeyAnalyse, $$KeyAnalysesTableReferences),
    KeyAnalyse,
    PrefetchHooks Function({bool keyId})> {
  $$KeyAnalysesTableTableManager(_$AppDatabase db, $KeyAnalysesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyAnalysesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyAnalysesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyAnalysesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> keyId = const Value.absent(),
            Value<String> analysis = const Value.absent(),
            Value<String?> stats = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              KeyAnalysesCompanion(
            keyId: keyId,
            analysis: analysis,
            stats: stats,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> keyId = const Value.absent(),
            required String analysis,
            Value<String?> stats = const Value.absent(),
            required DateTime updatedAt,
          }) =>
              KeyAnalysesCompanion.insert(
            keyId: keyId,
            analysis: analysis,
            stats: stats,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$KeyAnalysesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({keyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (keyId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.keyId,
                    referencedTable:
                        $$KeyAnalysesTableReferences._keyIdTable(db),
                    referencedColumn:
                        $$KeyAnalysesTableReferences._keyIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$KeyAnalysesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KeyAnalysesTable,
    KeyAnalyse,
    $$KeyAnalysesTableFilterComposer,
    $$KeyAnalysesTableOrderingComposer,
    $$KeyAnalysesTableAnnotationComposer,
    $$KeyAnalysesTableCreateCompanionBuilder,
    $$KeyAnalysesTableUpdateCompanionBuilder,
    (KeyAnalyse, $$KeyAnalysesTableReferences),
    KeyAnalyse,
    PrefetchHooks Function({bool keyId})>;
typedef $$PeriodSummariesTableCreateCompanionBuilder = PeriodSummariesCompanion
    Function({
  Value<int> id,
  required String period,
  required String startDate,
  required String endDate,
  required String summary,
});
typedef $$PeriodSummariesTableUpdateCompanionBuilder = PeriodSummariesCompanion
    Function({
  Value<int> id,
  Value<String> period,
  Value<String> startDate,
  Value<String> endDate,
  Value<String> summary,
});

class $$PeriodSummariesTableFilterComposer
    extends Composer<_$AppDatabase, $PeriodSummariesTable> {
  $$PeriodSummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));
}

class $$PeriodSummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $PeriodSummariesTable> {
  $$PeriodSummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));
}

class $$PeriodSummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeriodSummariesTable> {
  $$PeriodSummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);
}

class $$PeriodSummariesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PeriodSummariesTable,
    PeriodSummary,
    $$PeriodSummariesTableFilterComposer,
    $$PeriodSummariesTableOrderingComposer,
    $$PeriodSummariesTableAnnotationComposer,
    $$PeriodSummariesTableCreateCompanionBuilder,
    $$PeriodSummariesTableUpdateCompanionBuilder,
    (
      PeriodSummary,
      BaseReferences<_$AppDatabase, $PeriodSummariesTable, PeriodSummary>
    ),
    PeriodSummary,
    PrefetchHooks Function()> {
  $$PeriodSummariesTableTableManager(
      _$AppDatabase db, $PeriodSummariesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodSummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodSummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeriodSummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> period = const Value.absent(),
            Value<String> startDate = const Value.absent(),
            Value<String> endDate = const Value.absent(),
            Value<String> summary = const Value.absent(),
          }) =>
              PeriodSummariesCompanion(
            id: id,
            period: period,
            startDate: startDate,
            endDate: endDate,
            summary: summary,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String period,
            required String startDate,
            required String endDate,
            required String summary,
          }) =>
              PeriodSummariesCompanion.insert(
            id: id,
            period: period,
            startDate: startDate,
            endDate: endDate,
            summary: summary,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PeriodSummariesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PeriodSummariesTable,
    PeriodSummary,
    $$PeriodSummariesTableFilterComposer,
    $$PeriodSummariesTableOrderingComposer,
    $$PeriodSummariesTableAnnotationComposer,
    $$PeriodSummariesTableCreateCompanionBuilder,
    $$PeriodSummariesTableUpdateCompanionBuilder,
    (
      PeriodSummary,
      BaseReferences<_$AppDatabase, $PeriodSummariesTable, PeriodSummary>
    ),
    PeriodSummary,
    PrefetchHooks Function()>;
typedef $$RecurrencesTableCreateCompanionBuilder = RecurrencesCompanion
    Function({
  Value<int> id,
  required int keyId,
  required int dayOfWeek,
  required String windowStart,
  required String windowEnd,
  required String status,
  required double confidence,
  Value<int> hitCount,
  Value<int> consecutiveMisses,
  Value<DateTime> createdAt,
});
typedef $$RecurrencesTableUpdateCompanionBuilder = RecurrencesCompanion
    Function({
  Value<int> id,
  Value<int> keyId,
  Value<int> dayOfWeek,
  Value<String> windowStart,
  Value<String> windowEnd,
  Value<String> status,
  Value<double> confidence,
  Value<int> hitCount,
  Value<int> consecutiveMisses,
  Value<DateTime> createdAt,
});

final class $$RecurrencesTableReferences
    extends BaseReferences<_$AppDatabase, $RecurrencesTable, Recurrence> {
  $$RecurrencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KeysTable _keyIdTable(_$AppDatabase db) => db.keys
      .createAlias($_aliasNameGenerator(db.recurrences.keyId, db.keys.id));

  $$KeysTableProcessedTableManager get keyId {
    final $_column = $_itemColumn<int>('key_id')!;

    final manager = $$KeysTableTableManager($_db, $_db.keys)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_keyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RecurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get windowStart => $composableBuilder(
      column: $table.windowStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get windowEnd => $composableBuilder(
      column: $table.windowEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hitCount => $composableBuilder(
      column: $table.hitCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get consecutiveMisses => $composableBuilder(
      column: $table.consecutiveMisses,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$KeysTableFilterComposer get keyId {
    final $$KeysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableFilterComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get windowStart => $composableBuilder(
      column: $table.windowStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get windowEnd => $composableBuilder(
      column: $table.windowEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hitCount => $composableBuilder(
      column: $table.hitCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get consecutiveMisses => $composableBuilder(
      column: $table.consecutiveMisses,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$KeysTableOrderingComposer get keyId {
    final $$KeysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableOrderingComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<String> get windowStart => $composableBuilder(
      column: $table.windowStart, builder: (column) => column);

  GeneratedColumn<String> get windowEnd =>
      $composableBuilder(column: $table.windowEnd, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<int> get hitCount =>
      $composableBuilder(column: $table.hitCount, builder: (column) => column);

  GeneratedColumn<int> get consecutiveMisses => $composableBuilder(
      column: $table.consecutiveMisses, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$KeysTableAnnotationComposer get keyId {
    final $$KeysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableAnnotationComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecurrencesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurrencesTable,
    Recurrence,
    $$RecurrencesTableFilterComposer,
    $$RecurrencesTableOrderingComposer,
    $$RecurrencesTableAnnotationComposer,
    $$RecurrencesTableCreateCompanionBuilder,
    $$RecurrencesTableUpdateCompanionBuilder,
    (Recurrence, $$RecurrencesTableReferences),
    Recurrence,
    PrefetchHooks Function({bool keyId})> {
  $$RecurrencesTableTableManager(_$AppDatabase db, $RecurrencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> keyId = const Value.absent(),
            Value<int> dayOfWeek = const Value.absent(),
            Value<String> windowStart = const Value.absent(),
            Value<String> windowEnd = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double> confidence = const Value.absent(),
            Value<int> hitCount = const Value.absent(),
            Value<int> consecutiveMisses = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RecurrencesCompanion(
            id: id,
            keyId: keyId,
            dayOfWeek: dayOfWeek,
            windowStart: windowStart,
            windowEnd: windowEnd,
            status: status,
            confidence: confidence,
            hitCount: hitCount,
            consecutiveMisses: consecutiveMisses,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int keyId,
            required int dayOfWeek,
            required String windowStart,
            required String windowEnd,
            required String status,
            required double confidence,
            Value<int> hitCount = const Value.absent(),
            Value<int> consecutiveMisses = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RecurrencesCompanion.insert(
            id: id,
            keyId: keyId,
            dayOfWeek: dayOfWeek,
            windowStart: windowStart,
            windowEnd: windowEnd,
            status: status,
            confidence: confidence,
            hitCount: hitCount,
            consecutiveMisses: consecutiveMisses,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RecurrencesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({keyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (keyId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.keyId,
                    referencedTable:
                        $$RecurrencesTableReferences._keyIdTable(db),
                    referencedColumn:
                        $$RecurrencesTableReferences._keyIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RecurrencesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecurrencesTable,
    Recurrence,
    $$RecurrencesTableFilterComposer,
    $$RecurrencesTableOrderingComposer,
    $$RecurrencesTableAnnotationComposer,
    $$RecurrencesTableCreateCompanionBuilder,
    $$RecurrencesTableUpdateCompanionBuilder,
    (Recurrence, $$RecurrencesTableReferences),
    Recurrence,
    PrefetchHooks Function({bool keyId})>;
typedef $$RecurrenceSuppressionsTableCreateCompanionBuilder
    = RecurrenceSuppressionsCompanion Function({
  required int keyId,
  required int dayOfWeek,
  required String windowStart,
  required String windowEnd,
  Value<DateTime> suppressedAt,
  Value<int> rowid,
});
typedef $$RecurrenceSuppressionsTableUpdateCompanionBuilder
    = RecurrenceSuppressionsCompanion Function({
  Value<int> keyId,
  Value<int> dayOfWeek,
  Value<String> windowStart,
  Value<String> windowEnd,
  Value<DateTime> suppressedAt,
  Value<int> rowid,
});

final class $$RecurrenceSuppressionsTableReferences extends BaseReferences<
    _$AppDatabase, $RecurrenceSuppressionsTable, RecurrenceSuppression> {
  $$RecurrenceSuppressionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $KeysTable _keyIdTable(_$AppDatabase db) => db.keys.createAlias(
      $_aliasNameGenerator(db.recurrenceSuppressions.keyId, db.keys.id));

  $$KeysTableProcessedTableManager get keyId {
    final $_column = $_itemColumn<int>('key_id')!;

    final manager = $$KeysTableTableManager($_db, $_db.keys)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_keyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RecurrenceSuppressionsTableFilterComposer
    extends Composer<_$AppDatabase, $RecurrenceSuppressionsTable> {
  $$RecurrenceSuppressionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get windowStart => $composableBuilder(
      column: $table.windowStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get windowEnd => $composableBuilder(
      column: $table.windowEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get suppressedAt => $composableBuilder(
      column: $table.suppressedAt, builder: (column) => ColumnFilters(column));

  $$KeysTableFilterComposer get keyId {
    final $$KeysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableFilterComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecurrenceSuppressionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurrenceSuppressionsTable> {
  $$RecurrenceSuppressionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get windowStart => $composableBuilder(
      column: $table.windowStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get windowEnd => $composableBuilder(
      column: $table.windowEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get suppressedAt => $composableBuilder(
      column: $table.suppressedAt,
      builder: (column) => ColumnOrderings(column));

  $$KeysTableOrderingComposer get keyId {
    final $$KeysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableOrderingComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecurrenceSuppressionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurrenceSuppressionsTable> {
  $$RecurrenceSuppressionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<String> get windowStart => $composableBuilder(
      column: $table.windowStart, builder: (column) => column);

  GeneratedColumn<String> get windowEnd =>
      $composableBuilder(column: $table.windowEnd, builder: (column) => column);

  GeneratedColumn<DateTime> get suppressedAt => $composableBuilder(
      column: $table.suppressedAt, builder: (column) => column);

  $$KeysTableAnnotationComposer get keyId {
    final $$KeysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableAnnotationComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecurrenceSuppressionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurrenceSuppressionsTable,
    RecurrenceSuppression,
    $$RecurrenceSuppressionsTableFilterComposer,
    $$RecurrenceSuppressionsTableOrderingComposer,
    $$RecurrenceSuppressionsTableAnnotationComposer,
    $$RecurrenceSuppressionsTableCreateCompanionBuilder,
    $$RecurrenceSuppressionsTableUpdateCompanionBuilder,
    (RecurrenceSuppression, $$RecurrenceSuppressionsTableReferences),
    RecurrenceSuppression,
    PrefetchHooks Function({bool keyId})> {
  $$RecurrenceSuppressionsTableTableManager(
      _$AppDatabase db, $RecurrenceSuppressionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurrenceSuppressionsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurrenceSuppressionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurrenceSuppressionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> keyId = const Value.absent(),
            Value<int> dayOfWeek = const Value.absent(),
            Value<String> windowStart = const Value.absent(),
            Value<String> windowEnd = const Value.absent(),
            Value<DateTime> suppressedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurrenceSuppressionsCompanion(
            keyId: keyId,
            dayOfWeek: dayOfWeek,
            windowStart: windowStart,
            windowEnd: windowEnd,
            suppressedAt: suppressedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int keyId,
            required int dayOfWeek,
            required String windowStart,
            required String windowEnd,
            Value<DateTime> suppressedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurrenceSuppressionsCompanion.insert(
            keyId: keyId,
            dayOfWeek: dayOfWeek,
            windowStart: windowStart,
            windowEnd: windowEnd,
            suppressedAt: suppressedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RecurrenceSuppressionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({keyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (keyId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.keyId,
                    referencedTable:
                        $$RecurrenceSuppressionsTableReferences._keyIdTable(db),
                    referencedColumn: $$RecurrenceSuppressionsTableReferences
                        ._keyIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RecurrenceSuppressionsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $RecurrenceSuppressionsTable,
        RecurrenceSuppression,
        $$RecurrenceSuppressionsTableFilterComposer,
        $$RecurrenceSuppressionsTableOrderingComposer,
        $$RecurrenceSuppressionsTableAnnotationComposer,
        $$RecurrenceSuppressionsTableCreateCompanionBuilder,
        $$RecurrenceSuppressionsTableUpdateCompanionBuilder,
        (RecurrenceSuppression, $$RecurrenceSuppressionsTableReferences),
        RecurrenceSuppression,
        PrefetchHooks Function({bool keyId})>;
typedef $$FutureEntriesTableCreateCompanionBuilder = FutureEntriesCompanion
    Function({
  Value<int> id,
  required String entryDate,
  Value<int?> keyId,
  required String title,
  Value<String?> timeHint,
  required String source,
  Value<String?> metadata,
  Value<DateTime> createdAt,
});
typedef $$FutureEntriesTableUpdateCompanionBuilder = FutureEntriesCompanion
    Function({
  Value<int> id,
  Value<String> entryDate,
  Value<int?> keyId,
  Value<String> title,
  Value<String?> timeHint,
  Value<String> source,
  Value<String?> metadata,
  Value<DateTime> createdAt,
});

final class $$FutureEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $FutureEntriesTable, FutureEntry> {
  $$FutureEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $KeysTable _keyIdTable(_$AppDatabase db) => db.keys
      .createAlias($_aliasNameGenerator(db.futureEntries.keyId, db.keys.id));

  $$KeysTableProcessedTableManager? get keyId {
    final $_column = $_itemColumn<int>('key_id');
    if ($_column == null) return null;
    final manager = $$KeysTableTableManager($_db, $_db.keys)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_keyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$FutureEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FutureEntriesTable> {
  $$FutureEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entryDate => $composableBuilder(
      column: $table.entryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timeHint => $composableBuilder(
      column: $table.timeHint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$KeysTableFilterComposer get keyId {
    final $$KeysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableFilterComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FutureEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FutureEntriesTable> {
  $$FutureEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entryDate => $composableBuilder(
      column: $table.entryDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timeHint => $composableBuilder(
      column: $table.timeHint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$KeysTableOrderingComposer get keyId {
    final $$KeysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableOrderingComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FutureEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FutureEntriesTable> {
  $$FutureEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryDate =>
      $composableBuilder(column: $table.entryDate, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get timeHint =>
      $composableBuilder(column: $table.timeHint, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$KeysTableAnnotationComposer get keyId {
    final $$KeysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyId,
        referencedTable: $db.keys,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KeysTableAnnotationComposer(
              $db: $db,
              $table: $db.keys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FutureEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FutureEntriesTable,
    FutureEntry,
    $$FutureEntriesTableFilterComposer,
    $$FutureEntriesTableOrderingComposer,
    $$FutureEntriesTableAnnotationComposer,
    $$FutureEntriesTableCreateCompanionBuilder,
    $$FutureEntriesTableUpdateCompanionBuilder,
    (FutureEntry, $$FutureEntriesTableReferences),
    FutureEntry,
    PrefetchHooks Function({bool keyId})> {
  $$FutureEntriesTableTableManager(_$AppDatabase db, $FutureEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FutureEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FutureEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FutureEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entryDate = const Value.absent(),
            Value<int?> keyId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> timeHint = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              FutureEntriesCompanion(
            id: id,
            entryDate: entryDate,
            keyId: keyId,
            title: title,
            timeHint: timeHint,
            source: source,
            metadata: metadata,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entryDate,
            Value<int?> keyId = const Value.absent(),
            required String title,
            Value<String?> timeHint = const Value.absent(),
            required String source,
            Value<String?> metadata = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              FutureEntriesCompanion.insert(
            id: id,
            entryDate: entryDate,
            keyId: keyId,
            title: title,
            timeHint: timeHint,
            source: source,
            metadata: metadata,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FutureEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({keyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (keyId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.keyId,
                    referencedTable:
                        $$FutureEntriesTableReferences._keyIdTable(db),
                    referencedColumn:
                        $$FutureEntriesTableReferences._keyIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$FutureEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FutureEntriesTable,
    FutureEntry,
    $$FutureEntriesTableFilterComposer,
    $$FutureEntriesTableOrderingComposer,
    $$FutureEntriesTableAnnotationComposer,
    $$FutureEntriesTableCreateCompanionBuilder,
    $$FutureEntriesTableUpdateCompanionBuilder,
    (FutureEntry, $$FutureEntriesTableReferences),
    FutureEntry,
    PrefetchHooks Function({bool keyId})>;
typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  required String planDate,
  required String draft,
  Value<String?> finalPlan,
  Value<DateTime> createdAt,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  Value<String> planDate,
  Value<String> draft,
  Value<String?> finalPlan,
  Value<DateTime> createdAt,
});

class $$PlansTableFilterComposer extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planDate => $composableBuilder(
      column: $table.planDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get draft => $composableBuilder(
      column: $table.draft, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get finalPlan => $composableBuilder(
      column: $table.finalPlan, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PlansTableOrderingComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planDate => $composableBuilder(
      column: $table.planDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get draft => $composableBuilder(
      column: $table.draft, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get finalPlan => $composableBuilder(
      column: $table.finalPlan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planDate =>
      $composableBuilder(column: $table.planDate, builder: (column) => column);

  GeneratedColumn<String> get draft =>
      $composableBuilder(column: $table.draft, builder: (column) => column);

  GeneratedColumn<String> get finalPlan =>
      $composableBuilder(column: $table.finalPlan, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlansTable,
    Plan,
    $$PlansTableFilterComposer,
    $$PlansTableOrderingComposer,
    $$PlansTableAnnotationComposer,
    $$PlansTableCreateCompanionBuilder,
    $$PlansTableUpdateCompanionBuilder,
    (Plan, BaseReferences<_$AppDatabase, $PlansTable, Plan>),
    Plan,
    PrefetchHooks Function()> {
  $$PlansTableTableManager(_$AppDatabase db, $PlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> planDate = const Value.absent(),
            Value<String> draft = const Value.absent(),
            Value<String?> finalPlan = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PlansCompanion(
            id: id,
            planDate: planDate,
            draft: draft,
            finalPlan: finalPlan,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String planDate,
            required String draft,
            Value<String?> finalPlan = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PlansCompanion.insert(
            id: id,
            planDate: planDate,
            draft: draft,
            finalPlan: finalPlan,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlansTable,
    Plan,
    $$PlansTableFilterComposer,
    $$PlansTableOrderingComposer,
    $$PlansTableAnnotationComposer,
    $$PlansTableCreateCompanionBuilder,
    $$PlansTableUpdateCompanionBuilder,
    (Plan, BaseReferences<_$AppDatabase, $PlansTable, Plan>),
    Plan,
    PrefetchHooks Function()>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String k,
  required String v,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> k,
  Value<String> v,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get k => $composableBuilder(
      column: $table.k, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get v => $composableBuilder(
      column: $table.v, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get k => $composableBuilder(
      column: $table.k, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get v => $composableBuilder(
      column: $table.v, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get k =>
      $composableBuilder(column: $table.k, builder: (column) => column);

  GeneratedColumn<String> get v =>
      $composableBuilder(column: $table.v, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> k = const Value.absent(),
            Value<String> v = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            k: k,
            v: v,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String k,
            required String v,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            k: k,
            v: v,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KeysTableTableManager get keys => $$KeysTableTableManager(_db, _db.keys);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$ListItemsTableTableManager get listItems =>
      $$ListItemsTableTableManager(_db, _db.listItems);
  $$CorrectionsTableTableManager get corrections =>
      $$CorrectionsTableTableManager(_db, _db.corrections);
  $$KeyExamplesTableTableManager get keyExamples =>
      $$KeyExamplesTableTableManager(_db, _db.keyExamples);
  $$DaySummariesTableTableManager get daySummaries =>
      $$DaySummariesTableTableManager(_db, _db.daySummaries);
  $$KeyAnalysesTableTableManager get keyAnalyses =>
      $$KeyAnalysesTableTableManager(_db, _db.keyAnalyses);
  $$PeriodSummariesTableTableManager get periodSummaries =>
      $$PeriodSummariesTableTableManager(_db, _db.periodSummaries);
  $$RecurrencesTableTableManager get recurrences =>
      $$RecurrencesTableTableManager(_db, _db.recurrences);
  $$RecurrenceSuppressionsTableTableManager get recurrenceSuppressions =>
      $$RecurrenceSuppressionsTableTableManager(
          _db, _db.recurrenceSuppressions);
  $$FutureEntriesTableTableManager get futureEntries =>
      $$FutureEntriesTableTableManager(_db, _db.futureEntries);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
