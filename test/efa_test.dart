import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/trias/trias_parser.dart';
import 'package:gleichda/data/vrr_provider.dart';
import 'package:gleichda/domain/models.dart';

Map<String, dynamic> json(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('TRIAS-Fahrtreferenz wird zu EFA-Kennungen', () {
    final dep = DateTime.utc(2026, 9, 23, 14, 8);
    final k = EfaTripKey.fromJourneyRef(
        'wsw:66604::R:w25:266', 'de:05124:11071', dep)!;
    expect(k.line, 'wsw:66604: :R:w25');
    expect(k.tripCode, '266');
    expect(k.stopId, 'de:05124:11071');
    expect(k.date, '20260923');
    final l = dep.toLocal();
    expect(k.time,
        '${l.hour.toString().padLeft(2, '0')}${l.minute.toString().padLeft(2, '0')}');
  });

  test('TripStopTimes: alle Halte mit Plan- und Echtzeit', () {
    final stops = parseTripStopTimes(json('efa_tripstoptimes.json'))!;
    expect(stops.length, greaterThan(5));
    expect(stops.first.departure, isNotNull);
    expect(stops.last.arrival, isNotNull);
    expect(stops.any((s) => s.departure?.quality == TimeQuality.realtime),
        isTrue);
    expect(
        stops.every(
            (s) => s.stop.lat != null && s.stop.lat! > 50 && s.stop.lat! < 53),
        isTrue);
    expect(stops.every((s) => !RegExp(r'^\d+$').hasMatch(s.stop.name)), isTrue);
  });

  test('Abschnitt wird mit EFA-Halten aktualisiert', () {
    final stops = parseTripStopTimes(json('efa_tripstoptimes.json'))!;
    final a = stops[2], b = stops[6];
    final leg = Leg(
      type: LegType.ride,
      from: StopTime(
          stop: Location(
              id: stopAreaId(a.stop.id), providerId: 't', name: 'A'),
          departure: EventTime(planned: a.departure!.planned)),
      to: StopTime(
          stop: Location(
              id: stopAreaId(b.stop.id), providerId: 't', name: 'B'),
          arrival: EventTime(planned: b.arrival!.planned)),
      journeyRef: 'x:1',
    );
    final merged = mergeLeg(leg, stops)!;
    expect(merged.intermediates.length, 3);
    expect(merged.from.stop.name, 'A'); // Name aus TRIAS bleibt
    expect(merged.from.departure, a.departure);
    expect(merged.to.arrival, b.arrival);
    expect(mergeLeg(leg.copyWith(from: leg.to, to: leg.from), stops), isNull);
  });

  test('EFA kennt die Fahrt nicht: kein Ergebnis statt Absturz', () {
    expect(parseTripStopTimes(const {'serverInfo': {}}), isNull);
  });

  test('Linienwege aus der Verbindungsauskunft (XML_TRIP_REQUEST2)', () {
    final json = jsonDecode(File('test/fixtures/efa_trip_alter_markt_vohwinkel.json').readAsStringSync())
        as Map<String, dynamic>;
    final paths = parseLegPaths(json);
    final bus = paths.firstWhere((p) => p.lineName == '604');
    expect(bus.line, 'wsw:66604: :R:w25');
    expect(bus.tripCode, isNotNull);
    expect(bus.points.length, greaterThan(10));
    expect(bus.points.first.lat, closeTo(51.269, 0.01));
    final re = paths.firstWhere((p) => p.lineName == 'RE4');
    expect(re.points.length, greaterThan(100), reason: 'Zugweg entlang der Gleise');
  });

  test('Gebiet für Meldungen aus der Haltestellenkennung', () {
    expect(regionFromStopId('de:05124:11376'), '5124000'); // Wuppertal
    expect(regionFromStopId('de:05111:18235:0:1'), '5111000'); // Düsseldorf
    expect(regionFromStopId('de:11000:900100001'), '11000000'); // Berlin
    expect(regionFromStopId('coord:51.2:7.1'), isNull);
  });

  test('Haltestellennamen behalten den Ort', () {
    expect(fullStopName('Wuppertal, Alter Markt'), 'Wuppertal Alter Markt');
    expect(fullStopName('Wuppertal Hbf'), 'Wuppertal Hbf');
    final stops = parseTripStopTimes(
        jsonDecode(File('test/fixtures/efa_tripstoptimes.json').readAsStringSync()) as Map<String, dynamic>)!;
    expect(stops.first.stop.name, startsWith('Wuppertal '));
  });
}
