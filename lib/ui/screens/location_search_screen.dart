import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transit_provider.dart';
import '../../data/trias/trias_parser.dart' show distanceBetween;
import '../../data/trias/trias_provider.dart' show rankLocations;
import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../../state/location.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';
import 'places_screen.dart' show placeIcon;

/// Suche nach Haltestelle, Adresse oder Ort. Liefert die gewählte Location.
///
/// Ohne Eingabe: Mein Standort, Meine Orte, Haltestellen in der Nähe und
/// zuletzt Gesuchtes. Mit Eingabe: sofort Treffer aus dem lokalen
/// Haltestellen-Cache, danach die Auskunft; gleichnamige Haltestellen nach
/// Entfernung, immer mit Ort und Entfernung.
class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({
    super.key,
    required this.title,
    this.stopsOnly = false,
    this.showPlaces = true,
    this.allowHere = true,
    this.showNearby = true,
  });

  final String title;
  final bool stopsOnly;
  final bool showPlaces;
  final bool allowHere;

  /// Haltestellen in der Nähe vorschlagen – beim Start sinnvoll, beim Ziel
  /// nicht (dorthin will man ja erst).
  final bool showNearby;

  @override
  ConsumerState<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<Location> _local = const [];
  List<Location> _online = const [];
  List<Location>? _nearby;
  LatLon? _here;
  bool _loading = false;
  String? _error;
  String? _locationError;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    try {
      final p = await ref.read(locationServiceProvider).current();
      if (!mounted) return;
      setState(() => _here = p);
      if (!widget.showNearby) return;
      final near = await ref
          .read(transitProvider)
          .searchLocations('', near: p, limit: 6, radiusMeters: (ref.read(settingsProvider).value ?? const AppSettings()).walkRadiusMeters);
      if (!mounted) return;
      await ref.read(repositoryProvider).cacheStops(near);
      setState(() => _nearby = near);
    } on LocationException catch (e) {
      if (mounted) setState(() => _locationError = e.message);
    } on ProviderException catch (e) {
      if (mounted) setState(() => _locationError = e.message);
    }
  }

  void _changed(String q) async {
    final seq = ++_seq;
    _debounce?.cancel();
    final local = await ref.read(repositoryProvider).searchCachedStops(q);
    if (!mounted || seq != _seq) return;
    setState(() {
      _local = local;
      _error = null;
      _loading = q.trim().length >= 2;
      if (q.trim().isEmpty) _online = const [];
    });
    if (q.trim().length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final res = await ref.read(transitProvider).searchLocations(q, near: _here, limit: 20);
        if (!mounted || seq != _seq) return;
        await ref.read(repositoryProvider).cacheStops(res);
        setState(() {
          _online = res;
          _loading = false;
        });
      } on ProviderException catch (e) {
        if (!mounted || seq != _seq) return;
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    });
  }

  /// Treffer aus Auskunft und Zwischenspeicher, nach Standort sortiert.
  List<Location> get _results {
    final seen = <String>{};
    final out = <Location>[];
    for (final l in [..._online, ..._local]) {
      if (widget.stopsOnly && l.type != LocationType.stop) continue;
      if (seen.add(l.id)) out.add(l);
    }
    return rankLocations(out, _ctrl.text.trim(), _here);
  }

  void _pick(Location l) => Navigator.pop(context, l);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final q = _ctrl.text.trim();
    final history = ref.watch(historyProvider).value ?? const [];
    final places = widget.showPlaces ? (ref.watch(placesProvider).value ?? const <SavedPlace>[]) : const <SavedPlace>[];
    final recent = <String, Location>{};
    for (final h in history) {
      for (final l in [h.to, h.from]) {
        if (!isHere(l)) recent.putIfAbsent(l.id, () => l);
      }
    }
    final lower = q.toLowerCase();
    final matchingPlaces = places
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(lower) || p.location.name.toLowerCase().contains(lower))
        .where((p) => !widget.stopsOnly || p.location.type == LocationType.stop)
        .toList();
    final results = _results;
    return Scaffold(
      body: Padding(
        padding: pagePadding(context, bottom: 0),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _changed,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 17),
                decoration: InputDecoration(
                  hintText: widget.stopsOnly ? 'Haltestelle' : 'Haltestelle, Adresse, Ort',
                  prefixIcon: Icon(Icons.search, size: 20, color: c.muted),
                  isDense: true,
                ),
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ]),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
              if (q.isEmpty && widget.allowHere && !widget.stopsOnly) ...[
                ListGroup(children: [
                  _Row(
                    icon: Icons.my_location,
                    name: 'Mein Standort',
                    sub: _here != null ? 'Standort gefunden' : (_locationError ?? 'wird ermittelt'),
                    subColor: _locationError != null ? c.orange : null,
                    onTap: () => _pick(myLocation),
                  ),
                ]),
                const SizedBox(height: 18),
              ],
              if (matchingPlaces.isNotEmpty) ...[
                const SectionTitle('Meine Orte', small: true),
                ListGroup(children: [
                  for (final p in matchingPlaces)
                    _Row(
                      icon: placeIcon(p.kind),
                      name: p.name,
                      sub: [p.location.name, if (p.location.place != null) p.location.place!].join(', '),
                      onTap: () => _pick(p.location),
                    ),
                ]),
                const SizedBox(height: 18),
              ],
              if (q.isEmpty) ...[
                if (!widget.showNearby) ...[
                ] else if (_nearby == null && _locationError == null) ...[
                  const SectionTitle('In der Nähe', small: true),
                  ListGroup(children: [for (var i = 0; i < 3; i++) const _SkeletonRow()]),
                  const SizedBox(height: 18),
                ] else if (_nearby != null && _nearby!.isNotEmpty) ...[
                  const SectionTitle('In der Nähe', small: true),
                  ListGroup(children: [for (final l in _nearby!) _LocationRow(l, here: _here, onTap: () => _pick(l))]),
                  const SizedBox(height: 18),
                ],
                if (recent.isNotEmpty) ...[
                  const SectionTitle('Zuletzt gesucht', small: true),
                  ListGroup(children: [
                    for (final l in recent.values
                        .where((l) => !widget.stopsOnly || l.type == LocationType.stop)
                        .take(8))
                      _LocationRow(l, here: _here, onTap: () => _pick(l)),
                  ]),
                ],
              ],
              if (q.isNotEmpty) ...[
                SectionTitle(
                  widget.title,
                  small: true,
                  trailing: SizedBox(
                    width: 14,
                    height: 14,
                    child: _loading ? CircularProgressIndicator(strokeWidth: 2, color: c.muted) : null,
                  ),
                ),
                if (results.isNotEmpty)
                  ListGroup(children: [
                    for (final l in results) _LocationRow(l, here: _here, onTap: () => _pick(l)),
                  ])
                else if (!_loading)
                  Notice(_error ?? 'Keine Treffer für „$q“.', color: _error != null ? c.orange : null),
                if (_error != null && results.isNotEmpty)
                  Notice('$_error. Angezeigt werden gespeicherte Haltestellen.', color: c.orange),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.name, required this.sub, required this.onTap, this.subColor});

  final IconData icon;
  final String name;
  final String sub;
  final Color? subColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Icon(icon, size: 20, color: c.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              OneLine(name, style: context.t.listRow),
              OneLine(sub, style: TextStyle(fontSize: 13, color: subColor ?? c.muted)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow(this.l, {required this.onTap, this.here});

  final Location l;
  final LatLon? here;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final kind = switch (l.type) {
      LocationType.stop => 'Haltestelle',
      LocationType.address => 'Adresse',
      LocationType.poi => 'Ort',
      LocationType.coordinate => 'Standort',
    };
    final d = here == null ? null : distanceBetween(l, here!);
    final sub = [if (l.place != null && l.place!.isNotEmpty) l.place!, kind].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              OneLine(l.name, style: context.t.listRow),
              const SizedBox(height: 1),
              OneLine(sub, style: TextStyle(fontSize: 13, color: c.muted)),
            ]),
          ),
          if (d != null) ...[
            const SizedBox(width: 12),
            Text(distanceText(d), style: context.t.number(15).copyWith(color: c.muted)),
          ],
        ]),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 56,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SkeletonBlock(height: 16, width: 160),
            SizedBox(height: 6),
            SkeletonBlock(height: 12, width: 100),
          ]),
        ),
      );
}
