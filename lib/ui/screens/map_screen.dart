import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/transit_provider.dart';
import '../../domain/models.dart';
import '../../state/location.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../trip_map.dart' show MapButton, MapCredit;
import '../widgets.dart';
import 'departures_screen.dart' show DepartureRow;
import 'trip_screen.dart';
import 'walk_screen.dart' show tileUrl;

/// Reiter „Karte“: Haltestellen im sichtbaren Ausschnitt; Tipp auf eine
/// Haltestelle zeigt ihre Abfahrten, Tipp auf eine Abfahrt die Fahrt mit
/// Linienweg und Halten auf der Karte.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _map = MapController();
  Timer? _debounce;
  List<Location> _stops = const [];
  bool _loadingStops = false;
  LatLng? _me;

  /// Auf der Karte gezeigte Fahrt (nach Tipp auf eine Abfahrt).
  Trip? _trip;
  bool _loadingTrip = false;

  /// Ab dieser Zoomstufe werden Haltestellen geladen (sonst zu viele).
  static const _minZoom = 14.5;

  /// Wuppertal Hbf, bis der Standort da ist.
  static const _fallback = LatLng(51.2544, 7.1495);

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _locate({bool move = true}) async {
    try {
      final p = await ref.read(locationServiceProvider).current(preferRecent: true);
      if (!mounted) return;
      setState(() => _me = LatLng(p.lat, p.lon));
      if (move) _map.move(_me!, 16);
      _scheduleStops();
    } catch (_) {
      _scheduleStops();
    }
  }

  void _scheduleStops() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _loadStops);
  }

  /// Haltestellen im Ausschnitt: Umkreis um die Mitte bis zur Ecke, höchstens 3 km.
  Future<void> _loadStops() async {
    final cam = _map.camera;
    if (cam.zoom < _minZoom) {
      if (_stops.isNotEmpty) setState(() => _stops = const []);
      return;
    }
    final center = cam.center;
    final corner = cam.visibleBounds.northEast;
    final radius = math.min(3000, const Distance().as(LengthUnit.Meter, center, corner)).round();
    setState(() => _loadingStops = true);
    try {
      final list = await ref
          .read(transitProvider)
          .searchLocations('', near: (lat: center.latitude, lon: center.longitude), limit: 60, radiusMeters: radius);
      if (mounted) setState(() => _stops = list.where((l) => l.lat != null).toList());
    } on ProviderException {
      // Netz weg: vorhandene Haltestellen bleiben stehen.
    } finally {
      if (mounted) setState(() => _loadingStops = false);
    }
  }

  Future<void> _showStop(Location stop) async {
    final d = await showModalBottomSheet<Departure>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _StopSheet(stop: stop),
    );
    if (d != null) await _showDeparture(d);
  }

  Future<void> _showDeparture(Departure d) async {
    setState(() => _loadingTrip = true);
    try {
      final trip = await ref.read(transitProvider).tripOfDeparture(d);
      if (!mounted) return;
      if (trip == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Fahrtverlauf für diese Abfahrt nicht verfügbar.')));
        return;
      }
      setState(() => _trip = trip);
      final pts = [
        for (final s in [trip.legs.first.from, ...trip.legs.first.intermediates, trip.legs.first.to])
          if (s.stop.lat != null) LatLng(s.stop.lat!, s.stop.lon!),
      ];
      if (pts.length >= 2) {
        _map.fitCamera(CameraFit.coordinates(
            coordinates: pts, padding: const EdgeInsets.fromLTRB(40, 80, 40, 180), maxZoom: 16));
      }
    } on ProviderException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loadingTrip = false);
    }
  }

  Future<void> _openTrip() async {
    final t = _trip;
    if (t == null) return;
    await ref.read(lastTripProvider.notifier).open(t);
    if (mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final trip = _trip;
    final leg = trip?.rides.firstOrNull;
    final color = lineColor(context, leg?.line);
    final paths = trip == null ? null : ref.watch(legPathsProvider(TripPathKey(trip))).value;
    final tripStops = leg == null ? const <StopTime>[] : [leg.from, ...leg.intermediates, leg.to];
    final tripLine = paths != null && paths.isNotEmpty && paths.first != null
        ? [for (final p in paths.first!) LatLng(p.lat, p.lon)]
        : [for (final s in tripStops) if (s.stop.lat != null) LatLng(s.stop.lat!, s.stop.lon!)];
    final zoomedOut = _stops.isEmpty && !_loadingStops;

    return Stack(children: [
      FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: _me ?? _fallback,
          initialZoom: 15.5,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          onPositionChanged: (_, gesture) {
            if (gesture) _scheduleStops();
          },
          onMapReady: _scheduleStops,
        ),
        children: [
          TileLayer(urlTemplate: tileUrl, userAgentPackageName: 'de.gleichda.app', maxZoom: 19),
          if (tripLine.length >= 2)
            PolylineLayer(polylines: [
              Polyline(points: tripLine, color: color, strokeWidth: 5, borderColor: c.surface, borderStrokeWidth: 1.5),
            ]),
          MarkerLayer(markers: [
            for (final s in _stops)
              Marker(
                point: LatLng(s.lat!, s.lon!),
                width: 28,
                height: 28,
                child: GestureDetector(onTap: () => _showStop(s), child: _StopMarker(color: c.accent)),
              ),
            for (final s in tripStops)
              if (s.stop.lat != null)
                Marker(
                  point: LatLng(s.stop.lat!, s.stop.lon!),
                  width: 22,
                  height: 22,
                  child: GestureDetector(
                    onTap: () => _showStop(s.stop),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: c.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 3),
                        ),
                      ),
                    ),
                  ),
                ),
            if (_me != null)
              Marker(
                point: _me!,
                width: 22,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D5FD1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
          ]),
          const MapCredit(),
        ],
      ),
      // Oben: Titel und Hinweis, rechts Zentrieren.
      Positioned(
        top: MediaQuery.paddingOf(context).top + 12,
        left: 16,
        right: 16,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _Pill(text: 'Karte', bold: true),
              if (_loadingStops || _loadingTrip)
                const _Pill(text: 'Wird geladen …')
              else if (zoomedOut)
                const _Pill(text: 'Hineinzoomen für Haltestellen'),
            ]),
          ),
          MapButton(
            icon: Icons.my_location,
            tooltip: 'Auf mich zentrieren',
            onTap: () => _me == null ? _locate() : _map.move(_me!, math.max(_map.camera.zoom, 16)),
          ),
        ]),
      ),
      // Unten: gewählte Fahrt.
      if (trip != null && leg != null)
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Material(
            color: c.surface,
            elevation: 2,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(Radii.card),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
              child: Row(children: [
                LineBadge(leg.line),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    OneLine('Richtung ${leg.direction ?? trip.destination.label}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    OneLine('${tripStops.length} Halte ab ${trip.origin.label}',
                        style: TextStyle(fontSize: 13, color: c.muted)),
                  ]),
                ),
                TextButton(onPressed: _openTrip, child: const Text('Fahrtverlauf')),
                IconButton(
                  tooltip: 'Fahrt ausblenden',
                  icon: Icon(Icons.close, size: 20, color: c.muted),
                  onPressed: () => setState(() => _trip = null),
                ),
              ]),
            ),
          ),
        ),
    ]);
  }
}

class _StopMarker extends StatelessWidget {
  const _StopMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.c.surface,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
          ),
          child: Text('H',
              textScaler: TextScaler.noScaling,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, height: 1)),
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.hair, width: 0.5),
      ),
      child: Text(text,
          style: TextStyle(fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: bold ? c.ink : c.muted)),
    );
  }
}

/// Abfahrten einer Haltestelle von unten; Tipp auf eine Abfahrt gibt sie
/// an die Karte zurück.
class _StopSheet extends ConsumerStatefulWidget {
  const _StopSheet({required this.stop});

  final Location stop;

  @override
  ConsumerState<_StopSheet> createState() => _StopSheetState();
}

class _StopSheetState extends ConsumerState<_StopSheet> {
  DepartureBoard? _board;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await ref.read(transitProvider).departures(widget.stop, limit: 12);
      if (mounted) setState(() => _board = b);
    } on ProviderException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final board = _board;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SheetHeader(widget.stop.label, done: 'Schließen'),
          ),
          Flexible(
            child: board == null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: _error != null
                          ? Text(_error!, style: TextStyle(color: c.muted))
                          : const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : board.departures.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Keine Abfahrten in der nächsten Zeit.', style: TextStyle(color: c.muted)),
                      )
                    : ListView(shrinkWrap: true, children: [
                        for (final d in board.departures)
                          DepartureRow(d, now: now, onSelect: (d) => Navigator.pop(context, d)),
                      ]),
          ),
        ]),
      ),
    );
  }
}
