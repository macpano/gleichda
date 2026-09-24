import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/background.dart';
import 'package:gleichda/data/db/database.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/feedback.dart' show feedbackAccepted;
import 'package:gleichda/data/html_text.dart';
import 'package:gleichda/data/repository.dart';
import 'package:gleichda/data/transit_provider.dart';
import 'package:gleichda/data/trias/trias_parser.dart';
import 'package:gleichda/domain/companion.dart';
import 'package:gleichda/domain/realtime_memory.dart';
import 'package:gleichda/domain/connections.dart';
import 'package:gleichda/domain/models.dart';
import 'package:gleichda/domain/settings.dart';
import 'package:gleichda/domain/subscriptions.dart';
import 'package:gleichda/state/alarm_planner.dart';
import 'package:gleichda/data/trias/trias_provider.dart' show withEndpoints;
import 'package:gleichda/ui/trip_status.dart' show isReplacement, sevStopHint;
import 'package:gleichda/state/providers.dart' show MessagesState, arrivedLongAgo, tripEnd, walkEnds;
import 'package:gleichda/ui/connection_views.dart';
import 'package:gleichda/ui/format.dart' show countdownWithTime;
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
  test('Ankünfte aus TRIAS: Ankunftszeit und Herkunft', () {
    const hbf = Location(id: 'de:05124:11376', providerId: 'vrr', name: 'Wuppertal Hbf', type: LocationType.stop);
    final xml = File('test/fixtures/trias_se_ankuenfte.xml').readAsStringSync();
    final arr = parseStopEvents(xml, hbf, arrivals: true).departures;
    expect(arr, isNotEmpty);
    expect(arr.every((d) => d.arrival), isTrue);
    // Richtung ist die Herkunft, nicht das Ziel (das hieße ja Wuppertal Hbf).
    expect(arr.any((d) => d.direction.contains('Hbf') && d.direction.startsWith('Wuppertal')), isFalse);
    expect(arr.every((d) => d.direction.isNotEmpty), isTrue);
  });

  test('Ist-Zeiten vergangener Halte bleiben, wenn die Auskunft sie nicht mehr kennt', () {
    final t0 = DateTime(2026, 9, 24, 4, 37);
    StopTime st(String id, int min, {int? late}) => StopTime(
          stop: Location(id: id, providerId: 'x', name: id),
          arrival: EventTime(
              planned: t0.add(Duration(minutes: min)),
              estimated: late == null ? null : t0.add(Duration(minutes: min + late)),
              quality: late == null ? TimeQuality.planned : TimeQuality.realtime),
          departure: EventTime(
              planned: t0.add(Duration(minutes: min)),
              estimated: late == null ? null : t0.add(Duration(minutes: min + late)),
              quality: late == null ? TimeQuality.planned : TimeQuality.realtime),
        );
    Trip trip(List<StopTime> s) => Trip(id: 't', legs: [
          Leg(type: LegType.ride, from: s.first, to: s.last, intermediates: s.sublist(1, s.length - 1)),
        ]);
    final old = trip([st('de:1:1:1', 0, late: 3), st('de:1:2', 5, late: 3), st('de:1:3', 30, late: 2)]);
    final fresh = trip([st('de:1:1:2', 0), st('de:1:2', 5), st('de:1:3', 30)]);
    // Um 04:50: die ersten beiden Halte liegen zurück, der letzte nicht.
    final r = keepKnownRealtime(old, fresh, DateTime(2026, 9, 24, 4, 50)).legs.single;
    expect(r.from.departure!.delayMinutes, 3, reason: 'anderer Steig, gleiche Haltestelle');
    expect(r.intermediates.single.arrival!.delayMinutes, 3);
    expect(r.to.arrival!.hasRealtime, isFalse, reason: 'künftige Prognosen werden nicht festgehalten');
    // Neue Echtzeit hat Vorrang.
    final fresher = trip([st('de:1:1:1', 0, late: 4), st('de:1:2', 5), st('de:1:3', 30)]);
    expect(keepKnownRealtime(old, fresher, DateTime(2026, 9, 24, 4, 50)).legs.single.from.departure!.delayMinutes, 4);
  });

  test('Verkehrsunternehmen des Verbunds aus allen Meldungen', () {
    Map<String, dynamic> j(String f) => jsonDecode(File('test/fixtures/$f').readAsStringSync()) as Map<String, dynamic>;
    final a = parseOperators(j('efa_addinfo.json'));
    expect(a['sws'], 'Stadtwerke Solingen');
    expect(a['ves'], 'Vestische');
    expect(a['ddb'], 'Deutsche Bahn');
    // Auch Betriebe weit weg von hier (Remscheid, Rheinlandbus) sind suchbar.
    final w = parseOperators(j('efa_addinfo_wuppertal.json'));
    expect(w.keys, containsAll(['wsw', 'swr', 'bvr', 'sws']));
    expect(w['swr'], 'Stadtwerke Remscheid');
  });

  test('Verspätung in angezeigten Minuten', () {
    final p = DateTime(2026, 9, 24, 0, 40);
    EventTime e(int s) => EventTime(planned: p, estimated: p.add(Duration(seconds: s)), quality: TimeQuality.realtime);
    expect(e(50).delayMinutes, 0); // 00:40:50 – angezeigt 00:40, also pünktlich
    expect(e(70).delayMinutes, 1);
    expect(e(-30).delayMinutes, -1); // 00:39:30
  });

  test('Rückmeldung: Antwort von FormSubmit (als text/html geliefert)', () {
    expect(feedbackAccepted('{"success":"true","message":"The form was submitted successfully."}'), isTrue);
    expect(feedbackAccepted('{"success":"false","message":"This form needs Activation."}'), isFalse);
    expect(feedbackAccepted('<html>Fehler</html>'), isFalse);
  });

  test('Abo für ein Verkehrsunternehmen deckt alle seine Linien', () {
    const wsw = Subscription(lineId: 'netz:wsw', providerId: 'vrr', lineName: 'WSW');
    const line = Subscription(lineId: 'wsw:66604', providerId: 'vrr', lineName: '604');
    const m1 = Message(id: '1', title: 'Umleitung 611', lineIds: ['wsw:66611']);
    const m2 = Message(id: '2', title: 'S9 Bauarbeiten', lineIds: ['ddb:92S09']);
    expect(subscriptionCovers(wsw, m1), isTrue);
    expect(subscriptionCovers(wsw, m2), isFalse);
    expect(subscriptionCovers(line, m1), isFalse);
    expect(subscriptionCovers(line, const Message(id: '3', title: 'x', lineIds: ['wsw:66604'])), isTrue);
  });

  test('Countdown: Uhrzeit nicht doppelt', () {
    final now = DateTime(2026, 9, 24, 1, 48);
    expect(countdownWithTime(DateTime(2026, 9, 24, 2, 56), now), 'um 02:56');
    expect(countdownWithTime(DateTime(2026, 9, 24, 1, 53), now), 'in 5 min · 01:53');
  });

  group('Ersatzverkehr', () {
    Trip sev({List<Message> messages = const []}) => Trip(id: 's', messages: messages, legs: [
          Leg(
            type: LegType.ride,
            from: StopTime(stop: const Location(id: 'x', providerId: 't', name: 'Wuppertal Oberbarmen Bf'), departure: at(14, 0)),
            to: StopTime(stop: stop('B'), arrival: at(14, 20)),
            line: const Line(id: 'ddb:SEV', name: 'SEV S8', mode: TransportMode.replacementBus),
            messageIds: const ['m1'],
          ),
        ]);

    test('Satz zur Ersatzhaltestelle am Einstieg', () {
      final t = sev(messages: const [
        Message(id: 'm1', title: 'S8: Bauarbeiten', text: 'Zwischen Wuppertal und Hagen fahren Busse. '
            'Die Ersatzhaltestelle in Oberbarmen befindet sich in der Berliner Straße vor dem Bahnhof. Bitte Zeit einplanen.'),
      ]);
      expect(isReplacement(t.legs.first), isTrue);
      expect(sevStopHint(t, t.legs.first), 'Die Ersatzhaltestelle in Oberbarmen befindet sich in der Berliner Straße vor dem Bahnhof.');
    });

    test('ohne Angabe: null (ehrlicher Hinweis in der Ansicht)', () {
      expect(sevStopHint(sev(), sev().legs.first), isNull);
    });
  });

  group('Zu Fuß zum Ziel', () {
    const home = Location(id: 'addr', providerId: 't', name: 'Zuhause', type: LocationType.address, lat: 51.2600, lon: 7.1500);
    const exit = Location(id: 'B', providerId: 't', name: 'B', type: LocationType.stop, lat: 51.2600, lon: 7.1400);
    Trip trip() => Trip(id: 'z', legs: [
          Leg(
            type: LegType.ride,
            from: StopTime(stop: stop('A'), departure: at(14, 0)),
            to: StopTime(stop: exit, arrival: at(14, 10)),
            line: const Line(id: 'wsw:66640::H', name: '640', mode: TransportMode.bus),
          ),
          Leg(
            type: LegType.walk,
            from: StopTime(stop: exit, departure: at(14, 10)),
            to: StopTime(stop: home, arrival: at(14, 20)),
            durationMinutes: 10,
          ),
        ]);

    test('nach dem Ausstieg: zu Fuß zum Ziel, nach Uhrzeit', () {
      final s = nextStep(trip(), at(14, 15).planned);
      expect(s.phase, CompanionPhase.toDestination);
      expect(s.where.stop.name, 'Zuhause');
      expect(s.progress, closeTo(0.5, 0.01));
      expect(s.walking, isTrue);
      expect(nextStep(trip(), at(14, 22).planned).phase, CompanionPhase.arrived);
    });

    test('per GPS: angekommen erst an der Adresse, auch wenn es länger dauert', () {
      const halfway = (lat: 51.2600, lon: 7.1450);
      const door = (lat: 51.2601, lon: 7.1500);
      expect(nextStep(trip(), at(14, 25).planned, gps: halfway).phase, CompanionPhase.toDestination);
      expect(nextStep(trip(), at(14, 15).planned, gps: door).phase, CompanionPhase.arrived);
      expect(nextStep(trip(), at(14, 31).planned, gps: halfway).phase, CompanionPhase.arrived); // 10 min Nachlauf
    });
  });

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

    test('gesicherter Anschluss wartet, auch wenn die Zeit nicht reicht', () {
      expect(checkTransfers(trip(delay: 5), guaranteed: {1}).single.state, TransferState.guaranteed);
      expect(checkTransfers(trip(walk: 6), guaranteed: {2}).single.state, TransferState.guaranteed);
      expect(checkTransfers(trip(delay: 5), guaranteed: {0}).single.state, TransferState.missed);
    });

    test('Fahrtende: Verspätung der letzten Fahrt plus Fußweg zum Ziel', () {
      final t = Trip(id: 'z', legs: [
        ride('A', at(14, 0), 'B', at(14, 10, delay: 6)),
        Leg(
          type: LegType.walk,
          from: StopTime(stop: stop('B'), departure: at(14, 10)),
          to: StopTime(
              stop: const Location(id: 'coord', providerId: 't', name: 'Ziel', lat: 51.2, lon: 7.1),
              arrival: at(14, 18)),
          durationMinutes: 8,
        ),
      ]);
      // Plan sagt 14:18, tatsächlich 14:16 aus dem Bus + 8 min = 14:24.
      expect(tripEnd(t), at(14, 24).planned);
      expect(arrivedLongAgo(t, at(14, 21).planned), isFalse);
      expect(arrivedLongAgo(t, at(14, 27).planned), isTrue);
      expect(walkEnds(t, 1), isNull); // Ausstieg B ohne Koordinaten
    });

    test('Zieladresse ohne Koordinaten übernimmt die Lage aus der Suche', () {
      final t = Trip(id: 'z', legs: [
        ride('A', at(14, 0), 'B', at(14, 10)),
        Leg(
          type: LegType.walk,
          from: StopTime(stop: stop('B'), departure: at(14, 10)),
          to: StopTime(stop: const Location(id: 'streetID:1', providerId: 't', name: 'Ziel'), arrival: at(14, 18)),
          durationMinutes: 8,
        ),
      ]);
      const ziel = Location(id: 'streetID:1', providerId: 't', name: 'Ziel', lat: 51.25, lon: 7.15);
      final filled = withEndpoints(t, stop('A'), ziel);
      expect(filled.legs.last.to.stop.lat, 51.25);
      expect(filled.legs.first.from.stop.lat, isNull); // Fahrt beginnt an der Haltestelle
    });

    test('bevorstehender verpasster Umstieg; vorbei oder gesichert zählt nicht', () {
      final t = trip(delay: 5); // 0 min am selben Halt → nicht erreichbar
      expect(upcomingMissed(t, at(14, 5).planned)?.at.id, 'B');
      expect(upcomingMissed(t, at(14, 16).planned), isNull); // Anschluss schon weg
      expect(upcomingMissed(t, at(14, 5).planned, guaranteed: {1}), isNull);
      expect(upcomingMissed(trip(), at(14, 5).planned), isNull);
    });

    test('Alternativen: im Fahrzeug ab dem nächsten Halt, beim Umsteigen ab dem Halt, vorher ab Standort', () {
      final t = Trip(id: 'a', legs: [
        Leg(
          type: LegType.walk,
          from: StopTime(stop: const Location(id: 'home', providerId: 't', name: 'Start', type: LocationType.coordinate), departure: at(13, 50)),
          to: StopTime(stop: stop('A'), arrival: at(13, 58)),
          durationMinutes: 8,
        ),
        ride('A', at(14, 0), 'C', at(14, 20), via: [StopTime(stop: stop('B'), arrival: at(14, 10), departure: at(14, 10))]),
        ride('C', at(14, 25), 'D', at(14, 40)),
      ]);
      expect(alternativeStart(t, at(14, 5).planned)!.from.id, 'B'); // unterwegs, nächster Halt B
      expect(alternativeStart(t, at(14, 5).planned)!.time, at(14, 10).planned);
      expect(alternativeStart(t, at(14, 22).planned)!.from.id, 'C'); // Umstieg in C
      const gps = (lat: 51.25, lon: 7.15);
      final before = alternativeStart(t, at(13, 52).planned, gps: gps)!;
      expect(before.from.type, LocationType.coordinate); // vor dem Einsteigen: eigener Standort
      expect(before.from.lat, 51.25);
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

  test('Nach der Ankunft zählt nicht mehr das GPS am Anfang der Strecke', () {
    StopTime st(String id, double lon, EventTime t, {bool dep = true}) => StopTime(
        stop: Location(id: id, providerId: 't', name: id, lat: 51.25, lon: lon),
        departure: dep ? t : null,
        arrival: dep ? null : t);
    final leg = Leg(
      type: LegType.ride,
      from: st('A', 7.10, at(14, 0)),
      intermediates: [st('B', 7.11, at(14, 2))],
      to: st('C', 7.12, at(14, 4), dep: false),
    );
    final trip = Trip(id: 'x', legs: [leg]);
    // 2 min nach der Ankunft, GPS noch an A: angekommen, nicht wieder bei 0.
    final after = nextStep(trip, DateTime(2026, 9, 23, 14, 6), gps: (lat: 51.25, lon: 7.1));
    expect(after.phase, CompanionPhase.arrived);
    // Unterwegs, GPS weit hinter der Uhrzeit: Uhrzeit gilt.
    final behind = nextStep(trip, DateTime(2026, 9, 23, 14, 3, 30), gps: (lat: 51.25, lon: 7.1));
    expect(behind.byGps, isFalse);
    expect(behind.progress, greaterThan(0.8));
  });

  test('Meldungen: Nähe über Linien, fremde Betriebe fallen heraus', () {
    Message m(String id, List<String> lines, [List<String> regions = const ['5914000']]) =>
        Message(id: id, title: id, lineIds: lines, regions: regions);
    final st = MessagesState(const [], DateTime(2026), nearLines: const {'hst:50542', 'hst:50512'}, homeRegion: '5914000');
    expect(st.isNear(m('a', ['hst:50542'])), isTrue);
    expect(st.isRelevant(m('b', ['hst:50539'])), isTrue, reason: 'gleicher Betrieb');
    expect(st.isRelevant(m('c', ['mvg:10013'])), isFalse, reason: 'MVG in Iserlohn, unter Hagen geführt');
    expect(st.isRelevant(m('d', [])), isTrue, reason: 'allgemein, eigener Ort');
    expect(st.isRelevant(m('e', [], ['5913000'])), isFalse, reason: 'allgemein, Nachbarort');
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
