import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transit_provider.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../trip_status.dart';
import '../widgets.dart';
import 'trip_screen.dart';

/// Verbindungen als Liste mit Zeitleiste je Verbindung.
///
/// Ein gespeichertes Ergebnis aus dem Verlauf erscheint sofort und ist bis
/// zur Aktualisierung als „wird aktualisiert“ markiert.
// TODO: Suchprofile, Zeitraster, endloses Scrollen (Schritt 8).
class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({
    super.key,
    required this.from,
    required this.to,
    required this.time,
    required this.arriveBy,
  });

  final Location from;
  final Location to;

  /// null = jetzt
  final DateTime? time;
  final bool arriveBy;

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  List<Trip>? _trips;
  DateTime? _updatedAt;
  bool _loading = true;
  bool _fromCache = false;
  String? _error;
  Timer? _timer;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final repo = ref.read(repositoryProvider);
    if (widget.time == null) {
      final h = await repo.history(widget.from, widget.to);
      final now = DateTime.now();
      final cached = h?.cached
          ?.where((t) => t.departure.best.isAfter(now.subtract(const Duration(minutes: 2))))
          .toList();
      if (mounted && cached != null && cached.isNotEmpty) {
        setState(() {
          _trips = cached;
          _updatedAt = h!.cachedAt;
          _fromCache = true;
        });
      }
    }
    await _load();
    // Nur „jetzt“ wird laufend aktualisiert.
    if (widget.time == null) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trips = await ref.read(transitProvider).planTrip(TripQuery(
            from: widget.from,
            to: widget.to,
            time: widget.time ?? DateTime.now(),
            arriveBy: widget.arriveBy,
            maxResults: 5,
          ));
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _updatedAt = DateTime.now();
        _fromCache = false;
        _loading = false;
      });
      await ref.read(repositoryProvider).recordSearch(widget.from, widget.to, result: trips);
    } on ProviderException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _later() async {
    final trips = _trips;
    if (trips == null || trips.isEmpty || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final more = await ref.read(transitProvider).planTrip(TripQuery(
            from: widget.from,
            to: widget.to,
            time: trips.last.departure.planned.add(const Duration(minutes: 1)),
            maxResults: 5,
          ));
      if (!mounted) return;
      final ids = trips.map(_sig).toSet();
      setState(() => _trips = [...trips, ...more.where((t) => ids.add(_sig(t)))]);
    } on ProviderException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  String _sig(Trip t) =>
      '${t.departure.planned.toIso8601String()}|${t.rides.map((r) => r.line?.id).join(',')}';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final trips = _trips;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: pagePadding(context),
          children: [
            SubpageHeader(
              title: 'Verbindungen',
              backLabel: 'Suche',
              trailing: FreshnessStamp(
                updatedAt: _updatedAt,
                now: now,
                refreshing: _loading,
                failed: _error != null,
              ),
            ),
            const SizedBox(height: 4),
            _RouteSummary(
              from: widget.from.name,
              to: widget.to.name,
              when: widget.time == null
                  ? 'Heute ab ${hm(now)}'
                  : '${widget.arriveBy ? 'Ankunft bis' : 'Ab'} ${dayText(widget.time!, now)} ${hm(widget.time!)}',
            ),
            const SizedBox(height: 14),
            if (_error != null && trips != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('$_error. Angezeigt wird der letzte Stand.',
                    style: TextStyle(fontSize: 14, color: c.orange)),
              ),
            if (trips == null && _loading)
              ListGroup(children: [for (var i = 0; i < 4; i++) const _ConnectionSkeleton()])
            else if (trips == null)
              Notice(_error ?? 'Keine Verbindungen gefunden.', action: 'Erneut versuchen', onAction: _load)
            else if (trips.isEmpty)
              Notice('Keine Verbindungen gefunden.', action: 'Erneut versuchen', onAction: _load)
            else
              ListGroup(indent: 0, children: [
                for (final t in trips)
                  _ConnectionRow(
                    trip: t,
                    stale: _fromCache,
                    onTap: () {
                      ref.read(lastTripProvider.notifier).open(t, updatedAt: _updatedAt);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripScreen()));
                    },
                  ),
                SizedBox(
                  height: 44,
                  child: TextButton(
                    onPressed: _loadingMore ? null : _later,
                    child: Text(_loadingMore ? 'Wird geladen …' : 'Später'),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.from, required this.to, required this.when});

  final String from;
  final String to;
  final String when;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const name = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 10, height: 46, child: CustomPaint(painter: _MiniRoute(c.muted, c.ink))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              OneLine(from, style: name),
              OneLine(to, style: name),
            ]),
          ),
        ]),
        const SizedBox(height: 2),
        Text(when, style: context.t.number(14).copyWith(color: c.muted)),
      ]),
    );
  }
}

class _MiniRoute extends CustomPainter {
  _MiniRoute(this.muted, this.ink);

  final Color muted;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(const Offset(5, 11), 3.8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = muted);
    final p = Paint()
      ..color = muted
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var y = 17.0; y <= 29; y += 5) {
      canvas.drawLine(Offset(5, y), Offset(5, y + 0.5), p);
    }
    canvas.drawCircle(const Offset(5, 35), 4.2, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_MiniRoute old) => old.muted != muted || old.ink != ink;
}

class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({required this.trip, required this.onTap, this.stale = false});

  final Trip trip;
  final VoidCallback onTap;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dep = trip.departure;
    final issue = tripIssue(trip);
    final rt = trip.rides.any((r) => r.from.departure?.hasRealtime ?? false);
    final late = (trip.rides.isEmpty ? null : trip.rides.first.from.departure?.delayMinutes) ?? 0;
    final (String note, Color noteColor) = issue != null
        ? (issue.title, issue.color(context))
        : !rt
            ? ('nur Fahrplan', c.muted)
            : late > 0
                ? ('+$late min', c.orange)
                : ('pünktlich', c.green);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Opacity(
          opacity: issue?.level == IssueLevel.cancelled ? 0.55 : 1,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              TimeWithDelay(trip.rides.isEmpty ? dep : trip.rides.first.from.departure,
                  size: 19, delaySize: 13, neutral: c.ink),
              Text('– ${hm(trip.arrival.best)}', style: context.t.number(19).copyWith(color: c.ink2)),
              const Spacer(),
              Text(durationText(trip.duration), style: context.t.number(15).copyWith(color: c.ink2)),
            ]),
            const SizedBox(height: 9),
            _Timeline(trip: trip),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(
                child: OneLine(
                  [
                    interchangesText(trip.interchanges),
                    if (trip.legs.first.type == LegType.walk && trip.legs.first.durationMinutes != null)
                      '${trip.legs.first.durationMinutes} min Fußweg',
                  ].join(' · '),
                  style: TextStyle(fontSize: 13, color: c.muted),
                ),
              ),
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

/// Balken je Abschnitt, Länge proportional zur Dauer. Fußwege grau.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final segs = <Widget>[];
    for (final l in trip.legs) {
      final start = (l.from.departure ?? l.from.arrival)?.best;
      final end = (l.to.arrival ?? l.to.departure)?.best;
      var minutes = (start != null && end != null) ? end.difference(start).inMinutes : 0;
      if (minutes <= 0) minutes = l.durationMinutes ?? 1;
      final ride = l.type == LegType.ride;
      if (!ride && minutes < 1) continue;
      segs.add(Expanded(
        flex: minutes.clamp(1, 600),
        child: Container(
          height: 22,
          constraints: const BoxConstraints(minWidth: 14),
          margin: const EdgeInsets.only(right: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ride ? lineColor(context, l.line) : c.walk,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ride
              ? Text(l.line?.name ?? '',
                  maxLines: 1, overflow: TextOverflow.clip, style: context.t.lineNumber.copyWith(fontSize: 12))
              : null,
        ),
      ));
    }
    return SizedBox(height: 22, child: Row(children: segs));
  }
}

class _ConnectionSkeleton extends StatelessWidget {
  const _ConnectionSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SkeletonBlock(height: 22, width: 140),
          SizedBox(height: 9),
          SkeletonBlock(height: 22),
          SizedBox(height: 9),
          SkeletonBlock(height: 15, width: 180),
        ]),
      );
}
