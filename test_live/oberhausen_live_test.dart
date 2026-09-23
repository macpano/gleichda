// Live: Standort Wuppertal → Oberhausen Hbf spät abends, mit und ohne ausgeschlossene Verkehrsmittel.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/transit_provider.dart';
import 'package:gleichda/data/trias/trias_provider.dart';
import 'package:gleichda/data/vrr_provider.dart';
import 'package:gleichda/domain/models.dart';
import 'package:gleichda/ui/screens/connections_screen.dart' show dropStarted;

void main() {
  test('Wuppertal → Oberhausen Hbf', () async {
    final dio = Dio();
    final p = VrrProvider(TriasProvider(dio), EfaClient(dio));
    final to = (await p.searchLocations('Oberhausen Hbf')).firstWhere((l) => l.type == LocationType.stop);
    const here = Location(id: 'coord', providerId: 'vrr', name: 'Mein Standort', type: LocationType.coordinate, lat: 51.2560, lon: 7.1500);
    for (final ex in [<TransportMode>{}, {TransportMode.rail}, {TransportMode.bus}, {TransportMode.tram, TransportMode.subway}]) {
      final t = await p.planTrip(TripQuery(from: here, to: to, time: DateTime.now(), excludedModes: ex, maxWalkMinutes: 15));
      // ignore: avoid_print
      print('ohne $ex: ${t.length} – ${t.map((x) => x.rides.map((r) => '${r.line?.name}/${r.line?.mode.name}').join('>')).join(' | ')}');
    }
    for (final opt in TripOptimization.values) {
      final at = DateTime.now();
      final t = await p.planTrip(TripQuery(from: here, to: to, time: at, optimization: opt, maxWalkMinutes: 15));
      final kept = dropStarted(t, at);
      // ignore: avoid_print
      print('${opt.name}: ${t.length} → ${kept.length}  ${t.map((x) => '${x.departure.best.difference(at).inMinutes}min[${x.legs.first.type.name} ${x.legs.first.durationMinutes}]').join(' ')}');
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
