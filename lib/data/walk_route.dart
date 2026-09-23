// Fußwege über den Fußgänger-Router von FOSSGIS (routing.openstreetmap.de,
// OSRM, Profil „foot“, OpenStreetMap-Daten). Kostenlos bei maßvoller Nutzung,
// mit User-Agent. Liefert den Weg entlang von Gehwegen samt Abbiegehinweisen.
import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../domain/models.dart';
import 'transit_provider.dart';

class WalkStep {
  const WalkStep({required this.type, this.modifier, required this.name, required this.index});

  /// OSRM-Manöver: depart, turn, new name, continue, arrive …
  final String type;

  /// left, right, slight left, sharp right, straight, uturn …
  final String? modifier;

  /// Straßen- bzw. Wegname nach dem Manöver, leer bei namenlosen Wegen.
  final String name;

  /// Punkt des Wegs, an dem das Manöver liegt.
  final int index;

  /// Abbiegen oder Ankunft – nicht bloß ein neuer Straßenname oder
  /// „geradeaus weiter“.
  bool get isManeuver {
    if (type == 'arrive') return true;
    if (type == 'depart' || type == 'new name') return false;
    return modifier != null && modifier != 'straight';
  }

  /// Hinweis in Worten, z. B. „Links abbiegen in Alter Markt“.
  String get text {
    final into = name.isEmpty ? '' : ' in $name';
    if (type == 'arrive') return 'Ziel erreicht';
    if (type == 'depart') return name.isEmpty ? 'Losgehen' : 'Auf $name losgehen';
    final how = switch (modifier) {
      'left' => 'Links abbiegen',
      'right' => 'Rechts abbiegen',
      'slight left' => 'Leicht links halten',
      'slight right' => 'Leicht rechts halten',
      'sharp left' => 'Scharf links abbiegen',
      'sharp right' => 'Scharf rechts abbiegen',
      'uturn' => 'Umkehren',
      _ => 'Geradeaus weiter',
    };
    return '$how$into';
  }
}

class WalkRoute {
  const WalkRoute({required this.points, required this.steps, required this.cumulative});

  final List<GeoPoint> points;
  final List<WalkStep> steps;

  /// Meter vom Start bis zu jedem Punkt.
  final List<double> cumulative;

  double get meters => cumulative.isEmpty ? 0 : cumulative.last;

  /// Lage einer Position auf dem Weg: nächster Wegpunkt und Abstand in Metern.
  /// Mit [from] wird nur ab diesem Punkt (und wenige Punkte davor) gesucht –
  /// führt der Weg zurück, springt die Lage sonst auf das falsche Stück.
  ({int index, double off}) locate(GeoPoint p, {int from = 0}) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = (from - 3).clamp(0, points.length - 1); i < points.length; i++) {
      final d = metersBetween(points[i], p);
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return (index: best, off: bestD);
  }

  /// Restweg ab Wegpunkt [index].
  double remainingFrom(int index) => meters - cumulative[index];

  /// Nächstes echtes Manöver nach Wegpunkt [index] und die Meter bis dorthin.
  /// Straßennamenwechsel und „geradeaus weiter“ zählen nicht; eine Kehrtwende
  /// kurz vor dem Ziel (der Router hängt sie an, wenn das Ziel auf der anderen
  /// Wegseite liegt) auch nicht.
  ({WalkStep step, double meters})? nextStep(int index) {
    for (final s in steps) {
      if (s.index <= index) continue;
      if (!s.isManeuver) continue;
      if (s.modifier == 'uturn' && meters - cumulative[s.index] < 30) continue;
      return (step: s, meters: cumulative[s.index] - cumulative[index]);
    }
    return null;
  }
}

double metersBetween(GeoPoint a, GeoPoint b) {
  const r = 6371000.0;
  final dLat = (b.lat - a.lat) * math.pi / 180;
  final dLon = (b.lon - a.lon) * math.pi / 180;
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(a.lat * math.pi / 180) * math.cos(b.lat * math.pi / 180) * math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(h)));
}

WalkRoute? parseWalkRoute(Map<String, dynamic> json) {
  if (json['code'] != 'Ok') return null;
  final route = (json['routes'] as List?)?.firstOrNull;
  if (route is! Map) return null;
  final coords = (route['geometry'] as Map?)?['coordinates'];
  if (coords is! List || coords.length < 2) return null;
  final points = <GeoPoint>[
    for (final c in coords)
      if (c is List && c.length >= 2) (lat: (c[1] as num).toDouble(), lon: (c[0] as num).toDouble()),
  ];
  final cum = <double>[0];
  for (var i = 1; i < points.length; i++) {
    cum.add(cum.last + metersBetween(points[i - 1], points[i]));
  }
  // Manöver folgen dem Weg: jeweils ab dem vorigen suchen.
  var from = 0;
  int nearest(GeoPoint p) {
    var best = from;
    var bestD = double.infinity;
    for (var i = from; i < points.length; i++) {
      final d = metersBetween(points[i], p);
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  final steps = <WalkStep>[];
  for (final leg in (route['legs'] as List?) ?? const []) {
    for (final s in ((leg as Map)['steps'] as List?) ?? const []) {
      final m = (s as Map)['maneuver'] as Map?;
      final loc = m?['location'];
      if (m == null || loc is! List) continue;
      steps.add(WalkStep(
        type: m['type'] as String? ?? '',
        modifier: m['modifier'] as String?,
        name: (s['name'] as String?) ?? '',
        index: from = nearest((lat: (loc[1] as num).toDouble(), lon: (loc[0] as num).toDouble())),
      ));
    }
  }
  return WalkRoute(points: points, steps: steps, cumulative: cum);
}

class WalkRouter {
  WalkRouter(this._dio, {this.baseUrl = 'https://routing.openstreetmap.de/routed-foot/route/v1/driving'});

  final Dio _dio;

  /// Der Pfad heißt bei FOSSGIS „driving“, der Dienst rechnet trotzdem für
  /// Fußgänger (Profil steckt im Servernamen).
  final String baseUrl;

  Future<WalkRoute?> route(GeoPoint from, GeoPoint to) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/${from.lon},${from.lat};${to.lon},${to.lat}',
        queryParameters: {'overview': 'full', 'geometries': 'geojson', 'steps': 'true'},
      );
      return parseWalkRoute(res.data ?? const {});
    } on DioException catch (e) {
      throw ProviderException('Fußweg nicht abrufbar', cause: e);
    }
  }
}
