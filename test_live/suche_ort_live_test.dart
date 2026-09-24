// Live gegen den VRR-Testserver (nicht Teil der normalen Tests):
// flutter test test_live/suche_ort_live_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/trias/trias_provider.dart';

void main() {
  test('Suche findet zuerst, was am Standort liegt', () async {
    final p = TriasProvider(Dio());
    const elberfeld = (lat: 51.2560, lon: 7.1500);
    for (final (q, erwartet) in [
      ('Schleswiger', 'Wuppertal'),
      ('Kirchstr', 'Wuppertal'),
      ('Friedrich-Ebert-Str 100', 'Wuppertal'),
      ('Neumarkt', 'Wuppertal'),
    ]) {
      final r = await p.searchLocations(q, near: elberfeld, limit: 20);
      // ignore: avoid_print
      print('$q: ${r.take(5).map((l) => '${l.place}/${l.name} (${l.type.name})').join(' | ')}');
      expect(r.first.place, erwartet, reason: q);
    }
    // Ausdrücklich ein anderer Ort bleibt möglich.
    final k = await p.searchLocations('Köln Neumarkt', near: elberfeld, limit: 20);
    // ignore: avoid_print
    print('Köln Neumarkt: ${k.take(3).map((l) => '${l.place}/${l.name}').join(' | ')}');
    expect(k.first.place, 'Köln');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
