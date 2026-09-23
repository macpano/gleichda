import 'package:dio/dio.dart';

import '../../domain/models.dart';
import '../transit_provider.dart';
import 'trias_parser.dart';
import 'trias_requests.dart';

/// Standard-Datenquelle: TRIAS (VDV 431) über den VRR OpenService.
///
/// Bis zur Freigabe durch den VRR (opendata-oepnv@vrr.de) nur der
/// Testserver.
class TriasProvider implements TransitProvider {
  TriasProvider(this._dio,
      {this.endpoint = 'https://openservice-test.vrr.de/static02/trias',
      TriasRequests requests = const TriasRequests()})
      : _req = requests;

  final Dio _dio;
  final String endpoint;
  final TriasRequests _req;

  @override
  String get id => 'vrr-trias';

  Future<String> _post(String body) async {
    try {
      final res = await _dio.post<String>(
        endpoint,
        data: body,
        options: Options(
          contentType: 'text/xml; charset=utf-8',
          responseType: ResponseType.plain,
        ),
      );
      return res.data ?? '';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ProviderException('Keine Verbindung zur Auskunft', cause: e, offline: true);
      }
      throw ProviderException('Auskunft antwortet nicht wie erwartet', cause: e);
    }
  }

  @override
  Future<List<Location>> searchLocations(String query,
      {({double lat, double lon})? near, int limit = 10, int radiusMeters = 1000}) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (near == null) return const [];
      final list = parseLocations(
          await _post(_req.locationsNear(near.lat, near.lon, radiusMeters: radiusMeters, limit: limit)));
      list.sort((a, b) => (distanceBetween(a, near) ?? 1e9)
          .compareTo(distanceBetween(b, near) ?? 1e9));
      return list;
    }
    final list = parseLocations(await _post(_req.locationInformation(q, limit: limit < 20 ? 20 : limit)));
    return rankLocations(list, q, near);
  }

  @override
  Future<DepartureBoard> departures(Location stop,
      {DateTime? time, int limit = 20}) async {
    final xml = await _post(_req.stopEvent(stop.id, time: time, limit: limit));
    return parseStopEvents(xml, stop);
  }

  @override
  Future<List<Trip>> planTrip(TripQuery query) async {
    // Nur Busse ausschließen versteht der Server zuverlässig; Bahnen filtert
    // die App zusätzlich selbst (siehe docs/konzept.md).
    final ptModes = <String>{
      for (final m in query.excludedModes) ...switch (m) {
        TransportMode.bus || TransportMode.onDemand || TransportMode.replacementBus => ['bus'],
        TransportMode.tram => ['tram'],
        TransportMode.subway => ['metro'],
        _ => const <String>[],
      },
    }.toList();
    final xml = await _post(_req.trip(placeOf(query.from), placeOf(query.to),
        time: query.time,
        arriveBy: query.arriveBy,
        limit: query.maxResults,
        via: query.via == null ? null : placeOf(query.via!),
        modes: ptModes,
        accessible: query.accessible,
        walkSpeed: query.walkSpeedPercent,
        interchangeLimit: query.maxInterchanges,
        maxWalkMinutes: query.maxWalkMinutes,
        algorithm: switch (query.optimization) {
          TripOptimization.fastest => null,
          TripOptimization.minChanges => 'minChanges',
          TripOptimization.leastWalking => 'leastWalking',
        }));
    var trips = parseTrips(xml);
    if (query.excludedModes.isNotEmpty) {
      trips = trips.where((t) => !t.rides.any((r) => query.excludedModes.contains(r.line?.mode))).toList();
    }
    final maxWalk = query.maxWalkMinutes;
    if (maxWalk != null) {
      // Der Server begrenzt nur den Weg zum ersten und vom letzten Halt;
      // Umsteigewege prüft die App selbst. Bleibt nichts übrig, zeigt sie
      // lieber die Vorschläge des Servers als eine leere Liste.
      final ok = trips.where((t) => !t.legs.any((l) => l.type != LegType.ride && (l.durationMinutes ?? 0) > maxWalk)).toList();
      if (ok.isNotEmpty) trips = ok;
    }
    return trips;
  }

  /// Rückfall ohne Fahrtverlauf-Anfrage: dieselbe Verbindung neu suchen und
  /// über Linien und Planzeiten wiederfinden.
  @override
  Future<Trip?> refreshTrip(Trip trip) async {
    final dep = trip.departure.planned;
    final found = await planTrip(TripQuery(
      from: trip.origin,
      to: trip.destination,
      time: dep.subtract(const Duration(minutes: 1)),
      maxResults: 5,
    ));
    return matchTrip(trip, found);
  }

  /// TRIAS liefert keinen Linienweg (LegProjection leer, geprüft 23.09.2026).
  @override
  Future<List<List<GeoPoint>?>> legPaths(Trip trip) async => List.filled(trip.legs.length, null);

  /// Der Testserver beantwortet TripInfoRequest nicht (HTTP 400).
  @override
  Future<Trip?> tripOfDeparture(Departure departure) async => null;

  @override
  Future<List<Line>> searchLines(String query) async => const [];

  /// TRIAS kennt über die Suche nur die Haltestelle selbst, keine Steige.
  @override
  Future<List<Platform>> platforms(Location stop) async {
    if (stop.lat != null && stop.lon != null) {
      return [Platform(id: stop.id, stopId: stop.id, lat: stop.lat!, lon: stop.lon!)];
    }
    final found = parseLocations(await _post(_req.locationInformation(stop.name, limit: 5)))
        .where((l) => stopAreaId(l.id) == stopAreaId(stop.id) && l.lat != null)
        .toList();
    return [for (final l in found) Platform(id: l.id, stopId: l.id, lat: l.lat!, lon: l.lon!)];
  }

  @override
  Future<List<Message>> messages({List<String> lineIds = const []}) async {
    // TODO: Meldungsliste (Schritt 12) – TRIAS liefert Meldungen nur im
    // Kontext von Abfahrten und Verbindungen, die EFA über XML_ADDINFO_REQUEST.
    return const [];
  }
}

TriasPlace placeOf(Location l) => switch (l.type) {
      LocationType.stop => TriasStop(l.id),
      LocationType.address => TriasAddress(l.id),
      LocationType.poi => TriasPoi(l.id),
      LocationType.coordinate => TriasCoord(l.lat!, l.lon!, l.name),
    };

/// Sortierung der Suchtreffer nach Standort: Alle Treffer, die jedes Wort
/// der Eingabe enthalten, stehen vorn – untereinander nach Entfernung (auf
/// 250 m gerundet), bei gleicher Entfernung der genauere Name zuerst. Treffer
/// ohne alle Wörter folgen danach, ebenfalls nach Entfernung. Ohne Standort
/// entscheidet die Trefferqualität.
List<Location> rankLocations(
    List<Location> list, String query, ({double lat, double lon})? near) {
  String norm(String s) => s
      .toLowerCase()
      .replaceAll('hauptbahnhof', 'hbf')
      .replaceAll('bahnhof', 'bf')
      .replaceAll(RegExp(r'stra(ss|ß)e'), 'str')
      .replaceAll('.', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final q = norm(query);
  final words = q.split(' ').where((w) => w.isNotEmpty).toList();
  int tier(Location l) {
    final text = norm('${l.place ?? ''} ${l.name}');
    return words.every(text.contains) ? 0 : 1;
  }

  double quality(Location l) {
    var s = l.score ?? 0.5;
    final name = norm(l.name);
    if (name == q || norm('${l.place ?? ''} ${l.name}') == q) s += 0.5;
    if (name.startsWith(q)) s += 0.2;
    return s;
  }

  double bucket(Location l) {
    if (near == null) return 0;
    final d = distanceBetween(l, near);
    return d == null ? double.infinity : (d / 250).floorToDouble();
  }

  final keyed = [for (final l in list) (l, tier(l), bucket(l), quality(l))];
  keyed.sort((a, b) {
    final t = a.$2.compareTo(b.$2);
    if (t != 0) return t;
    final d = a.$3.compareTo(b.$3);
    if (d != 0) return d;
    return b.$4.compareTo(a.$4);
  });
  return [for (final e in keyed) e.$1];
}

/// Findet eine gespeicherte Verbindung in frischen Suchergebnissen wieder:
/// gleiche Linien in gleicher Reihenfolge, gleiche geplante Abfahrt je
/// Fahrtabschnitt.
Trip? matchTrip(Trip old, List<Trip> candidates) {
  final oldRides = old.rides;
  for (final c in candidates) {
    final rides = c.rides;
    if (rides.length != oldRides.length) continue;
    var ok = true;
    for (var i = 0; i < rides.length && ok; i++) {
      final a = oldRides[i], b = rides[i];
      ok = a.line?.id == b.line?.id &&
          a.from.departure?.planned == b.from.departure?.planned;
    }
    if (ok) return c;
  }
  return null;
}
