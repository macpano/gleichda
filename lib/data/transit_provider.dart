import '../domain/models.dart';

/// Worauf die Verbindungssuche optimiert.
enum TripOptimization { fastest, minChanges, leastWalking }

/// Suchanfrage für Verbindungen.
class TripQuery {
  const TripQuery({
    required this.from,
    required this.to,
    required this.time,
    this.arriveBy = false,
    this.maxResults = 5,
    this.via,
    this.optimization = TripOptimization.fastest,
    this.excludedModes = const {},
    this.accessible = false,
    this.walkSpeedPercent = 100,
    this.maxInterchanges,
    this.maxWalkMinutes,
  });

  final Location from;
  final Location to;
  final DateTime time;

  /// true: [time] ist die gewünschte Ankunft.
  final bool arriveBy;
  final int maxResults;

  /// Zwischenhalt.
  final Location? via;
  final TripOptimization optimization;

  /// Auszuschließende Verkehrsmittel.
  final Set<TransportMode> excludedModes;

  /// Nur stufenlose Wege.
  final bool accessible;

  /// Gehgeschwindigkeit in Prozent der üblichen.
  final int walkSpeedPercent;
  final int? maxInterchanges;

  /// Längster Fußweg zum ersten und vom letzten Halt, in Minuten.
  final int? maxWalkMinutes;

  TripQuery copyWith({DateTime? time, bool? arriveBy, TripOptimization? optimization, int? maxResults}) =>
      TripQuery(
        from: from,
        to: to,
        time: time ?? this.time,
        arriveBy: arriveBy ?? this.arriveBy,
        maxResults: maxResults ?? this.maxResults,
        via: via,
        optimization: optimization ?? this.optimization,
        excludedModes: excludedModes,
        accessible: accessible,
        walkSpeedPercent: walkSpeedPercent,
        maxInterchanges: maxInterchanges,
        maxWalkMinutes: maxWalkMinutes,
      );
}

/// Ergebnis einer Abfahrtsabfrage: Abfahrten und die zugehörigen Meldungen.
class DepartureBoard {
  const DepartureBoard(this.departures, this.messages);

  final List<Departure> departures;
  final List<Message> messages;
}

/// Fehler einer Datenquelle, mit Klartext für die Oberfläche.
class ProviderException implements Exception {
  const ProviderException(this.message, {this.cause, this.offline = false});

  final String message;
  final Object? cause;

  /// Kein Netz bzw. Server nicht erreichbar (für den Offline-Zustand).
  final bool offline;

  @override
  String toString() => 'ProviderException: $message${cause == null ? '' : ' ($cause)'}';
}

/// Gemeinsame Schnittstelle aller Datenquellen. Nur eigene Modelle in den
/// Signaturen – die App kennt keine Protokolltypen.
abstract class TransitProvider {
  /// Kurzname der Quelle, z. B. „vrr-trias“.
  String get id;

  /// Haltestellen, Adressen und Orte zum Suchbegriff. [near] dient der
  /// Sortierung gleichnamiger Treffer; ohne Suchbegriff liefert es die
  /// Haltestellen im Umkreis [radiusMeters] um [near].
  Future<List<Location>> searchLocations(String query,
      {({double lat, double lon})? near, int limit = 10, int radiusMeters = 1000});

  /// Abfahrten an einer Haltestelle ab [time] (Standard: jetzt).
  Future<DepartureBoard> departures(Location stop,
      {DateTime? time, int limit = 20});

  /// Verbindungen von A nach B.
  Future<List<Trip>> planTrip(TripQuery query);

  /// Aktualisiert eine bekannte Verbindung mit frischer Echtzeit. Liefert
  /// null, wenn die Fahrt nicht mehr gefunden wird.
  Future<Trip?> refreshTrip(Trip trip);

  /// Aktuelle Meldungen, optional auf Linien beschränkt.
  Future<List<Message>> messages({List<String> lineIds = const []});

  /// Steige einer Haltestelle mit Koordinaten. Leer, wenn unbekannt.
  Future<List<Platform>> platforms(Location stop);

  /// Linienweg je Abschnitt der Verbindung (gleiche Reihenfolge wie
  /// `trip.legs`); null, wo er unbekannt ist oder es ein Fußweg ist.
  Future<List<List<GeoPoint>?>> legPaths(Trip trip);

  /// Die ganze Fahrt einer Abfahrt ab dieser Haltestelle bis zur
  /// Endhaltestelle, als Verbindung mit einem Abschnitt. null, wenn unbekannt.
  Future<Trip?> tripOfDeparture(Departure departure);

  /// Linien zum Suchbegriff (Liniennummer), etwa zum Abonnieren.
  Future<List<Line>> searchLines(String query);
}
