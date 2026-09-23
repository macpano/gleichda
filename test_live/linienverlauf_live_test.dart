// Live: ganzer Linienverlauf einer Abfahrt (flutter test test_live/linienverlauf_live_test.dart)
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/trias/trias_provider.dart';
import 'package:gleichda/data/vrr_provider.dart';
import 'package:gleichda/domain/models.dart';

void main() {
  test('Linienverlauf ab der Starthaltestelle', () async {
    final dio = Dio();
    final p = VrrProvider(TriasProvider(dio), EfaClient(dio));
    final stop = (await p.searchLocations('Wuppertal Alter Markt')).firstWhere((l) => l.type == LocationType.stop);
    final d = (await p.departures(stop, limit: 10)).departures.firstWhere((d) => d.journeyRef != null);
    final part = await p.tripOfDeparture(d);
    final whole = await p.tripOfDeparture(d, whole: true);
    int n(Trip? t) => t == null ? 0 : t.legs.first.intermediates.length + 2;
    // ignore: avoid_print
    print('${d.line.name} → ${d.direction}: ab hier ${n(part)} Halte, ganz ${n(whole)} Halte, '
        'Start ${whole?.legs.first.from.stop.name}');
    expect(n(whole), greaterThanOrEqualTo(n(part)));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
