import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../trip_status.dart';
import '../widgets.dart';

/// Fahrtdetail der zuletzt geöffneten Fahrt, mit Fahrtverlauf nach
/// Öffi-Vorbild. Aktualisiert sich alle 30 s.
// TODO: Alternativen, Anschlussprüfung (Schritt 10), Losfahren (Schritt 14).
class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key});

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  final _expanded = <int>{};

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = ref.watch(lastTripProvider).value;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    if (s == null) {
      return Scaffold(
        body: Padding(
          padding: pagePadding(context),
          child: const Column(children: [SubpageHeader(title: 'Fahrt'), Notice('Keine Fahrt geöffnet.')]),
        ),
      );
    }
    final trip = s.trip;
    final issue = tripIssue(trip, lost: s.lost);
    final fav = ref.watch(_isFavorite((trip.origin, trip.destination))).value ?? false;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(lastTripProvider.notifier).refresh(),
        child: ListView(
          padding: pagePadding(context),
          children: [
            SubpageHeader(
              title: 'Fahrt',
              backLabel: 'Zurück',
              trailing: IconButton(
                tooltip: fav ? 'Favorit entfernen' : 'Als Favorit speichern',
                onPressed: () => ref.read(repositoryProvider).toggleFavoriteRoute(trip.origin, trip.destination),
                icon: Icon(fav ? Icons.star : Icons.star_border, color: fav ? c.accent : c.ink),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                OneLine(trip.origin.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3)),
                OneLine(trip.destination.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 2),
                Row(children: [
                  Expanded(
                    child: OneLine(
                      '${hm(trip.departure.best)} – ${hm(trip.arrival.best)} · ${durationText(trip.duration)} · ${interchangesText(trip.interchanges)}',
                      style: context.t.number(14).copyWith(color: c.muted),
                    ),
                  ),
                  FreshnessStamp(
                    updatedAt: s.updatedAt,
                    now: now,
                    refreshing: s.refreshing,
                    failed: s.failed,
                    realtime: s.hasRealtime,
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            if (issue != null) ...[_IssueBanner(issue), const SizedBox(height: 14)],
            Container(
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
              child: Column(children: _rows(context, trip)),
            ),
            if (trip.messages.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionTitle('Hinweise'),
              ListGroup(children: [
                for (final m in trip.messages)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(m.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      if (m.text != null && m.text != m.title) ...[
                        const SizedBox(height: 4),
                        Text(m.text!, style: context.t.secondary.copyWith(color: c.ink2, height: 1.4)),
                      ],
                    ]),
                  ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _rows(BuildContext context, Trip trip) {
    final c = context.c;
    final rows = <Widget>[];
    for (var i = 0; i < trip.legs.length; i++) {
      final l = trip.legs[i];
      if (l.type != LegType.ride) {
        final m = l.durationMinutes ??
            ((l.to.arrival?.best ?? l.to.departure?.best)
                    ?.difference((l.from.departure ?? l.from.arrival)!.best)
                    .inMinutes ??
                0);
        rows.add(_Row(
          height: 40,
          rail: _Rail(color: c.walkText.withValues(alpha: 0.5), dotted: true),
          child: OneLine(
            l.type == LegType.walk
                ? '$m min Fußweg${i == trip.legs.length - 1 ? ' zum Ziel' : ''}'
                : '$m min Umstieg',
            style: TextStyle(fontSize: 14, color: c.muted),
          ),
        ));
        continue;
      }
      // Umstieg am selben Halt ohne eigenen Fußweg-Abschnitt: Wartezeit zeigen.
      if (i > 0 && trip.legs[i - 1].type == LegType.ride) {
        final arr = trip.legs[i - 1].to.arrival?.best;
        final dep = l.from.departure?.best;
        final m = (arr != null && dep != null) ? dep.difference(arr).inMinutes : 0;
        rows.add(_Row(
          height: 40,
          rail: _Rail(color: c.walkText.withValues(alpha: 0.5), dotted: true),
          child: OneLine('$m min Umstieg', style: TextStyle(fontSize: 14, color: c.muted)),
        ));
      }
      final color = lineColor(context, l.line);
      final open = _expanded.contains(i);
      rows.add(_stopRow(context, l.from, color, departure: true, first: true));
      final dep = l.from.departure;
      final (tag, tagColor) = !(dep?.hasRealtime ?? false)
          ? ('nur Fahrplan', c.muted)
          : (dep!.delayMinutes ?? 0) > 0
              ? ('+${dep.delayMinutes} min', c.orange)
              : ('pünktlich', c.green);
      rows.add(InkWell(
        onTap: l.intermediates.isEmpty
            ? null
            : () => setState(() => open ? _expanded.remove(i) : _expanded.add(i)),
        child: _Row(
          height: 38,
          rail: _Rail(color: color),
          child: Row(children: [
            LineBadge(l.line),
            const SizedBox(width: 8),
            Expanded(
              child: OneLine(
                l.intermediates.isEmpty || open
                    ? 'Richtung ${l.direction ?? ''}'
                    : '${l.intermediates.length == 1 ? '1 Zwischenhalt' : '${l.intermediates.length} Zwischenhalte'} · Richtung ${l.direction ?? ''}',
                style: TextStyle(fontSize: 15, color: c.ink2),
              ),
            ),
            const SizedBox(width: 8),
            Text(tag, style: TextStyle(fontSize: 13, color: tagColor)),
          ]),
        ),
      ));
      final hidden = l.intermediates.where((s) => s.status != StopStatus.normal);
      for (final s in open ? l.intermediates : hidden) {
        rows.add(_stopRow(context, s, color));
      }
      rows.add(_stopRow(context, l.to, color, departure: false, last: true));
    }
    return rows;
  }

  Widget _stopRow(BuildContext context, StopTime s, Color color,
      {bool? departure, bool first = false, bool last = false}) {
    final c = context.c;
    final main = first || last;
    final t = (departure ?? true) ? (s.departure ?? s.arrival) : (s.arrival ?? s.departure);
    final cancelled = s.status == StopStatus.cancelled;
    final diverted = s.status == StopStatus.diversion;
    final tColor = timeColor(context, t, status: s.status, neutral: main ? c.ink : c.ink2);
    final delayed = (t?.delayMinutes ?? 0) > 0;
    return _Row(
      height: main ? 52 : 40,
      rail: _Rail(
        color: color,
        fromTop: !first,
        toBottom: !last,
        dot: main
            ? _Dot.big
            : cancelled
                ? _Dot.cancelled
                : diverted
                    ? _Dot.diverted
                    : _Dot.small,
        dotColor: cancelled ? c.red : diverted ? c.orange : color,
        fill: c.surface,
      ),
      time: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(t == null ? '' : hm(t.best),
            style: (main ? context.t.time(15) : context.t.number(15)).copyWith(
                color: cancelled ? c.muted : tColor,
                decoration: cancelled ? TextDecoration.lineThrough : null,
                height: 22 / 15)),
        if (main && delayed)
          Text(hm(t!.planned),
              style: context.t.number(12).copyWith(color: c.muted, decoration: TextDecoration.lineThrough)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Flexible(
            child: OneLine(s.stop.name,
                style: TextStyle(
                  fontSize: main ? 16 : 15,
                  fontWeight: main ? FontWeight.w600 : FontWeight.w400,
                  color: cancelled ? c.muted : c.ink,
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                  height: 22 / 16,
                )),
          ),
          if (cancelled || diverted) ...[
            const SizedBox(width: 8),
            Text(cancelled ? 'entfällt' : 'Umleitung',
                style: TextStyle(fontSize: 13, color: cancelled ? c.red : c.orange)),
          ],
        ]),
        if (main && s.platform != null)
          OneLine(
              s.plannedPlatform != null && s.platform != s.plannedPlatform
                  ? 'Steig ${s.platform} statt ${s.plannedPlatform}'
                  : 'Steig ${s.platform}',
              style: TextStyle(
                  fontSize: 13,
                  color: s.plannedPlatform != null && s.platform != s.plannedPlatform ? c.orange : c.muted)),
      ]),
    );
  }
}

final _isFavorite = StreamProvider.autoDispose.family<bool, (Location, Location)>(
    (ref, r) => ref.watch(repositoryProvider).watchIsFavoriteRoute(r.$1, r.$2));

class _IssueBanner extends StatelessWidget {
  const _IssueBanner(this.issue);

  final TripIssue issue;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final red = issue.level == IssueLevel.cancelled;
    final fg = red ? c.redText : c.orangeText;
    return Container(
      decoration: BoxDecoration(
        color: red ? c.redTint : c.orangeTint,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        OneLine(issue.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg)),
        if (issue.detail != null) ...[
          const SizedBox(height: 6),
          Text(issue.detail!, style: TextStyle(fontSize: 15, height: 1.4, color: fg)),
        ],
      ]),
    );
  }
}

enum _Dot { none, small, big, cancelled, diverted }

class _Rail {
  const _Rail({
    required this.color,
    this.dotted = false,
    this.fromTop = true,
    this.toBottom = true,
    this.dot = _Dot.none,
    this.dotColor,
    this.fill,
  });

  final Color color;
  final bool dotted;
  final bool fromTop;
  final bool toBottom;
  final _Dot dot;
  final Color? dotColor;
  final Color? fill;
}

/// Zeile im Fahrtverlauf: 52 px Zeit | 24 px Linie | Inhalt. Feste Höhe.
class _Row extends StatelessWidget {
  const _Row({required this.height, required this.rail, required this.child, this.time});

  final double height;
  final _Rail rail;
  final Widget child;
  final Widget? time;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 9, right: 8),
              child: Align(alignment: Alignment.topRight, child: time),
            ),
          ),
          SizedBox(width: 24, child: CustomPaint(painter: _RailPainter(rail))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 9),
              child: Align(alignment: Alignment.topLeft, child: child),
            ),
          ),
        ]),
      );
}

class _RailPainter extends CustomPainter {
  _RailPainter(this.r);

  final _Rail r;

  static const _x = 12.0;
  static const _dotY = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = r.color
      ..strokeWidth = r.dotted ? 3 : 4
      ..strokeCap = r.dotted ? StrokeCap.round : StrokeCap.butt;
    final top = r.fromTop ? 0.0 : _dotY;
    final bottom = r.toBottom ? size.height : _dotY;
    if (r.dotted) {
      for (var y = top + 3; y < bottom; y += 7) {
        canvas.drawLine(Offset(_x, y), Offset(_x, y + 0.1), line);
      }
    } else if (bottom > top) {
      canvas.drawLine(Offset(_x, top), Offset(_x, bottom), line);
    }
    final dc = r.dotColor ?? r.color;
    switch (r.dot) {
      case _Dot.none:
        break;
      case _Dot.small:
        canvas.drawCircle(const Offset(_x, _dotY), 5, Paint()..color = dc);
      case _Dot.big:
        canvas.drawCircle(const Offset(_x, _dotY), 7, Paint()..color = r.fill ?? Colors.white);
        canvas.drawCircle(
            const Offset(_x, _dotY),
            5.5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = dc);
      case _Dot.cancelled:
      case _Dot.diverted:
        canvas.drawCircle(const Offset(_x, _dotY), 6, Paint()..color = r.fill ?? Colors.white);
        canvas.drawCircle(
            const Offset(_x, _dotY),
            5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = dc);
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) => true;
}
