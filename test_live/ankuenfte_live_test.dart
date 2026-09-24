// Live gegen den VRR-Testserver (nicht Teil der normalen Tests):
// flutter test test_live/ankuenfte_live_test.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/trias/trias_provider.dart';
import 'package:gleichda/data/trias/trias_requests.dart';
import 'package:gleichda/data/vrr_provider.dart';
import 'package:gleichda/domain/models.dart';

void main() {
  test('Ankünfte: Herkunft, Ankunftszeit, Fahrt vom Start bis hierher', () async {
    final dio = Dio();
    final p = VrrProvider(TriasProvider(dio), EfaClient(dio));
    // Wuppertal Hbf und eine Endhaltestelle (Vohwinkel Schwebebahn).
    for (final (id, name) in [('de:05124:11376', 'Wuppertal Hbf'), ('de:05124:11025', 'Wuppertal Vohwinkel Schwebebahn')]) {
      final stop = Location(id: id, providerId: 'vrr', name: name, type: LocationType.stop);
      final arr = await p.departures(stop, limit: 8, arrivals: true);
      final dep = await p.departures(stop, limit: 8);
      // ignore: avoid_print
      print('$name an: ${arr.departures.map((d) => '${d.line.name} von ${d.direction} ${d.time.planned.toLocal().toIso8601String().substring(11, 16)}').join(' | ')}');
      // ignore: avoid_print
      print('$name ab: ${dep.departures.map((d) => '${d.line.name} nach ${d.direction}').join(' | ')}');
      expect(arr.departures, isNotEmpty);
      expect(arr.departures.every((d) => d.arrival), isTrue);
      var opened = 0;
      for (final d in arr.departures.take(4)) {
        final trip = await p.tripOfDeparture(d);
        final leg = trip?.legs.single;
        // ignore: avoid_print
        print('  ${d.line.name}: ${leg == null ? 'nicht gefunden' : '${leg.from.stop.name} → ${leg.to.stop.name}, ${leg.intermediates.length} Zwischenhalte'}');
        if (leg != null) {
          opened++;
          expect(leg.to.arrival?.planned, d.time.planned);
        }
      }
      expect(opened, greaterThan(0));
    }
    // Antwort als Beispiel für die Tests aufheben.
    final xml = await dio.post<String>('https://openservice-test.vrr.de/static02/trias',
        data: const TriasRequests().stopEvent('de:05124:11376', limit: 6, arrivals: true),
        options: Options(contentType: 'text/xml; charset=utf-8', responseType: ResponseType.plain));
    File('test/fixtures/trias_se_ankuenfte.xml').writeAsStringSync(xml.data!);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
