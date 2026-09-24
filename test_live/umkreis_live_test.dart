// Live gegen den VRR-Testserver (nicht Teil der normalen Tests):
// flutter test test_live/umkreis_live_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/trias/trias_provider.dart';
import 'package:gleichda/data/vrr_provider.dart';

void main() {
  test('Orte für Meldungen je Umkreis (Hagen-Boele)', () async {
    final dio = Dio();
    for (final r in [2000, 5000, 10000, 20000]) {
      final p = VrrProvider(TriasProvider(dio), EfaClient(dio));
      final sw = Stopwatch()..start();
      final regions = await p.regionsOf((lat: 51.3940, lon: 7.4660), radiusMeters: r);
      final list = await p.messages(regions: regions.keys.toList());
      // ignore: avoid_print
      print('${r ~/ 1000} km: ${regions.values.join(', ')} – ${list.length} Meldungen, ${sw.elapsedMilliseconds} ms');
      expect(regions, isNotEmpty);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
