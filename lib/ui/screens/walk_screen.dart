import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/transit_provider.dart';
import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../../state/location.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

/// Kartenkacheln: FOSSGIS (tile.openstreetmap.de). Der Kachelserver von
/// openstreetmap.org selbst darf von Apps nicht dauerhaft genutzt werden.
// TODO: Kachelanbieter endgültig festlegen (offene Entscheidung im Konzept).
const tileUrl = 'https://tile.openstreetmap.de/{z}/{x}/{y}.png';

/// „Letzte Meter“: Karte mit Standort, Ziel-Steig und Richtung.
class WalkScreen extends ConsumerStatefulWidget {
  const WalkScreen({super.key, required this.target, this.platform, this.departure});

  final Location target;

  /// Steigbezeichnung aus der Fahrt, z. B. „2“.
  final String? platform;
  final EventTime? departure;

  @override
  ConsumerState<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends ConsumerState<WalkScreen> {
  List<Platform>? _platforms;
  Platform? _target;
  Position? _pos;
  String? _error;
  StreamSubscription<Position>? _sub;
  final _map = MapController();
  bool _fitted = false;

  @override
  void initState() {
    super.initState();
    _loadPlatforms();
    _startLocation();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadPlatforms() async {
    try {
      final list = await ref.read(transitProvider).platforms(widget.target);
      if (!mounted) return;
      Platform? t;
      if (widget.platform != null) {
        t = list.where((p) => p.name == widget.platform).firstOrNull;
      }
      t ??= list.where((p) => p.id == widget.target.id).firstOrNull;
      if (t == null && widget.target.lat != null && list.isNotEmpty) {
        final tl = widget.target;
        t = list.reduce((a, b) =>
            _dist(a.lat, a.lon, tl.lat!, tl.lon!) <= _dist(b.lat, b.lon, tl.lat!, tl.lon!) ? a : b);
      }
      t ??= list.firstOrNull;
      if (t == null && widget.target.lat != null) {
        t = Platform(id: widget.target.id, stopId: widget.target.id, lat: widget.target.lat!, lon: widget.target.lon!);
      }
      setState(() {
        _platforms = list;
        _target = t;
      });
      _fit();
    } on ProviderException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _startLocation() async {
    try {
      await ref.read(locationServiceProvider).current();
      _sub = ref.read(locationServiceProvider).watch().listen((p) {
        if (!mounted) return;
        setState(() => _pos = p);
        _fit();
      });
    } on LocationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _fit() {
    if (_fitted || _target == null) return;
    final pts = [LatLng(_target!.lat, _target!.lon), if (_pos != null) LatLng(_pos!.latitude, _pos!.longitude)];
    try {
      if (pts.length == 1) {
        _map.move(pts.first, 17);
      } else {
        _map.fitCamera(CameraFit.coordinates(coordinates: pts, padding: const EdgeInsets.all(60), maxZoom: 18));
        _fitted = true;
      }
    } catch (_) {
      // Karte noch nicht bereit; nächster Versuch mit der nächsten Position.
    }
  }

  static double _dist(double lat1, double lon1, double lat2, double lon2) =>
      Geolocator.distanceBetween(lat1, lon1, lat2, lon2);

  static double _bearing(double lat1, double lon1, double lat2, double lon2) =>
      (Geolocator.bearingBetween(lat1, lon1, lat2, lon2) + 360) % 360;

  static String _compass(double deg) {
    const names = ['Norden', 'Nordosten', 'Osten', 'Südosten', 'Süden', 'Südwesten', 'Westen', 'Nordwesten'];
    return names[((deg + 22.5) % 360 ~/ 45)];
  }

  /// Richtung relativ zur Gehrichtung, wenn sie bekannt ist.
  static String _relative(double bearing, double heading) {
    final d = ((bearing - heading + 540) % 360) - 180;
    if (d.abs() < 20) return 'geradeaus';
    if (d.abs() > 150) return 'hinter dir';
    final side = d > 0 ? 'rechts' : 'links';
    return d.abs() < 60 ? 'schräg $side' : side;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final t = _target;
    final p = _pos;
    double? dist;
    String? direction;
    double? bearing;
    if (t != null && p != null) {
      dist = _dist(p.latitude, p.longitude, t.lat, t.lon);
      bearing = _bearing(p.latitude, p.longitude, t.lat, t.lon);
      direction = p.speed > 0.6 && p.heading > 0 ? _relative(bearing, p.heading) : 'Richtung ${_compass(bearing)}';
    }
    // Gehzeit: Luftlinie × 1,3 bei 1,3 m/s, angepasst an die Gehgeschwindigkeit.
    final walkMinutes = dist == null ? null : (dist * 1.3 / (1.3 * settings.walkPace.walkPercent / 100) / 60).ceil();
    final dep = widget.departure?.best;
    final leave = (dep != null && walkMinutes != null)
        ? dep.subtract(Duration(minutes: walkMinutes)).difference(now).inMinutes
        : null;
    final platformName = t?.name ?? widget.platform;
    final title = [
      if (platformName != null) 'Steig $platformName' else widget.target.name,
      if (t?.direction != null) 'Richtung ${t!.direction}',
    ].join(' – ');

    return Scaffold(
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(Space.page, MediaQuery.of(context).padding.top + 8, Space.page, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SubpageHeader(title: 'Weg zum Steig', backLabel: 'Fahrt'),
            OneLine(widget.target.name, style: TextStyle(fontSize: 15, color: c.muted)),
            OneLine(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(children: [
              if (bearing != null)
                Transform.rotate(
                  angle: (p!.speed > 0.6 && p.heading > 0 ? bearing - p.heading : bearing) * math.pi / 180,
                  child: Icon(Icons.navigation, size: 34, color: c.accent),
                )
              else
                SkeletonBlock(height: 34, width: 34, radius: 17),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FadeText(dist == null ? (_error ?? 'Standort wird ermittelt') : '${distanceText(dist)}, $direction',
                      style: context.t.time(17).copyWith(color: _error != null && dist == null ? c.orange : c.ink)),
                  FadeText(
                    leave == null
                        ? (walkMinutes == null ? '' : 'etwa $walkMinutes min zu Fuß')
                        : leave <= 0
                            ? 'Jetzt loslaufen · $walkMinutes min zu Fuß'
                            : 'Loslaufen in $leave min · $walkMinutes min zu Fuß',
                    style: context.t.number(14).copyWith(color: leave != null && leave <= 0 ? c.orange : c.muted),
                  ),
                ]),
              ),
            ]),
          ]),
        ),
        Expanded(
          child: t == null && _platforms == null
              ? Center(child: Text(_error ?? 'Steig wird gesucht …', style: TextStyle(color: c.muted)))
              : t == null
                  ? const Center(child: Text('Genaue Position unbekannt.'))
                  : FlutterMap(
                      mapController: _map,
                      options: MapOptions(
                        initialCenter: LatLng(t.lat, t.lon),
                        initialZoom: 17,
                        onMapReady: _fit,
                      ),
                      children: [
                        TileLayer(urlTemplate: tileUrl, userAgentPackageName: 'de.gleichda.app', maxZoom: 19),
                        if (p != null)
                          PolylineLayer(polylines: [
                            Polyline(
                              points: [LatLng(p.latitude, p.longitude), LatLng(t.lat, t.lon)],
                              color: c.accent,
                              strokeWidth: 4,
                              pattern: StrokePattern.dotted(),
                            ),
                          ]),
                        MarkerLayer(markers: [
                          for (final o in _platforms ?? const <Platform>[])
                            if (o.id != t.id)
                              Marker(
                                point: LatLng(o.lat, o.lon),
                                width: 26,
                                height: 26,
                                child: _PlatformDot(label: o.name ?? '', color: c.muted, bg: c.surface),
                              ),
                          Marker(
                            point: LatLng(t.lat, t.lon),
                            width: 40,
                            height: 40,
                            child: _PlatformDot(label: platformName ?? 'H', color: c.onAccent, bg: c.accent, big: true),
                          ),
                          if (p != null)
                            Marker(
                              point: LatLng(p.latitude, p.longitude),
                              width: 22,
                              height: 22,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: c.ink,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: c.surface, width: 3),
                                ),
                              ),
                            ),
                        ]),
                        const SimpleAttributionWidget(source: Text('© OpenStreetMap-Mitwirkende')),
                      ],
                    ),
        ),
        Container(
          color: c.bar,
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).padding.bottom),
          child: Row(children: [
            Expanded(
              child: Text('Gepunktet: Luftlinie. Andere Steige grau.',
                  style: TextStyle(fontSize: 13, color: c.muted)),
            ),
            if (t != null)
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse('geo:${t.lat},${t.lon}?q=${t.lat},${t.lon}(${Uri.encodeComponent(title)})'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text('In Karten-App'),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _PlatformDot extends StatelessWidget {
  const _PlatformDot({required this.label, required this.color, required this.bg, this.big = false});

  final String label;
  final Color color;
  final Color bg;
  final bool big;

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: big ? bg : color, width: 2),
        ),
        child: Text(label,
            maxLines: 1,
            style: TextStyle(fontSize: big ? 15 : 11, fontWeight: FontWeight.w700, color: color)),
      );
}
