import 'dart:math' as math;

import '../domain/models.dart';
import 'efa/efa_client.dart';
import 'transit_provider.dart';
import 'trias/trias_parser.dart' show distanceBetween, stopAreaId;
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

  /// Ohne bekannten Ort: Wuppertal (Gemeindeschlüssel 05124 → OMC 5124000).
  static const defaultRegion = '5124000';

  /// Gebiete rund um einen Ort: die Gemeinden an der Mitte und an acht
  /// Punkten im Abstand von 5 km. Eine Sperrung in Herdecke betrifft auch
  /// Hagener Linien, steht bei der EFA aber nur unter Herdecke (gemessen
  /// 23.09.2026: 518/519 nur unter OMC 5954020). Die EFA braucht den vollen
  /// Gemeindeschlüssel; aus der Haltestellenkennung („de:05954:…“) ergäbe
  /// sich nur der Kreis, und der liefert keine Meldungen.
  @override
  Future<List<String>> regionsOf(GeoPoint near) async {
    final last = _regionsAt;
    if (_regions != null && last != null && _distance(last, near) < 1000) return _regions!;
    final k = math.cos(near.lat * math.pi / 180);
    final points = [
      near,
      for (var a = 0; a < 360; a += 45)
        (
          lat: near.lat + 5000 * math.cos(a * math.pi / 180) / 110540,
          lon: near.lon + 5000 * math.sin(a * math.pi / 180) / (111320 * k),
        ),
    ];
    final sets = await Future.wait(points.map((p) => efa.placesNear(p.lat, p.lon).catchError((Object _) => <String>{})));
    final out = <String>[];
    for (final s in sets) {
      for (final omc in s) {
        if (!out.contains(omc)) out.add(omc);
      }
    }
    _regionsAt = near;
    return _regions = out.take(6).toList();
  }

  GeoPoint? _regionsAt;
  List<String>? _regions;

  static double _distance(GeoPoint a, GeoPoint b) =>
      distanceBetween(Location(id: '', providerId: '', name: '', lat: a.lat, lon: a.lon), b) ?? double.infinity;

  @override
  Future<DepartureBoard> departures(Location stop,
          {DateTime? time, int limit = 20}) =>
      trias.departures(stop, time: time, limit: limit);

  @override
  Future<List<Trip>> planTrip(TripQuery query) => trias.planTrip(query);

  /// Meldungsliste aus der EFA (XML_ADDINFO_REQUEST), weil TRIAS Meldungen
  /// nur im Zusammenhang einer Abfahrt oder Verbindung liefert.
  @override
  Future<List<Message>> messages({List<String> lineIds = const [], List<String> regions = const []}) async {
    final omcs = regions.isEmpty ? const [defaultRegion] : regions;
    final lists = await Future.wait(omcs.map((o) => efa.messages(omc: o).then<List<Message>?>((l) => l,
        onError: (Object _) => null)));
    if (lists.every((l) => l == null)) throw const ProviderException('Meldungen nicht abrufbar');
    final seen = <String>{};
    final all = [
      for (final l in lists)
        for (final m in l ?? const <Message>[])
          if (seen.add(m.id)) m,
    ];
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

  /// Liniensuche deutschlandweit (EFA `XML_SERVINGLINES_REQUEST mode=line`),
  /// nach Standort sortiert: zuerst Linien, die an Haltestellen in der Nähe
  /// halten, dann Linien derselben Verkehrsbetriebe bzw. DB-Region, dann der
  /// Rest. Linien in der Nähe erscheinen auch, wenn die Suche sie nicht
  /// liefert (bei kurzen Nummern wie „60“ bricht sie nach etwa 160 Treffern ab).
  @override
  Future<List<Line>> searchLines(String query, {GeoPoint? near}) async {
    String norm(String s) => s.toUpperCase().replaceAll(' ', '');
    final q = norm(query);
    if (q.isEmpty) return const [];
    final nearby = near == null ? const <Line>[] : await _linesNear(near);
    List<Line> remote;
    try {
      remote = await efa.searchLines(query.trim());
    } on ProviderException {
      if (nearby.isEmpty) rethrow;
      remote = const [];
    }
    final nearKeys = {for (final l in nearby) lineKey(l.id)};
    final nearNets = {for (final l in nearby) _network(l.id)};
    final out = <String, Line>{};
    for (final l in [...nearby.where((l) => norm(l.name).contains(q)), ...remote]) {
      out.putIfAbsent(lineKey(l.id), () => l);
    }
    int tier(Line l) => nearKeys.contains(lineKey(l.id)) ? 0 : (nearNets.contains(_network(l.id)) ? 1 : 2);
    int match(Line l) => norm(l.name) == q ? 0 : (norm(l.name).startsWith(q) ? 1 : 2);
    return out.values.toList()
      ..sort((a, b) {
        for (final c in [tier(a).compareTo(tier(b)), match(a).compareTo(match(b))]) {
          if (c != 0) return c;
        }
        return a.name.compareTo(b.name);
      });
  }

  /// Verkehrsbetrieb einer Linie; bei der DB (bundesweit „ddb“) die Region
  /// aus der Kennung („ddb:92E08“ → „ddb:E“, NRW).
  static String _network(String id) {
    final parts = id.split(':');
    if (parts.first == 'ddb' && parts.length > 1 && parts[1].length > 2) return 'ddb:${parts[1][2]}';
    return parts.first;
  }

  GeoPoint? _nearAt;
  Future<List<Line>>? _near;

  /// Linien an den vier nächsten Haltestellen (Umkreis 1,5 km), je Standort
  /// einmal abgefragt; neu erst nach mehr als 1 km Ortswechsel.
  Future<List<Line>> _linesNear(GeoPoint p) {
    final last = _nearAt;
    if (_near == null || last == null || distanceBetween(Location(id: '', providerId: '', name: '', lat: last.lat, lon: last.lon), p)! > 1000) {
      _nearAt = p;
      _near = () async {
        try {
          final stops = await trias.searchLocations('', near: p, limit: 4, radiusMeters: 1500);
          final lists = await Future.wait(
              stops.map((s) => efa.linesAt(stopAreaId(s.id)).catchError((Object _) => <Line>[])));
          return lists.expand((l) => l).toList();
        } on ProviderException {
          return <Line>[];
        }
      }();
    }
    return _near!;
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
  // Der volle Name der EFA („Wuppertal Hbf“) ersetzt einen gespeicherten
  // Kurznamen („Hbf“) – so heilen auch Fahrten aus älteren Versionen.
  String nameOf(StopTime old, StopTime fresh) =>
      fresh.stop.name.length > old.stop.name.length && fresh.stop.name.contains(old.stop.name)
          ? fresh.stop.name
          : old.stop.name;
  StopTime take(StopTime old, StopTime fresh) => old.copyWith(
        stop: old.stop.copyWith(
          name: nameOf(old, fresh),
          lat: fresh.stop.lat ?? old.stop.lat,
          lon: fresh.stop.lon ?? old.stop.lon,
        ),
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

