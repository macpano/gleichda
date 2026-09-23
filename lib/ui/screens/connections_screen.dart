import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transit_provider.dart';
import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../../state/location.dart';
import '../../state/providers.dart';
import '../connection_views.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';
import 'trip_screen.dart';

Set<TransportMode> modesOf(Set<ModeGroup> groups) => {
      for (final g in groups)
        for (final m in TransportMode.values)
          if (g.matches(m)) m,
    };

/// Baut die Anfrage aus Suchprofil und persönlichem Profil.
TripQuery buildQuery({
  required Location from,
  required Location to,
  Location? via,
  required DateTime time,
  bool arriveBy = false,
  required AppSettings settings,
  bool usePersonal = true,
  TripOptimization optimization = TripOptimization.fastest,
  bool accessible = false,
}) =>
    TripQuery(
      from: from,
      to: to,
      via: via,
      time: time,
      arriveBy: arriveBy,
      maxResults: 5,
      optimization: optimization,
      excludedModes: usePersonal ? modesOf(settings.excludedModes) : const {},
      accessible: accessible || (usePersonal && settings.accessible),
      walkSpeedPercent: usePersonal ? settings.walkPace.walkPercent : 100,
      maxWalkMinutes: settings.maxWalkMinutes,
    );

/// Mehrere Profile parallel, Doppelte entfernt, nach Abfahrt sortiert.
Future<List<Trip>> searchMerged(TransitProvider p, List<TripQuery> queries) async {
  final results = await Future.wait(queries.map((q) => p.planTrip(q).catchError((Object e) {
        if (identical(q, queries.first)) throw e;
        return <Trip>[];
      })));
  final seen = <String>{};
  final out = <Trip>[];
  for (final list in results) {
    for (final t in list) {
      if (seen.add(tripSignature(t))) out.add(t);
    }
  }
  out.sort((a, b) => a.departure.best.compareTo(b.departure.best));
  return out;
}

String tripSignature(Trip t) =>
    '${t.departure.planned.toIso8601String()}|${t.arrival.planned.toIso8601String()}|${t.rides.map((r) => r.line?.id).join(',')}';

/// Verbindungen als Liste oder Zeitraster.
///
/// Ein gespeichertes Ergebnis aus dem Verlauf erscheint sofort und ist bis
/// zur Aktualisierung als „wird aktualisiert“ markiert.
class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({
    super.key,
    required this.from,
    required this.to,
    required this.time,
    required this.arriveBy,
    this.via,
  });

  final Location from;
  final Location to;
  final Location? via;

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
  SearchProfile _profile = SearchProfile.all;
  bool _personal = true;
  int _seq = 0;

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
    if (widget.time == null && widget.via == null) {
      final h = await ref.read(repositoryProvider).history(widget.from, widget.to);
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
    if (widget.time == null) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load(quiet: true));
    }
  }

  Future<List<Trip>> _query(DateTime time, {bool arriveBy = false}) async {
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final loc = ref.read(locationServiceProvider);
    final from = await loc.resolve(widget.from);
    final to = await loc.resolve(widget.to);
    TripQuery q(TripOptimization o, {bool accessible = false}) => buildQuery(
          from: from,
          to: to,
          via: widget.via,
          time: time,
          arriveBy: arriveBy,
          settings: settings,
          usePersonal: _personal,
          optimization: o,
          accessible: accessible,
        );
    final p = ref.read(transitProvider);
    return switch (_profile) {
      SearchProfile.all => searchMerged(p, [
          q(TripOptimization.fastest),
          q(TripOptimization.minChanges),
          q(TripOptimization.leastWalking),
        ]),
      SearchProfile.fastest => p.planTrip(q(TripOptimization.fastest)),
      SearchProfile.fewChanges => p.planTrip(q(TripOptimization.minChanges)),
      SearchProfile.lessWalking => p.planTrip(q(TripOptimization.leastWalking)),
      SearchProfile.accessible => p.planTrip(q(TripOptimization.fastest, accessible: true)),
    };
  }

  Future<void> _load({bool quiet = false}) async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      if (!quiet) _error = null;
    });
    try {
      final trips = await _query(widget.time ?? DateTime.now(), arriveBy: widget.arriveBy);
      if (!mounted || seq != _seq) return;
      setState(() {
        _trips = trips;
        _updatedAt = DateTime.now();
        _fromCache = false;
        _loading = false;
        _error = null;
      });
      if (_profile == SearchProfile.all && widget.via == null) {
        await ref.read(repositoryProvider).recordSearch(widget.from, widget.to, result: trips);
      }
    } on ProviderException catch (e) {
      _fail(seq, e.message);
    } on LocationException catch (e) {
      _fail(seq, e.message);
    }
  }

  void _fail(int seq, String message) {
    if (!mounted || seq != _seq) return;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  Future<void> _more({required bool later}) async {
    final trips = _trips;
    if (trips == null || trips.isEmpty || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final at = later
          ? trips.last.departure.planned.add(const Duration(minutes: 1))
          : trips.first.departure.planned.subtract(const Duration(minutes: 40));
      final more = await _query(at);
      if (!mounted) return;
      final ids = trips.map(tripSignature).toSet();
      final add = more.where((t) => ids.add(tripSignature(t)) &&
          (later || t.departure.best.isBefore(trips.first.departure.best)));
      setState(() => _trips = [...trips, ...add]
        ..sort((a, b) => a.departure.best.compareTo(b.departure.best)));
    } on ProviderException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on LocationException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _open(Trip t) {
    ref.read(lastTripProvider.notifier).open(t, updatedAt: _updatedAt);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final grid = settings.connectionsGrid;
    final items = _trips == null
        ? null
        : rateConnections(_trips!, transferMinutes: settings.transferPace.transferMinutes);
    final unreachable = items?.where((i) => !i.reachable).length ?? 0;
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
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                child: RouteSummary(
                  from: widget.from.name,
                  to: widget.to.name,
                  when: [
                    if (widget.via != null) 'über ${widget.via!.name}',
                    widget.time == null
                        ? 'Heute ab ${hm(now)}'
                        : '${widget.arriveBy ? 'Ankunft bis' : 'Ab'} ${dayText(widget.time!, now)} ${hm(widget.time!)}',
                  ].join(' · '),
                ),
              ),
              _ViewToggle(
                grid: grid,
                onChanged: (g) => updateSettings(ref, (s) => s.copyWith(connectionsGrid: g)),
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 34,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                if (!settings.isDefault)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChipX(
                      label: _personal ? 'Profil an' : 'Profil aus',
                      selected: _personal,
                      icon: Icons.person_outline,
                      onTap: () {
                        setState(() => _personal = !_personal);
                        _load();
                      },
                    ),
                  ),
                for (final p in SearchProfile.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChipX(
                      label: p.label,
                      selected: _profile == p,
                      onTap: () {
                        if (_profile == p) return;
                        setState(() {
                          _profile = p;
                          _trips = null;
                        });
                        _load();
                      },
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 14),
            if (_error != null && items != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('$_error. Angezeigt wird der letzte Stand.',
                    style: TextStyle(fontSize: 14, color: c.orange)),
              ),
            if (items == null && _loading)
              ListGroup(children: [for (var i = 0; i < 4; i++) const _ConnectionSkeleton()])
            else if (items == null)
              Notice(_error ?? 'Keine Verbindungen gefunden.', action: 'Erneut versuchen', onAction: _load)
            else if (items.isEmpty)
              Notice('Keine Verbindungen gefunden.', action: 'Erneut versuchen', onAction: _load)
            else if (grid)
              ConnectionGrid(items: items, onTap: (i) => _open(i.trip))
            else
              ListGroup(indent: 0, children: [
                _MoreButton(label: 'Früher', busy: _loadingMore, onTap: () => _more(later: false)),
                for (final i in items)
                  ConnectionRow(item: i, stale: _fromCache, onTap: () => _open(i.trip)),
                _MoreButton(label: 'Später', busy: _loadingMore, onTap: () => _more(later: true)),
              ]),
            if (unreachable > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                child: Text(
                  unreachable == 1
                      ? '1 Verbindung wegen Verspätung nicht erreichbar.'
                      : '$unreachable Verbindungen wegen Verspätung nicht erreichbar.',
                  style: TextStyle(fontSize: 13, color: c.muted),
                ),
              ),
            if (grid && items != null && items.isNotEmpty)
              Row(children: [
                Expanded(child: _MoreButton(label: 'Früher', busy: _loadingMore, onTap: () => _more(later: false))),
                Expanded(child: _MoreButton(label: 'Später', busy: _loadingMore, onTap: () => _more(later: true))),
              ]),
          ],
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.label, required this.busy, required this.onTap});

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: TextButton(onPressed: busy ? null : onTap, child: Text(label)),
      );
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.grid, required this.onChanged});

  final bool grid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget b(bool g, IconData icon, String label) => Semantics(
          button: true,
          selected: grid == g,
          label: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onChanged(g),
            child: Container(
              width: 40,
              height: 32,
              decoration: BoxDecoration(
                color: grid == g ? (dark ? const Color(0xFF3A3F46) : c.surface) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: c.ink),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(Radii.input)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        b(false, Icons.view_agenda_outlined, 'Liste'),
        const SizedBox(width: 2),
        b(true, Icons.view_week_outlined, 'Zeitraster'),
      ]),
    );
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
