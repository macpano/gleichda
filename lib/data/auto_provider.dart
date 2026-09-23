import '../domain/models.dart';
import 'motis/motis_provider.dart';
import 'transit_provider.dart';

/// Wählt je Anfrage die Quelle: im VRR-Land (Nordrhein-Westfalen) der VRR mit
/// Echtzeit, Steigen, Meldungen und gesicherten Anschlüssen; außerhalb und für
/// alles, was von Transitous stammt, Transitous. Findet der VRR keine
/// Verbindung, versucht es Transitous (deckt auch den VRR ab).
class AutoProvider implements TransitProvider {
  AutoProvider(this.vrr, this.motis);

  final TransitProvider vrr;
  final MotisProvider motis;

  @override
  String get id => 'auto';

  /// Grob Nordrhein-Westfalen – dort antwortet der VRR vollständig.
  static bool inVrrLand(double lat, double lon) => lat > 50.30 && lat < 52.55 && lon > 5.85 && lon < 9.50;

  static bool _outside(Location l) => l.lat != null && l.lon != null && !inVrrLand(l.lat!, l.lon!);

  static bool _isMotis(Location l) => l.providerId == MotisProvider.providerKey;

  static bool _ref(String? ref) => ref != null && ref.startsWith(MotisProvider.refPrefix);

  static bool _tripIsMotis(Trip t) =>
      t.id.startsWith(MotisProvider.refPrefix) || t.id.contains(':${MotisProvider.refPrefix}') || t.rides.any((r) => _ref(r.journeyRef));

  @override
  Future<List<Location>> searchLocations(String query,
      {({double lat, double lon})? near, int limit = 10, int radiusMeters = 1000}) async {
    if (near != null && !inVrrLand(near.lat, near.lon)) {
      return motis.searchLocations(query, near: near, limit: limit, radiusMeters: radiusMeters);
    }
    final found = await vrr.searchLocations(query, near: near, limit: limit, radiusMeters: radiusMeters);
    if (found.isNotEmpty || query.trim().isEmpty) return found;
    // Nichts im VRR (z. B. „Berlin Alexanderplatz“): deutschlandweit suchen.
    try {
      return await motis.searchLocations(query, near: near, limit: limit, radiusMeters: radiusMeters);
    } on ProviderException {
      return found;
    }
  }

  @override
  Future<DepartureBoard> departures(Location stop, {DateTime? time, int limit = 20}) =>
      (_isMotis(stop) ? motis : vrr).departures(stop, time: time, limit: limit);

  @override
  Future<List<Trip>> planTrip(TripQuery query) async {
    final ends = [query.from, query.to, ?query.via];
    if (ends.any(_isMotis) || ends.any(_outside)) return motis.planTrip(query);
    List<Trip> trips;
    try {
      trips = await vrr.planTrip(query);
    } on ProviderException {
      trips = const [];
    }
    if (trips.isNotEmpty) return trips;
    // Ausweichen, wenn Start und Ziel eine Lage haben.
    if (query.from.lat != null && query.to.lat != null) {
      try {
        return await motis.planTrip(query);
      } on ProviderException {
        return trips;
      }
    }
    return trips;
  }

  @override
  Future<Trip?> refreshTrip(Trip trip) => (_tripIsMotis(trip) ? motis : vrr).refreshTrip(trip);

  @override
  Future<List<List<GeoPoint>?>> legPaths(Trip trip) => (_tripIsMotis(trip) ? motis : vrr).legPaths(trip);

  @override
  Future<Trip?> tripOfDeparture(Departure departure, {bool whole = false}) =>
      (_ref(departure.journeyRef) ? motis : vrr).tripOfDeparture(departure, whole: whole);

  @override
  Future<Set<int>> guaranteedConnections(Trip trip) =>
      _tripIsMotis(trip) ? Future.value(const {}) : vrr.guaranteedConnections(trip);

  @override
  Future<Map<String, Set<int>>> guaranteedForTrips(List<Trip> trips) =>
      vrr.guaranteedForTrips(trips.where((t) => !_tripIsMotis(t)).toList());

  @override
  Future<List<Platform>> platformsNear(GeoPoint near, {int radiusMeters = 800}) =>
      inVrrLand(near.lat, near.lon) ? vrr.platformsNear(near, radiusMeters: radiusMeters) : Future.value(const []);

  @override
  Future<List<Platform>> platforms(Location stop) => _isMotis(stop) ? Future.value(const []) : vrr.platforms(stop);

  // Meldungen, Gebiete und Linien kommen aus dem VRR.

  @override
  Future<List<Message>> messages({List<String> lineIds = const [], List<String> regions = const []}) =>
      vrr.messages(lineIds: lineIds, regions: regions);

  @override
  Future<List<String>> regionsOf(GeoPoint near) =>
      inVrrLand(near.lat, near.lon) ? vrr.regionsOf(near) : Future.value(const []);

  @override
  Future<List<Line>> linesNear(GeoPoint near) =>
      inVrrLand(near.lat, near.lon) ? vrr.linesNear(near) : Future.value(const []);

  @override
  Future<List<Line>> linesAround(GeoPoint near) =>
      inVrrLand(near.lat, near.lon) ? vrr.linesAround(near) : Future.value(const []);

  @override
  Future<List<Message>> messagesForLine(String lineKey) => vrr.messagesForLine(lineKey);

  @override
  Future<List<Line>> searchLines(String query, {GeoPoint? near}) => vrr.searchLines(query, near: near);
}
