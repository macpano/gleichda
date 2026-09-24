import 'dart:math' as math;

import 'models.dart';

/// [toDestination]: nach dem letzten Ausstieg zu Fuß zur Zieladresse.
enum CompanionPhase { toStop, waiting, onBoard, transfer, toDestination, arrived }

/// Der nächste Schritt einer begleiteten Fahrt – genau das, was die
/// Unterwegs-Anzeige und die Benachrichtigung zeigen.
class CompanionStep {
  const CompanionStep({
    required this.phase,
    required this.where,
    this.when,
    this.leg,
    this.progress = 0,
    this.stopsLeft,
    this.nextStop,
    this.byGps = false,
    this.leaveAt,
  });

  final CompanionPhase phase;

  /// Wo: Einstiegs- bzw. Ausstiegshalt.
  final StopTime where;

  /// Wann: Abfahrt bzw. Ankunft (Echtzeit, wenn vorhanden).
  final EventTime? when;

  /// Der betroffene Fahrtabschnitt.
  final Leg? leg;

  /// Fortschritt bis zum Ausstieg (0–1).
  final double progress;

  /// Halte bis zum Ausstieg (einschließlich).
  final int? stopsLeft;

  /// Im Fahrzeug: der nächste Halt, der noch nicht erreicht ist.
  final StopTime? nextStop;

  /// Position aus GPS statt aus der Uhrzeit.
  final bool byGps;

  /// Vor dem ersten Fußweg: Zeit zum Losgehen (Abfahrt mit Echtzeit minus
  /// Gehzeit). Liegt sie noch vor uns, heißt der Schritt „Losgehen in …“.
  final DateTime? leaveAt;

  /// Jetzt noch vor dem Losgehen.
  bool beforeLeaving(DateTime now) => leaveAt != null && now.isBefore(leaveAt!);

  /// Nächster Halt, wenn er nicht schon der Ausstieg ist – „nächster Halt:
  /// Wuppertal Hbf“ neben „Aussteigen: Wuppertal Hbf“ wäre doppelt.
  StopTime? get nextBeforeExit => nextStop == null || identical(nextStop, where) ? null : nextStop;

  bool get boarding => phase == CompanionPhase.toStop || phase == CompanionPhase.waiting || phase == CompanionPhase.transfer;

  /// Zu Fuß unterwegs (zum Einstieg oder zum Ziel): Weg zum Ziel anbieten.
  bool get walking => boarding || phase == CompanionPhase.toDestination;
}

double _meters(GeoPoint a, GeoPoint b) {
  const r = 6371000.0;
  final dLat = (b.lat - a.lat) * math.pi / 180;
  final dLon = (b.lon - a.lon) * math.pi / 180;
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(a.lat * math.pi / 180) * math.cos(b.lat * math.pi / 180) * math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

/// So nah an der Zieladresse gilt man als angekommen.
const arrivedMeters = 40.0;

DateTime? _t(StopTime s, {bool arrival = false}) =>
    (arrival ? (s.arrival ?? s.departure) : (s.departure ?? s.arrival))?.best;

/// Lage einer GPS-Position auf einem Fahrtabschnitt: zuletzt passierter
/// Halt (Index in `[from, ...intermediates, to]`) und Fortschritt 0–1.
typedef LegFix = ({int passed, double progress, double meters});

/// Legt [pos] auf die Haltestellenfolge des Abschnitts (gerade Stücke von Halt
/// zu Halt). null, wenn Koordinaten fehlen oder die Position weiter als
/// [maxMeters] von der Strecke entfernt ist – dann gilt die Uhrzeit.
LegFix? locateOnLeg(Leg leg, GeoPoint pos, {double maxMeters = 250}) {
  final stops = [leg.from, ...leg.intermediates, leg.to];
  final pts = [for (final s in stops) s.stop.lat == null ? null : (lat: s.stop.lat!, lon: s.stop.lon!)];
  if (pts.any((p) => p == null) || pts.length < 2) return null;
  // Ebene Näherung um die Position (auf wenigen Kilometern genau genug).
  final k = math.cos(pos.lat * math.pi / 180);
  (double, double) xy(GeoPoint p) => ((p.lon - pos.lon) * 111320 * k, (p.lat - pos.lat) * 110540);
  final lens = <double>[];
  var best = double.infinity, bestSeg = 0, bestT = 0.0;
  for (var i = 0; i < pts.length - 1; i++) {
    final (ax, ay) = xy(pts[i]!);
    final (bx, by) = xy(pts[i + 1]!);
    final dx = bx - ax, dy = by - ay;
    final len2 = dx * dx + dy * dy;
    lens.add(math.sqrt(len2));
    final t = len2 == 0 ? 0.0 : ((-ax * dx - ay * dy) / len2).clamp(0.0, 1.0);
    final px = ax + t * dx, py = ay + t * dy;
    final d = math.sqrt(px * px + py * py);
    if (d < best) {
      best = d;
      bestSeg = i;
      bestT = t;
    }
  }
  if (best > maxMeters) return null;
  final total = lens.fold(0.0, (a, b) => a + b);
  final done = lens.take(bestSeg).fold(0.0, (a, b) => a + b) + lens[bestSeg] * bestT;
  // Zwischen Halt i und i + 1 ist Halt i passiert; weniger als 30 m vor
  // dem letzten Halt gilt auch der als erreicht.
  var passed = bestSeg;
  if (bestSeg == pts.length - 2 && (1 - bestT) * lens[bestSeg] < 30) passed = pts.length - 1;
  return (passed: passed, progress: total == 0 ? 0 : (done / total).clamp(0.0, 1.0), meters: best);
}

/// Fahrtabschnitte, bei denen man im selben Fahrzeug sitzen bleibt, als
/// eine Fahrt: Einstieg des ersten, Ausstieg des letzten, der Wendehalt als
/// Zwischenhalt, Richtung des letzten Abschnitts.
List<Leg> joinedRides(Trip trip) {
  final out = <Leg>[];
  var staySeated = false;
  for (final l in trip.legs) {
    if (l.type != LegType.ride) {
      staySeated = staySeated || l.staySeated;
      continue;
    }
    if (staySeated && out.isNotEmpty) {
      final a = out.removeLast();
      final turn = a.to.copyWith(departure: l.from.departure);
      out.add(a.copyWith(
        to: l.to,
        intermediates: [...a.intermediates, turn, ...l.intermediates],
        direction: l.direction ?? a.direction,
      ));
    } else {
      out.add(l);
    }
    staySeated = false;
  }
  return out;
}

CompanionStep nextStep(Trip trip, DateTime now, {GeoPoint? gps}) {
  final rides = joinedRides(trip);
  for (var i = 0; i < rides.length; i++) {
    final r = rides[i];
    final dep = _t(r.from);
    final arr = _t(r.to, arrival: true);
    var fix = gps == null ? null : locateOnLeg(r, gps);
    if (fix != null && fix.passed >= r.intermediates.length + 1) continue; // per GPS am Ziel vorbei
    // Ankunft (mit Echtzeit) über eine Minute vorbei: erledigt, egal wo das
    // GPS steht – sonst sprang der Balken nach dem Ausstieg auf Anfang zurück,
    // wenn man nicht (mehr) im Fahrzeug war.
    if (arr != null && now.isAfter(arr.add(const Duration(minutes: 1)))) continue;
    // Per GPS schon unterwegs (Bus früher oder Uhr ungenau): im Fahrzeug.
    final movingByGps = fix != null && fix.passed >= 1;
    if (dep != null && now.isBefore(dep) && !movingByGps) {
      // Vor der Abfahrt: hingehen bzw. warten; nach einer Fahrt: umsteigen.
      final phase = i > 0
          ? CompanionPhase.transfer
          : (trip.legs.first.type == LegType.ride ? CompanionPhase.waiting : CompanionPhase.toStop);
      final start = i > 0 ? _t(rides[i - 1].to, arrival: true) : trip.departure.best;
      var p = 0.0;
      if (start != null && dep.isAfter(start)) {
        p = (now.difference(start).inSeconds / dep.difference(start).inSeconds).clamp(0.0, 1.0);
      }
      // Erst zu Fuß zum Einstieg: wann losgehen.
      DateTime? leaveAt;
      if (phase == CompanionPhase.toStop) {
        final walk = trip.legs
            .take(trip.legs.indexWhere((l) => l.type == LegType.ride))
            .fold<int>(0, (m, l) => m + (l.durationMinutes ?? 0));
        leaveAt = walk > 0 ? dep.subtract(Duration(minutes: walk)) : trip.departure.best;
      }
      return CompanionStep(phase: phase, where: r.from, when: r.from.departure, leg: r, progress: p, leaveAt: leaveAt);
    }
    // Im Fahrzeug: mit GPS die Lage auf der Strecke, sonst nach Uhrzeit.
    final stops = [...r.intermediates, r.to];
    // Nach Uhrzeit (mit Echtzeit) …
    var left = stops.where((s) => (_t(s, arrival: true) ?? arr ?? now).isAfter(now)).length.clamp(1, stops.length);
    var p = 0.0;
    if (dep != null && arr != null && arr.isAfter(dep)) {
      p = (now.difference(dep).inSeconds / arr.difference(dep).inSeconds).clamp(0.0, 1.0);
    }
    // … und per GPS, wenn es dazu passt: vor der Uhrzeit (Bus früher) oder
    // höchstens ein Viertel dahinter. Liegt die Position weit zurück, ist man
    // vermutlich nicht in diesem Fahrzeug – dann gilt die Uhrzeit.
    if (fix != null && fix.progress < p - 0.25) fix = null;
    if (fix != null) {
      left = (stops.length - fix.passed).clamp(1, stops.length);
      p = fix.progress;
    }
    return CompanionStep(
      phase: CompanionPhase.onBoard,
      where: r.to,
      when: r.to.arrival ?? r.to.departure,
      leg: r,
      progress: p,
      stopsLeft: left,
      nextStop: stops[stops.length - left],
      byGps: fix != null,
    );
  }
  final last = trip.legs.last;
  final arrived = CompanionStep(phase: CompanionPhase.arrived, where: last.to, when: last.to.arrival, progress: 1);
  // Nach dem letzten Ausstieg (oder bei einem reinen Fußweg): zu Fuß zum
  // Ziel, bis man per GPS dort ist – ohne GPS bis zur berechneten Ankunft.
  if (last.type == LegType.ride) return arrived;
  final lastRide = rides.isEmpty ? null : rides.last;
  final start = lastRide == null ? trip.departure.best : _t(lastRide.to, arrival: true);
  if (start == null) return arrived;
  final walk = trip.legs
      .skip(trip.legs.lastIndexWhere((l) => l.type == LegType.ride) + 1)
      .fold<int>(0, (m, l) => m + (l.durationMinutes ?? 0));
  final end = start.add(Duration(minutes: walk));
  final dest = last.to.stop.lat == null ? null : (lat: last.to.stop.lat!, lon: last.to.stop.lon!);
  final from = lastRide?.to.stop ?? trip.legs.first.from.stop;
  final origin = from.lat == null ? null : (lat: from.lat!, lon: from.lon!);
  if (gps != null && dest != null) {
    final left = _meters(gps, dest);
    if (left <= arrivedMeters) return arrived;
    // Wer trödelt, wird noch 10 min begleitet.
    if (now.isAfter(end.add(const Duration(minutes: 10)))) return arrived;
    final total = origin == null ? null : _meters(origin, dest);
    final p = total == null || total <= 0 ? 0.0 : (1 - left / total).clamp(0.0, 1.0);
    return CompanionStep(
        phase: CompanionPhase.toDestination, where: last.to, when: EventTime(planned: end), progress: p, byGps: true);
  }
  if (walk == 0 || now.isAfter(end.add(const Duration(minutes: 1)))) return arrived;
  final span = end.difference(start).inSeconds;
  final p = span <= 0 ? 1.0 : (now.difference(start).inSeconds / span).clamp(0.0, 1.0);
  return CompanionStep(phase: CompanionPhase.toDestination, where: last.to, when: EventTime(planned: end), progress: p);
}

/// Von wo aus Alternativen gesucht werden: im Fahrzeug ab dem nächsten Halt
/// (Ankunftszeit dort), beim Umsteigen bzw. Warten ab der Haltestelle, an der
/// man steht, vor dem ersten Einstieg ab dem eigenen Standort (mit GPS),
/// sonst ab dem Einstieg. Null, wenn nur noch der Fußweg zum Ziel fehlt.
({Location from, DateTime time})? alternativeStart(Trip trip, DateTime now, {GeoPoint? gps}) {
  final step = nextStep(trip, now, gps: gps);
  switch (step.phase) {
    case CompanionPhase.onBoard:
      final next = step.nextStop ?? step.where;
      final at = (next.arrival ?? next.departure)?.best;
      return (from: next.stop, time: at != null && at.isAfter(now) ? at : now);
    case CompanionPhase.transfer:
    case CompanionPhase.waiting:
      return (from: step.where.stop, time: now);
    case CompanionPhase.toStop:
      if (gps != null) {
        return (
          from: Location(
              id: 'coord:${gps.lat}:${gps.lon}',
              providerId: 'gps',
              name: 'Mein Standort',
              lat: gps.lat,
              lon: gps.lon,
              type: LocationType.coordinate),
          time: now,
        );
      }
      return (from: step.where.stop, time: now);
    case CompanionPhase.toDestination:
    case CompanionPhase.arrived:
      return null;
  }
}
