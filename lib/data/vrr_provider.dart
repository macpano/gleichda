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

  final _paths = <String, List<GeoPoint>?>{};

  /// Linienwege aus der EFA-Verbindungsauskunft: je Fahrtabschnitt eine
  /// Anfrage von dessen Ein- zu dessen Ausstieg, Zuordnung über Linie und
  /// Fahrtnummer (wie bei der Echtzeit), sonst über Linienname und Abfahrt.
  @override
  Future<List<List<GeoPoint>?>> legPaths(Trip trip) => Future.wait([
        for (final l in trip.legs)
          if (l.type != LegType.ride || l.from.departure == null) Future.value(null) else _legPath(l),
      ]);

  Future<List<GeoPoint>?> _legPath(Leg l) async {
    final dep = l.from.departure!.planned;
    final cacheKey = '${l.journeyRef}|${l.from.stop.id}|${l.to.stop.id}|$dep';
    if (_paths.containsKey(cacheKey)) return _paths[cacheKey];
    try {
      final paths = await efa.legPaths(stopAreaId(l.from.stop.id), stopAreaId(l.to.stop.id), dep);
      final key = l.journeyRef == null ? null : EfaTripKey.fromJourneyRef(l.journeyRef!, '', dep);
      final hit = paths
              .where((p) => key != null && p.tripCode == key.tripCode && lineKey(p.line) == lineKey(key.line))
              .firstOrNull ??
          paths
              .where((p) =>
                  p.lineName.replaceAll(' ', '') == (l.line?.name ?? '').replaceAll(' ', '') &&
                  p.departurePlanned == dep)
              .firstOrNull;
      return _paths[cacheKey] = hit?.points;
    } on ProviderException {
      return null;
    }
  }

  /// Fahrtverlauf per XML_TRIPSTOPTIMES_REQUEST, ab der Haltestelle der
  /// Abfahrt bis zur Endhaltestelle.
  @override
  Future<Trip?> tripOfDeparture(Departure d) async {
    final ref = d.journeyRef;
    if (ref == null) return null;
    final dep = d.time.planned;
    final key = EfaTripKey.fromJourneyRef(ref, stopAreaId(d.stop.id), dep);
    if (key == null) return null;
    final stops = await efa.tripStopTimes(key);
    if (stops == null || stops.length < 2) return null;
    final area = stopAreaId(d.stop.id);
    var i = stops.indexWhere((s) => stopAreaId(s.stop.id) == area && s.departure?.planned == dep);
    if (i < 0) i = stops.indexWhere((s) => stopAreaId(s.stop.id) == area);
    if (i < 0 || i >= stops.length - 1) return null;
    final last = stops.length - 1;
    return Trip(
      id: 'abfahrt:$ref:${dep.toIso8601String()}',
      legs: [
        Leg(
          type: LegType.ride,
          from: stops[i].copyWith(arrival: null),
          to: stops[last].copyWith(departure: null),
          intermediates: stops.sublist(i + 1, last),
          line: d.line,
          direction: d.direction,
          journeyRef: ref,
          operatingDay: d.operatingDay,
          messageIds: d.messageIds,
        ),
      ],
    );
  }

  /// Linien in Wuppertal: alle Linien an den großen Knoten (Hbf, Vohwinkel,
  /// Oberbarmen) plus die EFA-Liniensuche. Die sucht deutschlandweit und
  /// wird deshalb auf die Region begrenzt: WSW, Linien mit „Wuppertal“ in der
  /// Beschreibung und Züge aus dem NRW-Bereich der DB (Kennung „9xE..“).
  @override
  Future<List<Line>> searchLines(String query) async {
    String norm(String s) => s.toUpperCase().replaceAll(' ', '');
    final q = norm(query);
    if (q.isEmpty) return const [];
    _local ??= Future.wait(_hubs.map((h) => efa.linesAt(h).catchError((Object _) => <Line>[])))
        .then((l) => l.expand((x) => x).toList());
    final local = (await _local!).where((l) => norm(l.name).contains(q));
    List<Line> remote;
    try {
      remote = (await efa.searchLines(query.trim())).where(_inRegion).toList();
    } on ProviderException {
      remote = const [];
    }
    final out = <String, Line>{};
    for (final l in [...local, ...remote]) {
      out.putIfAbsent(lineKey(l.id), () => l);
    }
    final list = out.values.toList()
      ..sort((a, b) {
        int rank(Line l) => norm(l.name) == q ? 0 : (norm(l.name).startsWith(q) ? 1 : 2);
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
    return list;
  }

  Future<List<Line>>? _local;

  static const _hubs = ['de:05124:11376', 'de:05124:11302', 'de:05124:11602'];

  static bool _inRegion(Line l) {
    final parts = l.id.split(':');
    if (parts.first == 'wsw') return true;
    if ((l.longName ?? '').contains('Wuppertal')) return true;
    return parts.first == 'ddb' && parts.length > 1 && parts[1].length > 2 && parts[1][2] == 'E';
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
