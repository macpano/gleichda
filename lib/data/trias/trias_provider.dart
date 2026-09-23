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
        throw ProviderException('Keine Verbindung zur Auskunft', cause: e);
      }
      throw ProviderException('Auskunft antwortet nicht wie erwartet', cause: e);
    }
  }

  @override
  Future<List<Location>> searchLocations(String query,
      {({double lat, double lon})? near, int limit = 10}) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (near == null) return const [];
      final list = parseLocations(
          await _post(_req.locationsNear(near.lat, near.lon, limit: limit)));
      list.sort((a, b) => (distanceBetween(a, near) ?? 1e9)
          .compareTo(distanceBetween(b, near) ?? 1e9));
      return list;
    }
    final list = parseLocations(await _post(_req.locationInformation(q, limit: limit)));
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
    final xml = await _post(_req.trip(placeOf(query.from), placeOf(query.to),
        time: query.time, arriveBy: query.arriveBy, limit: query.maxResults));
    return parseTrips(xml);
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

/// Sortierung gleichnamiger Treffer: Trefferqualität und Entfernung
/// kombiniert, damit ein exakter Namenstreffer in der Nähe oben steht.
List<Location> rankLocations(
    List<Location> list, String query, ({double lat, double lon})? near) {
  final q = query.toLowerCase();
  double score(Location l) {
    var s = l.score ?? 0.5;
    final name = l.name.toLowerCase();
    if (name == q || '${l.place ?? ''} ${l.name}'.toLowerCase() == q) s += 0.5;
    if (name.startsWith(q)) s += 0.2;
    if (near != null) {
      final d = distanceBetween(l, near);
      // Bis 2 km kein Abzug, danach je 10 km ein Viertelpunkt.
      if (d != null && d > 2000) s -= ((d - 2000) / 10000 * 0.25).clamp(0, 1);
    }
    return s;
  }

  final scored = [for (final l in list) (l, score(l))];
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final e in scored) e.$1];
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
