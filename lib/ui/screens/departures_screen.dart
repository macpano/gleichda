import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transit_provider.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';
import 'location_search_screen.dart';

/// Abfahrtsmonitor für eine gewählte Haltestelle.
// TODO: mehrere Haltestellen in der Nähe per Standort, Zeitwahl, Filter
// nach Verkehrsmittel (Schritt 11).
class DeparturesScreen extends ConsumerStatefulWidget {
  const DeparturesScreen({super.key, this.initialStop});

  /// Vorgewählte Haltestelle, z. B. aus einem Favoriten.
  final Location? initialStop;

  @override
  ConsumerState<DeparturesScreen> createState() => _DeparturesScreenState();
}

class _DeparturesScreenState extends ConsumerState<DeparturesScreen> {
  Location? _stop;
  DepartureBoard? _board;
  DateTime? _updatedAt;
  bool _loading = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final s = widget.initialStop;
    if (s != null) Future.microtask(() => _show(s));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pick() async {
    final l = await Navigator.of(context).push<Location>(MaterialPageRoute(
        builder: (_) => const LocationSearchScreen(title: 'Haltestellen', stopsOnly: true)));
    if (l != null) await _show(l);
  }

  Future<void> _show(Location l) async {
    setState(() {
      _stop = l;
      _board = null;
    });
    _timer?.cancel();
    await _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  Future<void> _load() async {
    final stop = _stop;
    if (stop == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final b = await ref.read(transitProvider).departures(stop, limit: 20);
      if (!mounted || stop != _stop) return;
      setState(() {
        _board = b;
        _updatedAt = DateTime.now();
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
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final board = _board;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: pagePadding(context),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text('Abfahrten', style: context.t.screenTitle)),
            if (_stop != null)
              FreshnessStamp(updatedAt: _updatedAt, now: now, refreshing: _loading, failed: _error != null),
          ]),
          const SizedBox(height: 16),
          Material(
            color: c.fill,
            borderRadius: BorderRadius.circular(Radii.input),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.input),
              onTap: _pick,
              child: SizedBox(
                height: 44,
                child: Row(children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, size: 18, color: c.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OneLine(_stop?.name ?? 'Haltestelle wählen',
                        style: TextStyle(fontSize: 16, color: _stop == null ? c.muted : c.ink)),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_stop == null)
            const Notice('Wähle eine Haltestelle, um ihre nächsten Abfahrten zu sehen.')
          else if (board == null && _loading)
            ListGroup(children: [for (var i = 0; i < 6; i++) const _DepartureSkeleton()])
          else if (board == null)
            Notice(_error ?? 'Keine Abfahrten.', action: 'Erneut versuchen', onAction: _load)
          else if (board.departures.isEmpty)
            const Notice('Keine Abfahrten in der nächsten Zeit.')
          else ...[
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('$_error. Angezeigt wird der letzte Stand.',
                    style: TextStyle(fontSize: 14, color: c.orange)),
              ),
            SectionTitle(_stop!.name, trailing: _stop!.place == null
                ? null
                : Text(_stop!.place!, style: TextStyle(fontSize: 13, color: c.muted))),
            ListGroup(children: [
              for (final d in board.departures) _DepartureRow(d, now: now),
            ]),
          ],
        ],
      ),
    );
  }
}

class _DepartureRow extends StatelessWidget {
  const _DepartureRow(this.d, {required this.now});

  final Departure d;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final cancelled = d.status == StopStatus.cancelled;
    final sev = d.status == StopStatus.replacement;
    final color = timeColor(context, d.time, status: d.status, neutral: c.ink);
    final state = cancelled
        ? 'fällt aus'
        : !d.time.hasRealtime
            ? 'Fahrplan'
            : (d.time.delayMinutes ?? 0) > 0
                ? '+${d.time.delayMinutes} min'
                : countdown(d.time.best, now);
    final sub = [
      if (d.platform != null) 'Steig ${d.platform}',
      if (d.plannedPlatform != null && d.platform != d.plannedPlatform) 'statt ${d.plannedPlatform}',
      if (sev) 'Ersatzverkehr',
    ].join(' · ');
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          LineBadge(d.line, width: 40, height: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              OneLine(d.direction,
                  style: TextStyle(
                      fontSize: 16,
                      color: cancelled ? c.muted : c.ink,
                      decoration: cancelled ? TextDecoration.lineThrough : null)),
              if (sub.isNotEmpty)
                OneLine(sub, style: TextStyle(fontSize: 13, color: sev ? c.sev : c.muted)),
            ]),
          ),
          SizedBox(
            width: 76,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              FadeText(hm(d.time.best),
                  align: TextAlign.right,
                  style: context.t.time(16).copyWith(
                      color: color, decoration: cancelled ? TextDecoration.lineThrough : null)),
              FadeText(state,
                  align: TextAlign.right,
                  style: context.t.number(12).copyWith(color: d.time.hasRealtime || cancelled ? color : c.muted)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _DepartureSkeleton extends StatelessWidget {
  const _DepartureSkeleton();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 56,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            SkeletonBlock(height: 24, width: 40),
            SizedBox(width: 12),
            Expanded(child: SkeletonBlock(height: 16)),
            SizedBox(width: 24),
            SkeletonBlock(height: 16, width: 44),
          ]),
        ),
      );
}
