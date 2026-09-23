import '../domain/models.dart';

/// Suchanfrage für Verbindungen.
class TripQuery {
  const TripQuery({
    required this.from,
    required this.to,
    required this.time,
    this.arriveBy = false,
    this.maxResults = 5,
  });

  final Location from;
  final Location to;
  final DateTime time;

  /// true: [time] ist die gewünschte Ankunft.
  final bool arriveBy;
  final int maxResults;
}

/// Ergebnis einer Abfahrtsabfrage: Abfahrten und die zugehörigen Meldungen.
class DepartureBoard {
  const DepartureBoard(this.departures, this.messages);

  final List<Departure> departures;
  final List<Message> messages;
}

/// Fehler einer Datenquelle, mit Klartext für die Oberfläche.
class ProviderException implements Exception {
  const ProviderException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'ProviderException: $message${cause == null ? '' : ' ($cause)'}';
}

/// Gemeinsame Schnittstelle aller Datenquellen. Nur eigene Modelle in den
/// Signaturen – die App kennt keine Protokolltypen.
abstract class TransitProvider {
  /// Kurzname der Quelle, z. B. „vrr-trias“.
  String get id;

  /// Haltestellen, Adressen und Orte zum Suchbegriff. [near] dient der
  /// Sortierung gleichnamiger Treffer.
  Future<List<Location>> searchLocations(String query,
      {({double lat, double lon})? near, int limit = 10});

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
}
