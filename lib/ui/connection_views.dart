// Darstellung von Verbindungen: Zeile mit Zeitleiste und Zeitraster.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/connections.dart';
import '../domain/models.dart';
import '../domain/settings.dart';
import 'format.dart';
import 'theme.dart';
import 'trip_status.dart';
import 'widgets.dart';

/// Eine Verbindung mit ihren Besonderheiten für die Anzeige.
class ConnectionItem {
  const ConnectionItem(this.trip,
      {this.labels = const [], this.reachable = true, this.tight = false, this.guaranteed = false});

  final Trip trip;

  /// Etiketten wie „schnellste“, „ohne Umstieg“.
  final List<String> labels;
  final bool reachable;

  /// Mindestens ein Umstieg ist knapp.
  final bool tight;

  /// Mindestens ein Anschluss wartet (gesicherter Anschluss).
  final bool guaranteed;
}

/// Bewertet und sortiert Verbindungen: nicht erreichbare ans Ende,
/// Etiketten für die schnellste und die mit den wenigsten Umstiegen.
List<ConnectionItem> rateConnections(List<Trip> trips,
    {required int transferMinutes, bool labels = true, Map<String, Set<int>> guaranteed = const {}}) {
  if (trips.isEmpty) return const [];
  final checks = {
    for (final t in trips)
      t: checkTransfers(t, transferMinutes: transferMinutes, guaranteed: guaranteed[t.id] ?? const {}),
  };
  final reachable = trips.where((t) => !checks[t]!.any((c) => c.state == TransferState.missed)).toList();
  final minChanges = reachable.isEmpty ? 0 : reachable.map((t) => t.interchanges).reduce(math.min);
  final fewest = reachable.where((t) => t.interchanges == minChanges).toList();
  final out = <ConnectionItem>[];
  for (final t in trips) {
    final c = checks[t]!;
    final ok = !c.any((x) => x.state == TransferState.missed);
    out.add(ConnectionItem(
      t,
      reachable: ok,
      tight: c.any((x) => x.state == TransferState.tight),
      guaranteed: c.any((x) => x.state == TransferState.guaranteed),
      labels: !labels || !ok
          ? const []
          : [
              if (t.interchanges > 0 &&
                  fewest.length < reachable.length &&
                  fewest.contains(t) &&
                  identical(t, fewest.first))
                'wenigste Umstiege',
            ],
    ));
  }
  out.sort((a, b) {
    if (a.reachable != b.reachable) return a.reachable ? -1 : 1;
    return a.trip.departure.best.compareTo(b.trip.departure.best);
  });
  return out;
}

/// Sortiert bewertete Verbindungen: erreichbare zuerst, dann nach [sort],
/// bei Gleichstand nach Abfahrt.
List<ConnectionItem> sortConnections(List<ConnectionItem> items, ConnectionSort sort) {
  num key(Trip t) => switch (sort) {
        ConnectionSort.arrival => t.arrival.best.millisecondsSinceEpoch ~/ 60000,
        ConnectionSort.departure => 0,
        ConnectionSort.fastest => t.duration.inMinutes,
        ConnectionSort.fewChanges => t.interchanges,
        ConnectionSort.lessWalking => walkMinutes(t),
      };
  return [...items]
    ..sort((a, b) {
      if (a.reachable != b.reachable) return a.reachable ? -1 : 1;
      final k = key(a.trip).compareTo(key(b.trip));
      return k != 0 ? k : a.trip.departure.best.compareTo(b.trip.departure.best);
    });
}

/// Zeile der Verbindungsliste.
class ConnectionRow extends StatelessWidget {
  const ConnectionRow({super.key, required this.item, required this.onTap, this.stale = false, this.compareTo});

  final ConnectionItem item;
  final VoidCallback onTap;
  final bool stale;

  /// Für Alternativen: Ankunft der ursprünglichen Verbindung, zeigt „+12 min“.
  final DateTime? compareTo;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final trip = item.trip;
    final first = trip.rides.isEmpty ? null : trip.rides.first.from.departure;
    // Von–bis wie die Dauer: vom Losgehen bis zum Ankommen, Fußwege inklusive.
    final start = trip.departure;
    final issue = tripIssue(trip);
    final rt = trip.rides.any((r) => r.from.departure?.hasRealtime ?? false);
    final late = first?.delayMinutes ?? 0;
    final (String note, Color noteColor) = !item.reachable
        ? ('Anschluss nicht erreichbar', c.red)
        : issue != null
            ? (issue.title, issue.color(context))
            : item.tight
                ? ('Anschluss knapp', c.orange)
                : !rt
                    ? ('nur Fahrplan', c.muted)
                    : late > 0
                        ? ('+$late min', c.orange)
                        : ('pünktlich', c.green);
    final diff = compareTo == null ? null : trip.arrival.best.difference(compareTo!).inMinutes;
    final meta = [
      interchangesText(trip.interchanges),
      if (walkMinutes(trip) > 0) '${walkMinutes(trip)} min zu Fuß',
      if (item.guaranteed) 'Anschluss wartet',
      ...item.labels,
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: !item.reachable || issue?.level == IssueLevel.cancelled ? 0.55 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Abfahrt und Ankunft als Paar; die Verspätung steht rechts unten
            // („+3 min“), die Abfahrt trägt nur die Farbe. So bleibt keine
            // Lücke für eine Verspätung, die meist gar nicht da ist.
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              FadeText(hm(start.best),
                  style: context.t.time(18).copyWith(color: timeColor(context, first, neutral: c.ink))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('–', style: context.t.number(18).copyWith(color: c.muted)),
              ),
              FadeText(hm(trip.arrival.best), style: context.t.time(18).copyWith(color: c.ink)),
              const Spacer(),
              if (diff != null)
                Text(diff <= 0 ? '${diff == 0 ? '±0' : diff} min' : '+$diff min',
                    style: context.t.time(15).copyWith(color: diff <= 0 ? c.green : c.orange))
              else
                Text(durationText(trip.duration), style: context.t.number(15).copyWith(color: c.muted)),
            ]),
            const SizedBox(height: 9),
            TripTimeline(trip: trip),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: OneLine(meta, style: TextStyle(fontSize: 13, color: c.muted))),
              const SizedBox(width: 12),
              Text(stale ? 'wird aktualisiert' : note,
                  style: TextStyle(fontSize: 13, color: stale ? c.muted : noteColor)),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Fußwege einer Verbindung zusammen, in Minuten (Start, Umstiege, Ziel).
int walkMinutes(Trip trip) => trip.legs
    .where((l) => l.type != LegType.ride && !l.staySeated)
    .fold(0, (sum, l) => sum + (l.durationMinutes ?? 0));

/// Balken je Abschnitt, Länge proportional zur Dauer. Jede Linie bekommt
/// mindestens die Breite ihrer Nummer, Fußwege Platz für Gehsymbol und
/// Minuten; den Rest teilen sich die Abschnitte nach Dauer.
class TripTimeline extends StatelessWidget {
  const TripTimeline({super.key, required this.trip, this.height = 24});

  final Trip trip;
  final double height;

  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final badgeStyle = context.t.lineNumber.copyWith(fontSize: 13);
    final walkStyle = context.t.number(12).copyWith(color: c.walkText, fontWeight: FontWeight.w600);
    final scale = MediaQuery.textScalerOf(context);
    double textWidth(String t, TextStyle st) =>
        (TextPainter(text: TextSpan(text: t, style: st), textDirection: TextDirection.ltr, textScaler: scale)
              ..layout())
            .width;

    final segs = <({Leg leg, int minutes, double min})>[];
    for (final l in trip.legs) {
      final start = (l.from.departure ?? l.from.arrival)?.best;
      final end = (l.to.arrival ?? l.to.departure)?.best;
      var minutes = (start != null && end != null) ? end.difference(start).inMinutes : 0;
      if (minutes <= 0) minutes = l.durationMinutes ?? 1;
      final ride = l.type == LegType.ride;
      if (!ride && minutes < 1) continue;
      // Im selben Fahrzeug weiter: kein Fußweg, die Wartezeit zählt zur Fahrt davor.
      if (l.staySeated) continue;
      final min = ride
          ? textWidth(l.line?.name ?? '', badgeStyle) + 12
          : textWidth('$minutes′', walkStyle) + 22;
      segs.add((leg: l, minutes: minutes, min: min));
    }
    if (segs.isEmpty) return SizedBox(height: height);

    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (context, box) {
        final widths = _fit(
          [for (final s in segs) s.min],
          [for (final s in segs) s.minutes.toDouble()],
          box.maxWidth - _gap * (segs.length - 1),
        );
        return Row(children: [
          for (var i = 0; i < segs.length; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            SizedBox(width: widths[i], child: _segment(context, segs[i].leg, segs[i].minutes, widths[i], badgeStyle, walkStyle)),
          ],
        ]);
      }),
    );
  }

  Widget _segment(BuildContext context, Leg l, int minutes, double width, TextStyle badge, TextStyle walk) {
    final c = context.c;
    final ride = l.type == LegType.ride;
    Widget? child;
    if (ride) {
      child = Text(l.line?.name ?? '', maxLines: 1, overflow: TextOverflow.clip, softWrap: false, style: badge);
    } else if (width >= 34) {
      child = Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.directions_walk, size: 14, color: c.walkText),
        Text('$minutes′', maxLines: 1, softWrap: false, style: walk),
      ]);
    } else if (width >= 20) {
      child = Text('$minutes′', maxLines: 1, softWrap: false, style: walk);
    }
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ride ? lineColor(context, l.line) : c.walk,
        borderRadius: BorderRadius.circular(5),
      ),
      child: child,
    );
  }

  /// Breiten nach Dauer, aber nie unter dem Mindestmaß. Reicht der Platz
  /// nicht einmal für alle Mindestmaße, werden diese gleichmäßig gestaucht.
  static List<double> _fit(List<double> min, List<double> weight, double total) {
    final sumMin = min.fold(0.0, (a, b) => a + b);
    if (sumMin >= total) return [for (final m in min) m * total / sumMin];
    final fixed = List<bool>.filled(min.length, false);
    while (true) {
      var rest = total;
      var free = 0.0;
      for (var i = 0; i < min.length; i++) {
        if (fixed[i]) {
          rest -= min[i];
        } else {
          free += weight[i];
        }
      }
      final k = free == 0 ? 0.0 : rest / free;
      var changed = false;
      for (var i = 0; i < min.length; i++) {
        if (!fixed[i] && weight[i] * k < min[i]) {
          fixed[i] = true;
          changed = true;
        }
      }
      if (!changed) return [for (var i = 0; i < min.length; i++) fixed[i] ? min[i] : weight[i] * k];
    }
  }
}

/// Zeitraster wie in Öffi: Zeit von oben nach unten, je Verbindung eine
/// Spalte, Fahrten als Balken, Fußwege und Umstiege gepunktet.
///
/// Passt sich der Bildschirmhöhe an: Das Raster misst, wo es beginnt, und
/// verteilt die Zeitspanne auf den Platz bis zum unteren Rand (abzüglich
/// [reserveBelow] für das, was darunter steht) – senkrecht scrollen muss man
/// nur bei sehr langen Zeitspannen.
class ConnectionGrid extends StatefulWidget {
  const ConnectionGrid({super.key, required this.items, required this.onTap, this.reserveBelow = 110});

  final List<ConnectionItem> items;
  final ValueChanged<ConnectionItem> onTap;

  /// Platz unter dem Raster (Hinweis, „Früher | Später“, Rand).
  final double reserveBelow;

  static const colWidth = 58.0;

  /// Kopf jeder Spalte (Abfahrt, Dauer) – fest, damit die Zeitachse links
  /// immer auf Höhe der Balken steht.
  static const headHeight = 40.0;

  @override
  State<ConnectionGrid> createState() => _ConnectionGridState();
}

class _ConnectionGridState extends State<ConnectionGrid> {
  /// Oberkante des Rasters im Inhalt der Seite (ohne Scrollversatz).
  double? _top;

  void _measure() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final scrolled = Scrollable.maybeOf(context)?.position.pixels ?? 0;
    final top = box.localToGlobal(Offset.zero).dy + scrolled;
    if (_top == null || (top - _top!).abs() > 1) setState(() => _top = top);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final c = context.c;
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    DateTime startOf(Trip t) => (t.legs.first.from.departure ?? t.legs.first.from.arrival)!.best;
    final t0 = items.map((i) => startOf(i.trip)).reduce((a, b) => a.isBefore(b) ? a : b).toLocal();
    final t1 = items.map((i) => i.trip.arrival.best).reduce((a, b) => a.isAfter(b) ? a : b);
    // Skala in Ortszeit, auf 5 Minuten abgerundet.
    final base = DateTime(t0.year, t0.month, t0.day, t0.hour, t0.minute - t0.minute % 5);
    final minutes = t1.difference(base).inMinutes + 5;

    // Verfügbare Höhe: Bildschirm minus Beginn des Rasters, Kopf, Innenrand
    // und was darunter steht. Vor der ersten Messung eine Schätzung.
    final mq = MediaQuery.of(context);
    final top = _top ?? mq.size.height * 0.4;
    final avail = mq.size.height - top - mq.padding.bottom - widget.reserveBelow - ConnectionGrid.headHeight - 6 - 20;
    // Kurze Zeitspannen dürfen groß werden (vorher höchstens 6 px je Minute –
    // bei 35 min blieb der halbe Bildschirm leer und 3-min-Fahrten waren zu
    // klein für die Liniennummer).
    final perMinute = (avail / minutes).clamp(1.2, 16.0);
    final height = minutes * perMinute;
    double y(DateTime t) => t.difference(base).inSeconds / 60 * perMinute;

    // Beschriftung der Zeitachse ausdünnen, damit sie nicht übereinanderliegt.
    final step = [5, 10, 15, 30, 60].firstWhere((m) => m * perMinute >= 20, orElse: () => 60);
    final ticks = <Widget>[];
    for (var m = 0; m <= minutes; m += 5) {
      final t = base.add(Duration(minutes: m));
      if ((t.hour * 60 + t.minute) % step != 0) continue;
      ticks.add(Positioned(
        top: m * perMinute - 7,
        right: 6,
        child: Text(hm(t), textScaler: TextScaler.noScaling, style: context.t.number(11).copyWith(color: c.muted)),
      ));
    }

    Widget column(ConnectionItem item) {
      final trip = item.trip;
      final dep = trip.rides.isEmpty ? trip.departure : trip.rides.first.from.departure!;
      // Punkte (Fußwege, Warten) unten, Fahrten darüber – ein auf Mindesthöhe
      // gestreckter Balken verdeckt so die Punkte, nicht umgekehrt.
      final segs = <Widget>[];
      final dots = <Widget>[];
      for (final l in trip.legs) {
        final s = (l.from.departure ?? l.from.arrival)?.best;
        final e = (l.to.arrival ?? l.to.departure)?.best ??
            s?.add(Duration(minutes: l.durationMinutes ?? 0));
        if (s == null || e == null) continue;
        final top = y(s);
        // Fahrten mindestens so hoch, dass die Liniennummer hineinpasst.
        final h = math.max(y(e) - top, l.type == LegType.ride ? 18.0 : 6.0);
        if (l.type == LegType.ride) {
          segs.add(Positioned(
            top: top,
            left: 4,
            right: 4,
            height: h,
            child: Container(
              // Liniennummer mittig im Balken (Nutzerwunsch 24.09.2026).
              padding: const EdgeInsets.symmetric(horizontal: 2),
              alignment: Alignment.center,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: lineColor(context, l.line),
                borderRadius: BorderRadius.circular(6),
              ),
              // Liniennummer immer; in knappen Balken etwas kleiner.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(l.line?.name ?? '',
                    maxLines: 1,
                    textScaler: TextScaler.noScaling,
                    style: context.t.lineNumber.copyWith(fontSize: h < 24 ? 11 : 12)),
              ),
            ),
          ));
        } else {
          dots.add(Positioned(
            top: top,
            left: ConnectionGrid.colWidth / 2 - 1.5,
            width: 3,
            height: h,
            child: CustomPaint(painter: _DottedLine(c.muted)),
          ));
        }
      }
      // Wartezeiten zwischen Fahrten ohne eigenen Fußweg ebenfalls gepunktet.
      final rides = trip.rides;
      for (var i = 0; i + 1 < rides.length; i++) {
        final a = rides[i].to.arrival?.best, b = rides[i + 1].from.departure?.best;
        if (a == null || b == null || !b.isAfter(a)) continue;
        dots.add(Positioned(
          top: y(a),
          left: ConnectionGrid.colWidth / 2 - 1.5,
          width: 3,
          height: y(b) - y(a),
          child: CustomPaint(painter: _DottedLine(c.muted)),
        ));
      }
      return Opacity(
        opacity: item.reachable ? 1 : 0.45,
        child: InkWell(
          onTap: () => widget.onTap(item),
          child: SizedBox(
            width: ConnectionGrid.colWidth,
            child: Column(children: [
              // Fester Kopf, einzeilig: „1 Std 18 min“ wird kleiner statt umzubrechen.
              SizedBox(
                height: ConnectionGrid.headHeight,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(hm(dep.best),
                      maxLines: 1,
                      textScaler: TextScaler.noScaling,
                      style: context.t.time(14).copyWith(color: timeColor(context, dep, neutral: c.ink))),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(durationText(trip.duration),
                        maxLines: 1,
                        textScaler: TextScaler.noScaling,
                        style: context.t.number(11).copyWith(color: c.muted)),
                  ),
                ]),
              ),
              const SizedBox(height: 6),
              SizedBox(height: height, child: Stack(children: [...dots, ...segs])),
            ]),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
      padding: const EdgeInsets.fromLTRB(4, 10, 10, 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 44,
          child: Padding(
            padding: const EdgeInsets.only(top: ConnectionGrid.headHeight + 6),
            child: SizedBox(
              height: height,
              child: Stack(clipBehavior: Clip.none, children: ticks),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final i in items) column(i),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _DottedLine extends CustomPainter {
  _DottedLine(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var y = 2.0; y < size.height; y += 6) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + 0.1), p);
    }
  }

  @override
  bool shouldRepaint(_DottedLine old) => old.color != color;
}
