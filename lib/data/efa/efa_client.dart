// VRR EFA OpenService (Mentz, rapidJSON). Nur dort genutzt, wo TRIAS
// nachweislich weniger liefert – hier: Fahrtverlauf einer bekannten Fahrt
// per XML_TRIPSTOPTIMES_REQUEST, den der TRIAS-Testserver (TripInfoRequest)
// nicht beantwortet.
import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parseFragment;

import '../../domain/models.dart';
import '../../domain/product.dart';
import '../transit_provider.dart';

const _provider = 'vrr-efa';

/// Kennungen, mit denen die EFA einen Fahrtabschnitt wiederfindet.
class EfaTripKey {
  const EfaTripKey({
    required this.line,
    required this.stopId,
    required this.tripCode,
    required this.date,
    required this.time,
  });

  /// Aus der TRIAS-Fahrtreferenz: „wsw:66604::R:w25:266“ →
  /// line „wsw:66604: :R:w25“, tripCode „266“. [departure] ist die
  /// geplante Abfahrt am Einstiegshalt [stopId].
  static EfaTripKey? fromJourneyRef(
      String journeyRef, String stopId, DateTime departure) {
    final parts = journeyRef.split(':');
    if (parts.length < 3) return null;
    final code = parts.last;
    if (int.tryParse(code) == null) return null;
    final line = parts
        .sublist(0, parts.length - 1)
        .map((p) => p.isEmpty ? ' ' : p)
        .join(':');
    final l = departure.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return EfaTripKey(
      line: line,
      stopId: stopId,
      tripCode: code,
      date: '${l.year}${two(l.month)}${two(l.day)}',
      time: '${two(l.hour)}${two(l.minute)}',
    );
  }

  final String line;
  final String stopId;
  final String tripCode;

  /// JJJJMMTT
  final String date;

  /// HHMM, Ortszeit
  final String time;

  Map<String, String> toQuery() => {
        'line': line,
        'stopID': stopId,
        'tripCode': tripCode,
        'date': date,
        'time': time,
      };
}

class EfaClient {
  EfaClient(this._dio,
      {this.baseUrl = 'https://openservice-test.vrr.de/static02'});

  final Dio _dio;
  final String baseUrl;

  Future<Map<String, dynamic>> _get(
      String endpoint, Map<String, String> params) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/$endpoint',
        queryParameters: {
          'outputFormat': 'rapidJSON',
          'coordOutputFormat': 'WGS84[dd.ddddd]',
          'useRealtime': '1',
          ...params,
        },
        options: Options(responseType: ResponseType.json),
      );
      return res.data ?? const {};
    } on DioException catch (e) {
      final offline = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;
      throw ProviderException('EFA nicht erreichbar', cause: e, offline: offline);
    }
  }

  /// Steige einer Haltestelle mit Koordinaten.
  Future<List<Platform>> platforms(String stopId) async {
    final json = await _get('XML_DM_REQUEST', {
      'type_dm': 'any',
      'name_dm': stopId,
      'mode': 'direct',
      'limit': '40',
    });
    return parsePlatforms(json, stopId);
  }

  /// Aktuelle Störungsmeldungen im Gebiet [omc] (Gemeindeschlüssel,
  /// Wuppertal 5124000).
  Future<List<Message>> messages({String omc = '5124000'}) async {
    final json = await _get('XML_ADDINFO_REQUEST', {
      'filterPublicationStatus': 'current',
      'filterValidDay': '1',
      'filterOMC': omc,
    });
    return parseAddInfo(json);
  }

  /// Linienwege der Verbindung von [from] nach [to] ab [departure]
  /// (Haltestellen-IDs wie „de:05124:11097“).
  Future<List<EfaLegPath>> legPaths(String from, String to, DateTime departure) async {
    final l = departure.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final json = await _get('XML_TRIP_REQUEST2', {
      'type_origin': 'stop',
      'name_origin': from,
      'type_destination': 'stop',
      'name_destination': to,
      'itdDate': '${l.year}${two(l.month)}${two(l.day)}',
      'itdTime': '${two(l.hour)}${two(l.minute)}',
      'itdTripDateTimeDepArr': 'dep',
      'calcNumberOfTrips': '4',
    });
    return parseLegPaths(json);
  }

  /// Gemeindeschlüssel (OMC) der Haltestellen nahe einer Koordinate
  /// (XML_COORD_REQUEST): „placeID:5954020:2“ → „5954020“ (Herdecke).
  Future<Set<String>> placesNear(double lat, double lon, {int radiusMeters = 1500}) async =>
      {for (final s in await stopsNear(lat, lon, radiusMeters: radiusMeters)) ?s.omc};

  /// Steige (Haltepunkte) im Umkreis mit genauer Lage (XML_COORD_REQUEST,
  /// BUS_POINT). Die Haltestellenmitte aus TRIAS liegt an großen Haltestellen
  /// bis zu 120 m daneben (gemessen 23.09.2026, Hist. Stadthalle).
  Future<List<Platform>> platformsNear(double lat, double lon, {int radiusMeters = 800}) async {
    final json = await _get('XML_COORD_REQUEST', {
      'coord': '${lon.toStringAsFixed(5)}:${lat.toStringAsFixed(5)}:WGS84[dd.ddddd]',
      'inclFilter': '1',
      'type_1': 'BUS_POINT',
      'radius_1': '$radiusMeters',
      'max': '300',
    });
    return [
      for (final l in (json['locations'] as List?) ?? const [])
        if (l is Map && l['id'] is String && l['coord'] is List && (l['coord'] as List).length == 2)
          Platform(
            id: l['id'] as String,
            stopId: ((l['parent'] as Map?)?['id'] as String?) ?? stopAreaIdOf(l['id'] as String),
            name: (l['id'] as String).split(':').last,
            direction: l['name'] as String?,
            lat: ((l['coord'] as List)[0] as num).toDouble(),
            lon: ((l['coord'] as List)[1] as num).toDouble(),
          ),
    ];
  }

  /// Nächste Haltestellen (Kennung und Gemeinde) nahe einer Koordinate.
  Future<List<({String id, String? omc})>> stopsNear(double lat, double lon, {int radiusMeters = 1500}) async {
    final json = await _get('XML_COORD_REQUEST', {
      'coord': '${lon.toStringAsFixed(5)}:${lat.toStringAsFixed(5)}:WGS84[dd.ddddd]',
      'inclFilter': '1',
      'type_1': 'STOP',
      'radius_1': '$radiusMeters',
      'max': '3',
    });
    return [
      for (final l in (json['locations'] as List?) ?? const [])
        if (l is Map && l['id'] is String)
          (id: l['id'] as String, omc: omcFromPlaceId(((l['parent'] as Map?)?['id']) as String?)),
    ];
  }

  /// Alle aktuellen Meldungen im VRR (gut 1000, rund 4 MB) – nur für eine
  /// einzelne Linie, weil die EFA nicht nach Linie filtern kann (geprüft
  /// 23.09.2026: filterLine, filterPNLineDir u. a. wirkungslos).
  Future<List<Message>> allMessages() async {
    final json = await _get('XML_ADDINFO_REQUEST', {'filterPublicationStatus': 'current'});
    return parseAddInfo(json);
  }

  /// Linien zum Suchbegriff (Liniennummer), deutschlandweit.
  Future<List<Line>> searchLines(String query) async {
    final json = await _get('XML_SERVINGLINES_REQUEST', {'mode': 'line', 'lineName': query});
    return parseServingLines(json);
  }

  /// Linien, die an einer Haltestelle halten.
  Future<List<Line>> linesAt(String stopId) async {
    final json = await _get('XML_SERVINGLINES_REQUEST',
        {'mode': 'odv', 'type_sl': 'stopID', 'name_sl': stopId, 'lsShowTrainsExplicit': '1'});
    return parseServingLines(json);
  }

  /// Alle Halte eines Fahrtabschnitts mit Plan- und Echtzeit. null, wenn die
  /// EFA die Fahrt nicht kennt.
  Future<List<StopTime>?> tripStopTimes(EfaTripKey key) async {
    final json = await _get('XML_TRIPSTOPTIMES_REQUEST', {
      ...key.toQuery(),
      'tStOTType': 'all',
    });
    return parseTripStopTimes(json);
  }
}

DateTime? _t(Object? s) => s is String ? DateTime.tryParse(s) : null;

EventTime? _time(Map<String, dynamic> s, String kind, bool monitored) {
  final planned = _t(s['${kind}TimePlanned']);
  if (planned == null) return null;
  final est = _t(s['${kind}TimeEstimated']);
  return EventTime(
    planned: planned,
    estimated: est,
    quality: est == null
        ? TimeQuality.planned
        : (monitored ? TimeQuality.realtime : TimeQuality.estimated),
  );
}

List<StopTime>? parseTripStopTimes(Map<String, dynamic> json) {
  final leg = json['leg'];
  if (leg is! Map<String, dynamic>) return null;
  final seq = leg['stopSequence'];
  if (seq is! List || seq.isEmpty) return null;
  final legStatus = (leg['realtimeStatus'] as List?)?.cast<String>() ?? const [];
  final monitored = legStatus.contains('MONITORED');
  final tripCancelled = legStatus.contains('TRIP_CANCELLED');
  final out = <StopTime>[];
  var i = 0;
  for (final raw in seq) {
    if (raw is! Map<String, dynamic>) continue;
    final props = (raw['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
    final parent = (raw['parent'] as Map?)?.cast<String, dynamic>();
    final locality = (parent?['parent'] as Map?)?['name'] as String?;
    final coord = raw['coord'] as List?;
    final status = (raw['realtimeStatus'] as List?)?.cast<String>() ?? const [];
    // Voller Name mit Ort („Wuppertal Hauptbahnhof“), nicht der Kurzname.
    final name = (parent?['name'] ?? raw['name'] ?? parent?['disassembledName']) as String;
    out.add(StopTime(
      stop: Location(
        id: raw['id'] as String,
        providerId: _provider,
        // disassembledName ist bei Steigen teils nur die Steignummer.
        name: RegExp(r'^\d+$').hasMatch(name) ? (raw['name'] as String) : name,
        place: locality,
        lat: (coord != null && coord.length == 2) ? (coord[0] as num).toDouble() : null,
        lon: (coord != null && coord.length == 2) ? (coord[1] as num).toDouble() : null,
      ),
      arrival: _time(raw, 'arrival', monitored),
      departure: _time(raw, 'departure', monitored),
      plannedPlatform: props['plannedPlatformName'] as String?,
      platform: (props['platformName'] ?? props['plannedPlatformName']) as String?,
      status: tripCancelled || status.contains('STOP_CANCELLED')
          ? StopStatus.cancelled
          : (status.contains('EXTRA_STOP') ? StopStatus.diversion : StopStatus.normal),
      sequence: i++,
    ));
  }
  return out;
}

/// Steige aus den Abfahrten einer Haltestelle (XML_DM_REQUEST): Die EFA
/// liefert je Abfahrt den Steig mit Koordinate.
List<Platform> parsePlatforms(Map<String, dynamic> json, String stopId) {
  final events = json['stopEvents'];
  if (events is! List) return const [];
  final out = <String, Platform>{};
  for (final e in events) {
    if (e is! Map) continue;
    final l = e['location'];
    if (l is! Map) continue;
    final coord = l['coord'];
    final id = l['id'] as String?;
    if (id == null || coord is! List || coord.length != 2) continue;
    final props = (l['properties'] as Map?) ?? const {};
    final dest = ((e['transportation'] as Map?)?['destination'] as Map?)?['name'] as String?;
    out.putIfAbsent(
      id,
      () => Platform(
        id: id,
        stopId: stopId,
        name: (props['platformName'] ?? props['platform']) as String?,
        direction: dest,
        lat: (coord[0] as num).toDouble(),
        lon: (coord[1] as num).toDouble(),
      ),
    );
  }
  return out.values.toList();
}

/// Linienkennung ohne Richtung und Fahrplanperiode: „wsw:66620::H“ und
/// „wsw:66620: :H:“ werden beide zu „wsw:66620“. So passen TRIAS- und
/// EFA-Linien zusammen, etwa für Linienabos.
String lineKey(String id) {
  final parts = id.split(':');
  return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : id;
}

/// Störungsmeldungen aus XML_ADDINFO_REQUEST.
List<Message> parseAddInfo(Map<String, dynamic> json) {
  final current = (json['infos'] as Map?)?['current'];
  if (current is! List) return const [];
  final out = <Message>[];
  for (final raw in current) {
    if (raw is! Map) continue;
    final link = (raw['infoLinks'] as List?)?.whereType<Map>().firstOrNull;
    final title = (link?['title'] ?? link?['subtitle'] ?? link?['urlText']) as String?;
    if (title == null || title.trim().isEmpty) continue;
    final affected = (raw['affected'] as Map?) ?? const {};
    final lines = ((affected['lines'] as List?) ?? const []).whereType<Map>().toList();
    final stops = ((affected['stops'] as List?) ?? const []).whereType<Map>().toList();
    final validity = ((raw['timestamps'] as Map?)?['validity'] as List?)?.whereType<Map>().toList() ?? const [];
    final source = ((raw['properties'] as Map?)?['source'] as Map?)?['name'] as String?;
    // Je Linie einmal (die EFA nennt Hin- und Rückrichtung einzeln).
    final seenLines = <String>{};
    final uniqueLines = [
      for (final l in lines)
        if (seenLines.add(lineKey(l['id'] as String? ?? '${l['number']}'))) l,
    ];
    out.add(Message(
      id: raw['id'] as String,
      title: title.trim(),
      text: htmlToText(link?['content'] as String?),
      lineIds: [for (final l in uniqueLines) lineKey(l['id'] as String? ?? '')],
      lineNames: [for (final l in uniqueLines) (l['number'] ?? l['name'] ?? '') as String],
      stopIds: [for (final s in stops) if (s['id'] is String) s['id'] as String],
      validFrom: validity.isEmpty ? null : DateTime.tryParse(validity.first['from'] as String? ?? ''),
      validTo: validity.isEmpty ? null : DateTime.tryParse(validity.last['to'] as String? ?? ''),
      source: source == null ? null : (source.startsWith('VRR') ? 'VRR' : source),
    ));
  }
  return out;
}

/// Klartext aus dem HTML der Meldung: Absätze als Zeilen, Entities aufgelöst.
String? htmlToText(String? html) {
  if (html == null || html.trim().isEmpty) return null;
  final doc = parseFragment(html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>|</li>|</div>', caseSensitive: false), '\n'));
  final text = doc.text ?? '';
  return text
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((l) => l.isNotEmpty)
      .join('\n');
}

/// Linienweg eines Fahrtabschnitts aus XML_TRIP_REQUEST2 (`legs[].coords`).
/// Gemessen 23.09.2026: dichte Punktfolge entlang Straße bzw. Gleis, z. B.
/// 210 Punkte für einen RE4-Abschnitt. TRIAS liefert keinen Linienweg.
class EfaLegPath {
  const EfaLegPath({
    required this.line,
    required this.lineName,
    required this.tripCode,
    required this.departurePlanned,
    required this.points,
  });

  /// Linienkennung wie „wsw:66604: :R:w25“.
  final String line;
  final String lineName;
  final String? tripCode;
  final DateTime? departurePlanned;
  final List<GeoPoint> points;
}

List<EfaLegPath> parseLegPaths(Map<String, dynamic> json) {
  final out = <EfaLegPath>[];
  for (final j in (json['journeys'] as List?) ?? const []) {
    if (j is! Map) continue;
    for (final l in (j['legs'] as List?) ?? const []) {
      if (l is! Map) continue;
      final t = l['transportation'];
      final coords = l['coords'];
      if (t is! Map || coords is! List || coords.length < 2) continue;
      final id = t['id'] as String?;
      if (id == null) continue;
      out.add(EfaLegPath(
        line: id,
        lineName: (t['disassembledName'] ?? t['number'] ?? '') as String,
        tripCode: ((t['properties'] as Map?)?['tripCode'])?.toString(),
        departurePlanned: _t((l['origin'] as Map?)?['departureTimePlanned']),
        points: [
          for (final c in coords)
            if (c is List && c.length >= 2) (lat: (c[0] as num).toDouble(), lon: (c[1] as num).toDouble()),
        ],
      ));
    }
  }
  return out;
}

/// Linien aus XML_SERVINGLINES_REQUEST, je Linie (ohne Richtung und
/// Fahrplanperiode) einmal.
List<Line> parseServingLines(Map<String, dynamic> json) {
  final out = <String, Line>{};
  for (final raw in (json['lines'] as List?) ?? const []) {
    if (raw is! Map) continue;
    final id = raw['id'] as String?;
    final name = (raw['disassembledName'] ?? raw['number']) as String?;
    if (id == null || name == null || name.isEmpty) continue;
    final product = (raw['product'] as Map?) ?? const {};
    final cls = (product['class'] as num?)?.toInt();
    final pName = product['name'] as String?;
    final info = classifyLine(
      ptMode: switch (cls) {
        0 || 13 || 14 || 15 || 16 => 'rail',
        1 => 'rail',
        2 || 3 => 'metro',
        4 => 'tram',
        9 => 'water',
        _ => 'bus',
      },
      submode: switch (cls) {
        1 => 'suburbanRailway',
        15 || 16 => 'longDistance',
        10 => 'demandAndResponseBus',
        17 => 'railReplacementBus',
        _ => null,
      },
      modeName: pName,
      published: name,
      lineRef: id,
    );
    out.putIfAbsent(
      lineKey(id),
      () => Line(
        id: id,
        name: info.name,
        mode: info.product.mode,
        operator: ((raw['operator'] as Map?)?['name']) as String?,
        longName: htmlToText(raw['description'] as String?)?.replaceAll(r'\n', ' ').replaceAll(r'\(', '('),
        product: info.product.name,
      ),
    );
  }
  return out.values.toList();
}

/// „placeID:5914000:29“ → „5914000“.
String? omcFromPlaceId(String? id) {
  final m = RegExp(r'^placeID:(\d{6,8}):').firstMatch(id ?? '');
  return m?.group(1);
}

/// „de:05124:11376:91:2“ → „de:05124:11376“.
String stopAreaIdOf(String id) {
  final p = id.split(':');
  return p.length >= 3 ? p.take(3).join(':') : id;
}
