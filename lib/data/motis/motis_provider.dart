import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../../domain/models.dart';
import '../../domain/product.dart';
import '../transit_provider.dart';

/// Transitous (MOTIS 2, https://transitous.org): offene, gemeinschaftlich
/// betriebene Auskunft für ganz Deutschland und Europa – hier für alles
/// außerhalb des VRR. Bedingungen (geprüft 23.09.2026): Projekt Open Source
/// und nicht kommerziell, schonender Abruf, User-Agent mit Kontakt, sichtbarer
/// Verweis auf https://transitous.org/sources/ (unter Mehr → Datenquellen).
class MotisProvider implements TransitProvider {
  MotisProvider(Dio dio, {this.base = 'https://api.transitous.org/api/v1'}) : _dio = dio;

  final Dio _dio;
  final String base;

  static const providerKey = 'motis';

  /// Präfix für Fahrt- und Abfahrtskennungen, damit die App sie der Quelle
  /// zuordnen kann.
  static const refPrefix = 'motis:';

  static const _userAgent = 'Gleich.da (+https://github.com/macpano/gleich.da)';

  @override
  String get id => 'transitous';

  /// Linienwege je Fahrt und Einstieg, aus der Verbindungssuche gemerkt.
  final _geometry = <String, List<GeoPoint>>{};

  Future<dynamic> _get(String path, Map<String, dynamic> params) async {
    try {
      final res = await _dio.get<dynamic>('$base/$path',
          queryParameters: {...params, 'language': 'de'},
          options: Options(headers: {'User-Agent': _userAgent}));
      return res.data;
    } on DioException catch (e) {
      final offline = e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout;
      throw ProviderException(offline ? 'Keine Verbindung zu Transitous' : 'Transitous antwortet nicht',
          cause: e, offline: offline);
    }
  }

  // --- Orte ---

  @override
  Future<List<Location>> searchLocations(String query,
      {({double lat, double lon})? near, int limit = 10, int radiusMeters = 1000}) async {
    if (query.trim().isEmpty) {
      if (near == null) return const [];
      return _stopsNear(near, radiusMeters, limit);
    }
    final data = await _get('geocode', {
      'text': query,
      if (near != null) 'place': '${near.lat},${near.lon}',
    });
    final out = <Location>[];
    for (final m in (data as List? ?? const [])) {
      if (m is! Map) continue;
      final l = parseMotisPlace(m);
      if (l != null) out.add(l);
      if (out.length >= limit) break;
    }
    return out;
  }

  Future<List<Location>> _stopsNear(GeoPoint near, int radius, int limit) async {
    final dLat = radius / 110540;
    final dLon = radius / (111320 * math.cos(near.lat * math.pi / 180));
    final data = await _get('map/stops', {
      'min': '${near.lat - dLat},${near.lon - dLon}',
      'max': '${near.lat + dLat},${near.lon + dLon}',
    });
    final seen = <String>{};
    final list = <Location>[];
    for (final m in (data as List? ?? const [])) {
      if (m is! Map) continue;
      final l = parseMotisStop(m, parent: true);
      if (l == null || !seen.add(l.id)) continue;
      list.add(l);
    }
    double d(Location l) => _meters(near, (lat: l.lat!, lon: l.lon!));
    list.sort((a, b) => d(a).compareTo(d(b)));
    return list.where((l) => d(l) <= radius).take(limit).toList();
  }

  // --- Abfahrten ---

  @override
  Future<DepartureBoard> departures(Location stop, {DateTime? time, int limit = 20}) async {
    final data = await _get('stoptimes', {
      'stopId': stop.id,
      'n': limit,
      if (time != null) 'time': time.toUtc().toIso8601String(),
    });
    final out = <Departure>[];
    for (final s in ((data as Map?)?['stopTimes'] as List? ?? const [])) {
      if (s is! Map) continue;
      final place = (s['place'] as Map?) ?? const {};
      final t = _time(place['scheduledDeparture'], place['departure'], s['realTime'] == true);
      if (t == null) continue;
      final cancelled = s['cancelled'] == true || s['tripCancelled'] == true || place['cancelled'] == true;
      out.add(Departure(
        stop: stop,
        line: motisLine(s),
        direction: (s['headsign'] as String?) ?? ((s['tripTo'] as Map?)?['name'] as String?) ?? '',
        time: t,
        plannedPlatform: place['scheduledTrack'] as String? ?? place['track'] as String?,
        platform: place['track'] as String?,
        status: cancelled ? StopStatus.cancelled : StopStatus.normal,
        journeyRef: s['tripId'] == null ? null : '$refPrefix${s['tripId']}',
      ));
    }
    out.sort((a, b) => a.time.best.compareTo(b.time.best));
    return DepartureBoard(out, const []);
  }

  // --- Verbindungen ---

  static String _placeParam(Location l) {
    if (l.providerId == providerKey && l.type == LocationType.stop) return l.id;
    if (l.lat != null && l.lon != null) return '${l.lat},${l.lon}';
    return l.id;
  }

  @override
  Future<List<Trip>> planTrip(TripQuery query) async {
    final excluded = query.excludedModes;
    final modes = <String>{
      if (!excluded.contains(TransportMode.bus)) ...['BUS', 'COACH'],
      if (!excluded.contains(TransportMode.tram)) 'TRAM',
      if (!excluded.contains(TransportMode.subway)) ...['SUBWAY', 'METRO'],
      if (!excluded.contains(TransportMode.suburbanRail)) 'SUBURBAN',
      if (!excluded.contains(TransportMode.rail)) ...['REGIONAL_RAIL', 'REGIONAL_FAST_RAIL', 'RAIL'],
      if (!excluded.contains(TransportMode.longDistanceRail)) ...['HIGHSPEED_RAIL', 'LONG_DISTANCE', 'NIGHT_RAIL'],
      if (!excluded.contains(TransportMode.ferry)) 'FERRY',
      if (!excluded.contains(TransportMode.onDemand)) 'ODM',
      'FUNICULAR',
      'AERIAL_LIFT',
    };
    final walk = query.maxWalkMinutes;
    final data = await _get('plan', {
      'fromPlace': _placeParam(query.from),
      'toPlace': _placeParam(query.to),
      if (query.via != null) 'via': _placeParam(query.via!),
      'time': query.time.toUtc().toIso8601String(),
      'arriveBy': query.arriveBy,
      'numItineraries': query.maxResults,
      if (excluded.isNotEmpty) 'transitModes': modes.join(','),
      if (query.maxInterchanges != null) 'maxTransfers': query.maxInterchanges,
      if (walk != null) 'maxPreTransitTime': walk * 60,
      if (walk != null) 'maxPostTransitTime': walk * 60,
      if (query.accessible) 'pedestrianProfile': 'WHEELCHAIR',
    });
    final trips = <Trip>[];
    for (final it in ((data as Map?)?['itineraries'] as List? ?? const [])) {
      if (it is! Map) continue;
      final t = parseMotisItinerary(it, from: query.from, to: query.to, geometry: _geometry);
      if (t != null) trips.add(t);
    }
    // Direkter Fußweg, wenn es sonst nichts gibt (nah am Ziel).
    if (trips.isEmpty) {
      for (final it in (data?['direct'] as List? ?? const [])) {
        if (it is! Map) continue;
        final t = parseMotisItinerary(it, from: query.from, to: query.to, geometry: _geometry);
        if (t != null) trips.add(t);
      }
    }
    return trips;
  }

  /// Dieselbe Verbindung neu suchen und über ihre Fahrten wiederfinden.
  @override
  Future<Trip?> refreshTrip(Trip trip) async {
    final rides = trip.rides;
    if (trip.legs.isEmpty) return null;
    final start = trip.departure.planned.subtract(const Duration(minutes: 2));
    final found = await planTrip(TripQuery(
      from: trip.legs.first.from.stop,
      to: trip.legs.last.to.stop,
      time: start,
      maxResults: 6,
    ));
    String sig(Trip t) => t.rides.map((r) => r.journeyRef).join('|');
    final want = sig(trip);
    final hit = found.where((t) => rides.isEmpty ? t.rides.isEmpty : sig(t) == want).firstOrNull;
    return hit?.copyWith(id: trip.id, messages: trip.messages);
  }

  @override
  Future<List<List<GeoPoint>?>> legPaths(Trip trip) async => [
        for (final l in trip.legs)
          l.type == LegType.ride ? _geometry['${l.journeyRef}|${l.from.stop.id}'] : null,
      ];

  /// Ganze Fahrt eines Fahrzeugs (`/trip`), ab der Abfahrt bzw. [whole].
  @override
  Future<Trip?> tripOfDeparture(Departure d, {bool whole = false}) async {
    final ref = d.journeyRef;
    if (ref == null || !ref.startsWith(refPrefix)) return null;
    final data = await _get('trip', {'tripId': ref.substring(refPrefix.length)});
    if (data is! Map) return null;
    final full = parseMotisItinerary(data, geometry: _geometry);
    if (full == null || full.rides.isEmpty) return null;
    final leg = full.rides.first;
    final stops = [leg.from, ...leg.intermediates, leg.to];
    var i = whole ? 0 : stops.indexWhere((s) => s.stop.id == d.stop.id || s.departure?.planned == d.time.planned);
    if (i < 0) i = 0;
    if (i >= stops.length - 1) return null;
    return Trip(
      id: '${whole ? 'linie' : 'abfahrt'}:$ref:${d.time.planned.toIso8601String()}',
      legs: [
        leg.copyWith(
          from: stops[i].copyWith(arrival: null),
          to: stops.last.copyWith(departure: null),
          intermediates: stops.sublist(i + 1, stops.length - 1),
          line: d.line,
          direction: d.direction,
        ),
      ],
    );
  }

  // --- Was Transitous nicht liefert ---

  @override
  Future<List<Message>> messages({List<String> lineIds = const [], List<String> regions = const []}) async =>
      const [];

  @override
  Future<List<String>> regionsOf(GeoPoint near) async => const [];

  @override
  Future<List<Platform>> platforms(Location stop) async => const [];

  @override
  Future<Set<int>> guaranteedConnections(Trip trip) async => const {};

  @override
  Future<Map<String, Set<int>>> guaranteedForTrips(List<Trip> trips) async => const {};

  @override
  Future<List<Platform>> platformsNear(GeoPoint near, {int radiusMeters = 800}) async => const [];

  @override
  Future<List<Line>> linesNear(GeoPoint near) async => const [];

  @override
  Future<List<Line>> linesAround(GeoPoint near) async => const [];

  @override
  Future<List<Message>> messagesForLine(String lineKey) async => const [];

  @override
  Future<List<Line>> searchLines(String query, {GeoPoint? near}) async => const [];
}

// --- Umsetzung der Antworten (öffentlich für Tests) ---

EventTime? _time(Object? scheduled, Object? actual, bool realtime) {
  final p = DateTime.tryParse(scheduled as String? ?? '') ?? DateTime.tryParse(actual as String? ?? '');
  if (p == null) return null;
  final a = DateTime.tryParse(actual as String? ?? '');
  return EventTime(
    planned: p,
    estimated: realtime ? a : null,
    quality: realtime ? TimeQuality.realtime : TimeQuality.planned,
  );
}

double _meters(GeoPoint a, GeoPoint b) {
  const r = 6371000.0;
  final dLat = (b.lat - a.lat) * math.pi / 180;
  final dLon = (b.lon - a.lon) * math.pi / 180;
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(a.lat * math.pi / 180) * math.cos(b.lat * math.pi / 180) * math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

/// Ort aus `/geocode`: Haltestelle, Adresse oder Ort (POI).
Location? parseMotisPlace(Map m) {
  final lat = (m['lat'] as num?)?.toDouble();
  final lon = (m['lon'] as num?)?.toDouble();
  final name = m['name'] as String?;
  final id = m['id'] as String?;
  if (lat == null || lon == null || name == null || id == null) return null;
  final type = switch (m['type']) {
    'STOP' => LocationType.stop,
    'ADDRESS' => LocationType.address,
    _ => LocationType.poi,
  };
  final areas = (m['areas'] as List? ?? const []).whereType<Map>().toList();
  // Ort: die Gemeinde (Verwaltungsebene 8), sonst Kreis (6), sonst Land (4 –
  // Berlin, Hamburg, Bremen) – nicht der Stadtteil („Charlottenburg“).
  String? level(int n) =>
      areas.where((a) => ((a['adminLevel'] as num?) ?? 0).toInt() == n).map((a) => a['name'] as String?).firstOrNull;
  final place = level(8) ?? level(6) ?? level(4);
  final street = m['street'] as String?;
  final house = m['houseNumber'] as String?;
  return Location(
    id: id,
    providerId: MotisProvider.providerKey,
    name: type == LocationType.address && street != null ? [street, ?house].join(' ') : name,
    place: place,
    lat: lat,
    lon: lon,
    type: type,
  );
}

/// Haltestelle aus `/map/stops` bzw. einem Halt der Fahrt. Mit [parent] die
/// übergeordnete Haltestelle statt des einzelnen Steigs.
Location? parseMotisStop(Map m, {bool parent = false}) {
  final lat = (m['lat'] as num?)?.toDouble();
  final lon = (m['lon'] as num?)?.toDouble();
  final id = (parent ? (m['parentId'] ?? m['stopId']) : m['stopId']) as String?;
  if (lat == null || lon == null || id == null) return null;
  return Location(
    id: id.endsWith('_G') ? id.substring(0, id.length - 2) : id,
    providerId: MotisProvider.providerKey,
    name: (m['name'] as String?) ?? '',
    lat: lat,
    lon: lon,
    type: LocationType.stop,
  );
}

/// Verkehrsmittel aus dem GTFS-Routentyp (genauer als MOTIS' `mode`, das
/// etwa die Münchner S-Bahn als METRO führt), sonst aus `mode`.
TransportMode motisMode(Map m) {
  final rt = (m['routeType'] as num?)?.toInt();
  if (rt != null) {
    if (rt == 0 || (rt >= 900 && rt < 1000)) return TransportMode.tram;
    if (rt == 1 || (rt >= 400 && rt < 500)) return TransportMode.subway;
    if (rt == 109) return TransportMode.suburbanRail;
    if (rt == 101 || rt == 102 || rt == 105) return TransportMode.longDistanceRail;
    if (rt == 714) return TransportMode.replacementBus;
    if (rt == 715) return TransportMode.onDemand;
    if (rt == 2 || (rt >= 100 && rt < 200)) return TransportMode.rail;
    if (rt == 3 || (rt >= 200 && rt < 300) || (rt >= 700 && rt < 800)) return TransportMode.bus;
    if (rt == 4 || (rt >= 1000 && rt < 1300)) return TransportMode.ferry;
  }
  return switch (m['mode']) {
    'BUS' || 'COACH' => TransportMode.bus,
    'TRAM' => TransportMode.tram,
    'SUBWAY' || 'METRO' => TransportMode.subway,
    'SUBURBAN' => TransportMode.suburbanRail,
    'HIGHSPEED_RAIL' || 'LONG_DISTANCE' || 'NIGHT_RAIL' => TransportMode.longDistanceRail,
    'RAIL' || 'REGIONAL_RAIL' || 'REGIONAL_FAST_RAIL' => TransportMode.rail,
    'FERRY' => TransportMode.ferry,
    'ODM' => TransportMode.onDemand,
    _ => TransportMode.other,
  };
}

/// Linie aus einer Abfahrt bzw. einem Fahrtabschnitt.
Line motisLine(Map m) {
  final mode = motisMode(m);
  var name = ((m['displayName'] ?? m['routeShortName'] ?? m['tripShortName']) as String?)?.trim() ?? '';
  if (name.isEmpty) name = '?';
  // Fernzüge: „ICE 512“ statt nur „ICE“.
  final number = (m['tripShortName'] as String?)?.trim();
  if (mode == TransportMode.longDistanceRail &&
      RegExp(r'^[A-Z]{2,3}$').hasMatch(name) &&
      number != null &&
      RegExp(r'^\d+$').hasMatch(number)) {
    name = '$name ${int.parse(number)}';
  }
  return Line(
    id: '${MotisProvider.refPrefix}${m['routeId'] ?? name}',
    name: name,
    mode: mode,
    operator: m['agencyName'] as String?,
    longName: (m['routeLongName'] as String?)?.isNotEmpty == true ? m['routeLongName'] as String : null,
    product: guessProduct(name, mode: mode).name,
  );
}

StopTime _stopTime(Map p, {required bool realtime}) {
  final loc = parseMotisStop(p) ??
      Location(
        id: 'coord:${p['lat']}:${p['lon']}',
        providerId: MotisProvider.providerKey,
        name: (p['name'] as String?) ?? '',
        lat: (p['lat'] as num?)?.toDouble(),
        lon: (p['lon'] as num?)?.toDouble(),
        type: LocationType.coordinate,
      );
  return StopTime(
    stop: loc,
    arrival: _time(p['scheduledArrival'], p['arrival'], realtime),
    departure: _time(p['scheduledDeparture'], p['departure'], realtime),
    plannedPlatform: p['scheduledTrack'] as String? ?? p['track'] as String?,
    platform: p['track'] as String?,
    status: p['cancelled'] == true ? StopStatus.cancelled : StopStatus.normal,
  );
}

/// Verbindung aus `/plan` bzw. `/trip`. Start und Ziel („START“, „END“)
/// tragen die Namen aus der Suche. Linienwege landen in [geometry].
Trip? parseMotisItinerary(Map it, {Location? from, Location? to, Map<String, List<GeoPoint>>? geometry}) {
  final raw = (it['legs'] as List? ?? const []).whereType<Map>().toList();
  if (raw.isEmpty) return null;
  final legs = <Leg>[];
  for (var i = 0; i < raw.length; i++) {
    final l = raw[i];
    final realtime = l['realTime'] == true;
    var a = _stopTime((l['from'] as Map?) ?? const {}, realtime: realtime);
    var b = _stopTime((l['to'] as Map?) ?? const {}, realtime: realtime);
    if (i == 0 && from != null && a.stop.type == LocationType.coordinate) {
      a = a.copyWith(stop: from.copyWith(lat: a.stop.lat ?? from.lat, lon: a.stop.lon ?? from.lon));
    }
    if (i == raw.length - 1 && to != null && b.stop.type == LocationType.coordinate) {
      b = b.copyWith(stop: to.copyWith(lat: b.stop.lat ?? to.lat, lon: b.stop.lon ?? to.lon));
    }
    if (l['mode'] == 'WALK' || l['mode'] == 'BIKE' || l['mode'] == 'CAR') {
      final minutes = (((l['duration'] as num?) ?? 0) / 60).ceil();
      final start = _time(l['scheduledStartTime'], l['startTime'], false);
      final end = _time(l['scheduledEndTime'], l['endTime'], false);
      legs.add(Leg(
        type: i == 0 || i == raw.length - 1 ? LegType.walk : LegType.transfer,
        from: a.copyWith(departure: start ?? a.departure, arrival: null),
        to: b.copyWith(arrival: end ?? b.arrival, departure: null),
        durationMinutes: minutes,
      ));
      continue;
    }
    // Im selben Fahrzeug weiter: wie bei TRIAS als eigener Übergang.
    if (l['interlineWithPreviousLeg'] == true && legs.isNotEmpty && legs.last.type == LegType.ride) {
      legs.add(Leg(
        type: LegType.transfer,
        from: legs.last.to.copyWith(departure: a.departure),
        to: a.copyWith(departure: null),
        durationMinutes: 0,
        staySeated: true,
      ));
    }
    final tripId = l['tripId'] as String?;
    final ref = tripId == null ? null : '${MotisProvider.refPrefix}$tripId';
    final mids = [
      for (final s in (l['intermediateStops'] as List? ?? const []))
        if (s is Map) _stopTime(s, realtime: realtime),
    ];
    final geom = (l['legGeometry'] as Map?)?['points'] as String?;
    if (geometry != null && geom != null && ref != null) {
      final precision = ((l['legGeometry'] as Map?)?['precision'] as num?)?.toInt() ?? 6;
      geometry['$ref|${a.stop.id}'] = decodePolyline(geom, precision: precision);
    }
    final cancelled = l['cancelled'] == true;
    legs.add(Leg(
      type: LegType.ride,
      from: cancelled ? a.copyWith(status: StopStatus.cancelled) : a,
      to: cancelled ? b.copyWith(status: StopStatus.cancelled) : b,
      intermediates: mids,
      line: motisLine(l),
      direction: (l['headsign'] as String?) ?? ((l['tripTo'] as Map?)?['name'] as String?),
      journeyRef: ref,
    ));
  }
  final start = it['startTime'] ?? '';
  final ids = legs.map((l) => l.journeyRef ?? l.type.name).join(',');
  return Trip(id: '${MotisProvider.refPrefix}$start|$ids', legs: legs);
}

/// Polyline (Google-Format) mit [precision] Nachkommastellen – Transitous
/// liefert 7 statt der üblichen 5.
List<GeoPoint> decodePolyline(String s, {int precision = 5}) {
  final factor = math.pow(10, precision).toDouble();
  final out = <GeoPoint>[];
  var index = 0, lat = 0, lon = 0;
  int next() {
    var result = 0, shift = 0, b = 0;
    do {
      b = s.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20 && index < s.length);
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }

  while (index < s.length) {
    lat += next();
    if (index >= s.length) break;
    lon += next();
    out.add((lat: lat / factor, lon: lon / factor));
  }
  return out;
}
