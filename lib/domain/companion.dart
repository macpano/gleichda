import 'dart:math' as math;

import 'models.dart';

enum CompanionPhase { toStop, waiting, onBoard, transfer, arrived }

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

  /// Nächster Halt, wenn er nicht schon der Ausstieg ist – „nächster Halt:
  /// Wuppertal Hbf“ neben „Aussteigen: Wuppertal Hbf“ wäre doppelt.
  StopTime? get nextBeforeExit => nextStop == null || identical(nextStop, where) ? null : nextStop;

  bool get boarding => phase == CompanionPhase.toStop || phase == CompanionPhase.waiting || phase == CompanionPhase.transfer;
}

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

CompanionStep nextStep(Trip trip, DateTime now, {GeoPoint? gps}) {
  final rides = trip.rides;
  for (var i = 0; i < rides.length; i++) {
    final r = rides[i];
    final dep = _t(r.from);
    final arr = _t(r.to, arrival: true);
    final fix = gps == null ? null : locateOnLeg(r, gps);
    if (fix != null && fix.passed >= r.intermediates.length + 1) continue; // per GPS am Ziel vorbei
    if (arr != null && !arr.isAfter(now) && fix == null) continue; // Abschnitt vorbei
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
      return CompanionStep(phase: phase, where: r.from, when: r.from.departure, leg: r, progress: p);
    }
    // Im Fahrzeug: mit GPS die Lage auf der Strecke, sonst nach Uhrzeit.
    final stops = [...r.intermediates, r.to];
    int left;
    var p = 0.0;
    if (fix != null) {
      left = (stops.length - fix.passed).clamp(1, stops.length);
      p = fix.progress;
    } else {
      left = stops.where((s) => (_t(s, arrival: true) ?? arr ?? now).isAfter(now)).length.clamp(1, stops.length);
      if (dep != null && arr != null && arr.isAfter(dep)) {
        p = (now.difference(dep).inSeconds / arr.difference(dep).inSeconds).clamp(0.0, 1.0);
      }
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
  return CompanionStep(phase: CompanionPhase.arrived, where: last.to, when: last.to.arrival, progress: 1);
}
