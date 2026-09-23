// Live gegen VRR und FOSSGIS (nicht Teil der normalen Tests):
// flutter test test_live/fussweg_ziel_live_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/transit_provider.dart';
import 'package:gleichda/data/trias/trias_provider.dart';
import 'package:gleichda/data/vrr_provider.dart';
import 'package:gleichda/data/walk_route.dart';
import 'package:gleichda/domain/models.dart';
import 'package:gleichda/state/providers.dart' show walkEnds;

void main() {
  test('Fußweg vom Ausstieg zur Zieladresse hat Koordinaten und Gehweg', () async {
    final dio = Dio();
    final p = VrrProvider(TriasProvider(dio), EfaClient(dio));
    final from = (await p.searchLocations('Wuppertal Alter Markt')).firstWhere((l) => l.type == LocationType.stop);
    final to = (await p.searchLocations('Wuppertal Friedrich-Ebert-Straße 100'))
        .firstWhere((l) => l.type == LocationType.address);
    // ignore: avoid_print
    print('Ziel: ${to.name} ${to.id} ${to.lat},${to.lon}');
    final trips = await p.planTrip(TripQuery(from: from, to: to, time: DateTime.now().add(const Duration(minutes: 5))));
    expect(trips, isNotEmpty);
    // Wie in der App: Die geöffnete Fahrt wird sofort aktualisiert (EFA) und
    // bekommt dabei die Lage der Haltestellen.
    final t = (await p.refreshTrip(trips.first))!;
    final i = t.legs.length - 1;
    expect(t.legs[i].type, isNot(LegType.ride));
    final ends = walkEnds(t, i);
    // ignore: avoid_print
    print('letzter Fußweg: ${t.legs[i].from.stop.name} ${t.legs[i].from.stop.lat} → ${t.legs[i].to.stop.name} ${t.legs[i].to.stop.lat}; Ausstieg ${t.legs[i-1].to.stop.id} ${t.legs[i-1].to.stop.lat}; Enden $ends');
    expect(ends, isNotNull);
    final route = await WalkRouter(dio).route(ends!.$1, ends.$2);
    // ignore: avoid_print
    print('Gehweg: ${route?.points.length} Punkte, ${route?.meters.round()} m');
    expect(route!.points.length, greaterThan(2));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
