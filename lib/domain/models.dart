// Kernmodelle der App (docs/konzept.md, Abschnitt „Datenmodell“).
// Alle Provider liefern in diese Objekte; kein Protokolldetail verlässt
// seinen Adapter.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

/// Woher eine Zeitangabe stammt. Jede Zeit trägt ihre Qualität explizit,
/// damit „nur Fahrplan“ nie als Echtzeit ausgegeben wird.
enum TimeQuality {
  /// Nur Fahrplan, keine Echtzeit geliefert.
  planned,

  /// Echtzeit vom Fahrzeug bzw. der Leitstelle.
  realtime,

  /// Geschätzt, z. B. aus der Verspätung am vorigen Halt fortgeschrieben.
  estimated,
}

enum LocationType { stop, address, poi, coordinate }

enum TransportMode {
  bus,
  tram,
  subway,
  suspension, // Schwebebahn
  suburbanRail,
  rail,
  ferry,
  replacementBus, // SEV
  onDemand,
  other,
}

/// Status eines Halts bzw. einer Abfahrt.
enum StopStatus { normal, cancelled, diversion, replacement }

/// Eine Zeit mit Plan- und Ist-Wert.
@freezed
abstract class EventTime with _$EventTime {
  const EventTime._();

  const factory EventTime({
    required DateTime planned,
    DateTime? estimated,
    @Default(TimeQuality.planned) TimeQuality quality,
  }) = _EventTime;

  factory EventTime.fromJson(Map<String, dynamic> json) =>
      _$EventTimeFromJson(json);

  /// Die beste bekannte Zeit.
  DateTime get best => estimated ?? planned;

  /// Abweichung in ganzen Minuten; null ohne Echtzeit.
  int? get delayMinutes => estimated == null
      ? null
      : (estimated!.difference(planned).inSeconds / 60).round();

  bool get hasRealtime => quality != TimeQuality.planned && estimated != null;
}

@freezed
abstract class Location with _$Location {
  const factory Location({
    required String id,
    required String providerId,
    required String name,
    String? place,
    double? lat,
    double? lon,
    @Default(LocationType.stop) LocationType type,
    @Default(<TransportMode>[]) List<TransportMode> modes,

    /// Trefferqualität der Suche (0–1), falls geliefert.
    double? score,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
}

@freezed
abstract class Line with _$Line {
  const factory Line({
    /// Kennung beim Provider (TRIAS LineRef, EFA line id).
    required String id,

    /// Liniennummer wie angezeigt, z. B. „640“, „S8“, „60“.
    required String name,
    required TransportMode mode,
    String? operator,

    /// Ausführliche Bezeichnung, z. B. „ICE 950 InterCityExpress“.
    String? longName,
  }) = _Line;

  factory Line.fromJson(Map<String, dynamic> json) => _$LineFromJson(json);
}

/// Halt einer Fahrt mit Plan- und Ist-Zeiten.
@freezed
abstract class StopTime with _$StopTime {
  const factory StopTime({
    required Location stop,
    EventTime? arrival,
    EventTime? departure,
    String? plannedPlatform,
    String? platform,
    @Default(StopStatus.normal) StopStatus status,
    int? sequence,
  }) = _StopTime;

  factory StopTime.fromJson(Map<String, dynamic> json) =>
      _$StopTimeFromJson(json);
}

enum LegType { ride, walk, transfer }

/// Abschnitt einer Verbindung.
@freezed
abstract class Leg with _$Leg {
  const factory Leg({
    required LegType type,
    required StopTime from,
    required StopTime to,
    Line? line,
    String? direction,
    @Default(<StopTime>[]) List<StopTime> intermediates,

    /// Fahrt-Referenz des Providers (TRIAS JourneyRef).
    String? journeyRef,

    /// Betriebstag der Fahrt.
    String? operatingDay,

    /// Dauer bei Fuß- und Umsteigewegen.
    int? durationMinutes,
    @Default(<String>[]) List<String> messageIds,
  }) = _Leg;

  factory Leg.fromJson(Map<String, dynamic> json) => _$LegFromJson(json);
}

/// Verbindung von A nach B (im Konzept „Verbindung“).
@freezed
abstract class Trip with _$Trip {
  const Trip._();

  const factory Trip({
    required String id,
    required List<Leg> legs,
    @Default(<Message>[]) List<Message> messages,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  List<Leg> get rides => legs.where((l) => l.type == LegType.ride).toList();

  EventTime get departure => legs.first.from.departure ?? legs.first.from.arrival!;
  EventTime get arrival => legs.last.to.arrival ?? legs.last.to.departure!;

  int get interchanges => rides.isEmpty ? 0 : rides.length - 1;

  Duration get duration => arrival.best.difference(departure.best);

  Location get origin => legs.first.from.stop;
  Location get destination => legs.last.to.stop;
}

/// Abfahrt an einer Haltestelle.
@freezed
abstract class Departure with _$Departure {
  const factory Departure({
    required Location stop,
    required Line line,
    required String direction,
    required EventTime time,
    String? plannedPlatform,
    String? platform,
    @Default(StopStatus.normal) StopStatus status,
    String? journeyRef,
    String? operatingDay,
    @Default(<String>[]) List<String> messageIds,
  }) = _Departure;

  factory Departure.fromJson(Map<String, dynamic> json) =>
      _$DepartureFromJson(json);
}

/// Störungs- oder Hinweismeldung.
@freezed
abstract class Message with _$Message {
  const factory Message({
    required String id,
    required String title,
    String? text,
    @Default(<String>[]) List<String> lineIds,

    /// Liniennummern passend zu [lineIds], für die Anzeige als Plaketten.
    @Default(<String>[]) List<String> lineNames,
    @Default(<String>[]) List<String> stopIds,
    DateTime? validFrom,
    DateTime? validTo,

    /// Datenquelle, z. B. „VRR“ oder „DB“.
    String? source,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

/// Zeitfenster, z. B. „werktags 6–9 Uhr“. Wochentage 1 = Montag.
@freezed
abstract class TimeWindow with _$TimeWindow {
  const factory TimeWindow({
    @Default(<int>[1, 2, 3, 4, 5, 6, 7]) List<int> weekdays,
    int? fromMinute,
    int? toMinute,
  }) = _TimeWindow;

  factory TimeWindow.fromJson(Map<String, dynamic> json) =>
      _$TimeWindowFromJson(json);
}

/// Linienabo.
@freezed
abstract class Subscription with _$Subscription {
  const factory Subscription({
    required String lineId,
    required String providerId,
    required String lineName,
    TimeWindow? window,
    String? pushTopic,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
}

enum AlarmTimeRef { arriveBy, departAt }

/// Fahrtenwecker.
@freezed
abstract class Alarm with _$Alarm {
  const factory Alarm({
    required String id,
    required String name,
    required Location from,
    required Location to,
    required AlarmTimeRef timeRef,

    /// Minuten nach Mitternacht.
    required int minuteOfDay,
    @Default(<int>[1, 2, 3, 4, 5]) List<int> weekdays,
    @Default(5) int leadMinutes,
    @Default(true) bool earlierOnDisruption,
    @Default(false) bool startCompanion,
    @Default(true) bool enabled,
  }) = _Alarm;

  factory Alarm.fromJson(Map<String, dynamic> json) => _$AlarmFromJson(json);
}

enum PlaceKind { home, work, other }

/// Gespeicherter Ort („Zuhause“, „Arbeit“ …).
@freezed
abstract class SavedPlace with _$SavedPlace {
  const factory SavedPlace({
    required String id,
    required String name,
    required PlaceKind kind,
    required Location location,
  }) = _SavedPlace;

  factory SavedPlace.fromJson(Map<String, dynamic> json) =>
      _$SavedPlaceFromJson(json);
}

/// Steig einer Haltestelle mit genauer Position.
class Platform {
  const Platform({
    required this.id,
    required this.stopId,
    required this.lat,
    required this.lon,
    this.name,
    this.direction,
    this.isReplacement = false,
  });

  final String id;
  final String stopId;

  /// Bezeichnung, z. B. „2“.
  final String? name;

  /// Fahrtrichtung, z. B. „Vohwinkel“, falls bekannt.
  final String? direction;
  final double lat;
  final double lon;
  final bool isReplacement;
}
