import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/transit_provider.dart';
import 'package:gleichda/data/trias/trias_parser.dart';
import 'package:gleichda/data/trias/trias_provider.dart';
import 'package:gleichda/data/trias/trias_requests.dart';
import 'package:gleichda/domain/models.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  group('LocationInformationRequest', () {
    test('Wuppertal Hbf: Haltestelle mit Ort und Koordinate', () {
      final list = parseLocations(fixture('trias_lir_hbf.xml'));
      // Der Server sortiert nicht nach Trefferqualität: an erster Stelle
      // steht „Hauptbahnhof (SEV)“ mit 0,25.
      expect(list.first.name, 'Hauptbahnhof (SEV)');
      final hbf = rankLocations(list, 'Wuppertal Hauptbahnhof', null).first;
      expect(hbf.id, 'de:05124:11376');
      expect(hbf.name, 'Wuppertal Hbf'); // „Hbf“ allein wäre zu knapp
      expect(hbf.place, 'Wuppertal');
      expect(hbf.lat, closeTo(51.255, 0.01));
      expect(hbf.type, LocationType.stop);
    });

    test('gleichnamige Haltestellen werden nach Nähe sortiert', () {
      final list = parseLocations(fixture('trias_lir_markt.xml'));
      expect(list.length, greaterThan(3));
      const here = (lat: 51.27, lon: 7.19);
      final ranked = rankLocations(list, 'Markt', here);
      final d = distanceBetween(ranked.first, here)!;
      final farthest = list
          .map((l) => distanceBetween(l, here))
          .whereType<double>()
          .reduce((a, b) => a > b ? a : b);
      expect(d, lessThan(farthest));
    });

    test('Umkreissuche liefert Haltestellen ohne Ortspräfix', () {
      final list = parseLocations(fixture('trias_lir_near.xml'));
      expect(list.map((l) => l.name), contains('Alter Markt'));
      expect(list.every((l) => l.lat != null), isTrue);
    });
  });

  group('StopEventRequest', () {
    const stop =
        Location(id: 'de:05124:11376', providerId: 't', name: 'Wuppertal Hbf');

    test('Abfahrten mit Linie, Ziel, Steig und Echtzeit', () {
      final board = parseStopEvents(fixture('trias_se_hbf.xml'), stop);
      expect(board.departures.length, greaterThan(10));
      final bus =
          board.departures.firstWhere((d) => d.line.mode == TransportMode.bus);
      expect(bus.line.name, matches(RegExp(r'^\w+$')));
      expect(bus.direction, isNotEmpty);
      expect(bus.journeyRef, isNotNull);
      for (var i = 1; i < board.departures.length; i++) {
        expect(
            board.departures[i].time.best
                .isBefore(board.departures[i - 1].time.best),
            isFalse);
      }
    });

    test('Schwebebahn: Liniennummer aus der Linienkennung, nur Fahrplan', () {
      final board = parseStopEvents(fixture('trias_se_hbf.xml'), stop);
      final sb = board.departures
          .where((d) => d.line.mode == TransportMode.suspension);
      expect(sb, isNotEmpty);
      expect(sb.first.line.name, '60');
      expect(sb.first.time.quality, TimeQuality.planned);
      expect(sb.first.time.delayMinutes, isNull);
    });

    test('S-Bahn-Namen werden für die Plakette zusammengezogen', () {
      final board = parseStopEvents(fixture('trias_se_hbf.xml'), stop);
      final names = board.departures.map((d) => d.line.name).toSet();
      expect(names, contains('S8'));
      expect(names.any((n) => RegExp(r'^S \d').hasMatch(n)), isFalse);
    });

    test('Meldungen aus dem Antwortkontext', () {
      final board = parseStopEvents(fixture('trias_se_hbf.xml'), stop);
      expect(board.messages.every((m) => m.id.isNotEmpty && m.title.isNotEmpty),
          isTrue);
    });

    test('Folgehalte einer Fahrt über die Fahrt-Referenz', () {
      final xml = fixture('trias_se_onward.xml');
      final ref =
          RegExp(r'<trias:JourneyRef>([^<]+)<').firstMatch(xml)!.group(1)!;
      final calls = parseOnwardCalls(xml, ref)!;
      expect(calls.length, greaterThan(2));
      expect(parseOnwardCalls(xml, 'gibt:es:nicht'), isNull);
    });
  });

  group('TripRequest', () {
    test('Verbindungen mit Abschnitten, Zwischenhalten und Fahrt-Referenz', () {
      final trips = parseTrips(fixture('trias_trip_alter_markt_vohwinkel.xml'));
      expect(trips, isNotEmpty);
      for (final t in trips) {
        expect(t.legs, isNotEmpty);
        expect(t.arrival.best.isAfter(t.departure.best), isTrue);
        for (final r in t.rides) {
          expect(r.journeyRef, isNotNull);
          expect(r.operatingDay, isNotNull);
          expect(r.line, isNotNull);
          expect(r.from.departure, isNotNull);
          expect(r.to.arrival, isNotNull);
        }
      }
    });

    test('Fußweg vom Standort und Umstiegsweg', () {
      final trips = parseTrips(fixture('trias_trip_coord.xml'));
      final first = trips.first;
      expect(first.legs.first.type, LegType.walk);
      expect(first.legs.first.from.stop.type, LocationType.coordinate);
      expect(first.legs.first.durationMinutes, greaterThan(0));
      expect(trips.expand((t) => t.legs).any((l) => l.type == LegType.transfer),
          isTrue);
    });

    test('Gespeicherte Verbindung wird in neuen Ergebnissen wiedergefunden', () {
      final trips = parseTrips(fixture('trias_trip_alter_markt_vohwinkel.xml'));
      expect(matchTrip(trips[1], trips), same(trips[1]));
    });

    test('Modelle überstehen JSON (für den Cache)', () {
      final t = parseTrips(fixture('trias_trip_coord.xml')).first;
      expect(Trip.fromJson(t.toJson()), t);
    });
  });

  test('Fehlerantwort wird als ProviderException gemeldet', () {
    expect(() => parseTrips(fixture('trias_tripinfo.txt')),
        throwsA(isA<ProviderException>()));
  });

  test('Anfragen sind gültiges TRIAS mit Zeitstempel', () {
    final r = TriasRequests(clock: () => DateTime.utc(2026, 9, 23, 12));
    final xml = r.trip(const TriasStop('de:1'), const TriasCoord(51.2, 7.1),
        time: DateTime.utc(2026, 9, 23, 13));
    expect(xml, contains('<siri:RequestTimestamp>2026-09-23T12:00:00Z<'));
    expect(xml, contains('<StopPointRef>de:1</StopPointRef>'));
    expect(xml, contains('<Latitude>51.200000</Latitude>'));
    expect(xml, contains('<DepArrTime>2026-09-23T13:00:00Z</DepArrTime>'));
  });

  test('Ortsnamen: Präfix nur abtrennen, wenn genug übrig bleibt', () {
    expect(displayName('Wuppertal Alter Markt', 'Wuppertal'), 'Alter Markt');
    expect(displayName('Wuppertal Hbf', 'Wuppertal'), 'Wuppertal Hbf');
    expect(displayName('Velbert Neviges Markt/Bahnhof', 'Velbert'),
        'Neviges Markt/Bahnhof');
  });
}
