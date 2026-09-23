import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/walk_route.dart';

void main() {
  test('Fußweg mit Abbiegehinweisen (FOSSGIS/OSRM)', () {
    final json = jsonDecode(File('test/fixtures/osrm_foot_alter_markt.json').readAsStringSync())
        as Map<String, dynamic>;
    final r = parseWalkRoute(json)!;
    expect(r.points.length, greaterThan(10));
    expect(r.meters, closeTo(320, 20));
    expect(r.steps.first.type, 'depart');
    expect(r.steps[1].text, 'Links abbiegen in Alter Markt');
    expect(r.steps.last.type, 'arrive');
    // Vom Start aus: nächstes Manöver ist das Abbiegen nach gut 50 m.
    final next = r.nextStep(0)!;
    expect(next.step.modifier, 'left');
    expect(next.meters, closeTo(55, 15));
    // Position abseits: Abstand zum Weg wird gemessen.
    final at = r.locate((lat: r.points[5].lat + 0.003, lon: r.points[5].lon));
    expect(at.off, greaterThan(150));
  });
}
