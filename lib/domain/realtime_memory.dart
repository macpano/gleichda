import 'models.dart';

/// Behält Ist-Zeiten, die schon bekannt waren.
///
/// Die VRR-Auskunft hält Echtzeit nur etwa eine Stunde nach dem Ereignis vor
/// (gemessen 17.09.2026); danach liefert sie dieselbe Fahrt nur noch mit
/// Planzeiten. Eine Aktualisierung würde die Ist-Zeiten vergangener Halte
/// sonst löschen – bei abgeschlossenen Fahrten sah man keine Echtzeit mehr.
///
/// Übernommen wird nur, was vor [now] lag und in der neuen Antwort ohne
/// Echtzeit steht. Halte werden über die Haltestelle (ohne Steig) und die
/// Planzeit gefunden.
Trip keepKnownRealtime(Trip old, Trip fresh, DateTime now) {
  if (old.legs.length != fresh.legs.length) return fresh;
  String key(StopTime s, EventTime? t) {
    final parts = s.stop.id.split(':');
    final area = parts.length > 3 ? parts.sublist(0, 3).join(':') : s.stop.id;
    return '$area|${t?.planned.toUtc().toIso8601String()}';
  }

  EventTime? keep(EventTime? fresh, EventTime? old) {
    if (fresh == null || old == null || fresh.hasRealtime || !old.hasRealtime) return fresh;
    if (old.planned != fresh.planned || !old.best.isBefore(now)) return fresh;
    return old;
  }

  Leg merge(Leg o, Leg f) {
    if (o.type != f.type) return f;
    final arr = <String, EventTime>{};
    final dep = <String, EventTime>{};
    for (final s in [o.from, ...o.intermediates, o.to]) {
      if (s.arrival != null) arr[key(s, s.arrival)] = s.arrival!;
      if (s.departure != null) dep[key(s, s.departure)] = s.departure!;
    }
    StopTime m(StopTime s) => s.copyWith(
          arrival: keep(s.arrival, arr[key(s, s.arrival)]),
          departure: keep(s.departure, dep[key(s, s.departure)]),
        );
    return f.copyWith(from: m(f.from), to: m(f.to), intermediates: [for (final s in f.intermediates) m(s)]);
  }

  return fresh.copyWith(legs: [for (var i = 0; i < fresh.legs.length; i++) merge(old.legs[i], fresh.legs[i])]);
}
