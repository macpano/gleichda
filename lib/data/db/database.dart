// Lokale Datenbank (Drift). Alles Persönliche bleibt auf dem Gerät.
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Verlauf der Verbindungssuchen („Zuletzt gesucht“).
class HistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Location als JSON.
  TextColumn get fromLocation => text()();
  TextColumn get toLocation => text()();

  /// Schlüssel aus Start- und Ziel-ID, damit eine Suche nur einmal steht.
  TextColumn get routeKey => text().unique()();
  TextColumn get profile => text().nullable()();
  DateTimeColumn get lastUsed => dateTime()();

  /// Letztes Ergebnis als JSON-Liste von Trips, für die Sofortanzeige.
  TextColumn get cachedResult => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().nullable()();
}

/// Favoriten: Verbindung oder Haltestelle.
class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'route' oder 'stop'.
  TextColumn get kind => text()();

  /// Verbindung: routeKey; Haltestelle: Location-ID.
  TextColumn get ref => text().unique()();
  TextColumn get name => text()();

  /// Location(s) als JSON: bei 'route' {from, to}, bei 'stop' die Location.
  TextColumn get payload => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Linienabos (zunächst nur lokal).
@DataClassName('SubscriptionRow')
class Subscriptions extends Table {
  TextColumn get lineId => text()();
  TextColumn get providerId => text()();
  TextColumn get lineName => text()();
  TextColumn get window => text().nullable()();
  TextColumn get pushTopic => text().nullable()();

  @override
  Set<Column> get primaryKey => {lineId, providerId};
}

/// Gespeicherte Orte („Zuhause“, „Arbeit“ …).
@DataClassName('SavedPlaceRow')
class SavedPlaces extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  TextColumn get location => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Zuletzt angesehene Fahrt: genau eine Zeile (id = 1).
///
/// Neben der ganzen Fahrt als JSON stehen die Kennungen für die Neuabfrage
/// des ersten Fahrtabschnitts einzeln in Spalten (Linie, stopID, tripCode,
/// Datum, Zeit); die Kennungen aller Abschnitte stecken in [trip].
class LastTrips extends Table {
  IntColumn get id => integer()();
  TextColumn get trip => text()();
  TextColumn get line => text().nullable()();
  TextColumn get stopId => text().nullable()();
  TextColumn get tripCode => text().nullable()();

  /// JJJJMMTT
  TextColumn get date => text().nullable()();

  /// HHMM, Ortszeit
  TextColumn get time => text().nullable()();

  /// Zeitpunkt der letzten erfolgreichen Aktualisierung.
  DateTimeColumn get updatedAt => dateTime()();

  /// Ob der gespeicherte Stand Echtzeit enthielt.
  BoolColumn get hasRealtime => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Haltestellen-Cache für Vorschläge ohne Netz.
class StopCache extends Table {
  TextColumn get id => text()();
  TextColumn get providerId => text()();
  TextColumn get name => text()();
  TextColumn get place => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lon => real().nullable()();

  /// Verkehrsmittel, kommagetrennt.
  TextColumn get modes => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Fahrtenwecker, als JSON des Modells Alarm.
@DataClassName('AlarmRow')
class Alarms extends Table {
  TextColumn get id => text()();
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Einfache Einstellungen als Schlüssel/Wert.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  HistoryEntries,
  Favorites,
  Subscriptions,
  SavedPlaces,
  LastTrips,
  StopCache,
  Settings,
  Alarms,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ??
            driftDatabase(
              name: 'gleichda',
              // Hintergrundprüfung (Linienabos, Wecker) nutzt dieselbe Datei.
              native: const DriftNativeOptions(shareAcrossIsolates: true),
            ));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(alarms);
        },
      );
}
