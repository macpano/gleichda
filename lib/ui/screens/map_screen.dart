import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/trias/trias_parser.dart' show stopAreaId;
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

  /// Bisher geladene Haltestellen und Steige (mit genauer Lage aus der EFA;
  /// die Haltestelle steht an deren Mitte). Sie bleiben beim Verschieben
  /// stehen – Haltestellen ändern sich nicht, neu geladen wird nur, was noch
  /// fehlt.
  final _stopById = <String, Location>{};
  final _platformById = <String, Platform>{};

  /// Schon abgefragte Kreise; liegt der Ausschnitt ganz in einem, wird
  /// nichts nachgeladen.
  final _covered = <({LatLng center, double radius})>[];
  LatLngBounds? _bounds;
  bool _loadingStops = false;

  /// Letzter Abruf fehlgeschlagen (Netz weg, Server langsam).
  bool _stopsFailed = false;

  /// Zu weit herausgezoomt für Haltestellen.
  bool _tooFar = false;
  int _stopsSeq = 0;
  LatLng? _me;

  /// Auf der Karte gezeigte Fahrt (nach Tipp auf eine Abfahrt).
  Trip? _trip;
  bool _loadingTrip = false;

  /// Ab dieser Zoomstufe werden Haltestellen geladen (sonst zu viele).
  static const _minZoom = 14.5;

  /// Ab dieser Zoomstufe jeder Steig einzeln statt einer Haltestelle – erst
  /// nah am Straßenraum, sonst liegen die Schilder übereinander.
  static const _platformZoom = 17.5;

  /// Höchstens so viele Haltestellen je Abfrage.
  static const _limit = 60;
  bool _detail = false;

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

  static const _dist = Distance();

  /// Haltestellen im Ausschnitt. Liegt er in einem schon abgefragten Kreis,
  /// geschieht nichts; sonst wird ein etwas größerer Kreis geladen (höchstens
  /// 3 km), damit kleine Verschiebungen nicht gleich wieder nachladen.
  Future<void> _loadStops() async {
    final cam = _map.camera;
    if (cam.zoom < _minZoom) {
      if (_stopsFailed) setState(() => _stopsFailed = false);
      return;
    }
    final center = cam.center;
    final need = _dist.as(LengthUnit.Meter, center, cam.visibleBounds.northEast);
    if (_covered.any((c) => _dist.as(LengthUnit.Meter, center, c.center) + need <= c.radius)) return;
    final seq = ++_stopsSeq;
    final radius = math.min(3000.0, math.max(need * 1.6, 800.0));
    setState(() => _loadingStops = true);
    try {
      final p = ref.read(transitProvider);
      final at = (lat: center.latitude, lon: center.longitude);
      final results = await Future.wait([
        p.searchLocations('', near: at, limit: _limit, radiusMeters: radius.round()),
        p.platformsNear(at, radiusMeters: radius.round()).catchError((Object _) => <Platform>[]),
      ]);
      if (!mounted) return;
      final stops = (results[0] as List<Location>).where((l) => l.lat != null).toList();
      // Volle Liste: Weiter außen fehlen womöglich Haltestellen – als
      // abgedeckt gilt dann nur der Kreis bis zur nächstgelegenen Hälfte.
      var covered = radius;
      if (stops.length >= _limit) {
        final d = [for (final s in stops) _dist.as(LengthUnit.Meter, center, LatLng(s.lat!, s.lon!))]..sort();
        covered = d[d.length ~/ 2];
      }
      setState(() {
        for (final s in stops) {
          _stopById[stopAreaId(s.id)] = s;
        }
        for (final pf in results[1] as List<Platform>) {
          _platformById[pf.id] = pf;
        }
        _covered.add((center: center, radius: covered));
        _stopsFailed = false;
      });
    } catch (_) {
      // Netz weg: vorhandene Haltestellen bleiben stehen, Hinweis zum Wiederholen.
      if (mounted && seq == _stopsSeq) setState(() => _stopsFailed = true);
    } finally {
      if (mounted && seq == _stopsSeq) setState(() => _loadingStops = false);
    }
  }

  /// Für Bildschirmfotos: auf Zoomstufe [zoom] springen und nachladen.
  @visibleForTesting
  void debugZoom(double zoom) {
    _map.move(_map.camera.center, zoom);
    _scheduleStops();
  }

  Future<void> _showStop(Location stop, {Platform? platform}) async {
    final d = await showModalBottomSheet<Departure>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _StopSheet(stop: stop, platform: platform),
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
        _map.fitCamera(
          CameraFit.coordinates(coordinates: pts, padding: const EdgeInsets.fromLTRB(40, 80, 40, 180), maxZoom: 16),
        );
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
    if (mounted) Navigator.of(context).push(MaterialPageRoute(settings: const RouteSettings(name: 'fahrt'), builder: (_) => const TripScreen()));
  }

  /// Haltestellen an der Mitte ihrer Steige; nah herangezoomt jeder Steig
  /// einzeln mit Nummer. Haltestellen ohne bekannte Steige an der
  /// TRIAS-Position.
  List<Marker> _stopMarkers(Color color) {
    if (_tooFar) return const [];
    // Nur, was im Ausschnitt (mit etwas Rand) liegt – der Vorrat wächst mit
    // jedem Verschieben.
    final b = _bounds;
    bool inView(double lat, double lon) {
      if (b == null) return true;
      final dLat = (b.north - b.south) * 0.3, dLon = (b.east - b.west) * 0.3;
      return lat >= b.south - dLat && lat <= b.north + dLat && lon >= b.west - dLon && lon <= b.east + dLon;
    }

    final byStop = <String, List<Platform>>{};
    for (final p in _platformById.values) {
      if (inView(p.lat, p.lon)) byStop.putIfAbsent(p.stopId, () => []).add(p);
    }
    final names = {
      for (final e in _stopById.entries)
        if (inView(e.value.lat!, e.value.lon!)) e.key: e.value,
    };
    final out = <Marker>[];
    final ids = {...names.keys, ...byStop.keys};
    for (final id in ids) {
      final pf = byStop[id] ?? const <Platform>[];
      final stop =
          names[id] ??
          Location(id: id, providerId: 'vrr-efa', name: pf.first.direction ?? 'Haltestelle', type: LocationType.stop);
      if (_detail && pf.isNotEmpty) {
        for (final p in pf) {
          out.add(
            Marker(
              point: LatLng(p.lat, p.lon),
              width: 34,
              height: 24,
              child: GestureDetector(
                onTap: () => _showStop(stop, platform: p),
                // Ohne Nummer (etwa Schwebebahn-Richtungen) ein Punkt.
                child: p.name == null ? _StopMarker(color: color, small: true) : _PlatformMarker(label: p.name!, color: color),
              ),
            ),
          );
        }
        continue;
      }
      if (pf.isEmpty) {
        if (stop.lat == null || stop.lon == null) continue;
        out.add(_stopMarker(LatLng(stop.lat!, stop.lon!), stop, color));
        continue;
      }
      // Zusammengefasst nur, was nah beieinanderliegt – sonst stand das
      // Zeichen zwischen zwei Straßen. Große Haltestellen großzügiger.
      for (final group in clusterPlatforms(pf)) {
        final lat = group.map((p) => p.lat).reduce((a, b) => a + b) / group.length;
        final lon = group.map((p) => p.lon).reduce((a, b) => a + b) / group.length;
        out.add(_stopMarker(LatLng(lat, lon), stop, color));
      }
    }
    return out;
  }

  Marker _stopMarker(LatLng at, Location stop, Color color) => Marker(
        point: at,
        width: 28,
        height: 28,
        child: GestureDetector(
          onTap: () => _showStop(stop),
          child: _StopMarker(color: color),
        ),
      );

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
        : [
            for (final s in tripStops)
              if (s.stop.lat != null) LatLng(s.stop.lat!, s.stop.lon!),
          ];

    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _me ?? _fallback,
            initialZoom: 15.5,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            // Auch Bewegungen per Knopf (Zentrieren, Fahrt zeigen) laden nach.
            onPositionChanged: (camera, gesture) {
              _scheduleStops();
              setState(() {
                _bounds = camera.visibleBounds;
                _detail = camera.zoom >= _platformZoom;
                _tooFar = camera.zoom < _minZoom;
              });
            },
            onMapReady: _scheduleStops,
          ),
          children: [
            TileLayer(urlTemplate: tileUrl, userAgentPackageName: 'de.gleichda.app', maxZoom: 19),
            if (tripLine.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: tripLine,
                    color: color,
                    strokeWidth: 5,
                    borderColor: c.surface,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                ..._stopMarkers(c.accent),
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
              ],
            ),
            const MapCredit(),
          ],
        ),
        // Oben: Titel und Hinweis, rechts Zentrieren.
        Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(text: 'Karte', bold: true),
                    // Nachladen am Rand läuft still – nur solange noch gar nichts
                    // da ist, steht ein Hinweis.
                    if (_loadingTrip || (_loadingStops && _stopById.isEmpty))
                      const _Pill(text: 'Wird geladen …')
                    else if (_tooFar)
                      const _Pill(text: 'Hineinzoomen für Haltestellen')
                    else if (_stopsFailed)
                      GestureDetector(
                        onTap: _loadStops,
                        child: const _Pill(text: 'Haltestellen nicht geladen · erneut laden'),
                      ),
                  ],
                ),
              ),
              MapButton(
                icon: Icons.my_location,
                tooltip: 'Auf mich zentrieren',
                onTap: () => _me == null ? _locate() : _map.move(_me!, math.max(_map.camera.zoom, 16)),
              ),
            ],
          ),
        ),
        // Unten: gewählte Fahrt.
        if (trip != null && leg != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            // Von unten hereinschieben, je Fahrt neu.
            child: TweenAnimationBuilder<double>(
              key: ValueKey(trip.id),
              tween: Tween(begin: 1, end: 0),
              duration: Motion.of(context, Motion.medium),
              curve: Motion.curve,
              builder: (context, v, child) => Opacity(
                opacity: 1 - v,
                child: FractionalTranslation(translation: Offset(0, v * 0.6), child: child),
              ),
              child: Material(
                color: c.surface,
                elevation: 2,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(Radii.card),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                  child: Row(
                    children: [
                      LineBadge(leg.line),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OneLine(
                              'Richtung ${leg.direction ?? trip.destination.label}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            OneLine(
                              '${tripStops.length} Halte ab ${trip.origin.label}',
                              style: TextStyle(fontSize: 13, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                      TextButton(onPressed: _openTrip, child: const Text('Fahrtverlauf')),
                      IconButton(
                        tooltip: 'Fahrt ausblenden',
                        icon: Icon(Icons.close, size: 20, color: c.muted),
                        onPressed: () => setState(() => _trip = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StopMarker extends StatelessWidget {
  const _StopMarker({required this.color, this.small = false});

  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: small ? 16 : 20,
      height: small ? 16 : 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.c.surface,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
      ),
      child: Text(
        'H',
        textScaler: TextScaler.noScaling,
        style: TextStyle(fontSize: small ? 8 : 10, fontWeight: FontWeight.w700, color: color, height: 1),
      ),
    ),
  );
}

/// Einzelner Steig: kleines Schild mit Nummer.
class _PlatformMarker extends StatelessWidget {
  const _PlatformMarker({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: context.c.surface, width: 1.5),
      ),
      child: Text(
        label.length > 4 ? label.substring(0, 4) : label,
        textScaler: TextScaler.noScaling,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, height: 1),
      ),
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
      child: Text(
        text,
        style: TextStyle(
          fontSize: bold ? 16 : 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: bold ? c.ink : c.muted,
        ),
      ),
    );
  }
}

/// Abfahrten einer Haltestelle von unten; Tipp auf eine Abfahrt gibt sie
/// an die Karte zurück.
class _StopSheet extends ConsumerStatefulWidget {
  const _StopSheet({required this.stop, this.platform});

  final Location stop;

  /// Nur Abfahrten dieses Steigs (nach Tipp auf einen einzelnen Steig).
  final Platform? platform;

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
      // Steiggenau über die volle Steigkennung („de:05124:11376:91:2“): Die
      // Nummer allein ist nicht eindeutig – am Hbf gibt es Steig 2 am
      // Busbahnhof (…:2:2) und an der Straße (…:91:2).
      final p = widget.platform;
      final b = await ref
          .read(transitProvider)
          .departures(p == null ? widget.stop : widget.stop.copyWith(id: p.id), limit: 12);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SheetHeader(
                widget.platform?.name == null
                    ? widget.stop.label
                    : '${widget.stop.label} · Steig ${widget.platform!.name}',
                done: 'Schließen',
              ),
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
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final d in board.departures)
                          DepartureRow(d, now: now, onSelect: (d) => Navigator.pop(context, d)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Steige einer Haltestelle, die auf der Karte zu einem Zeichen werden:
/// verbunden ist, was höchstens [near] Meter auseinanderliegt (über
/// Zwischenstationen hinweg). Ab [bigFrom] Steigen gilt die Haltestelle als
/// groß – dort reicht [nearBig], damit ein Busbahnhof ein Zeichen bleibt.
@visibleForTesting
List<List<Platform>> clusterPlatforms(List<Platform> pf,
    {double near = 40, double nearBig = 150, int bigFrom = 6}) {
  const d = Distance();
  final limit = pf.length >= bigFrom ? nearBig : near;
  final group = List<int>.generate(pf.length, (i) => i);
  int root(int i) => group[i] == i ? i : group[i] = root(group[i]);
  for (var i = 0; i < pf.length; i++) {
    for (var j = i + 1; j < pf.length; j++) {
      if (d.as(LengthUnit.Meter, LatLng(pf[i].lat, pf[i].lon), LatLng(pf[j].lat, pf[j].lon)) <= limit) {
        group[root(i)] = root(j);
      }
    }
  }
  final out = <int, List<Platform>>{};
  for (var i = 0; i < pf.length; i++) {
    out.putIfAbsent(root(i), () => []).add(pf[i]);
  }
  return out.values.toList();
}
