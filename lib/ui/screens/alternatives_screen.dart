import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transit_provider.dart';
import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../../state/providers.dart';
import '../connection_views.dart';
import '../format.dart';
import '../theme.dart';
import '../trip_status.dart';
import '../widgets.dart';
import 'connections_screen.dart';
import 'trip_screen.dart';

/// Alternativen bei Ausfall oder verpasstem Anschluss: Suche ohne Eingabe
/// vom betroffenen Halt (bzw. vom Start) zum Ziel. Zuerst die nächste Fahrt
/// derselben Linie, dann Umwege mit Zeitdifferenz.
class AlternativesScreen extends ConsumerStatefulWidget {
  const AlternativesScreen({super.key, required this.trip});

  final Trip trip;

  @override
  ConsumerState<AlternativesScreen> createState() => _AlternativesScreenState();
}

class _AlternativesScreenState extends ConsumerState<AlternativesScreen> {
  List<Trip>? _trips;
  String? _error;
  bool _loading = true;
  bool _loadingMore = false;
  late final Location _from;

  @override
  void initState() {
    super.initState();
    _from = _startPoint(widget.trip, DateTime.now());
    _load();
  }

  /// Wer schon unterwegs ist, sucht ab dem nächsten erreichbaren Halt; sonst
  /// ab dem ursprünglichen Start.
  static Location _startPoint(Trip trip, DateTime now) {
    for (final r in trip.rides) {
      final dep = r.from.departure?.best;
      if (dep != null && dep.isAfter(now)) return r.from.stop;
      final arr = r.to.arrival?.best;
      if (arr != null && arr.isAfter(now)) return r.to.stop;
    }
    return trip.origin;
  }

  Future<List<Trip>> _search(DateTime time) {
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final p = ref.read(transitProvider);
    TripQuery q(TripOptimization o) => buildQuery(
          from: _from,
          to: widget.trip.destination,
          time: time,
          settings: settings,
          optimization: o,
        );
    return searchMerged(p, [q(TripOptimization.fastest), q(TripOptimization.minChanges)]);
  }

  /// Spätere Alternativen: ab der letzten gefundenen Abfahrt weitersuchen.
  Future<void> _later() async {
    final trips = _trips;
    if (trips == null || trips.isEmpty || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final last = trips.map((t) => t.departure.planned).reduce((a, b) => a.isAfter(b) ? a : b);
      final more = await _search(last.add(const Duration(minutes: 1)));
      if (!mounted) return;
      final seen = {...trips.map(tripSignature), tripSignature(widget.trip)};
      setState(() => _trips = [...trips, ...more.where((t) => seen.add(tripSignature(t)))]
        ..sort((a, b) => a.departure.best.compareTo(b.departure.best)));
    } on ProviderException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trips = await _search(DateTime.now());
      if (!mounted) return;
      setState(() {
        _trips = trips.where((t) => tripSignature(t) != tripSignature(widget.trip)).toList();
        _loading = false;
      });
    } on ProviderException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final original = widget.trip;
    final issue = tripIssue(original);
    final firstLine = original.rides.isEmpty ? null : original.rides.first.line?.id;
    final items = _trips == null
        ? null
        : rateConnections(_trips!, transferMinutes: settings.transferPace.transferMinutes)
            .where((i) => i.reachable)
            .toList();
    final sameLine = items?.where((i) => i.trip.rides.isNotEmpty && i.trip.rides.first.line?.id == firstLine).take(1).toList() ?? [];
    final rest = items?.where((i) => !sameLine.contains(i)).toList() ?? [];
    final arr = original.arrival.best;
    final faster = rest.where((i) => !i.trip.arrival.best.isAfter(arr)).toList();
    final later = rest.where((i) => i.trip.arrival.best.isAfter(arr)).toList();

    void open(Trip t) {
      ref.read(lastTripProvider.notifier).open(t);
      Navigator.of(context).pushReplacement(MaterialPageRoute(settings: const RouteSettings(name: 'fahrt'), builder: (_) => const TripScreen()));
    }

    Widget group(String title, List<ConnectionItem> list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            SectionTitle(title, small: true),
            ListGroup(indent: 0, children: [
              for (final i in list) ConnectionRow(item: i, compareTo: arr, onTap: () => open(i.trip)),
            ]),
          ],
        );

    return Scaffold(
      body: RefreshIndicator(
        edgeOffset: MediaQuery.paddingOf(context).top,
        onRefresh: _load,
        child: ListView(
          padding: pagePadding(context),
          children: [
            const SubpageHeader(title: 'Alternativen', backLabel: 'Fahrt'),
            RouteSummary(from: _from.label, to: original.destination.label, when: 'ab jetzt'),
            const SizedBox(height: 14),
            _Original(trip: original, issue: issue),
            if (_loading && items == null) ...[
              const SizedBox(height: 20),
              const SkeletonBlock(height: 96, radius: Radii.card),
              const SizedBox(height: 8),
              const SkeletonBlock(height: 96, radius: Radii.card),
            ] else if (items == null)
              Notice(_error ?? 'Keine Alternativen gefunden.', action: 'Erneut versuchen', onAction: _load)
            else if (items.isEmpty)
              const Notice('Keine erreichbaren Alternativen gefunden.')
            else ...[
              if (sameLine.isNotEmpty) group('Nächste Fahrt derselben Linie', sameLine),
              if (faster.isNotEmpty) group('Schneller oder gleich schnell', faster),
              if (later.isNotEmpty) group('Etwas später', later),
              const SizedBox(height: 8),
              MoreButton(label: 'Spätere Verbindungen', busy: _loadingMore, onTap: _later),
            ],
            const SizedBox(height: 12),
            Text('Zeitangaben rechts: Ankunft im Vergleich zu deiner Verbindung (${hm(arr)}).',
                style: TextStyle(fontSize: 13, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

/// Die betroffene Verbindung kompakt, getönt nach Art der Abweichung.
class _Original extends StatelessWidget {
  const _Original({required this.trip, this.issue});

  final Trip trip;
  final TripIssue? issue;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final red = issue?.level == IssueLevel.cancelled;
    final bg = issue == null ? c.surface : (red ? c.redTint : c.orangeTint);
    final fg = issue == null ? c.ink : (red ? c.redText : c.orangeText);
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.card)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Deine Verbindung', style: TextStyle(fontSize: 13, color: fg)),
              const SizedBox(height: 2),
              OneLine(
                '${hm(trip.departure.best)} – ${hm(trip.arrival.best)}${issue == null ? '' : ' · ${issue!.title}'}',
                style: context.t.time(16).copyWith(color: fg),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Text(durationText(trip.duration), style: context.t.number(15).copyWith(color: fg)),
        ]),
      ),
    );
  }
}
