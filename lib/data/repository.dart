import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/models.dart';
import 'db/database.dart';
import 'efa/efa_client.dart';
import 'trias/trias_parser.dart' show stopAreaId;

String routeKey(Location from, Location to) => '${from.id}>${to.id}';

class HistoryItem {
  const HistoryItem(this.from, this.to, this.lastUsed, this.cached, this.cachedAt);

  final Location from;
  final Location to;
  final DateTime lastUsed;
  final List<Trip>? cached;
  final DateTime? cachedAt;

  String get key => routeKey(from, to);
}

class FavoriteItem {
  const FavoriteItem(this.id, this.kind, this.name, this.from, this.to, this.stop);

  final int id;

  /// 'route' oder 'stop'
  final String kind;
  final String name;
  final Location? from;
  final Location? to;
  final Location? stop;
}

/// Gespeicherte „Zuletzt angesehene Fahrt“.
class SavedTrip {
  const SavedTrip(this.trip, this.updatedAt, this.hasRealtime);

  final Trip trip;
  final DateTime updatedAt;
  final bool hasRealtime;
}

bool tripHasRealtime(Trip t) => t.legs.any((l) =>
    l.type == LegType.ride &&
    [l.from.departure, l.to.arrival, ...l.intermediates.map((s) => s.departure)]
        .any((e) => e?.hasRealtime ?? false));

/// Zugriff auf die lokale Datenbank. Nichts davon verlässt das Gerät.
class Repository {
  Repository(this.db);

  final AppDatabase db;

  Location _loc(String json) => Location.fromJson(jsonDecode(json) as Map<String, dynamic>);
  String _enc(Object o) => jsonEncode(o);

  // --- Verlauf ---

  Stream<List<HistoryItem>> watchHistory({int limit = 8}) {
    final q = db.select(db.historyEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.lastUsed)])
      ..limit(limit);
    return q.watch().map((rows) => rows.map(_history).toList());
  }

  HistoryItem _history(HistoryEntry r) => HistoryItem(
        _loc(r.fromLocation),
        _loc(r.toLocation),
        r.lastUsed,
        r.cachedResult == null
            ? null
            : (jsonDecode(r.cachedResult!) as List)
                .map((e) => Trip.fromJson(e as Map<String, dynamic>))
                .toList(),
        r.cachedAt,
      );

  Future<HistoryItem?> history(Location from, Location to) async {
    final r = await (db.select(db.historyEntries)
          ..where((t) => t.routeKey.equals(routeKey(from, to))))
        .getSingleOrNull();
    return r == null ? null : _history(r);
  }

  Future<void> recordSearch(Location from, Location to, {List<Trip>? result}) =>
      db.into(db.historyEntries).insert(
            HistoryEntriesCompanion.insert(
              fromLocation: _enc(from.toJson()),
              toLocation: _enc(to.toJson()),
              routeKey: routeKey(from, to),
              lastUsed: DateTime.now(),
              cachedResult: Value(result == null
                  ? null
                  : _enc(result.map((t) => t.toJson()).toList())),
              cachedAt: Value(result == null ? null : DateTime.now()),
            ),
            onConflict: DoUpdate(
              (old) => HistoryEntriesCompanion(
                lastUsed: Value(DateTime.now()),
                cachedResult: result == null
                    ? const Value.absent()
                    : Value(_enc(result.map((t) => t.toJson()).toList())),
                cachedAt: result == null ? const Value.absent() : Value(DateTime.now()),
              ),
              target: [db.historyEntries.routeKey],
            ),
          );

  Future<void> deleteHistory(String key) =>
      (db.delete(db.historyEntries)..where((t) => t.routeKey.equals(key))).go();

  Future<void> clearHistory() => db.delete(db.historyEntries).go();

  // --- Favoriten ---

  Stream<List<FavoriteItem>> watchFavorites() => (db.select(db.favorites)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
      .watch()
      .map((rows) => rows.map((r) {
            final p = jsonDecode(r.payload) as Map<String, dynamic>;
            if (r.kind == 'route') {
              return FavoriteItem(
                  r.id,
                  r.kind,
                  r.name,
                  Location.fromJson(p['from'] as Map<String, dynamic>),
                  Location.fromJson(p['to'] as Map<String, dynamic>),
                  null);
            }
            return FavoriteItem(r.id, r.kind, r.name, null, null, Location.fromJson(p));
          }).toList());

  Stream<bool> watchIsFavoriteRoute(Location from, Location to) =>
      (db.select(db.favorites)..where((t) => t.ref.equals(routeKey(from, to))))
          .watch()
          .map((r) => r.isNotEmpty);

  Future<void> toggleFavoriteRoute(Location from, Location to) async {
    final key = routeKey(from, to);
    final n = await (db.delete(db.favorites)..where((t) => t.ref.equals(key))).go();
    if (n > 0) return;
    await db.into(db.favorites).insert(FavoritesCompanion.insert(
          kind: 'route',
          ref: key,
          name: '${from.name} → ${to.name}',
          payload: _enc({'from': from.toJson(), 'to': to.toJson()}),
        ));
  }

  /// Haltestelle als Favorit an/aus (je Haltestelle, nicht je Steig).
  Future<void> toggleFavoriteStop(Location stop) async {
    final key = 'stop:${stopAreaId(stop.id)}';
    final n = await (db.delete(db.favorites)..where((t) => t.ref.equals(key))).go();
    if (n > 0) return;
    await db.into(db.favorites).insert(FavoritesCompanion.insert(
          kind: 'stop',
          ref: key,
          name: stop.name,
          payload: _enc(stop.copyWith(id: stopAreaId(stop.id)).toJson()),
        ));
  }

  Future<void> deleteFavorite(int id) =>
      (db.delete(db.favorites)..where((t) => t.id.equals(id))).go();

  // --- Zuletzt angesehene Fahrt ---

  Future<SavedTrip?> lastTrip() async {
    final r = await (db.select(db.lastTrips)..where((t) => t.id.equals(1))).getSingleOrNull();
    if (r == null) return null;
    try {
      return SavedTrip(Trip.fromJson(jsonDecode(r.trip) as Map<String, dynamic>),
          r.updatedAt, r.hasRealtime);
    } catch (_) {
      return null; // älteres Format: verwerfen statt abstürzen
    }
  }

  /// Speichert die Fahrt samt Kennungen des ersten Fahrtabschnitts
  /// (Linie, stopID, tripCode, Datum, Zeit) für die Neuabfrage.
  Future<void> saveLastTrip(Trip trip, {DateTime? updatedAt}) {
    final first = trip.rides.isEmpty ? null : trip.rides.first;
    final dep = first?.from.departure?.planned;
    final key = (first?.journeyRef != null && dep != null)
        ? EfaTripKey.fromJourneyRef(first!.journeyRef!, stopAreaId(first.from.stop.id), dep)
        : null;
    return db.into(db.lastTrips).insertOnConflictUpdate(LastTripsCompanion.insert(
          id: const Value(1),
          trip: _enc(trip.toJson()),
          line: Value(key?.line),
          stopId: Value(key?.stopId),
          tripCode: Value(key?.tripCode),
          date: Value(key?.date),
          time: Value(key?.time),
          updatedAt: updatedAt ?? DateTime.now(),
          hasRealtime: Value(tripHasRealtime(trip)),
        ));
  }

  Future<void> clearLastTrip() => db.delete(db.lastTrips).go();

  // --- Haltestellen-Cache ---

  Future<void> cacheStops(Iterable<Location> stops) => db.batch((b) {
        for (final s in stops.where((s) => s.type == LocationType.stop)) {
          b.insert(
            db.stopCache,
            StopCacheCompanion.insert(
              id: s.id,
              providerId: s.providerId,
              name: s.name,
              place: Value(s.place),
              lat: Value(s.lat),
              lon: Value(s.lon),
              modes: Value(s.modes.map((m) => m.name).join(',')),
              updatedAt: DateTime.now(),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });

  /// Offline-Vorschläge aus dem lokalen Haltestellenindex.
  Future<List<Location>> searchCachedStops(String query, {int limit = 8}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final like = '%${q.replaceAll('%', '').replaceAll('_', '')}%';
    final rows = await (db.select(db.stopCache)
          ..where((t) => t.name.like(like) | (t.place + const Constant(' ') + t.name).like(like))
          ..limit(limit))
        .get();
    return rows
        .map((r) => Location(
              id: r.id,
              providerId: r.providerId,
              name: r.name,
              place: r.place,
              lat: r.lat,
              lon: r.lon,
              modes: r.modes.isEmpty
                  ? const []
                  : r.modes.split(',').map((m) => TransportMode.values.byName(m)).toList(),
            ))
        .toList();
  }

  // --- Linienabos ---

  Stream<List<Subscription>> watchSubscriptions() => db.select(db.subscriptions).watch().map((rows) => [
        for (final r in rows)
          Subscription(
            lineId: r.lineId,
            providerId: r.providerId,
            lineName: r.lineName,
            window: r.window == null ? null : TimeWindow.fromJson(jsonDecode(r.window!) as Map<String, dynamic>),
          ),
      ]);

  Future<List<Subscription>> subscriptions() => watchSubscriptions().first;

  Future<void> subscribe(Subscription s) => db.into(db.subscriptions).insertOnConflictUpdate(
        SubscriptionsCompanion.insert(
          lineId: s.lineId,
          providerId: s.providerId,
          lineName: s.lineName,
          window: Value(s.window == null ? null : _enc(s.window!.toJson())),
        ),
      );

  Future<void> unsubscribe(String lineId) =>
      (db.delete(db.subscriptions)..where((t) => t.lineId.equals(lineId))).go();

  // --- Meine Orte ---

  Stream<List<SavedPlace>> watchPlaces() => db.select(db.savedPlaces).watch().map((rows) {
        final list = [
          for (final r in rows)
            SavedPlace(
              id: r.id,
              name: r.name,
              kind: PlaceKind.values.firstWhere((k) => k.name == r.kind, orElse: () => PlaceKind.other),
              location: _loc(r.location),
            ),
        ];
        list.sort((a, b) => a.kind.index != b.kind.index ? a.kind.index - b.kind.index : a.name.compareTo(b.name));
        return list;
      });

  Future<void> savePlace(SavedPlace p) => db.into(db.savedPlaces).insertOnConflictUpdate(
        SavedPlacesCompanion.insert(id: p.id, name: p.name, kind: p.kind.name, location: _enc(p.location.toJson())),
      );

  Future<void> deletePlace(String id) => (db.delete(db.savedPlaces)..where((t) => t.id.equals(id))).go();

  // --- Fahrtenwecker ---

  Stream<List<Alarm>> watchAlarms() => db.select(db.alarms).watch().map((rows) {
        final list = <Alarm>[];
        for (final r in rows) {
          try {
            list.add(Alarm.fromJson(jsonDecode(r.data) as Map<String, dynamic>));
          } catch (_) {}
        }
        list.sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
        return list;
      });

  Future<List<Alarm>> alarms() => watchAlarms().first;

  Future<void> saveAlarm(Alarm a) =>
      db.into(db.alarms).insertOnConflictUpdate(AlarmsCompanion.insert(id: a.id, data: _enc(a.toJson())));

  Future<void> deleteAlarm(String id) => (db.delete(db.alarms)..where((t) => t.id.equals(id))).go();

  // --- Einstellungen ---

  Future<String?> setting(String key) async =>
      (await (db.select(db.settings)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Stream<String?> watchSetting(String key) =>
      (db.select(db.settings)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((r) => r?.value);

  Future<void> setSetting(String key, String value) =>
      db.into(db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value));
}
