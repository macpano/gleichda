// Bildschirmfotos der Screens ohne Handy, mit echten Antworten aus
// test/fixtures (Zeiten auf „jetzt“ verschoben).
//
//   flutter test test_screens --update-goldens   →  test_screens/out/*.png
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/app.dart';
import 'package:gleichda/data/db/database.dart';
import 'package:gleichda/data/efa/efa_client.dart' show parseAddInfo, lineKey;
import 'package:gleichda/data/repository.dart';
import 'package:gleichda/data/transit_provider.dart';
import 'package:gleichda/data/trias/trias_parser.dart';
import 'package:gleichda/domain/models.dart' hide Platform;
import 'package:gleichda/domain/models.dart' as m show Platform;
import 'package:gleichda/state/providers.dart';
import 'package:gleichda/ui/screens/connections_screen.dart';
import 'package:gleichda/ui/screens/departures_screen.dart';
import 'package:gleichda/ui/screens/design_demo_screen.dart';
import 'package:gleichda/ui/screens/alarms_screen.dart';
import 'package:gleichda/ui/screens/alternatives_screen.dart';
import 'package:gleichda/state/companion.dart';
import 'package:gleichda/ui/screens/location_search_screen.dart';
import 'package:gleichda/ui/screens/line_screen.dart';
import 'package:gleichda/ui/screens/map_screen.dart';
import 'package:gleichda/ui/screens/messages_screen.dart';
import 'package:gleichda/ui/screens/more_screen.dart';
import 'package:gleichda/ui/screens/trip_screen.dart';
import 'package:gleichda/ui/screens/walk_screen.dart';
import 'package:gleichda/domain/settings.dart';
import 'package:gleichda/ui/theme.dart';
import 'package:gleichda/ui/trip_map.dart';
import 'package:intl/date_symbol_data_local.dart';

String fixture(String n) => File('test/fixtures/$n').readAsStringSync();

/// Verschiebt alle Zeitangaben in einem JSON-Baum um [d].
Object? shift(Object? v, Duration d) {
  if (v is Map) return <String, dynamic>{for (final e in v.entries) e.key as String: shift(e.value, d)};
  if (v is List) return v.map((x) => shift(x, d)).toList();
  if (v is String && RegExp(r'^\d{4}-\d\d-\d\dT').hasMatch(v)) {
    return DateTime.parse(v).add(d).toIso8601String();
  }
  return v;
}

List<Trip> tripsNow(String name, {Duration lead = const Duration(minutes: 6)}) {
  final trips = parseTrips(fixture(name));
  final d = DateTime.now().add(lead).difference(trips.first.rides.first.from.departure!.planned);
  return trips
      .map((t) => Trip.fromJson(shift(jsonDecode(jsonEncode(t.toJson())), d) as Map<String, dynamic>))
      .toList();
}

class FakeProvider implements TransitProvider {
  FakeProvider(this.trips, this.board, {this.offline = false});

  final List<Trip> trips;
  final DepartureBoard board;
  final bool offline;

  @override
  String get id => 'fake';

  @override
  Future<DepartureBoard> departures(Location stop, {DateTime? time, int limit = 20}) async => board;

  @override
  Future<List<String>> regionsOf(GeoPoint near) async => const [];

  @override
  Future<List<Message>> messages({List<String> lineIds = const [], List<String> regions = const []}) async =>
      parseAddInfo(jsonDecode(fixture('efa_addinfo_wuppertal.json')) as Map<String, dynamic>);

  @override
  Future<List<Trip>> planTrip(TripQuery query) async => trips;

  @override
  Future<Trip?> refreshTrip(Trip trip) async {
    if (offline) throw const ProviderException('Keine Verbindung zur Auskunft', offline: true);
    return trip;
  }

  @override
  Future<List<m.Platform>> platforms(Location stop) async => const [];

  @override
  Future<List<List<GeoPoint>?>> legPaths(Trip trip) async => List.filled(trip.legs.length, null);

  @override
  Future<Trip?> tripOfDeparture(Departure departure) async => null;

  @override
  Future<List<Line>> linesNear(GeoPoint near) async => const [];

  @override
  Future<Set<int>> guaranteedConnections(Trip trip) async => const {};

  @override
  Future<List<m.Platform>> platformsNear(GeoPoint near, {int radiusMeters = 800}) async => const [
        m.Platform(id: 'de:05124:11376:91:2', stopId: 'de:05124:11376', name: '2', lat: 51.25453, lon: 7.14995),
        m.Platform(id: 'de:05124:11376:91:3', stopId: 'de:05124:11376', name: '3', lat: 51.25442, lon: 7.15001),
      ];

  @override
  Future<List<Line>> linesAround(GeoPoint near) async => const [];

  @override
  Future<List<Message>> messagesForLine(String lineKey) async =>
      board.messages.where((m) => m.lineIds.contains(lineKey)).toList();

  @override
  Future<List<Line>> searchLines(String query, {GeoPoint? near}) async => const [
        Line(id: 'wsw:66604', name: '604', mode: TransportMode.bus, product: 'bus', longName: 'Langerfeld – Rott'),
        Line(id: 'wsw:64060', name: '60', mode: TransportMode.suspension, product: 'suspension', longName: 'Oberbarmen – Vohwinkel'),
      ];

  @override
  Future<List<Location>> searchLocations(String query,
          {({double lat, double lon})? near, int limit = 10, int radiusMeters = 1000}) async =>
      query.isEmpty && near != null
          ? const [
              Location(id: 'de:05124:11376', providerId: 't', name: 'Wuppertal Hbf', lat: 51.2544, lon: 7.1495),
              Location(id: 'de:05124:11071', providerId: 't', name: 'Wuppertal Alter Markt', lat: 51.2560, lon: 7.1535),
            ]
          : const [];
}

Future<void> loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  ByteData bytes(String p) => ByteData.sublistView(File(p).readAsBytesSync());
  final roboto = FontLoader('Roboto');
  for (final f in ['roboto-regular', 'roboto-medium', 'roboto-bold', 'roboto-italic']) {
    roboto.addFont(Future.value(bytes('$dir/$f.ttf')));
  }
  await roboto.load();
  await (FontLoader('Rubik')..addFont(Future.value(bytes('assets/fonts/Rubik-Italic.ttf')))).load();
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(bytes('$dir/MaterialIcons-Regular.otf'))))
      .load();
}

void main() {
  late List<Trip> trips;
  late DepartureBoard board;
  late Location hbf;

  setUpAll(() async {
    // Kartenkacheln legen einen Zwischenspeicher an; im Test ein Temp-Ordner.
    final tmp = Directory.systemTemp.createTempSync('gleichda_test').path;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (_) async => tmp);
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    await initializeDateFormatting('de');
    await loadFonts();
    trips = tripsNow('trias_trip_alter_markt_vohwinkel.xml');
    hbf = const Location(id: 'de:05124:11376', providerId: 'vrr-trias', name: 'Wuppertal Hbf', place: 'Wuppertal');
    board = parseStopEvents(fixture('trias_se_hbf.xml'), hbf);
    final d = DateTime.now().difference(board.departures.first.time.planned);
    board = DepartureBoard(
      board.departures
          .map((x) => Departure.fromJson(shift(jsonDecode(jsonEncode(x.toJson())), d) as Map<String, dynamic>))
          .toList(),
      board.messages,
    );
  });

  Future<void> shot(WidgetTester tester, String name, Widget home,
      {Brightness brightness = Brightness.light,
      Future<void> Function(Repository)? seed,
      Future<void> Function(WidgetTester)? act,
      List<Override> overrides = const [],
      List<Trip>? planned,
      bool offline = false}) async {
    tabBarHeight.value = 0; // Reiterleiste eines vorigen Tests vergessen
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 24 * 3, bottom: 16 * 3);
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    final repo = Repository(db);
    await tester.runAsync(() async {
      if (seed != null) await seed(repo);
      await repo.setSetting('themeMode', brightness == Brightness.dark ? 'dark' : 'light');
    });
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      transitProvider.overrideWithValue(FakeProvider(planned ?? trips, board, offline: offline)),
      ...overrides,
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorObservers: [PageStack()],
        debugShowCheckedModeBanner: false,
        theme: buildTheme(brightness, TargetPlatform.android),
        home: home,
        builder: appFrame,
      ),
    ));
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 200));
    }
    // SVG-Logo wird asynchron dekodiert.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 300));
    if (act != null) {
      await act(tester);
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 250));
      }
    }
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/$name.png'));
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    // db.close() würde auf Abfragen aus der Testzone warten; die Speicher-DB verfällt so.
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> seedHome(Repository r) async {
    await r.saveLastTrip(trips.first, updatedAt: DateTime.now().subtract(const Duration(seconds: 12)));
    await r.recordSearch(trips.first.origin, trips.first.destination);
    await r.recordSearch(hbf, trips.first.origin);
    await r.toggleFavoriteRoute(hbf, trips.first.destination);
    await r.savePlace(SavedPlace(id: 'home', name: 'Zuhause', kind: PlaceKind.home, location: trips.first.destination));
    await r.savePlace(SavedPlace(id: 'work', name: 'Arbeit', kind: PlaceKind.work, location: hbf));
  }

  testWidgets('Start hell', (t) => shot(t, 'start_hell', const HomeShell(), seed: seedHome));
  testWidgets('Start dunkel',
      (t) => shot(t, 'start_dunkel', const HomeShell(), brightness: Brightness.dark, seed: seedHome));
  testWidgets('Verbindungen', (t) => shot(t, 'verbindungen',
      ConnectionsScreen(from: trips.first.origin, to: trips.first.destination, time: null, arriveBy: false)));
  testWidgets('Verbindungen: nur Fußweg nach Hause', (t) {
    // Nah an der Zieladresse liefert die Auskunft nur einen Fußweg (live 0–6 min).
    final now = DateTime.now();
    const here = Location(id: 'coord', providerId: 'vrr', name: 'Mein Standort', type: LocationType.coordinate,
        lat: 51.2533, lon: 7.1326);
    const home = Location(id: 'streetID:1', providerId: 'vrr', name: 'Friedrich-Ebert-Straße 100',
        type: LocationType.address, lat: 51.2533, lon: 7.1326);
    final walk = Trip(id: 'zu-fuss', legs: [
      Leg(
        type: LegType.walk,
        from: StopTime(stop: here, departure: EventTime(planned: now.subtract(const Duration(seconds: 20)))),
        to: StopTime(stop: home, arrival: EventTime(planned: now.add(const Duration(minutes: 4)))),
        durationMinutes: 4,
      ),
    ]);
    return shot(t, 'verbindungen_fussweg',
        const ConnectionsScreen(from: here, to: home, time: null, arriveBy: false), planned: [walk]);
  });
  testWidgets('Fahrt', (t) => shot(t, 'fahrt', const TripScreen(), seed: seedHome));
  testWidgets('Fahrt dunkel',
      (t) => shot(t, 'fahrt_dunkel', const TripScreen(), brightness: Brightness.dark, seed: seedHome));
  testWidgets('Abfahrten', (t) => shot(t, 'abfahrten', Scaffold(body: DeparturesScreen(initialStop: hbf))));
  testWidgets('Zeitraster', (t) => shot(t, 'zeitraster',
      ConnectionsScreen(from: trips.first.origin, to: trips.first.destination, time: null, arriveBy: false),
      seed: (r) => r.setSetting('settings', const AppSettings(connectionsGrid: true).encode())));
  testWidgets('Meldungen', (t) => shot(t, 'meldungen', const Scaffold(body: MessagesScreen())));
  testWidgets('Mehr', (t) => shot(t, 'mehr', const Scaffold(body: MoreScreen())));
  testWidgets('Unterwegs', (t) {
    final onBoard = withCoords(tripsNow('trias_trip_alter_markt_vohwinkel.xml', lead: const Duration(minutes: -2)).first);
    return shot(t, 'unterwegs', const TripScreen(),
        seed: (r) => r.saveLastTrip(onBoard),
        overrides: [companionProvider.overrideWith(() => _Following(onBoard.id))]);
  });
  testWidgets('Unterwegs auf der Startseite', (t) {
    final onBoard = withCoords(tripsNow('trias_trip_alter_markt_vohwinkel.xml', lead: const Duration(minutes: -2)).first);
    return shot(t, 'unterwegs_startseite', const HomeShell(),
        seed: (r) => r.saveLastTrip(onBoard),
        overrides: [companionProvider.overrideWith(() => _Following(onBoard.id))]);
  });
  testWidgets('Unterseite: Unterwegs auf der Startseite', (t) {
    final onBoard = withCoords(tripsNow('trias_trip_alter_markt_vohwinkel.xml', lead: const Duration(minutes: -2)).first);
    return shot(t, 'unterwegs_unterseite', const HomeShell(),
        seed: (r) => r.saveLastTrip(onBoard),
        overrides: [companionProvider.overrideWith(() => _Following(onBoard.id))],
        act: (t) async {
          // Von der Startseite in die Fahrt: Die Leiste gleitet nach ganz unten.
          Navigator.of(t.element(find.byType(NavigationBar)))
              .push(MaterialPageRoute<void>(builder: (_) => const TripScreen()));
          for (var i = 0; i < 6; i++) {
            await t.pump(const Duration(milliseconds: 100));
          }
        });
  });
  testWidgets('Fahrt unterwegs', (t) => shot(t, 'fahrt_unterwegs', const TripScreen(), seed: (r) async {
        final onBoard = tripsNow('trias_trip_alter_markt_vohwinkel.xml', lead: const Duration(minutes: -2)).first;
        await r.saveLastTrip(onBoard);
      }));
  testWidgets('Karte', (t) {
    final onBoard = withCoords(tripsNow('trias_trip_alter_markt_vohwinkel.xml', lead: const Duration(minutes: -2)).first);
    return shot(t, 'karte', const TripMapScreen(), seed: (r) => r.saveLastTrip(onBoard));
  });
  testWidgets('Fahrtverlauf aus dem Abfahrtsmonitor', (t) {
    final ride = trips.first.legs.lastWhere((l) => l.type == LegType.ride);
    final vehicle = Trip(id: 'abfahrt:test', legs: [ride]);
    return shot(t, 'fahrtverlauf', const TripScreen(), seed: (r) => r.saveLastTrip(vehicle));
  });
  testWidgets('Karte (Reiter)', (t) => shot(t, 'karte_reiter', const Scaffold(body: MapScreen())));
  testWidgets('Karte: Haltestelle angetippt', (t) => shot(t, 'karte_haltestelle', const Scaffold(body: MapScreen()),
      act: (t) async => t.tap(find.text('H').first)));
  testWidgets('Karte: Steige nah', (t) => shot(t, 'karte_steige', const Scaffold(body: MapScreen()),
      act: (t) async {
        final state = t.state(find.byType(MapScreen)) as dynamic;
        state.debugZoom(17.5);
        await t.pump(const Duration(seconds: 1));
      }));
  testWidgets('Linie ohne Abo', (t) {
    final d = board.departures.firstWhere(
        (d) => board.messages.any((m) => m.lineIds.contains(lineKey(d.line.id))),
        orElse: () => board.departures.first);
    return shot(t, 'linie', LineScreen(line: d.line));
  });
  testWidgets('Alternativen', (t) => shot(t, 'alternativen', AlternativesScreen(trip: trips.first)));
  testWidgets('Neuer Wecker', (t) => shot(t, 'wecker_neu', const AlarmEditScreen()));
  testWidgets('Suche leer', (t) => shot(t, 'suche_leer', const LocationSearchScreen(title: 'Nach'), seed: seedHome));
  testWidgets('Zeitwahl', (t) => shot(t, 'zeitwahl', const HomeShell(), seed: seedHome, act: (t) async {
        await t.tap(find.text('Jetzt').first);
      }));
  testWidgets('Suchoptionen', (t) => shot(t, 'suchoptionen', const HomeShell(), seed: seedHome, act: (t) async {
        await t.tap(find.text('Optionen').first);
      }));
  testWidgets('Offline', (t) => shot(t, 'offline', const HomeShell(), seed: seedHome, offline: true));
  testWidgets('Wecker', (t) => shot(t, 'wecker', const AlarmsScreen(), seed: (r) async {
        await r.saveAlarm(Alarm(
          id: 'a1',
          name: 'Zur Arbeit',
          from: trips.first.origin,
          to: trips.first.destination,
          timeRef: AlarmTimeRef.arriveBy,
          minuteOfDay: 7 * 60 + 50,
        ));
        await r.saveAlarm(Alarm(
          id: 'a2',
          name: 'Training',
          from: trips.first.destination,
          to: trips.first.origin,
          timeRef: AlarmTimeRef.departAt,
          minuteOfDay: 18 * 60 + 30,
          weekdays: const [2, 4],
          enabled: false,
        ));
      }));
  testWidgets('Weg zum Steig', (t) => shot(t, 'weg', WalkScreen(target: trips.first.origin, platform: '2')));
  testWidgets('Farben dunkel',
      (t) => shot(t, 'farben_dunkel', const DesignDemoScreen(), brightness: Brightness.dark));
}

/// Begleitung läuft, ohne echte Benachrichtigung.
class _Following extends CompanionController {
  _Following(this.tripId);

  final String tripId;

  @override
  CompanionState build() => CompanionState(active: true, tripId: tripId);
}

/// Die TRIAS-Aufzeichnungen tragen keine Koordinaten (die kommen im Betrieb
/// aus der EFA). Für die Kartenbilder werden die Halte gleichmäßig zwischen
/// Alter Markt und Vohwinkel verteilt – nur für den Test.
Trip withCoords(Trip trip) {
  const a = (lat: 51.2717, lon: 7.1968), b = (lat: 51.2317, lon: 7.0739);
  final all = [for (final l in trip.legs) ...[l.from, ...l.intermediates, l.to]];
  var i = 0;
  StopTime put(StopTime s) {
    final f = i++ / (all.length - 1);
    final wiggle = (i % 3 - 1) * 0.0015;
    return s.copyWith(
        stop: s.stop.copyWith(lat: a.lat + (b.lat - a.lat) * f + wiggle, lon: a.lon + (b.lon - a.lon) * f));
  }

  return trip.copyWith(legs: [
    for (final l in trip.legs)
      l.copyWith(from: put(l.from), intermediates: [for (final s in l.intermediates) put(s)], to: put(l.to)),
  ]);
}
