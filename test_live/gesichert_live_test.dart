// Live gegen den VRR-Testserver (nicht Teil der normalen Tests):
// flutter test test_live/gesichert_live_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/transit_provider.dart';
import 'package:gleichda/data/trias/trias_provider.dart';
import 'package:gleichda/data/vrr_provider.dart';
import 'package:gleichda/domain/models.dart';

void main() {
  test('Oberbarmen Bf → Hannoverstraße: 602 → 632 gesichert', () async {
    final dio = Dio();
    final p = VrrProvider(TriasProvider(dio), EfaClient(dio));
    const from = Location(id: 'de:05124:11602', providerId: 'vrr', name: 'Oberbarmen Bf', type: LocationType.stop);
    const to = Location(id: 'de:05124:11662', providerId: 'vrr', name: 'Hannoverstraße', type: LocationType.stop);
    final now = DateTime.now();
    final morning = DateTime(now.year, now.month, now.day + 1, 7, 29);
    final trips = await p.planTrip(TripQuery(from: from, to: to, time: morning));
    var seen = 0;
    for (final t in trips) {
      final g = await p.guaranteedConnections(t);
      final names = [for (final l in t.legs) l.type == LegType.ride ? l.line?.name : '·'];
      // ignore: avoid_print
      print('$names ${t.departure.planned} → gesichert $g');
      if (names.whereType<String>().where((n) => n != '·').join(',') == '602,632') {
        expect(g, isNotEmpty);
        seen++;
      }
    }
    expect(seen, greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
