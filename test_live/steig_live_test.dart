// Live gegen den VRR-Testserver (nicht Teil der normalen Tests):
// flutter test test_live/steig_live_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/trias/trias_provider.dart';
import 'package:gleichda/data/vrr_provider.dart';
import 'package:gleichda/domain/models.dart';

void main() {
  test('Wuppertal Hbf: Abfahrten je Steig nur von diesem Steig', () async {
    final dio = Dio();
    final p = VrrProvider(TriasProvider(dio), EfaClient(dio));
    final platforms = await p.platformsNear((lat: 51.2544, lon: 7.1495), radiusMeters: 250);
    final hbf = platforms.where((x) => x.stopId == 'de:05124:11376').toList();
    expect(hbf.length, greaterThan(3));
    const stop = Location(id: 'de:05124:11376', providerId: 'vrr', name: 'Wuppertal Hbf', type: LocationType.stop);
    for (final pf in hbf.take(4)) {
      final board = await p.departures(stop.copyWith(id: pf.id), limit: 8);
      // Gleiswechsel (geplant 4, heute 5) zählt zum geplanten Steig.
      // ignore: avoid_print
      print('${pf.id} (Steig ${pf.name}): ${board.departures.map((d) => '${d.line.name}/${d.platform}').join(', ')}');
      expect(board.departures.every((d) => d.plannedPlatform == null || d.plannedPlatform == pf.name), isTrue);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
