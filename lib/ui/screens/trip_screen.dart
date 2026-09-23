import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart' show pushOnce;
import '../../domain/companion.dart';
import '../../domain/connections.dart';
import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../../state/companion.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../trip_map.dart';
import '../trip_status.dart';
import '../widgets.dart';
import 'alternatives_screen.dart';
import 'walk_screen.dart';

/// Fahrtdetail der zuletzt geöffneten Fahrt, mit Fahrtverlauf nach
/// Öffi-Vorbild. Aktualisiert sich alle 30 s.
class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key});

  /// Wie viele Fahrtansichten gerade im Stapel liegen (die Unterwegs-Leiste
  /// öffnet dann keine weitere).
  static int open = 0;

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  @override
  void initState() {
    super.initState();
    TripScreen.open++;
  }

  @override
  void dispose() {
    TripScreen.open--;
    super.dispose();
  }

  final _expanded = <int>{};
  final _openMessages = <String>{};

  /// Fahrt, deren Zwischenhalte schon von selbst aufgeklappt wurden.
  String? _autoOpened;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = ref.watch(lastTripProvider).value;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
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
    final guaranteed = ref.watch(guaranteedProvider(TripPathKey(trip))).value ?? const <int>{};
    final checks =
        checkTransfers(trip, transferMinutes: settings.transferPace.transferMinutes, guaranteed: guaranteed);
    final missed = checks.where((x) => x.state == TransferState.missed).toList();
    final fav = ref.watch(_isFavorite((trip.origin, trip.destination))).value ?? false;
    final companion = ref.watch(companionProvider);
    final arrived = trip.arrival.best.isBefore(now);
    final following = companion.active && companion.tripId == trip.id;
    // Über den Abfahrtsmonitor geöffnet: Verlauf eines Fahrzeugs, keine
    // Reise von A nach B – Zwischenhalte gleich aufgeklappt.
    final vehicleView = trip.id.startsWith('abfahrt:') && trip.rides.length == 1;
    if (vehicleView && _autoOpened != trip.id) {
      _autoOpened = trip.id;
      _expanded.add(trip.legs.indexWhere((l) => l.type == LegType.ride));
    }
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(lastTripProvider.notifier).refresh(),
        child: ListView(
          padding: pagePadding(context),
          children: [
            SubpageHeader(
              title: vehicleView ? 'Fahrtverlauf' : 'Fahrt',
              backLabel: 'Zurück',
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  tooltip: 'Karte',
                  onPressed: () => pushOnce(Navigator.of(context), 'karte', (_) => const TripMapScreen()),
                  icon: Icon(Icons.map_outlined, color: c.ink),
                ),
                IconButton(
                  tooltip: fav ? 'Favorit entfernen' : 'Als Favorit speichern',
                  onPressed: () => ref.read(repositoryProvider).toggleFavoriteRoute(trip.origin, trip.destination),
                  icon: Icon(fav ? Icons.star : Icons.star_border, color: fav ? c.accent : c.ink),
                ),
              ]),
            ),
            // Über eine Abfahrt geöffnet: Linie und Ziel stehen oben.
            if (vehicleView)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Row(children: [
                  LineBadge(trip.rides.first.line),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OneLine('Richtung ${trip.rides.first.direction ?? trip.destination.label}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            if (!vehicleView) RouteSummary(from: trip.origin.label, to: trip.destination.label),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(children: [
                Expanded(
                  child: OneLine(
                    vehicleView
                        ? 'ab ${trip.origin.label} ${hm(trip.departure.best)} · an ${hm(trip.arrival.best)}'
                        : [
                            '${hm(trip.departure.best)} – ${hm(trip.arrival.best)}',
                            durationText(trip.duration),
                            interchangesText(trip.interchanges),
                          ].join(' · '),
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
            ),
            const SizedBox(height: 14),
            if (issue != null) ...[
              IssueBanner(issue, onAlternatives: () => openAlternatives(context, trip)),
              const SizedBox(height: 14),
            ] else if (missed.isNotEmpty) ...[
              IssueBanner(
                TripIssue(IssueLevel.cancelled, 'Anschluss in ${missed.first.at.name} nicht erreichbar',
                    'Mit der aktuellen Verspätung reicht die Zeit zum Umsteigen nicht.'),
                onAlternatives: () => openAlternatives(context, trip),
              ),
              const SizedBox(height: 14),
            ],
            Container(
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
              child: Column(children: _rows(context, trip, checks, now, following: following, gps: companion.freshGps(now))),
            ),
            if (trip.messages.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionTitle('Hinweise'),
              // Eingeklappt: nur die Überschriften; ein Tipp zeigt den Text.
              ListGroup(children: [
                for (final m in trip.messages)
                  InkWell(
                    onTap: m.text == null || m.text == m.title
                        ? null
                        : () => setState(() => _openMessages.contains(m.id)
                            ? _openMessages.remove(m.id)
                            : _openMessages.add(m.id)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Text(m.title,
                                maxLines: _openMessages.contains(m.id) ? null : 2,
                                overflow: _openMessages.contains(m.id) ? null : TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                          if (m.text != null && m.text != m.title)
                            Icon(_openMessages.contains(m.id) ? Icons.expand_less : Icons.expand_more,
                                size: 20, color: c.muted),
                        ]),
                        if (_openMessages.contains(m.id) && m.text != null && m.text != m.title) ...[
                          const SizedBox(height: 4),
                          Text(m.text!, style: context.t.secondary.copyWith(color: c.ink2, height: 1.4)),
                        ],
                      ]),
                    ),
                  ),
              ]),
            ],
          ],
        ),
      ),
      // Bei laufender Begleitung steht die Unterwegs-Leiste app-weit unten
      // (GlobalCompanionBar in app.dart).
      bottomNavigationBar: following
          ? null
          : arrived
              ? null
              : Container(
                  decoration: BoxDecoration(color: c.bar, border: Border(top: BorderSide(color: c.hair, width: 0.5))),
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
                  child: SizedBox(
                    height: 46,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: c.onAccent,
                        shape: buttonShape(context),
                      ),
                      // Startet die Begleitung in der Benachrichtigung; die
                      // Fahrt bleibt offen, unten steht dann der nächste Schritt.
                      onPressed: () => ref.read(companionProvider.notifier).start(),
                      child: const Text('Losfahren', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
    );
  }

  List<Widget> _rows(BuildContext context, Trip trip, List<TransferCheck> checks, DateTime now,
      {required bool following, GeoPoint? gps}) {
    final c = context.c;
    final walkColor = c.walkText.withValues(alpha: 0.5);
    final rows = <Widget>[];
    var transfer = 0;

    Widget walkRow(String text,
        {TransferCheck? check, Location? target, String? platform, EventTime? departure, Location? origin}) {
      final (String state, Color color) = switch (check?.state) {
        TransferState.safe => ('Anschluss sicher', c.green),
        TransferState.tight => ('Anschluss knapp', c.orange),
        TransferState.missed => ('Anschluss nicht erreichbar', c.red),
        TransferState.staySeated => ('', c.muted),
        TransferState.guaranteed => ('Anschluss wartet', c.green),
        null => ('', c.muted),
      };
      return _Row(
        height: 40,
        rail: _Rail(color: walkColor, dotted: true),
        child: Row(children: [
          Expanded(
            child: OneLine(state.isEmpty ? text : '$text · $state',
                style: TextStyle(fontSize: 14, color: state.isEmpty ? c.muted : color)),
          ),
          // Weg zum Steig – dasselbe Symbol wie in der Unterwegs-Leiste.
          if (target != null)
            InkResponse(
              radius: 20,
              onTap: () => pushOnce(Navigator.of(context), 'weg:${target.id}',
                  (_) => WalkScreen(target: target, platform: platform, departure: departure, origin: origin)),
              child: Tooltip(
                message: target.type != LocationType.stop
                    ? 'Weg zum Ziel'
                    : platform == null
                        ? 'Weg zur Haltestelle'
                        : 'Weg zu Steig $platform',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.directions_walk, size: 20, color: c.accent),
                ),
              ),
            ),
        ]),
      );
    }

    for (var i = 0; i < trip.legs.length; i++) {
      final l = trip.legs[i];
      if (l.type != LegType.ride) {
        final m = l.durationMinutes ??
            ((l.to.arrival?.best ?? l.to.departure?.best)
                    ?.difference((l.from.departure ?? l.from.arrival)!.best)
                    .inMinutes ??
                0);
        final isFirst = i == 0;
        final isLast = i == trip.legs.length - 1;
        if (isFirst) {
          final next = i + 1 < trip.legs.length ? trip.legs[i + 1].from : null;
          rows.add(walkRow('$m min Fußweg', target: next?.stop, platform: next?.platform, departure: next?.departure));
        } else if (isLast) {
          // Vom Ausstieg zur Zieladresse: auch dieser Weg mit Karte.
          final exit = trip.legs.take(i).where((x) => x.type == LegType.ride).lastOrNull?.to;
          rows.add(walkRow('$m min Fußweg zum Ziel',
              target: l.to.stop.lat == null ? null : l.to.stop, origin: exit?.stop));
        } else if (l.staySeated) {
          // Im selben Fahrzeug weiter: Linie durchgezogen, kein Umstieg.
          final prev = trip.legs.take(i).lastWhere((x) => x.type == LegType.ride, orElse: () => l);
          rows.add(_Row(
            height: 40,
            rail: _Rail(color: lineColor(context, prev.line)),
            child: Row(children: [
              Icon(Icons.airline_seat_recline_normal, size: 16, color: c.ink2),
              const SizedBox(width: 6),
              Expanded(
                child: OneLine('Weiterfahrt im selben Fahrzeug',
                    style: TextStyle(fontSize: 14, color: c.ink2)),
              ),
            ]),
          ));
          transfer++;
        } else {
          // Umstieg: Weg zum Steig des Anschlusses.
          final next = trip.legs.skip(i + 1).where((x) => x.type == LegType.ride).firstOrNull?.from;
          final arrived = trip.legs.take(i).where((x) => x.type == LegType.ride).lastOrNull?.to;
          rows.add(walkRow(l.type == LegType.walk ? '$m min Fußweg' : '$m min Umstieg',
              check: transfer < checks.length ? checks[transfer] : null,
              target: next?.stop,
              platform: next?.platform,
              departure: next?.departure,
              origin: arrived?.stop));
          transfer++;
        }
        continue;
      }
      if (i > 0 && trip.legs[i - 1].type == LegType.ride) {
        final arr = trip.legs[i - 1].to.arrival?.best;
        final dep = l.from.departure?.best;
        final m = (arr != null && dep != null) ? dep.difference(arr).inMinutes : 0;
        rows.add(walkRow('$m min Umstieg',
            check: transfer < checks.length ? checks[transfer] : null,
            target: l.from.stop,
            platform: l.from.platform,
            departure: l.from.departure,
            origin: trip.legs[i - 1].to.stop));
        transfer++;
      }
      final color = lineColor(context, l.line);
      final open = _expanded.contains(i);
      rows.add(_stopRow(context, l.from, color, now,
          departure: true, first: true, walkLink: i == 0 ? l.from.stop : null));
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
        // Zwei Zeilen: Linie und volles Ziel, darunter Zwischenhalte und
        // Echtzeit – vorher in einer Zeile, das Ziel wurde abgeschnitten.
        child: _Row(
          height: 56,
          rail: _Rail(color: color),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 1), child: LineBadge(l.line)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                OneLine('Richtung ${l.direction ?? ''}', style: TextStyle(fontSize: 15, color: c.ink2, height: 1.3)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(children: [
                    if (l.intermediates.isNotEmpty)
                      TextSpan(
                          text: '${l.intermediates.length == 1 ? '1 Zwischenhalt' : '${l.intermediates.length} Zwischenhalte'} · ',
                          style: TextStyle(color: c.muted)),
                    TextSpan(text: tag, style: TextStyle(color: tagColor)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
              ]),
            ),
            if (l.intermediates.isNotEmpty) ...[
              const SizedBox(width: 4),
              Icon(open ? Icons.expand_less : Icons.expand_more, size: 20, color: c.muted),
            ],
          ]),
        ),
      ));

      // Aktuelle Position nach dem letzten passierten Halt – nur, wenn man
      // mit „Losfahren“ gerade unterwegs ist.
      final stops = [l.from, ...l.intermediates, l.to];
      final onBoard = following && isPassed(l.from, now) && !isPassed(l.to, now);
      var lastPassed = -1;
      for (var k = 0; k < stops.length; k++) {
        if (isPassed(stops[k], now)) lastPassed = k;
      }
      // Mit GPS: die Lage auf der Strecke statt der Uhrzeit.
      final fix = following && gps != null ? locateOnLeg(l, gps) : null;
      final onLeg = fix != null ? fix.passed < stops.length - 1 : onBoard;
      if (fix != null) lastPassed = fix.passed;
      // Direkt vor dem Ausstieg keine Beschriftung – der Ausstieg steht
      // gleich darunter.
      Widget position(StopTime next) => _Row(
            height: 36,
            rail: _Rail(color: color),
            marker: PositionDot(color: color),
            child: identical(next, l.to)
                ? const SizedBox.shrink()
                : OneLine('nächster Halt ${next.stop.name}', style: TextStyle(fontSize: 13, color: c.muted)),
          );
      final shown = open
          ? l.intermediates
          : l.intermediates.where((s) => s.status != StopStatus.normal).toList();
      var placed = false;
      if (onLeg && lastPassed >= 0 && (lastPassed == 0 || !open)) {
        rows.add(position(stops[lastPassed + 1]));
        placed = true;
      }
      for (final s in shown) {
        rows.add(_stopRow(context, s, color, now));
        final k = stops.indexOf(s);
        if (onLeg && !placed && k == lastPassed) {
          rows.add(position(stops[k + 1]));
          placed = true;
        }
      }
      rows.add(_stopRow(context, l.to, color, now, departure: false, last: true));
    }
    return rows;
  }

  Widget _stopRow(BuildContext context, StopTime s, Color color, DateTime now,
      {bool? departure, bool first = false, bool last = false, Location? walkLink}) {
    final c = context.c;
    final main = first || last;
    final t = (departure ?? true) ? (s.departure ?? s.arrival) : (s.arrival ?? s.departure);
    final cancelled = s.status == StopStatus.cancelled;
    final diverted = s.status == StopStatus.diversion;
    final passed = isPassed(s, now);
    final tColor = passed ? c.muted : timeColor(context, t, status: s.status, neutral: main ? c.ink : c.ink2);
    final delayed = (t?.delayMinutes ?? 0) > 0;
    final platformChanged = s.plannedPlatform != null && s.platform != s.plannedPlatform;
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
                  color: cancelled || passed ? c.muted : c.ink,
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
        if (main && (s.platform != null || walkLink != null))
          Row(children: [
            if (s.platform != null)
              Flexible(
                child: OneLine(platformChanged ? 'Steig ${s.platform} statt ${s.plannedPlatform}' : 'Steig ${s.platform}',
                    style: TextStyle(fontSize: 13, color: platformChanged ? c.orange : c.muted)),
              ),
            if (walkLink != null && !passed) ...[
              if (s.platform != null) Text(' · ', style: TextStyle(fontSize: 13, color: c.muted)),
              GestureDetector(
                onTap: () => pushOnce(Navigator.of(context), 'weg:${walkLink.id}',
                    (_) => WalkScreen(target: walkLink, platform: s.platform)),
                child: Text('Weg zum Steig', style: TextStyle(fontSize: 13, color: c.accent)),
              ),
            ],
          ]),
      ]),
    );
  }
}

void openAlternatives(BuildContext context, Trip trip) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlternativesScreen(trip: trip)));

final _isFavorite = StreamProvider.autoDispose.family<bool, (Location, Location)>(
    (ref, r) => ref.watch(repositoryProvider).watchIsFavoriteRoute(r.$1, r.$2));

/// Abweichung in Klartext, oben in der Fahrt. Mit „Alternativen anzeigen“.
class IssueBanner extends StatelessWidget {
  const IssueBanner(this.issue, {super.key, this.onAlternatives});

  final TripIssue issue;
  final VoidCallback? onAlternatives;

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
      padding: EdgeInsets.fromLTRB(16, 14, 16, onAlternatives == null ? 14 : 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        OneLine(issue.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg)),
        if (issue.detail != null) ...[
          const SizedBox(height: 6),
          Text(issue.detail!, style: TextStyle(fontSize: 15, height: 1.4, color: fg)),
        ],
        if (onAlternatives != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: fg),
              onPressed: onAlternatives,
              child: const Text('Alternativen anzeigen',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
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
  const _Row({required this.height, required this.rail, required this.child, this.time, this.marker});

  final double height;
  final _Rail rail;
  final Widget child;
  final Widget? time;

  /// Symbol auf der Linie, z. B. das Fahrzeug an der aktuellen Position.
  final Widget? marker;

  @override
  Widget build(BuildContext context) {
    // Große Systemschrift: Zeilen, Zeitspalte und Punkte wachsen mit, damit
    // Uhrzeiten nicht umbrechen und die Punkte neben dem Namen bleiben.
    final k = (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 1.8);
    return SizedBox(
        height: height * k,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 52 * k,
            child: Padding(
              padding: EdgeInsets.only(top: 9 * k, right: 8),
              child: Align(alignment: Alignment.topRight, child: time),
            ),
          ),
          SizedBox(
            width: 24,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: CustomPaint(painter: _RailPainter(rail, dotY: 20 * k))),
              if (marker != null)
                Positioned(left: 0, right: 0, top: 0, height: 36 * k, child: Center(child: marker)),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8, top: 9 * k),
              child: Align(alignment: Alignment.topLeft, child: child),
            ),
          ),
        ]),
      );
  }
}

class _RailPainter extends CustomPainter {
  _RailPainter(this.r, {this.dotY = 20});

  final _Rail r;
  final double dotY;

  static const _x = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = r.color
      ..strokeWidth = r.dotted ? 3 : 4
      ..strokeCap = r.dotted ? StrokeCap.round : StrokeCap.butt;
    final top = r.fromTop ? 0.0 : dotY;
    final bottom = r.toBottom ? size.height : dotY;
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
        canvas.drawCircle(Offset(_x, dotY), 5, Paint()..color = dc);
      case _Dot.big:
        canvas.drawCircle(Offset(_x, dotY), 7, Paint()..color = r.fill ?? Colors.white);
        canvas.drawCircle(
            Offset(_x, dotY),
            5.5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = dc);
      case _Dot.cancelled:
      case _Dot.diverted:
        canvas.drawCircle(Offset(_x, dotY), 6, Paint()..color = r.fill ?? Colors.white);
        canvas.drawCircle(
            Offset(_x, dotY),
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
