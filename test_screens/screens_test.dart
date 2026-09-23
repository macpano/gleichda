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
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/app.dart';
import 'package:gleichda/data/db/database.dart';
import 'package:gleichda/data/repository.dart';
import 'package:gleichda/data/transit_provider.dart';
import 'package:gleichda/data/trias/trias_parser.dart';
import 'package:gleichda/domain/models.dart';
import 'package:gleichda/state/providers.dart';
import 'package:gleichda/ui/screens/connections_screen.dart';
import 'package:gleichda/ui/screens/departures_screen.dart';
import 'package:gleichda/ui/screens/design_demo_screen.dart';
import 'package:gleichda/ui/screens/trip_screen.dart';
import 'package:gleichda/ui/theme.dart';
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
  FakeProvider(this.trips, this.board);

  final List<Trip> trips;
  final DepartureBoard board;

  @override
  String get id => 'fake';

  @override
  Future<DepartureBoard> departures(Location stop, {DateTime? time, int limit = 20}) async => board;

  @override
  Future<List<Message>> messages({List<String> lineIds = const []}) async => const [];

  @override
  Future<List<Trip>> planTrip(TripQuery query) async => trips;

  @override
  Future<Trip?> refreshTrip(Trip trip) async => trip;

  @override
  Future<List<Location>> searchLocations(String query,
          {({double lat, double lon})? near, int limit = 10}) async =>
      const [];
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
      {Brightness brightness = Brightness.light, Future<void> Function(Repository)? seed}) async {
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
      transitProvider.overrideWithValue(FakeProvider(trips, board)),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(brightness, TargetPlatform.android),
        home: home,
      ),
    ));
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 200));
    }
    // SVG-Logo wird asynchron dekodiert.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 300));
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
  }

  testWidgets('Start hell', (t) => shot(t, 'start_hell', const HomeShell(), seed: seedHome));
  testWidgets('Start dunkel',
      (t) => shot(t, 'start_dunkel', const HomeShell(), brightness: Brightness.dark, seed: seedHome));
  testWidgets('Verbindungen', (t) => shot(t, 'verbindungen',
      ConnectionsScreen(from: trips.first.origin, to: trips.first.destination, time: null, arriveBy: false)));
  testWidgets('Fahrt', (t) => shot(t, 'fahrt', const TripScreen(), seed: seedHome));
  testWidgets('Fahrt dunkel',
      (t) => shot(t, 'fahrt_dunkel', const TripScreen(), brightness: Brightness.dark, seed: seedHome));
  testWidgets('Abfahrten', (t) => shot(t, 'abfahrten', Scaffold(body: DeparturesScreen(initialStop: hbf))));
  testWidgets('Farben dunkel',
      (t) => shot(t, 'farben_dunkel', const DesignDemoScreen(), brightness: Brightness.dark));
}
