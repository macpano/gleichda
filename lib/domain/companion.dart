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

  bool get boarding => phase == CompanionPhase.toStop || phase == CompanionPhase.waiting || phase == CompanionPhase.transfer;
}

DateTime? _t(StopTime s, {bool arrival = false}) =>
    (arrival ? (s.arrival ?? s.departure) : (s.departure ?? s.arrival))?.best;

CompanionStep nextStep(Trip trip, DateTime now) {
  final rides = trip.rides;
  for (var i = 0; i < rides.length; i++) {
    final r = rides[i];
    final dep = _t(r.from);
    final arr = _t(r.to, arrival: true);
    if (arr != null && !arr.isAfter(now)) continue; // Abschnitt vorbei
    if (dep != null && now.isBefore(dep)) {
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
    // Im Fahrzeug.
    final stops = [...r.intermediates, r.to];
    final left = stops.where((s) => (_t(s, arrival: true) ?? arr ?? now).isAfter(now)).length;
    var p = 0.0;
    if (dep != null && arr != null && arr.isAfter(dep)) {
      p = (now.difference(dep).inSeconds / arr.difference(dep).inSeconds).clamp(0.0, 1.0);
    }
    return CompanionStep(
      phase: CompanionPhase.onBoard,
      where: r.to,
      when: r.to.arrival ?? r.to.departure,
      leg: r,
      progress: p,
      stopsLeft: left,
    );
  }
  final last = trip.legs.last;
  return CompanionStep(phase: CompanionPhase.arrived, where: last.to, when: last.to.arrival, progress: 1);
}
