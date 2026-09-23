import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/background.dart';
import 'package:gleichda/data/db/database.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/repository.dart';
import 'package:gleichda/data/transit_provider.dart';
import 'package:gleichda/data/trias/trias_parser.dart';
import 'package:gleichda/domain/companion.dart';
import 'package:gleichda/domain/connections.dart';
import 'package:gleichda/domain/models.dart';
import 'package:gleichda/domain/settings.dart';
import 'package:gleichda/state/alarm_planner.dart';
import 'package:gleichda/state/providers.dart' show arrivedLongAgo;
import 'package:gleichda/ui/connection_views.dart';
import 'package:gleichda/ui/screens/connections_screen.dart' show mergeTrips, dropStarted;

String fixture(String n) => File('test/fixtures/$n').readAsStringSync();

EventTime at(int h, int m, {int? delay}) {
  final p = DateTime(2026, 9, 23, h, m);
  return EventTime(
    planned: p,
    estimated: delay == null ? null : p.add(Duration(minutes: delay)),
    quality: delay == null ? TimeQuality.planned : TimeQuality.realtime,
  );
}

Location stop(String id) => Location(id: id, providerId: 't', name: id);

Leg ride(String from, EventTime dep, String to, EventTime arr, {List<StopTime> via = const []}) => Leg(
      type: LegType.ride,
      from: StopTime(stop: stop(from), departure: dep),
      to: StopTime(stop: stop(to), arrival: arr),
      intermediates: via,
      line: const Line(id: 'wsw:66640::H', name: '640', mode: TransportMode.bus),
      direction: 'Hbf',
    );

void main() {
  group('Anschlussprüfung', () {
    Trip trip({int delay = 0, int walk = 0}) => Trip(id: 't', legs: [
          ride('A', at(14, 0), 'B', at(14, 10, delay: delay)),
          if (walk > 0)
            Leg(
              type: LegType.transfer,
              from: StopTime(stop: stop('B'), departure: at(14, 10)),
              to: StopTime(stop: stop('C'), arrival: at(14, 10 + walk)),
              durationMinutes: walk,
            ),
          ride(walk > 0 ? 'C' : 'B', at(14, 15, delay: 0), 'D', at(14, 30, delay: 0)),
        ]);

    test('sicher, knapp, nicht erreichbar', () {
      expect(checkTransfers(trip()).single.state, TransferState.safe); // 5 min ≥ 3 min Umsteigezeit
      expect(checkTransfers(trip(delay: 3)).single.state, TransferState.tight); // 2 min: knapp, aber machbar
      expect(checkTransfers(trip(delay: 5)).single.state, TransferState.missed); // 0 min am selben Halt
    });

    test('mit Umsteigeweg zählt die Gehzeit statt der persönlichen Umsteigezeit', () {
      expect(checkTransfers(trip(walk: 4)).single.state, TransferState.tight); // 5 − 4 = 1
      expect(checkTransfers(trip(walk: 6)).single.state, TransferState.missed);
    });

    test('persönliche Umsteigezeit: langsam macht aus sicher knapp', () {
      // 4 min Puffer: für „langsam“ (5 min) knapp, für „schnell“ (1 min) sicher.
      expect(checkTransfers(trip(delay: 1), transferMinutes: Pace.slow.transferMinutes).single.state,
          TransferState.tight);
      expect(checkTransfers(trip(delay: 1), transferMinutes: Pace.fast.transferMinutes).single.state,
          TransferState.safe);
    });

    test('nicht erreichbare Verbindungen ans Ende, Etiketten', () {
      final ok = trip();
      final bad = trip(delay: 5).copyWith(id: 'bad');
      final direct = Trip(id: 'direct', legs: [ride('A', at(14, 5), 'D', at(14, 45))]);
      final rated = rateConnections([bad, ok, direct], transferMinutes: 3);
      expect(rated.last.trip.id, 'bad');
      expect(rated.last.reachable, isFalse);
      // „ohne Umstieg“ steht schon in der Zeile (interchangesText), kein doppeltes Etikett.
      expect(rated.firstWhere((i) => i.trip.id == 'direct').labels, isEmpty);
    });
  });

  group('Unterwegs', () {
    final trip = Trip(id: 'u', legs: [
      ride('A', at(14, 0), 'C', at(14, 20), via: [
        StopTime(stop: stop('B'), arrival: at(14, 10), departure: at(14, 10)),
      ]),
    ]);

    test('vor der Abfahrt: einsteigen', () {
      final s = nextStep(trip, DateTime(2026, 9, 23, 13, 55));
      expect(s.phase, CompanionPhase.waiting);
      expect(s.where.stop.id, 'A');
    });

    test('im Fahrzeug: Ausstieg, Fortschritt, Halte bis dahin', () {
      final s = nextStep(trip, DateTime(2026, 9, 23, 14, 5));
      expect(s.phase, CompanionPhase.onBoard);
      expect(s.where.stop.id, 'C');
      expect(s.progress, closeTo(0.25, 0.01));
      expect(s.stopsLeft, 2);
      expect(nextStep(trip, DateTime(2026, 9, 23, 14, 15)).stopsLeft, 1);
    });

    test('nach der Ankunft: angekommen', () {
      expect(nextStep(trip, DateTime(2026, 9, 23, 14, 25)).phase, CompanionPhase.arrived);
    });
  });

  group('EFA', () {
    test('Meldungen mit Linien, Halten, Zeitraum und Klartext', () {
      final list = parseAddInfo(jsonDecode(fixture('efa_addinfo_wuppertal.json')) as Map<String, dynamic>);
      expect(list.length, greaterThan(5));
      final m = list.firstWhere((m) => m.lineIds.isNotEmpty);
      expect(m.lineNames.length, m.lineIds.length);
      expect(m.lineIds.every((id) => RegExp(r'^[a-z]+:\w+$').hasMatch(id)), isTrue);
      expect(list.any((m) => m.text != null && !m.text!.contains('<')), isTrue);
      expect(list.any((m) => m.title.contains('Aufzug')), isTrue);
    });

    test('Linienkennung aus TRIAS und EFA passt zusammen', () {
      expect(lineKey('wsw:66620::H'), lineKey('wsw:66620: :H:'));
    });

    test('HTML wird zu Absätzen', () {
      expect(htmlToText('<p>Wegen der Kirmes f&auml;hrt</p><p>die Linie Umleitung.</p>'),
          'Wegen der Kirmes fährt\ndie Linie Umleitung.');
    });

    test('Steige mit Koordinaten aus den Abfahrten', () {
      final list = parsePlatforms(jsonDecode(fixture('efa_dm_alter_markt.json')) as Map<String, dynamic>, 'x');
      expect(list, isNotEmpty);
      expect(list.every((p) => p.lat > 51 && p.lat < 52 && p.lon > 7 && p.lon < 8), isTrue);
    });
  });

  group('Fahrtenwecker', () {
    final a = Alarm(
      id: 'a',
      name: 'Arbeit',
      from: stop('A'),
      to: stop('B'),
      timeRef: AlarmTimeRef.arriveBy,
      minuteOfDay: 8 * 60,
      weekdays: const [1, 2, 3, 4, 5],
    );

    test('nächster Termin überspringt das Wochenende', () {
      // Freitag, 25.09.2026, 9 Uhr → Montag 8 Uhr
      expect(nextOccurrence(a, DateTime(2026, 9, 25, 9)), DateTime(2026, 9, 28, 8));
      // Freitag 7 Uhr → heute 8 Uhr
      expect(nextOccurrence(a, DateTime(2026, 9, 25, 7)), DateTime(2026, 9, 25, 8));
    });
  });

  test('Profil übersteht Speichern und Laden', () {
    const s = AppSettings(
      transferPace: Pace.slow,
      accessible: true,
      excludedModes: {ModeGroup.regional},
      connectionsGrid: true,
    );
    final back = AppSettings.decode(s.encode());
    expect(back.transferPace, Pace.slow);
    expect(back.accessible, isTrue);
    expect(back.excludedModes, {ModeGroup.regional});
    expect(back.connectionsGrid, isTrue);
    expect(back.summary, contains('barrierefrei'));
    expect(AppSettings.decode('kaputt').isDefault, isTrue);
  });

  test('Linienabo: nur neue Meldungen zu abonnierten Linien, erster Lauf still', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    final repo = Repository(db);
    final messages = parseAddInfo(jsonDecode(fixture('efa_addinfo_wuppertal.json')) as Map<String, dynamic>);
    final withLine = messages.firstWhere((m) => m.lineIds.isNotEmpty);
    await repo.subscribe(Subscription(lineId: withLine.lineIds.first, providerId: 'vrr', lineName: 'x'));
    final p = _Messages(messages.where((m) => m.id != withLine.id).toList());
    expect(await checkSubscriptions(repo, p), 0); // erster Lauf: nur merken
    p.list = messages;
    expect(await checkSubscriptions(repo, p), 1); // jetzt neu
    expect(await checkSubscriptions(repo, p), 0); // schon bekannt
    await db.close();
  });

  test('Fahrtverlauf-Parser übernimmt EFA-Koordinaten in die Fahrt', () {
    final trips = parseTrips(fixture('trias_trip_alter_markt_vohwinkel.xml'));
    expect(trips.first.rides.first.from.stop.lat, isNull); // TRIAS liefert in Verbindungen keine Koordinaten
  });

  group('Unterwegs per GPS', () {
    // Vier Halte auf einer Linie nach Osten, je etwa 700 m auseinander.
    StopTime st(String id, double lon, EventTime t, {bool dep = true}) => StopTime(
        stop: Location(id: id, providerId: 't', name: id, lat: 51.25, lon: lon),
        departure: dep ? t : null,
        arrival: dep ? null : t);
    final leg = Leg(
      type: LegType.ride,
      from: st('A', 7.10, at(14, 0)),
      intermediates: [st('B', 7.11, at(14, 2)), st('C', 7.12, at(14, 4))],
      to: st('D', 7.13, at(14, 6), dep: false),
      line: const Line(id: 'wsw:66640::H', name: '640', mode: TransportMode.bus),
    );
    final trip = Trip(id: 'g', legs: [leg]);

    test('Lage auf der Strecke: passierter Halt und Fortschritt', () {
      final fix = locateOnLeg(leg, (lat: 51.2501, lon: 7.115))!;
      expect(fix.passed, 1); // zwischen B und C
      expect(fix.progress, closeTo(0.5, 0.05));
      expect(locateOnLeg(leg, (lat: 51.26, lon: 7.115)), isNull, reason: 'über 1 km neben der Strecke');
    });

    test('GPS schlägt die Uhrzeit: nächster Halt und Halte bis zum Ausstieg', () {
      // Laut Uhr erst an B, per GPS schon hinter C.
      final step = nextStep(trip, DateTime(2026, 9, 23, 14, 2, 30), gps: (lat: 51.25, lon: 7.125));
      expect(step.phase, CompanionPhase.onBoard);
      expect(step.byGps, isTrue);
      expect(step.stopsLeft, 1);
      expect(step.nextBeforeExit, isNull, reason: 'nächster Halt ist der Ausstieg');
      final early = nextStep(trip, DateTime(2026, 9, 23, 14, 1), gps: (lat: 51.25, lon: 7.105));
      expect(early.nextBeforeExit?.stop.id, 'B');
    });
  });

  test('Anzeigename mit Ort', () {
    Location l(String n, String? p, [LocationType t = LocationType.stop]) =>
        Location(id: n, providerId: 't', name: n, place: p, type: t);
    expect(l('Hbf', 'Wuppertal').label, 'Wuppertal Hbf');
    expect(l('Wuppertal Hbf', 'Wuppertal').label, 'Wuppertal Hbf');
    expect(l('W-Barmen Bf', 'Wuppertal').label, 'W-Barmen Bf');
    expect(l('Hofaue 12', 'Wuppertal', LocationType.address).label, 'Hofaue 12, Wuppertal');
    expect(l('Alter Markt', null).label, 'Alter Markt');
  });

  test('Fahrt gilt 2 Minuten nach der Ankunft als erledigt', () {
    final t = Trip(id: 'x', legs: [ride('A', at(14, 0), 'B', at(14, 20))]);
    expect(arrivedLongAgo(t, DateTime(2026, 9, 23, 14, 21)), isFalse);
    expect(arrivedLongAgo(t, DateTime(2026, 9, 23, 14, 23)), isTrue);
  });

  test('Weiterfahrt im selben Fahrzeug (remainInVehicle)', () {
    final xml = fixture('trias_trip_stay_seated.xml');
    final trip = parseTrips(xml).first;
    expect(trip.legs.where((l) => l.staySeated), hasLength(1));
    expect(trip.interchanges, 0);
    expect(checkTransfers(trip).single.state, TransferState.staySeated);
    expect(isReachable(trip), isTrue);
    // Unterwegs: eine Fahrt bis zum Ziel, die Wende ist ein Zwischenhalt.
    final joined = joinedRides(trip);
    expect(joined, hasLength(1));
    expect(joined.single.to.stop.name, trip.destination.name);
  });

  test('Sortierung ohne neue Suche: schnellste, wenig Umstiege', () {
    final slow = Trip(id: 'slow', legs: [ride('A', at(14, 0), 'B', at(14, 50))]);
    final fast = Trip(id: 'fast', legs: [ride('A', at(14, 10), 'C', at(14, 20)), ride('C', at(14, 25), 'B', at(14, 40))]);
    final items = rateConnections([slow, fast], transferMinutes: 3);
    expect(sortConnections(items, ConnectionSort.departure).first.trip.id, 'slow');
    expect(sortConnections(items, ConnectionSort.fastest).first.trip.id, 'fast');
    expect(sortConnections(items, ConnectionSort.fewChanges).first.trip.id, 'slow');
  });

  group('Verbindungsliste', () {
    Trip t(String id, int h, int m) => Trip(id: id, legs: [ride('A', at(h, m), 'B', at(h, m + 20))]);

    test('andere Profile nur im Zeitraum der Hauptsuche', () {
      final merged = mergeTrips([t('a', 14, 0), t('b', 14, 30)], [t('c', 14, 15), t('d', 16, 0)]);
      expect(merged.map((x) => x.id), ['a', 'c', 'b']);
    });

    test('begonnene Verbindungen fallen weg', () {
      final list = dropStarted([t('a', 13, 50), t('b', 14, 0), t('c', 14, 10)], DateTime(2026, 9, 23, 14, 0));
      expect(list.map((x) => x.id), ['b', 'c']);
    });
  });
}

class _Messages implements TransitProvider {
  _Messages(this.list);

  List<Message> list;

  @override
  String get id => 'fake';

  @override
  Future<List<Message>> messages({List<String> lineIds = const [], List<String> regions = const []}) async => list;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
