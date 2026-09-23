// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $HistoryEntriesTable extends HistoryEntries
    with TableInfo<$HistoryEntriesTable, HistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fromLocationMeta = const VerificationMeta(
    'fromLocation',
  );
  @override
  late final GeneratedColumn<String> fromLocation = GeneratedColumn<String>(
    'from_location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toLocationMeta = const VerificationMeta(
    'toLocation',
  );
  @override
  late final GeneratedColumn<String> toLocation = GeneratedColumn<String>(
    'to_location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routeKeyMeta = const VerificationMeta(
    'routeKey',
  );
  @override
  late final GeneratedColumn<String> routeKey = GeneratedColumn<String>(
    'route_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _profileMeta = const VerificationMeta(
    'profile',
  );
  @override
  late final GeneratedColumn<String> profile = GeneratedColumn<String>(
    'profile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUsedMeta = const VerificationMeta(
    'lastUsed',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsed = GeneratedColumn<DateTime>(
    'last_used',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedResultMeta = const VerificationMeta(
    'cachedResult',
  );
  @override
  late final GeneratedColumn<String> cachedResult = GeneratedColumn<String>(
    'cached_result',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fromLocation,
    toLocation,
    routeKey,
    profile,
    lastUsed,
    cachedResult,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('from_location')) {
      context.handle(
        _fromLocationMeta,
        fromLocation.isAcceptableOrUnknown(
          data['from_location']!,
          _fromLocationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromLocationMeta);
    }
    if (data.containsKey('to_location')) {
      context.handle(
        _toLocationMeta,
        toLocation.isAcceptableOrUnknown(data['to_location']!, _toLocationMeta),
      );
    } else if (isInserting) {
      context.missing(_toLocationMeta);
    }
    if (data.containsKey('route_key')) {
      context.handle(
        _routeKeyMeta,
        routeKey.isAcceptableOrUnknown(data['route_key']!, _routeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_routeKeyMeta);
    }
    if (data.containsKey('profile')) {
      context.handle(
        _profileMeta,
        profile.isAcceptableOrUnknown(data['profile']!, _profileMeta),
      );
    }
    if (data.containsKey('last_used')) {
      context.handle(
        _lastUsedMeta,
        lastUsed.isAcceptableOrUnknown(data['last_used']!, _lastUsedMeta),
      );
    } else if (isInserting) {
      context.missing(_lastUsedMeta);
    }
    if (data.containsKey('cached_result')) {
      context.handle(
        _cachedResultMeta,
        cachedResult.isAcceptableOrUnknown(
          data['cached_result']!,
          _cachedResultMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fromLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_location'],
      )!,
      toLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_location'],
      )!,
      routeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_key'],
      )!,
      profile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile'],
      ),
      lastUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used'],
      )!,
      cachedResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_result'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      ),
    );
  }

  @override
  $HistoryEntriesTable createAlias(String alias) {
    return $HistoryEntriesTable(attachedDatabase, alias);
  }
}

class HistoryEntry extends DataClass implements Insertable<HistoryEntry> {
  final int id;

  /// Location als JSON.
  final String fromLocation;
  final String toLocation;

  /// Schlüssel aus Start- und Ziel-ID, damit eine Suche nur einmal steht.
  final String routeKey;
  final String? profile;
  final DateTime lastUsed;

  /// Letztes Ergebnis als JSON-Liste von Trips, für die Sofortanzeige.
  final String? cachedResult;
  final DateTime? cachedAt;
  const HistoryEntry({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.routeKey,
    this.profile,
    required this.lastUsed,
    this.cachedResult,
    this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['from_location'] = Variable<String>(fromLocation);
    map['to_location'] = Variable<String>(toLocation);
    map['route_key'] = Variable<String>(routeKey);
    if (!nullToAbsent || profile != null) {
      map['profile'] = Variable<String>(profile);
    }
    map['last_used'] = Variable<DateTime>(lastUsed);
    if (!nullToAbsent || cachedResult != null) {
      map['cached_result'] = Variable<String>(cachedResult);
    }
    if (!nullToAbsent || cachedAt != null) {
      map['cached_at'] = Variable<DateTime>(cachedAt);
    }
    return map;
  }

  HistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return HistoryEntriesCompanion(
      id: Value(id),
      fromLocation: Value(fromLocation),
      toLocation: Value(toLocation),
      routeKey: Value(routeKey),
      profile: profile == null && nullToAbsent
          ? const Value.absent()
          : Value(profile),
      lastUsed: Value(lastUsed),
      cachedResult: cachedResult == null && nullToAbsent
          ? const Value.absent()
          : Value(cachedResult),
      cachedAt: cachedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cachedAt),
    );
  }

  factory HistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryEntry(
      id: serializer.fromJson<int>(json['id']),
      fromLocation: serializer.fromJson<String>(json['fromLocation']),
      toLocation: serializer.fromJson<String>(json['toLocation']),
      routeKey: serializer.fromJson<String>(json['routeKey']),
      profile: serializer.fromJson<String?>(json['profile']),
      lastUsed: serializer.fromJson<DateTime>(json['lastUsed']),
      cachedResult: serializer.fromJson<String?>(json['cachedResult']),
      cachedAt: serializer.fromJson<DateTime?>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fromLocation': serializer.toJson<String>(fromLocation),
      'toLocation': serializer.toJson<String>(toLocation),
      'routeKey': serializer.toJson<String>(routeKey),
      'profile': serializer.toJson<String?>(profile),
      'lastUsed': serializer.toJson<DateTime>(lastUsed),
      'cachedResult': serializer.toJson<String?>(cachedResult),
      'cachedAt': serializer.toJson<DateTime?>(cachedAt),
    };
  }

  HistoryEntry copyWith({
    int? id,
    String? fromLocation,
    String? toLocation,
    String? routeKey,
    Value<String?> profile = const Value.absent(),
    DateTime? lastUsed,
    Value<String?> cachedResult = const Value.absent(),
    Value<DateTime?> cachedAt = const Value.absent(),
  }) => HistoryEntry(
    id: id ?? this.id,
    fromLocation: fromLocation ?? this.fromLocation,
    toLocation: toLocation ?? this.toLocation,
    routeKey: routeKey ?? this.routeKey,
    profile: profile.present ? profile.value : this.profile,
    lastUsed: lastUsed ?? this.lastUsed,
    cachedResult: cachedResult.present ? cachedResult.value : this.cachedResult,
    cachedAt: cachedAt.present ? cachedAt.value : this.cachedAt,
  );
  HistoryEntry copyWithCompanion(HistoryEntriesCompanion data) {
    return HistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      fromLocation: data.fromLocation.present
          ? data.fromLocation.value
          : this.fromLocation,
      toLocation: data.toLocation.present
          ? data.toLocation.value
          : this.toLocation,
      routeKey: data.routeKey.present ? data.routeKey.value : this.routeKey,
      profile: data.profile.present ? data.profile.value : this.profile,
      lastUsed: data.lastUsed.present ? data.lastUsed.value : this.lastUsed,
      cachedResult: data.cachedResult.present
          ? data.cachedResult.value
          : this.cachedResult,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryEntry(')
          ..write('id: $id, ')
          ..write('fromLocation: $fromLocation, ')
          ..write('toLocation: $toLocation, ')
          ..write('routeKey: $routeKey, ')
          ..write('profile: $profile, ')
          ..write('lastUsed: $lastUsed, ')
          ..write('cachedResult: $cachedResult, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fromLocation,
    toLocation,
    routeKey,
    profile,
    lastUsed,
    cachedResult,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryEntry &&
          other.id == this.id &&
          other.fromLocation == this.fromLocation &&
          other.toLocation == this.toLocation &&
          other.routeKey == this.routeKey &&
          other.profile == this.profile &&
          other.lastUsed == this.lastUsed &&
          other.cachedResult == this.cachedResult &&
          other.cachedAt == this.cachedAt);
}

class HistoryEntriesCompanion extends UpdateCompanion<HistoryEntry> {
  final Value<int> id;
  final Value<String> fromLocation;
  final Value<String> toLocation;
  final Value<String> routeKey;
  final Value<String?> profile;
  final Value<DateTime> lastUsed;
  final Value<String?> cachedResult;
  final Value<DateTime?> cachedAt;
  const HistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.fromLocation = const Value.absent(),
    this.toLocation = const Value.absent(),
    this.routeKey = const Value.absent(),
    this.profile = const Value.absent(),
    this.lastUsed = const Value.absent(),
    this.cachedResult = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  HistoryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String fromLocation,
    required String toLocation,
    required String routeKey,
    this.profile = const Value.absent(),
    required DateTime lastUsed,
    this.cachedResult = const Value.absent(),
    this.cachedAt = const Value.absent(),
  }) : fromLocation = Value(fromLocation),
       toLocation = Value(toLocation),
       routeKey = Value(routeKey),
       lastUsed = Value(lastUsed);
  static Insertable<HistoryEntry> custom({
    Expression<int>? id,
    Expression<String>? fromLocation,
    Expression<String>? toLocation,
    Expression<String>? routeKey,
    Expression<String>? profile,
    Expression<DateTime>? lastUsed,
    Expression<String>? cachedResult,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromLocation != null) 'from_location': fromLocation,
      if (toLocation != null) 'to_location': toLocation,
      if (routeKey != null) 'route_key': routeKey,
      if (profile != null) 'profile': profile,
      if (lastUsed != null) 'last_used': lastUsed,
      if (cachedResult != null) 'cached_result': cachedResult,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  HistoryEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? fromLocation,
    Value<String>? toLocation,
    Value<String>? routeKey,
    Value<String?>? profile,
    Value<DateTime>? lastUsed,
    Value<String?>? cachedResult,
    Value<DateTime?>? cachedAt,
  }) {
    return HistoryEntriesCompanion(
      id: id ?? this.id,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      routeKey: routeKey ?? this.routeKey,
      profile: profile ?? this.profile,
      lastUsed: lastUsed ?? this.lastUsed,
      cachedResult: cachedResult ?? this.cachedResult,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fromLocation.present) {
      map['from_location'] = Variable<String>(fromLocation.value);
    }
    if (toLocation.present) {
      map['to_location'] = Variable<String>(toLocation.value);
    }
    if (routeKey.present) {
      map['route_key'] = Variable<String>(routeKey.value);
    }
    if (profile.present) {
      map['profile'] = Variable<String>(profile.value);
    }
    if (lastUsed.present) {
      map['last_used'] = Variable<DateTime>(lastUsed.value);
    }
    if (cachedResult.present) {
      map['cached_result'] = Variable<String>(cachedResult.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('fromLocation: $fromLocation, ')
          ..write('toLocation: $toLocation, ')
          ..write('routeKey: $routeKey, ')
          ..write('profile: $profile, ')
          ..write('lastUsed: $lastUsed, ')
          ..write('cachedResult: $cachedResult, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refMeta = const VerificationMeta('ref');
  @override
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
    'ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    ref,
    name,
    payload,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('ref')) {
      context.handle(
        _refMeta,
        ref.isAcceptableOrUnknown(data['ref']!, _refMeta),
      );
    } else if (isInserting) {
      context.missing(_refMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      ref: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int id;

  /// 'route' oder 'stop'.
  final String kind;

  /// Verbindung: routeKey; Haltestelle: Location-ID.
  final String ref;
  final String name;

  /// Location(s) als JSON: bei 'route' {from, to}, bei 'stop' die Location.
  final String payload;
  final int sortOrder;
  const Favorite({
    required this.id,
    required this.kind,
    required this.ref,
    required this.name,
    required this.payload,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['ref'] = Variable<String>(ref);
    map['name'] = Variable<String>(name);
    map['payload'] = Variable<String>(payload);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      id: Value(id),
      kind: Value(kind),
      ref: Value(ref),
      name: Value(name),
      payload: Value(payload),
      sortOrder: Value(sortOrder),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      ref: serializer.fromJson<String>(json['ref']),
      name: serializer.fromJson<String>(json['name']),
      payload: serializer.fromJson<String>(json['payload']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'ref': serializer.toJson<String>(ref),
      'name': serializer.toJson<String>(name),
      'payload': serializer.toJson<String>(payload),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Favorite copyWith({
    int? id,
    String? kind,
    String? ref,
    String? name,
    String? payload,
    int? sortOrder,
  }) => Favorite(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    ref: ref ?? this.ref,
    name: name ?? this.name,
    payload: payload ?? this.payload,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      ref: data.ref.present ? data.ref.value : this.ref,
      name: data.name.present ? data.name.value : this.name,
      payload: data.payload.present ? data.payload.value : this.payload,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('ref: $ref, ')
          ..write('name: $name, ')
          ..write('payload: $payload, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, ref, name, payload, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.ref == this.ref &&
          other.name == this.name &&
          other.payload == this.payload &&
          other.sortOrder == this.sortOrder);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> ref;
  final Value<String> name;
  final Value<String> payload;
  final Value<int> sortOrder;
  const FavoritesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.ref = const Value.absent(),
    this.name = const Value.absent(),
    this.payload = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String ref,
    required String name,
    required String payload,
    this.sortOrder = const Value.absent(),
  }) : kind = Value(kind),
       ref = Value(ref),
       name = Value(name),
       payload = Value(payload);
  static Insertable<Favorite> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? ref,
    Expression<String>? name,
    Expression<String>? payload,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (ref != null) 'ref': ref,
      if (name != null) 'name': name,
      if (payload != null) 'payload': payload,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  FavoritesCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? ref,
    Value<String>? name,
    Value<String>? payload,
    Value<int>? sortOrder,
  }) {
    return FavoritesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      ref: ref ?? this.ref,
      name: name ?? this.name,
      payload: payload ?? this.payload,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('ref: $ref, ')
          ..write('name: $name, ')
          ..write('payload: $payload, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, SubscriptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lineIdMeta = const VerificationMeta('lineId');
  @override
  late final GeneratedColumn<String> lineId = GeneratedColumn<String>(
    'line_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineNameMeta = const VerificationMeta(
    'lineName',
  );
  @override
  late final GeneratedColumn<String> lineName = GeneratedColumn<String>(
    'line_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windowMeta = const VerificationMeta('window');
  @override
  late final GeneratedColumn<String> window = GeneratedColumn<String>(
    'window',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pushTopicMeta = const VerificationMeta(
    'pushTopic',
  );
  @override
  late final GeneratedColumn<String> pushTopic = GeneratedColumn<String>(
    'push_topic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    lineId,
    providerId,
    lineName,
    window,
    pushTopic,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubscriptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('line_id')) {
      context.handle(
        _lineIdMeta,
        lineId.isAcceptableOrUnknown(data['line_id']!, _lineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lineIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('line_name')) {
      context.handle(
        _lineNameMeta,
        lineName.isAcceptableOrUnknown(data['line_name']!, _lineNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lineNameMeta);
    }
    if (data.containsKey('window')) {
      context.handle(
        _windowMeta,
        window.isAcceptableOrUnknown(data['window']!, _windowMeta),
      );
    }
    if (data.containsKey('push_topic')) {
      context.handle(
        _pushTopicMeta,
        pushTopic.isAcceptableOrUnknown(data['push_topic']!, _pushTopicMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lineId, providerId};
  @override
  SubscriptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubscriptionRow(
      lineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      lineName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_name'],
      )!,
      window: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}window'],
      ),
      pushTopic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}push_topic'],
      ),
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }
}

class SubscriptionRow extends DataClass implements Insertable<SubscriptionRow> {
  final String lineId;
  final String providerId;
  final String lineName;
  final String? window;
  final String? pushTopic;
  const SubscriptionRow({
    required this.lineId,
    required this.providerId,
    required this.lineName,
    this.window,
    this.pushTopic,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['line_id'] = Variable<String>(lineId);
    map['provider_id'] = Variable<String>(providerId);
    map['line_name'] = Variable<String>(lineName);
    if (!nullToAbsent || window != null) {
      map['window'] = Variable<String>(window);
    }
    if (!nullToAbsent || pushTopic != null) {
      map['push_topic'] = Variable<String>(pushTopic);
    }
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      lineId: Value(lineId),
      providerId: Value(providerId),
      lineName: Value(lineName),
      window: window == null && nullToAbsent
          ? const Value.absent()
          : Value(window),
      pushTopic: pushTopic == null && nullToAbsent
          ? const Value.absent()
          : Value(pushTopic),
    );
  }

  factory SubscriptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubscriptionRow(
      lineId: serializer.fromJson<String>(json['lineId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      lineName: serializer.fromJson<String>(json['lineName']),
      window: serializer.fromJson<String?>(json['window']),
      pushTopic: serializer.fromJson<String?>(json['pushTopic']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lineId': serializer.toJson<String>(lineId),
      'providerId': serializer.toJson<String>(providerId),
      'lineName': serializer.toJson<String>(lineName),
      'window': serializer.toJson<String?>(window),
      'pushTopic': serializer.toJson<String?>(pushTopic),
    };
  }

  SubscriptionRow copyWith({
    String? lineId,
    String? providerId,
    String? lineName,
    Value<String?> window = const Value.absent(),
    Value<String?> pushTopic = const Value.absent(),
  }) => SubscriptionRow(
    lineId: lineId ?? this.lineId,
    providerId: providerId ?? this.providerId,
    lineName: lineName ?? this.lineName,
    window: window.present ? window.value : this.window,
    pushTopic: pushTopic.present ? pushTopic.value : this.pushTopic,
  );
  SubscriptionRow copyWithCompanion(SubscriptionsCompanion data) {
    return SubscriptionRow(
      lineId: data.lineId.present ? data.lineId.value : this.lineId,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      lineName: data.lineName.present ? data.lineName.value : this.lineName,
      window: data.window.present ? data.window.value : this.window,
      pushTopic: data.pushTopic.present ? data.pushTopic.value : this.pushTopic,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionRow(')
          ..write('lineId: $lineId, ')
          ..write('providerId: $providerId, ')
          ..write('lineName: $lineName, ')
          ..write('window: $window, ')
          ..write('pushTopic: $pushTopic')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(lineId, providerId, lineName, window, pushTopic);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubscriptionRow &&
          other.lineId == this.lineId &&
          other.providerId == this.providerId &&
          other.lineName == this.lineName &&
          other.window == this.window &&
          other.pushTopic == this.pushTopic);
}

class SubscriptionsCompanion extends UpdateCompanion<SubscriptionRow> {
  final Value<String> lineId;
  final Value<String> providerId;
  final Value<String> lineName;
  final Value<String?> window;
  final Value<String?> pushTopic;
  final Value<int> rowid;
  const SubscriptionsCompanion({
    this.lineId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.lineName = const Value.absent(),
    this.window = const Value.absent(),
    this.pushTopic = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    required String lineId,
    required String providerId,
    required String lineName,
    this.window = const Value.absent(),
    this.pushTopic = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : lineId = Value(lineId),
       providerId = Value(providerId),
       lineName = Value(lineName);
  static Insertable<SubscriptionRow> custom({
    Expression<String>? lineId,
    Expression<String>? providerId,
    Expression<String>? lineName,
    Expression<String>? window,
    Expression<String>? pushTopic,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lineId != null) 'line_id': lineId,
      if (providerId != null) 'provider_id': providerId,
      if (lineName != null) 'line_name': lineName,
      if (window != null) 'window': window,
      if (pushTopic != null) 'push_topic': pushTopic,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubscriptionsCompanion copyWith({
    Value<String>? lineId,
    Value<String>? providerId,
    Value<String>? lineName,
    Value<String?>? window,
    Value<String?>? pushTopic,
    Value<int>? rowid,
  }) {
    return SubscriptionsCompanion(
      lineId: lineId ?? this.lineId,
      providerId: providerId ?? this.providerId,
      lineName: lineName ?? this.lineName,
      window: window ?? this.window,
      pushTopic: pushTopic ?? this.pushTopic,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lineId.present) {
      map['line_id'] = Variable<String>(lineId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (lineName.present) {
      map['line_name'] = Variable<String>(lineName.value);
    }
    if (window.present) {
      map['window'] = Variable<String>(window.value);
    }
    if (pushTopic.present) {
      map['push_topic'] = Variable<String>(pushTopic.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('lineId: $lineId, ')
          ..write('providerId: $providerId, ')
          ..write('lineName: $lineName, ')
          ..write('window: $window, ')
          ..write('pushTopic: $pushTopic, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedPlacesTable extends SavedPlaces
    with TableInfo<$SavedPlacesTable, SavedPlaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedPlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, kind, location];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_places';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedPlaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedPlaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedPlaceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
    );
  }

  @override
  $SavedPlacesTable createAlias(String alias) {
    return $SavedPlacesTable(attachedDatabase, alias);
  }
}

class SavedPlaceRow extends DataClass implements Insertable<SavedPlaceRow> {
  final String id;
  final String name;
  final String kind;
  final String location;
  const SavedPlaceRow({
    required this.id,
    required this.name,
    required this.kind,
    required this.location,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['location'] = Variable<String>(location);
    return map;
  }

  SavedPlacesCompanion toCompanion(bool nullToAbsent) {
    return SavedPlacesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      location: Value(location),
    );
  }

  factory SavedPlaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedPlaceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      location: serializer.fromJson<String>(json['location']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'location': serializer.toJson<String>(location),
    };
  }

  SavedPlaceRow copyWith({
    String? id,
    String? name,
    String? kind,
    String? location,
  }) => SavedPlaceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    location: location ?? this.location,
  );
  SavedPlaceRow copyWithCompanion(SavedPlacesCompanion data) {
    return SavedPlaceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      location: data.location.present ? data.location.value : this.location,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedPlaceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('location: $location')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, kind, location);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedPlaceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.location == this.location);
}

class SavedPlacesCompanion extends UpdateCompanion<SavedPlaceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> location;
  final Value<int> rowid;
  const SavedPlacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.location = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedPlacesCompanion.insert({
    required String id,
    required String name,
    required String kind,
    required String location,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       location = Value(location);
  static Insertable<SavedPlaceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? location,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (location != null) 'location': location,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedPlacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? location,
    Value<int>? rowid,
  }) {
    return SavedPlacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      location: location ?? this.location,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedPlacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('location: $location, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LastTripsTable extends LastTrips
    with TableInfo<$LastTripsTable, LastTrip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LastTripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tripMeta = const VerificationMeta('trip');
  @override
  late final GeneratedColumn<String> trip = GeneratedColumn<String>(
    'trip',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineMeta = const VerificationMeta('line');
  @override
  late final GeneratedColumn<String> line = GeneratedColumn<String>(
    'line',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stopIdMeta = const VerificationMeta('stopId');
  @override
  late final GeneratedColumn<String> stopId = GeneratedColumn<String>(
    'stop_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tripCodeMeta = const VerificationMeta(
    'tripCode',
  );
  @override
  late final GeneratedColumn<String> tripCode = GeneratedColumn<String>(
    'trip_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
    'time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasRealtimeMeta = const VerificationMeta(
    'hasRealtime',
  );
  @override
  late final GeneratedColumn<bool> hasRealtime = GeneratedColumn<bool>(
    'has_realtime',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_realtime" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trip,
    line,
    stopId,
    tripCode,
    date,
    time,
    updatedAt,
    hasRealtime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'last_trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<LastTrip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip')) {
      context.handle(
        _tripMeta,
        trip.isAcceptableOrUnknown(data['trip']!, _tripMeta),
      );
    } else if (isInserting) {
      context.missing(_tripMeta);
    }
    if (data.containsKey('line')) {
      context.handle(
        _lineMeta,
        line.isAcceptableOrUnknown(data['line']!, _lineMeta),
      );
    }
    if (data.containsKey('stop_id')) {
      context.handle(
        _stopIdMeta,
        stopId.isAcceptableOrUnknown(data['stop_id']!, _stopIdMeta),
      );
    }
    if (data.containsKey('trip_code')) {
      context.handle(
        _tripCodeMeta,
        tripCode.isAcceptableOrUnknown(data['trip_code']!, _tripCodeMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('has_realtime')) {
      context.handle(
        _hasRealtimeMeta,
        hasRealtime.isAcceptableOrUnknown(
          data['has_realtime']!,
          _hasRealtimeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LastTrip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LastTrip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip'],
      )!,
      line: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line'],
      ),
      stopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stop_id'],
      ),
      tripCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_code'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      ),
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      hasRealtime: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_realtime'],
      )!,
    );
  }

  @override
  $LastTripsTable createAlias(String alias) {
    return $LastTripsTable(attachedDatabase, alias);
  }
}

class LastTrip extends DataClass implements Insertable<LastTrip> {
  final int id;
  final String trip;
  final String? line;
  final String? stopId;
  final String? tripCode;

  /// JJJJMMTT
  final String? date;

  /// HHMM, Ortszeit
  final String? time;

  /// Zeitpunkt der letzten erfolgreichen Aktualisierung.
  final DateTime updatedAt;

  /// Ob der gespeicherte Stand Echtzeit enthielt.
  final bool hasRealtime;
  const LastTrip({
    required this.id,
    required this.trip,
    this.line,
    this.stopId,
    this.tripCode,
    this.date,
    this.time,
    required this.updatedAt,
    required this.hasRealtime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip'] = Variable<String>(trip);
    if (!nullToAbsent || line != null) {
      map['line'] = Variable<String>(line);
    }
    if (!nullToAbsent || stopId != null) {
      map['stop_id'] = Variable<String>(stopId);
    }
    if (!nullToAbsent || tripCode != null) {
      map['trip_code'] = Variable<String>(tripCode);
    }
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<String>(date);
    }
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<String>(time);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['has_realtime'] = Variable<bool>(hasRealtime);
    return map;
  }

  LastTripsCompanion toCompanion(bool nullToAbsent) {
    return LastTripsCompanion(
      id: Value(id),
      trip: Value(trip),
      line: line == null && nullToAbsent ? const Value.absent() : Value(line),
      stopId: stopId == null && nullToAbsent
          ? const Value.absent()
          : Value(stopId),
      tripCode: tripCode == null && nullToAbsent
          ? const Value.absent()
          : Value(tripCode),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
      updatedAt: Value(updatedAt),
      hasRealtime: Value(hasRealtime),
    );
  }

  factory LastTrip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LastTrip(
      id: serializer.fromJson<int>(json['id']),
      trip: serializer.fromJson<String>(json['trip']),
      line: serializer.fromJson<String?>(json['line']),
      stopId: serializer.fromJson<String?>(json['stopId']),
      tripCode: serializer.fromJson<String?>(json['tripCode']),
      date: serializer.fromJson<String?>(json['date']),
      time: serializer.fromJson<String?>(json['time']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      hasRealtime: serializer.fromJson<bool>(json['hasRealtime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trip': serializer.toJson<String>(trip),
      'line': serializer.toJson<String?>(line),
      'stopId': serializer.toJson<String?>(stopId),
      'tripCode': serializer.toJson<String?>(tripCode),
      'date': serializer.toJson<String?>(date),
      'time': serializer.toJson<String?>(time),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'hasRealtime': serializer.toJson<bool>(hasRealtime),
    };
  }

  LastTrip copyWith({
    int? id,
    String? trip,
    Value<String?> line = const Value.absent(),
    Value<String?> stopId = const Value.absent(),
    Value<String?> tripCode = const Value.absent(),
    Value<String?> date = const Value.absent(),
    Value<String?> time = const Value.absent(),
    DateTime? updatedAt,
    bool? hasRealtime,
  }) => LastTrip(
    id: id ?? this.id,
    trip: trip ?? this.trip,
    line: line.present ? line.value : this.line,
    stopId: stopId.present ? stopId.value : this.stopId,
    tripCode: tripCode.present ? tripCode.value : this.tripCode,
    date: date.present ? date.value : this.date,
    time: time.present ? time.value : this.time,
    updatedAt: updatedAt ?? this.updatedAt,
    hasRealtime: hasRealtime ?? this.hasRealtime,
  );
  LastTrip copyWithCompanion(LastTripsCompanion data) {
    return LastTrip(
      id: data.id.present ? data.id.value : this.id,
      trip: data.trip.present ? data.trip.value : this.trip,
      line: data.line.present ? data.line.value : this.line,
      stopId: data.stopId.present ? data.stopId.value : this.stopId,
      tripCode: data.tripCode.present ? data.tripCode.value : this.tripCode,
      date: data.date.present ? data.date.value : this.date,
      time: data.time.present ? data.time.value : this.time,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      hasRealtime: data.hasRealtime.present
          ? data.hasRealtime.value
          : this.hasRealtime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LastTrip(')
          ..write('id: $id, ')
          ..write('trip: $trip, ')
          ..write('line: $line, ')
          ..write('stopId: $stopId, ')
          ..write('tripCode: $tripCode, ')
          ..write('date: $date, ')
          ..write('time: $time, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('hasRealtime: $hasRealtime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trip,
    line,
    stopId,
    tripCode,
    date,
    time,
    updatedAt,
    hasRealtime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LastTrip &&
          other.id == this.id &&
          other.trip == this.trip &&
          other.line == this.line &&
          other.stopId == this.stopId &&
          other.tripCode == this.tripCode &&
          other.date == this.date &&
          other.time == this.time &&
          other.updatedAt == this.updatedAt &&
          other.hasRealtime == this.hasRealtime);
}

class LastTripsCompanion extends UpdateCompanion<LastTrip> {
  final Value<int> id;
  final Value<String> trip;
  final Value<String?> line;
  final Value<String?> stopId;
  final Value<String?> tripCode;
  final Value<String?> date;
  final Value<String?> time;
  final Value<DateTime> updatedAt;
  final Value<bool> hasRealtime;
  const LastTripsCompanion({
    this.id = const Value.absent(),
    this.trip = const Value.absent(),
    this.line = const Value.absent(),
    this.stopId = const Value.absent(),
    this.tripCode = const Value.absent(),
    this.date = const Value.absent(),
    this.time = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.hasRealtime = const Value.absent(),
  });
  LastTripsCompanion.insert({
    this.id = const Value.absent(),
    required String trip,
    this.line = const Value.absent(),
    this.stopId = const Value.absent(),
    this.tripCode = const Value.absent(),
    this.date = const Value.absent(),
    this.time = const Value.absent(),
    required DateTime updatedAt,
    this.hasRealtime = const Value.absent(),
  }) : trip = Value(trip),
       updatedAt = Value(updatedAt);
  static Insertable<LastTrip> custom({
    Expression<int>? id,
    Expression<String>? trip,
    Expression<String>? line,
    Expression<String>? stopId,
    Expression<String>? tripCode,
    Expression<String>? date,
    Expression<String>? time,
    Expression<DateTime>? updatedAt,
    Expression<bool>? hasRealtime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trip != null) 'trip': trip,
      if (line != null) 'line': line,
      if (stopId != null) 'stop_id': stopId,
      if (tripCode != null) 'trip_code': tripCode,
      if (date != null) 'date': date,
      if (time != null) 'time': time,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (hasRealtime != null) 'has_realtime': hasRealtime,
    });
  }

  LastTripsCompanion copyWith({
    Value<int>? id,
    Value<String>? trip,
    Value<String?>? line,
    Value<String?>? stopId,
    Value<String?>? tripCode,
    Value<String?>? date,
    Value<String?>? time,
    Value<DateTime>? updatedAt,
    Value<bool>? hasRealtime,
  }) {
    return LastTripsCompanion(
      id: id ?? this.id,
      trip: trip ?? this.trip,
      line: line ?? this.line,
      stopId: stopId ?? this.stopId,
      tripCode: tripCode ?? this.tripCode,
      date: date ?? this.date,
      time: time ?? this.time,
      updatedAt: updatedAt ?? this.updatedAt,
      hasRealtime: hasRealtime ?? this.hasRealtime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trip.present) {
      map['trip'] = Variable<String>(trip.value);
    }
    if (line.present) {
      map['line'] = Variable<String>(line.value);
    }
    if (stopId.present) {
      map['stop_id'] = Variable<String>(stopId.value);
    }
    if (tripCode.present) {
      map['trip_code'] = Variable<String>(tripCode.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (hasRealtime.present) {
      map['has_realtime'] = Variable<bool>(hasRealtime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LastTripsCompanion(')
          ..write('id: $id, ')
          ..write('trip: $trip, ')
          ..write('line: $line, ')
          ..write('stopId: $stopId, ')
          ..write('tripCode: $tripCode, ')
          ..write('date: $date, ')
          ..write('time: $time, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('hasRealtime: $hasRealtime')
          ..write(')'))
        .toString();
  }
}

class $StopCacheTable extends StopCache
    with TableInfo<$StopCacheTable, StopCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StopCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placeMeta = const VerificationMeta('place');
  @override
  late final GeneratedColumn<String> place = GeneratedColumn<String>(
    'place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modesMeta = const VerificationMeta('modes');
  @override
  late final GeneratedColumn<String> modes = GeneratedColumn<String>(
    'modes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    name,
    place,
    lat,
    lon,
    modes,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stop_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<StopCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('place')) {
      context.handle(
        _placeMeta,
        place.isAcceptableOrUnknown(data['place']!, _placeMeta),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    }
    if (data.containsKey('modes')) {
      context.handle(
        _modesMeta,
        modes.isAcceptableOrUnknown(data['modes']!, _modesMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StopCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StopCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      place: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      ),
      modes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modes'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StopCacheTable createAlias(String alias) {
    return $StopCacheTable(attachedDatabase, alias);
  }
}

class StopCacheData extends DataClass implements Insertable<StopCacheData> {
  final String id;
  final String providerId;
  final String name;
  final String? place;
  final double? lat;
  final double? lon;

  /// Verkehrsmittel, kommagetrennt.
  final String modes;
  final DateTime updatedAt;
  const StopCacheData({
    required this.id,
    required this.providerId,
    required this.name,
    this.place,
    this.lat,
    this.lon,
    required this.modes,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider_id'] = Variable<String>(providerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || place != null) {
      map['place'] = Variable<String>(place);
    }
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lon != null) {
      map['lon'] = Variable<double>(lon);
    }
    map['modes'] = Variable<String>(modes);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StopCacheCompanion toCompanion(bool nullToAbsent) {
    return StopCacheCompanion(
      id: Value(id),
      providerId: Value(providerId),
      name: Value(name),
      place: place == null && nullToAbsent
          ? const Value.absent()
          : Value(place),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lon: lon == null && nullToAbsent ? const Value.absent() : Value(lon),
      modes: Value(modes),
      updatedAt: Value(updatedAt),
    );
  }

  factory StopCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StopCacheData(
      id: serializer.fromJson<String>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      name: serializer.fromJson<String>(json['name']),
      place: serializer.fromJson<String?>(json['place']),
      lat: serializer.fromJson<double?>(json['lat']),
      lon: serializer.fromJson<double?>(json['lon']),
      modes: serializer.fromJson<String>(json['modes']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'providerId': serializer.toJson<String>(providerId),
      'name': serializer.toJson<String>(name),
      'place': serializer.toJson<String?>(place),
      'lat': serializer.toJson<double?>(lat),
      'lon': serializer.toJson<double?>(lon),
      'modes': serializer.toJson<String>(modes),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StopCacheData copyWith({
    String? id,
    String? providerId,
    String? name,
    Value<String?> place = const Value.absent(),
    Value<double?> lat = const Value.absent(),
    Value<double?> lon = const Value.absent(),
    String? modes,
    DateTime? updatedAt,
  }) => StopCacheData(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    name: name ?? this.name,
    place: place.present ? place.value : this.place,
    lat: lat.present ? lat.value : this.lat,
    lon: lon.present ? lon.value : this.lon,
    modes: modes ?? this.modes,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StopCacheData copyWithCompanion(StopCacheCompanion data) {
    return StopCacheData(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      name: data.name.present ? data.name.value : this.name,
      place: data.place.present ? data.place.value : this.place,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      modes: data.modes.present ? data.modes.value : this.modes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StopCacheData(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('name: $name, ')
          ..write('place: $place, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('modes: $modes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, providerId, name, place, lat, lon, modes, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StopCacheData &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.name == this.name &&
          other.place == this.place &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.modes == this.modes &&
          other.updatedAt == this.updatedAt);
}

class StopCacheCompanion extends UpdateCompanion<StopCacheData> {
  final Value<String> id;
  final Value<String> providerId;
  final Value<String> name;
  final Value<String?> place;
  final Value<double?> lat;
  final Value<double?> lon;
  final Value<String> modes;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StopCacheCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.name = const Value.absent(),
    this.place = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.modes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StopCacheCompanion.insert({
    required String id,
    required String providerId,
    required String name,
    this.place = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.modes = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       providerId = Value(providerId),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<StopCacheData> custom({
    Expression<String>? id,
    Expression<String>? providerId,
    Expression<String>? name,
    Expression<String>? place,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? modes,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (name != null) 'name': name,
      if (place != null) 'place': place,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (modes != null) 'modes': modes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StopCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? providerId,
    Value<String>? name,
    Value<String?>? place,
    Value<double?>? lat,
    Value<double?>? lon,
    Value<String>? modes,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StopCacheCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      place: place ?? this.place,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      modes: modes ?? this.modes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (place.present) {
      map['place'] = Variable<String>(place.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (modes.present) {
      map['modes'] = Variable<String>(modes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StopCacheCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('name: $name, ')
          ..write('place: $place, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('modes: $modes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlarmsTable extends Alarms with TableInfo<$AlarmsTable, AlarmRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarms';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlarmRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlarmRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlarmRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
    );
  }

  @override
  $AlarmsTable createAlias(String alias) {
    return $AlarmsTable(attachedDatabase, alias);
  }
}

class AlarmRow extends DataClass implements Insertable<AlarmRow> {
  final String id;
  final String data;
  const AlarmRow({required this.id, required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    return map;
  }

  AlarmsCompanion toCompanion(bool nullToAbsent) {
    return AlarmsCompanion(id: Value(id), data: Value(data));
  }

  factory AlarmRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlarmRow(
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
    };
  }

  AlarmRow copyWith({String? id, String? data}) =>
      AlarmRow(id: id ?? this.id, data: data ?? this.data);
  AlarmRow copyWithCompanion(AlarmsCompanion data) {
    return AlarmRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlarmRow(')
          ..write('id: $id, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlarmRow && other.id == this.id && other.data == this.data);
}

class AlarmsCompanion extends UpdateCompanion<AlarmRow> {
  final Value<String> id;
  final Value<String> data;
  final Value<int> rowid;
  const AlarmsCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlarmsCompanion.insert({
    required String id,
    required String data,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       data = Value(data);
  static Insertable<AlarmRow> custom({
    Expression<String>? id,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlarmsCompanion copyWith({
    Value<String>? id,
    Value<String>? data,
    Value<int>? rowid,
  }) {
    return AlarmsCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmsCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HistoryEntriesTable historyEntries = $HistoryEntriesTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  late final $SavedPlacesTable savedPlaces = $SavedPlacesTable(this);
  late final $LastTripsTable lastTrips = $LastTripsTable(this);
  late final $StopCacheTable stopCache = $StopCacheTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $AlarmsTable alarms = $AlarmsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    historyEntries,
    favorites,
    subscriptions,
    savedPlaces,
    lastTrips,
    stopCache,
    settings,
    alarms,
  ];
}

typedef $$HistoryEntriesTableCreateCompanionBuilder =
    HistoryEntriesCompanion Function({
      Value<int> id,
      required String fromLocation,
      required String toLocation,
      required String routeKey,
      Value<String?> profile,
      required DateTime lastUsed,
      Value<String?> cachedResult,
      Value<DateTime?> cachedAt,
    });
typedef $$HistoryEntriesTableUpdateCompanionBuilder =
    HistoryEntriesCompanion Function({
      Value<int> id,
      Value<String> fromLocation,
      Value<String> toLocation,
      Value<String> routeKey,
      Value<String?> profile,
      Value<DateTime> lastUsed,
      Value<String?> cachedResult,
      Value<DateTime?> cachedAt,
    });

class $$HistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $HistoryEntriesTable> {
  $$HistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromLocation => $composableBuilder(
    column: $table.fromLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toLocation => $composableBuilder(
    column: $table.toLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeKey => $composableBuilder(
    column: $table.routeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profile => $composableBuilder(
    column: $table.profile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsed => $composableBuilder(
    column: $table.lastUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedResult => $composableBuilder(
    column: $table.cachedResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HistoryEntriesTable> {
  $$HistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromLocation => $composableBuilder(
    column: $table.fromLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toLocation => $composableBuilder(
    column: $table.toLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeKey => $composableBuilder(
    column: $table.routeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profile => $composableBuilder(
    column: $table.profile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsed => $composableBuilder(
    column: $table.lastUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedResult => $composableBuilder(
    column: $table.cachedResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HistoryEntriesTable> {
  $$HistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fromLocation => $composableBuilder(
    column: $table.fromLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toLocation => $composableBuilder(
    column: $table.toLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get routeKey =>
      $composableBuilder(column: $table.routeKey, builder: (column) => column);

  GeneratedColumn<String> get profile =>
      $composableBuilder(column: $table.profile, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsed =>
      $composableBuilder(column: $table.lastUsed, builder: (column) => column);

  GeneratedColumn<String> get cachedResult => $composableBuilder(
    column: $table.cachedResult,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$HistoryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HistoryEntriesTable,
          HistoryEntry,
          $$HistoryEntriesTableFilterComposer,
          $$HistoryEntriesTableOrderingComposer,
          $$HistoryEntriesTableAnnotationComposer,
          $$HistoryEntriesTableCreateCompanionBuilder,
          $$HistoryEntriesTableUpdateCompanionBuilder,
          (
            HistoryEntry,
            BaseReferences<_$AppDatabase, $HistoryEntriesTable, HistoryEntry>,
          ),
          HistoryEntry,
          PrefetchHooks Function()
        > {
  $$HistoryEntriesTableTableManager(
    _$AppDatabase db,
    $HistoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fromLocation = const Value.absent(),
                Value<String> toLocation = const Value.absent(),
                Value<String> routeKey = const Value.absent(),
                Value<String?> profile = const Value.absent(),
                Value<DateTime> lastUsed = const Value.absent(),
                Value<String?> cachedResult = const Value.absent(),
                Value<DateTime?> cachedAt = const Value.absent(),
              }) => HistoryEntriesCompanion(
                id: id,
                fromLocation: fromLocation,
                toLocation: toLocation,
                routeKey: routeKey,
                profile: profile,
                lastUsed: lastUsed,
                cachedResult: cachedResult,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fromLocation,
                required String toLocation,
                required String routeKey,
                Value<String?> profile = const Value.absent(),
                required DateTime lastUsed,
                Value<String?> cachedResult = const Value.absent(),
                Value<DateTime?> cachedAt = const Value.absent(),
              }) => HistoryEntriesCompanion.insert(
                id: id,
                fromLocation: fromLocation,
                toLocation: toLocation,
                routeKey: routeKey,
                profile: profile,
                lastUsed: lastUsed,
                cachedResult: cachedResult,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HistoryEntriesTable, HistoryEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HistoryEntriesTable,
                    HistoryEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HistoryEntriesTable,
      HistoryEntry,
      $$HistoryEntriesTableFilterComposer,
      $$HistoryEntriesTableOrderingComposer,
      $$HistoryEntriesTableAnnotationComposer,
      $$HistoryEntriesTableCreateCompanionBuilder,
      $$HistoryEntriesTableUpdateCompanionBuilder,
      (
        HistoryEntry,
        BaseReferences<_$AppDatabase, $HistoryEntriesTable, HistoryEntry>,
      ),
      HistoryEntry,
      PrefetchHooks Function()
    >;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  Value<int> id,
  required String kind,
  required String ref,
  required String name,
  required String payload,
  Value<int> sortOrder,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<int> id,
  Value<String> kind,
  Value<String> ref,
  Value<String> name,
  Value<String> payload,
  Value<int> sortOrder,
});

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ref => $composableBuilder(
    column: $table.ref,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ref => $composableBuilder(
    column: $table.ref,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get ref =>
      $composableBuilder(column: $table.ref, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
          Favorite,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> ref = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => FavoritesCompanion(
                id: id,
                kind: kind,
                ref: ref,
                name: name,
                payload: payload,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String ref,
                required String name,
                required String payload,
                Value<int> sortOrder = const Value.absent(),
              }) => FavoritesCompanion.insert(
                id: id,
                kind: kind,
                ref: ref,
                name: name,
                payload: payload,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoritesTable, Favorite>(table),
                  BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
      Favorite,
      PrefetchHooks Function()
    >;
typedef $$SubscriptionsTableCreateCompanionBuilder =
    SubscriptionsCompanion Function({
      required String lineId,
      required String providerId,
      required String lineName,
      Value<String?> window,
      Value<String?> pushTopic,
      Value<int> rowid,
    });
typedef $$SubscriptionsTableUpdateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<String> lineId,
      Value<String> providerId,
      Value<String> lineName,
      Value<String?> window,
      Value<String?> pushTopic,
      Value<int> rowid,
    });

class $$SubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lineId => $composableBuilder(
    column: $table.lineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineName => $composableBuilder(
    column: $table.lineName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get window => $composableBuilder(
    column: $table.window,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pushTopic => $composableBuilder(
    column: $table.pushTopic,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lineId => $composableBuilder(
    column: $table.lineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineName => $composableBuilder(
    column: $table.lineName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get window => $composableBuilder(
    column: $table.window,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pushTopic => $composableBuilder(
    column: $table.pushTopic,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lineId =>
      $composableBuilder(column: $table.lineId, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lineName =>
      $composableBuilder(column: $table.lineName, builder: (column) => column);

  GeneratedColumn<String> get window =>
      $composableBuilder(column: $table.window, builder: (column) => column);

  GeneratedColumn<String> get pushTopic =>
      $composableBuilder(column: $table.pushTopic, builder: (column) => column);
}

class $$SubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubscriptionsTable,
          SubscriptionRow,
          $$SubscriptionsTableFilterComposer,
          $$SubscriptionsTableOrderingComposer,
          $$SubscriptionsTableAnnotationComposer,
          $$SubscriptionsTableCreateCompanionBuilder,
          $$SubscriptionsTableUpdateCompanionBuilder,
          (
            SubscriptionRow,
            BaseReferences<_$AppDatabase, $SubscriptionsTable, SubscriptionRow>,
          ),
          SubscriptionRow,
          PrefetchHooks Function()
        > {
  $$SubscriptionsTableTableManager(_$AppDatabase db, $SubscriptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lineId = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> lineName = const Value.absent(),
                Value<String?> window = const Value.absent(),
                Value<String?> pushTopic = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsCompanion(
                lineId: lineId,
                providerId: providerId,
                lineName: lineName,
                window: window,
                pushTopic: pushTopic,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lineId,
                required String providerId,
                required String lineName,
                Value<String?> window = const Value.absent(),
                Value<String?> pushTopic = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsCompanion.insert(
                lineId: lineId,
                providerId: providerId,
                lineName: lineName,
                window: window,
                pushTopic: pushTopic,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubscriptionsTable, SubscriptionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SubscriptionsTable,
                    SubscriptionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubscriptionsTable,
      SubscriptionRow,
      $$SubscriptionsTableFilterComposer,
      $$SubscriptionsTableOrderingComposer,
      $$SubscriptionsTableAnnotationComposer,
      $$SubscriptionsTableCreateCompanionBuilder,
      $$SubscriptionsTableUpdateCompanionBuilder,
      (
        SubscriptionRow,
        BaseReferences<_$AppDatabase, $SubscriptionsTable, SubscriptionRow>,
      ),
      SubscriptionRow,
      PrefetchHooks Function()
    >;
typedef $$SavedPlacesTableCreateCompanionBuilder =
    SavedPlacesCompanion Function({
      required String id,
      required String name,
      required String kind,
      required String location,
      Value<int> rowid,
    });
typedef $$SavedPlacesTableUpdateCompanionBuilder =
    SavedPlacesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> kind,
      Value<String> location,
      Value<int> rowid,
    });

class $$SavedPlacesTableFilterComposer
    extends Composer<_$AppDatabase, $SavedPlacesTable> {
  $$SavedPlacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedPlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedPlacesTable> {
  $$SavedPlacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedPlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedPlacesTable> {
  $$SavedPlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);
}

class $$SavedPlacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedPlacesTable,
          SavedPlaceRow,
          $$SavedPlacesTableFilterComposer,
          $$SavedPlacesTableOrderingComposer,
          $$SavedPlacesTableAnnotationComposer,
          $$SavedPlacesTableCreateCompanionBuilder,
          $$SavedPlacesTableUpdateCompanionBuilder,
          (
            SavedPlaceRow,
            BaseReferences<_$AppDatabase, $SavedPlacesTable, SavedPlaceRow>,
          ),
          SavedPlaceRow,
          PrefetchHooks Function()
        > {
  $$SavedPlacesTableTableManager(_$AppDatabase db, $SavedPlacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedPlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedPlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedPlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedPlacesCompanion(
                id: id,
                name: name,
                kind: kind,
                location: location,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String kind,
                required String location,
                Value<int> rowid = const Value.absent(),
              }) => SavedPlacesCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                location: location,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedPlacesTable, SavedPlaceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SavedPlacesTable,
                    SavedPlaceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedPlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedPlacesTable,
      SavedPlaceRow,
      $$SavedPlacesTableFilterComposer,
      $$SavedPlacesTableOrderingComposer,
      $$SavedPlacesTableAnnotationComposer,
      $$SavedPlacesTableCreateCompanionBuilder,
      $$SavedPlacesTableUpdateCompanionBuilder,
      (
        SavedPlaceRow,
        BaseReferences<_$AppDatabase, $SavedPlacesTable, SavedPlaceRow>,
      ),
      SavedPlaceRow,
      PrefetchHooks Function()
    >;
typedef $$LastTripsTableCreateCompanionBuilder = LastTripsCompanion Function({
  Value<int> id,
  required String trip,
  Value<String?> line,
  Value<String?> stopId,
  Value<String?> tripCode,
  Value<String?> date,
  Value<String?> time,
  required DateTime updatedAt,
  Value<bool> hasRealtime,
});
typedef $$LastTripsTableUpdateCompanionBuilder = LastTripsCompanion Function({
  Value<int> id,
  Value<String> trip,
  Value<String?> line,
  Value<String?> stopId,
  Value<String?> tripCode,
  Value<String?> date,
  Value<String?> time,
  Value<DateTime> updatedAt,
  Value<bool> hasRealtime,
});

class $$LastTripsTableFilterComposer
    extends Composer<_$AppDatabase, $LastTripsTable> {
  $$LastTripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trip => $composableBuilder(
    column: $table.trip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stopId => $composableBuilder(
    column: $table.stopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripCode => $composableBuilder(
    column: $table.tripCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasRealtime => $composableBuilder(
    column: $table.hasRealtime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LastTripsTableOrderingComposer
    extends Composer<_$AppDatabase, $LastTripsTable> {
  $$LastTripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trip => $composableBuilder(
    column: $table.trip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stopId => $composableBuilder(
    column: $table.stopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripCode => $composableBuilder(
    column: $table.tripCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasRealtime => $composableBuilder(
    column: $table.hasRealtime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LastTripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LastTripsTable> {
  $$LastTripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trip =>
      $composableBuilder(column: $table.trip, builder: (column) => column);

  GeneratedColumn<String> get line =>
      $composableBuilder(column: $table.line, builder: (column) => column);

  GeneratedColumn<String> get stopId =>
      $composableBuilder(column: $table.stopId, builder: (column) => column);

  GeneratedColumn<String> get tripCode =>
      $composableBuilder(column: $table.tripCode, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get hasRealtime => $composableBuilder(
    column: $table.hasRealtime,
    builder: (column) => column,
  );
}

class $$LastTripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LastTripsTable,
          LastTrip,
          $$LastTripsTableFilterComposer,
          $$LastTripsTableOrderingComposer,
          $$LastTripsTableAnnotationComposer,
          $$LastTripsTableCreateCompanionBuilder,
          $$LastTripsTableUpdateCompanionBuilder,
          (LastTrip, BaseReferences<_$AppDatabase, $LastTripsTable, LastTrip>),
          LastTrip,
          PrefetchHooks Function()
        > {
  $$LastTripsTableTableManager(_$AppDatabase db, $LastTripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LastTripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LastTripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LastTripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trip = const Value.absent(),
                Value<String?> line = const Value.absent(),
                Value<String?> stopId = const Value.absent(),
                Value<String?> tripCode = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<String?> time = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> hasRealtime = const Value.absent(),
              }) => LastTripsCompanion(
                id: id,
                trip: trip,
                line: line,
                stopId: stopId,
                tripCode: tripCode,
                date: date,
                time: time,
                updatedAt: updatedAt,
                hasRealtime: hasRealtime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trip,
                Value<String?> line = const Value.absent(),
                Value<String?> stopId = const Value.absent(),
                Value<String?> tripCode = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<String?> time = const Value.absent(),
                required DateTime updatedAt,
                Value<bool> hasRealtime = const Value.absent(),
              }) => LastTripsCompanion.insert(
                id: id,
                trip: trip,
                line: line,
                stopId: stopId,
                tripCode: tripCode,
                date: date,
                time: time,
                updatedAt: updatedAt,
                hasRealtime: hasRealtime,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LastTripsTable, LastTrip>(table),
                  BaseReferences<_$AppDatabase, $LastTripsTable, LastTrip>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LastTripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LastTripsTable,
      LastTrip,
      $$LastTripsTableFilterComposer,
      $$LastTripsTableOrderingComposer,
      $$LastTripsTableAnnotationComposer,
      $$LastTripsTableCreateCompanionBuilder,
      $$LastTripsTableUpdateCompanionBuilder,
      (LastTrip, BaseReferences<_$AppDatabase, $LastTripsTable, LastTrip>),
      LastTrip,
      PrefetchHooks Function()
    >;
typedef $$StopCacheTableCreateCompanionBuilder = StopCacheCompanion Function({
  required String id,
  required String providerId,
  required String name,
  Value<String?> place,
  Value<double?> lat,
  Value<double?> lon,
  Value<String> modes,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$StopCacheTableUpdateCompanionBuilder = StopCacheCompanion Function({
  Value<String> id,
  Value<String> providerId,
  Value<String> name,
  Value<String?> place,
  Value<double?> lat,
  Value<double?> lon,
  Value<String> modes,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$StopCacheTableFilterComposer
    extends Composer<_$AppDatabase, $StopCacheTable> {
  $$StopCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modes => $composableBuilder(
    column: $table.modes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StopCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $StopCacheTable> {
  $$StopCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modes => $composableBuilder(
    column: $table.modes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StopCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $StopCacheTable> {
  $$StopCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get place =>
      $composableBuilder(column: $table.place, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<String> get modes =>
      $composableBuilder(column: $table.modes, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StopCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StopCacheTable,
          StopCacheData,
          $$StopCacheTableFilterComposer,
          $$StopCacheTableOrderingComposer,
          $$StopCacheTableAnnotationComposer,
          $$StopCacheTableCreateCompanionBuilder,
          $$StopCacheTableUpdateCompanionBuilder,
          (
            StopCacheData,
            BaseReferences<_$AppDatabase, $StopCacheTable, StopCacheData>,
          ),
          StopCacheData,
          PrefetchHooks Function()
        > {
  $$StopCacheTableTableManager(_$AppDatabase db, $StopCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StopCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StopCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StopCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> place = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lon = const Value.absent(),
                Value<String> modes = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StopCacheCompanion(
                id: id,
                providerId: providerId,
                name: name,
                place: place,
                lat: lat,
                lon: lon,
                modes: modes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String providerId,
                required String name,
                Value<String?> place = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lon = const Value.absent(),
                Value<String> modes = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StopCacheCompanion.insert(
                id: id,
                providerId: providerId,
                name: name,
                place: place,
                lat: lat,
                lon: lon,
                modes: modes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StopCacheTable, StopCacheData>(table),
                  BaseReferences<_$AppDatabase, $StopCacheTable, StopCacheData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StopCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StopCacheTable,
      StopCacheData,
      $$StopCacheTableFilterComposer,
      $$StopCacheTableOrderingComposer,
      $$StopCacheTableAnnotationComposer,
      $$StopCacheTableCreateCompanionBuilder,
      $$StopCacheTableUpdateCompanionBuilder,
      (
        StopCacheData,
        BaseReferences<_$AppDatabase, $StopCacheTable, StopCacheData>,
      ),
      StopCacheData,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
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
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
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
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
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
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
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
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
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
      PrefetchHooks Function()
    >;
typedef $$AlarmsTableCreateCompanionBuilder = AlarmsCompanion Function({
  required String id,
  required String data,
  Value<int> rowid,
});
typedef $$AlarmsTableUpdateCompanionBuilder = AlarmsCompanion Function({
  Value<String> id,
  Value<String> data,
  Value<int> rowid,
});

class $$AlarmsTableFilterComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlarmsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlarmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$AlarmsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlarmsTable,
          AlarmRow,
          $$AlarmsTableFilterComposer,
          $$AlarmsTableOrderingComposer,
          $$AlarmsTableAnnotationComposer,
          $$AlarmsTableCreateCompanionBuilder,
          $$AlarmsTableUpdateCompanionBuilder,
          (AlarmRow, BaseReferences<_$AppDatabase, $AlarmsTable, AlarmRow>),
          AlarmRow,
          PrefetchHooks Function()
        > {
  $$AlarmsTableTableManager(_$AppDatabase db, $AlarmsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlarmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlarmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlarmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AlarmsCompanion(id: id, data: data, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            required String data,
            Value<int> rowid = const Value.absent(),
          }) => AlarmsCompanion.insert(id: id, data: data, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlarmsTable, AlarmRow>(table),
                  BaseReferences<_$AppDatabase, $AlarmsTable, AlarmRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlarmsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlarmsTable,
      AlarmRow,
      $$AlarmsTableFilterComposer,
      $$AlarmsTableOrderingComposer,
      $$AlarmsTableAnnotationComposer,
      $$AlarmsTableCreateCompanionBuilder,
      $$AlarmsTableUpdateCompanionBuilder,
      (AlarmRow, BaseReferences<_$AppDatabase, $AlarmsTable, AlarmRow>),
      AlarmRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HistoryEntriesTableTableManager get historyEntries =>
      $$HistoryEntriesTableTableManager(_db, _db.historyEntries);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db, _db.subscriptions);
  $$SavedPlacesTableTableManager get savedPlaces =>
      $$SavedPlacesTableTableManager(_db, _db.savedPlaces);
  $$LastTripsTableTableManager get lastTrips =>
      $$LastTripsTableTableManager(_db, _db.lastTrips);
  $$StopCacheTableTableManager get stopCache =>
      $$StopCacheTableTableManager(_db, _db.stopCache);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$AlarmsTableTableManager get alarms =>
      $$AlarmsTableTableManager(_db, _db.alarms);
}
