// Live: Liefert die Suche (wie die Verbindungsliste sie filtert) zeitweise nichts?
// flutter test test_live/verbindungen_wiederholt_live_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/transit_provider.dart';
import 'package:gleichda/data/trias/trias_provider.dart';
import 'package:gleichda/data/vrr_provider.dart';
import 'package:gleichda/domain/models.dart';
import 'package:gleichda/ui/screens/connections_screen.dart' show dropStarted;

void main() {
  test('Suchen wie in der Verbindungsliste', () async {
    final dio = Dio();
    final p = VrrProvider(TriasProvider(dio), EfaClient(dio));
    final stop = (await p.searchLocations('Wuppertal Alter Markt')).firstWhere((l) => l.type == LocationType.stop);
    final hbf = (await p.searchLocations('Wuppertal Hbf')).firstWhere((l) => l.type == LocationType.stop);
    final addr = (await p.searchLocations('Wuppertal Friedrich-Ebert-Straße 100')).firstWhere((l) => l.type == LocationType.address);
    const here = Location(id: 'coord', providerId: 'vrr', name: 'Mein Standort', type: LocationType.coordinate, lat: 51.2645, lon: 7.1775);
    for (final (name, a, b) in [('Halt→Halt', stop, hbf), ('Halt→Adresse', stop, addr), ('Standort→Halt', here, hbf), ('Standort→Adresse', here, addr)]) {
      for (final opt in TripOptimization.values) {
        final at = DateTime.now();
        final t = await p.planTrip(TripQuery(from: a, to: b, time: at, optimization: opt, maxWalkMinutes: 10));
        final kept = dropStarted(t, at);
        // ignore: avoid_print
        print('$name ${opt.name}: ${t.length} → ${kept.length}  '
            '${t.map((x) => '${x.departure.best.difference(at).inSeconds}s').join(' ')}');
      }
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
