import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/auto_provider.dart';
import 'package:gleichda/data/motis/motis_provider.dart';
import 'package:gleichda/domain/models.dart';

Map<String, dynamic> json(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('Transitous: Verbindung Marienplatz → Hbf (Fußweg, U-Bahn, Fußweg)', () {
    final it = (json('motis_plan_muenchen.json')['itineraries'] as List).first as Map;
    const from = Location(id: 'start', providerId: 'motis', name: 'Start', type: LocationType.coordinate);
    const to = Location(id: 'ziel', providerId: 'motis', name: 'Ziel', type: LocationType.address);
    final geometry = <String, List<GeoPoint>>{};
    final t = parseMotisItinerary(it, from: from, to: to, geometry: geometry)!;
    expect(t.legs.map((l) => l.type), [LegType.walk, LegType.ride, LegType.walk]);
    final ride = t.legs[1];
    expect(ride.line!.name, isNotEmpty);
    expect(ride.journeyRef, startsWith(MotisProvider.refPrefix));
    expect(ride.from.departure!.hasRealtime, isTrue);
    expect(ride.from.stop.lat, closeTo(48.137, 0.01));
    // Start und Ziel tragen die Namen aus der Suche.
    expect(t.legs.last.to.stop.name, 'Ziel');
    expect(geometry.values.single.length, greaterThan(5));
    expect(t.id, startsWith(MotisProvider.refPrefix));
  });

  test('Transitous: S-Bahn München ist S-Bahn, nicht U-Bahn (Routentyp 109)', () {
    final s = (json('motis_stoptimes_marienplatz.json')['stopTimes'] as List).first as Map;
    expect(s['mode'], 'METRO');
    final line = motisLine(s);
    expect(line.mode, TransportMode.suburbanRail);
    expect(line.name, 'S1');
  });

  test('Quelle nach Lage: NRW beim VRR, sonst Transitous', () {
    expect(AutoProvider.inVrrLand(51.2544, 7.1495), isTrue); // Wuppertal
    expect(AutoProvider.inVrrLand(51.47, 7.0), isTrue); // Essen
    expect(AutoProvider.inVrrLand(48.137, 11.575), isFalse); // München
    expect(AutoProvider.inVrrLand(52.52, 13.41), isFalse); // Berlin
  });
}
