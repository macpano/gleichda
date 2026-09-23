// Live: Suche vom Standort zur Adresse, wenn man schon (fast) dort ist.
// flutter test test_live/nah_am_ziel_live_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/transit_provider.dart';
import 'package:gleichda/data/trias/trias_provider.dart';
import 'package:gleichda/data/vrr_provider.dart';
import 'package:gleichda/domain/models.dart';
import 'package:gleichda/ui/screens/connections_screen.dart' show dropStarted;

void main() {
  test('Standort nah an der Zieladresse', () async {
    final dio = Dio();
    final p = VrrProvider(TriasProvider(dio), EfaClient(dio));
    final addr = (await p.searchLocations('Wuppertal Friedrich-Ebert-Straße 100')).firstWhere((l) => l.type == LocationType.address);
    for (final m in [0, 30, 150, 400, 900]) {
      final here = Location(id: 'coord', providerId: 'vrr', name: 'Mein Standort', type: LocationType.coordinate,
          lat: addr.lat! + m / 111000, lon: addr.lon!);
      for (final walk in [null, 10]) {
        final at = DateTime.now();
        try {
          final t = await p.planTrip(TripQuery(from: here, to: addr, time: at, maxWalkMinutes: walk));
          final kept = dropStarted(t, at);
          // ignore: avoid_print
          print('$m m, Fußweg ≤ $walk: ${t.length} → ${kept.length}  '
              '${t.map((x) => '[${x.legs.map((l) => l.type == LegType.ride ? l.line?.name : 'zu Fuß ${l.durationMinutes}').join(',')}] ${x.departure.best.difference(at).inSeconds}s').join('  ')}');
        } catch (e) {
          // ignore: avoid_print
          print('$m m, Fußweg ≤ $walk: Fehler $e');
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
