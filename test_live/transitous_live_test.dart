// Live gegen Transitous und VRR über den Verteiler (nicht Teil der normalen Tests):
// flutter test test_live/transitous_live_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/auto_provider.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/motis/motis_provider.dart';
import 'package:gleichda/data/transit_provider.dart';
import 'package:gleichda/data/trias/trias_provider.dart';
import 'package:gleichda/data/vrr_provider.dart';
import 'package:gleichda/domain/models.dart';

// ignore_for_file: avoid_print
void main() {
  final dio = Dio();
  final p = AutoProvider(VrrProvider(TriasProvider(dio), EfaClient(dio)), MotisProvider(dio));
  String legs(Trip t) => t.legs
      .map((l) => l.type == LegType.ride ? '${l.line?.name}(${l.line?.mode.name})' : 'zu Fuß ${l.durationMinutes}')
      .join(' > ');

  test('München: Suche, Verbindung, Abfahrten, Linienweg, Linienverlauf', () async {
    const muc = (lat: 48.137, lon: 11.575);
    final a = (await p.searchLocations('Marienplatz', near: muc)).firstWhere((l) => l.type == LocationType.stop);
    final b = (await p.searchLocations('Olympiazentrum', near: muc)).firstWhere((l) => l.type == LocationType.stop);
    print('Orte: ${a.name} (${a.providerId}) → ${b.name}');
    final trips = await p.planTrip(TripQuery(from: a, to: b, time: DateTime.now()));
    expect(trips, isNotEmpty);
    for (final t in trips.take(3)) {
      print('${t.departure.best.toLocal()} – ${t.arrival.best.toLocal()}: ${legs(t)}');
    }
    final paths = await p.legPaths(trips.first);
    print('Linienweg: ${paths.map((x) => x?.length).toList()}');
    expect(paths.whereType<List<GeoPoint>>(), isNotEmpty);
    final board = await p.departures(a, limit: 5);
    print('Abfahrten: ${board.departures.map((d) => '${d.line.name}→${d.direction} ${d.platform ?? ''}').join(', ')}');
    expect(board.departures, isNotEmpty);
    final run = await p.tripOfDeparture(board.departures.first, whole: true);
    print('Linienverlauf: ${run == null ? 'keiner' : '${run.legs.first.intermediates.length + 2} Halte'}');
    expect(run, isNotNull);
    final fresh = await p.refreshTrip(trips.first);
    print('Aktualisiert: ${fresh != null}');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Berlin von Standort zu Adresse; Wuppertal bleibt beim VRR', () async {
    const here = Location(id: 'coord', providerId: 'vrr', name: 'Mein Standort', type: LocationType.coordinate, lat: 52.5219, lon: 13.4132);
    final to = (await p.searchLocations('Kurfürstendamm 21', near: (lat: 52.52, lon: 13.41))).first;
    print('Ziel: ${to.name}, ${to.place} (${to.type.name})');
    final trips = await p.planTrip(TripQuery(from: here, to: to, time: DateTime.now(), maxWalkMinutes: 15));
    expect(trips, isNotEmpty);
    print('Berlin: ${legs(trips.first)}; Ende ${trips.first.legs.last.to.stop.name} ${trips.first.legs.last.to.stop.lat}');
    final w = (await p.searchLocations('Wuppertal Hbf')).first;
    print('Wuppertal Hbf über ${w.providerId}');
    expect(w.providerId, isNot(MotisProvider.providerKey));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Polyline mit 7 Stellen', () {
    final pts = decodePolyline('kuocu[gw`x{E??', precision: 7);
    expect(pts.first.lat, closeTo(48.137047, 1e-5));
    expect(pts.first.lon, closeTo(11.575386, 1e-5));
  });
}
