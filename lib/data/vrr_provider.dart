import '../domain/models.dart';
import 'efa/efa_client.dart';
import 'transit_provider.dart';
import 'trias/trias_parser.dart' show stopAreaId;
import 'trias/trias_provider.dart';

/// VRR: TRIAS für alles, EFA nur für die Neuabfrage einer bekannten Fahrt
/// (XML_TRIPSTOPTIMES_REQUEST), weil der TRIAS-Testserver keinen
/// TripInfoRequest beantwortet.
class VrrProvider implements TransitProvider {
  VrrProvider(this.trias, this.efa);

  final TriasProvider trias;
  final EfaClient efa;

  @override
  String get id => 'vrr';

  @override
  Future<List<Location>> searchLocations(String query,
          {({double lat, double lon})? near, int limit = 10, int radiusMeters = 1000}) =>
      trias.searchLocations(query, near: near, limit: limit, radiusMeters: radiusMeters);

  @override
  Future<DepartureBoard> departures(Location stop,
          {DateTime? time, int limit = 20}) =>
      trias.departures(stop, time: time, limit: limit);

  @override
  Future<List<Trip>> planTrip(TripQuery query) => trias.planTrip(query);

  /// Meldungsliste aus der EFA (XML_ADDINFO_REQUEST), weil TRIAS Meldungen
  /// nur im Zusammenhang einer Abfahrt oder Verbindung liefert.
  @override
  Future<List<Message>> messages({List<String> lineIds = const []}) async {
    final all = await efa.messages();
    if (lineIds.isEmpty) return all;
    final keys = lineIds.map(lineKey).toSet();
    return all.where((m) => m.lineIds.any(keys.contains)).toList();
  }

  /// Steige mit Koordinaten aus der EFA, sonst die Haltestelle aus TRIAS.
  @override
  Future<List<Platform>> platforms(Location stop) async {
    try {
      final list = await efa.platforms(stopAreaId(stop.id));
      if (list.isNotEmpty) return list;
    } on ProviderException {
      // weiter mit TRIAS
    }
    return trias.platforms(stop);
  }

  /// Zuerst jeden Fahrtabschnitt einzeln über die EFA; gelingt das für einen
  /// Abschnitt nicht, die ganze Verbindung per Suche nach Linie und Zeiten.
  @override
  Future<Trip?> refreshTrip(Trip trip) async {
    try {
      final legs = <Leg>[];
      for (final leg in trip.legs) {
        if (leg.type != LegType.ride) {
          legs.add(leg);
          continue;
        }
        final updated = await refreshLegViaEfa(efa, leg);
        if (updated == null) throw const ProviderException('Abschnitt nicht gefunden');
        legs.add(updated);
      }
      return trip.copyWith(legs: legs);
    } on ProviderException {
      return trias.refreshTrip(trip);
    }
  }
}

/// Aktualisiert einen Fahrtabschnitt mit den Halten aus der EFA.
Future<Leg?> refreshLegViaEfa(EfaClient efa, Leg leg) async {
  final dep = leg.from.departure?.planned;
  if (leg.journeyRef == null || dep == null) return null;
  final key = EfaTripKey.fromJourneyRef(leg.journeyRef!, stopAreaId(leg.from.stop.id), dep);
  if (key == null) return null;
  final stops = await efa.tripStopTimes(key);
  if (stops == null) return null;
  return mergeLeg(leg, stops);
}

/// Legt die EFA-Halte über einen Abschnitt: Ein- und Ausstieg werden über
/// Haltestelle und Planzeit gefunden, die Zwischenhalte ersetzt.
Leg? mergeLeg(Leg leg, List<StopTime> stops) {
  bool same(StopTime a, StopTime b) =>
      stopAreaId(a.stop.id) == stopAreaId(b.stop.id);
  final boardAt = leg.from.departure?.planned;
  final alightAt = leg.to.arrival?.planned;
  var from = -1;
  for (var i = 0; i < stops.length; i++) {
    if (same(stops[i], leg.from) &&
        (boardAt == null || stops[i].departure?.planned == boardAt)) {
      from = i;
      break;
    }
  }
  if (from < 0) return null;
  var to = -1;
  for (var i = from + 1; i < stops.length; i++) {
    if (same(stops[i], leg.to) &&
        (alightAt == null || stops[i].arrival?.planned == alightAt)) {
      to = i;
      break;
    }
  }
  if (to < 0) return null;
  StopTime take(StopTime old, StopTime fresh) => old.copyWith(
        stop: old.stop.copyWith(lat: fresh.stop.lat ?? old.stop.lat, lon: fresh.stop.lon ?? old.stop.lon),
        arrival: fresh.arrival ?? old.arrival,
        departure: fresh.departure ?? old.departure,
        platform: fresh.platform ?? old.platform,
        status: fresh.status,
      );
  return leg.copyWith(
    from: take(leg.from, stops[from]).copyWith(arrival: null),
    to: take(leg.to, stops[to]).copyWith(departure: null),
    intermediates: stops.sublist(from + 1, to),
  );
}
