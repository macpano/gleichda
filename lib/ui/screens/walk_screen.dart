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
    final headerTitle = platformName != null ? 'Zu Steig $platformName' : 'Zur Haltestelle';
    final minutesLeft = dep?.difference(now).inMinutes;
    final arrow = p != null && p.speed > 0.6 && p.heading > 0 && bearing != null ? bearing - p.heading : bearing;
    final instruction = dist == null
        ? (_error ?? 'Standort wird ermittelt')
        : direction![0].toUpperCase() + direction.substring(1);
    final hint = [
      if (t?.direction != null) '${platformName != null ? 'Steig $platformName' : 'Der Halt'} fährt Richtung ${t!.direction}.',
      if (leave != null)
        leave <= 0 ? 'Jetzt loslaufen, $walkMinutes min zu Fuß.' : 'Loslaufen in $leave min, $walkMinutes min zu Fuß.'
      else if (walkMinutes != null)
        'Etwa $walkMinutes min zu Fuß, gepunktet die Luftlinie.',
    ].join(' ');
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(children: [
        Container(
          color: c.bar,
          padding: EdgeInsets.fromLTRB(Space.page, MediaQuery.of(context).padding.top, Space.page, 0),
          child: SubpageHeader(
            title: headerTitle,
            backLabel: 'Fahrt',
            trailing: minutesLeft == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('$minutesLeft min',
                        style: context.t.time(15).copyWith(color: leave != null && leave <= 0 ? c.orange : c.muted)),
                  ),
          ),
        ),
        Divider(height: 1, color: c.hair),
        Expanded(
          child: t == null && _platforms == null
              ? Center(child: Text(_error ?? 'Steig wird gesucht …', style: TextStyle(color: c.muted)))
              : t == null
                  ? Center(child: Text('Genaue Position unbekannt.', style: TextStyle(color: c.muted)))
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
                                width: 24,
                                height: 24,
                                child: _PlatformDot(label: o.name ?? '', color: c.muted, bg: c.surface),
                              ),
                          Marker(
                            point: LatLng(t.lat, t.lon),
                            width: 30,
                            height: 30,
                            child: _PlatformDot(label: platformName ?? 'H', color: c.onAccent, bg: c.accent, big: true),
                          ),
                          if (p != null)
                            Marker(
                              point: LatLng(p.latitude, p.longitude),
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
                        const SimpleAttributionWidget(source: Text('OpenStreetMap-Mitwirkende')),
                      ],
                    ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(top: BorderSide(color: c.hair)),
          ),
          padding: EdgeInsets.fromLTRB(16, 18, 16, 16 + MediaQuery.of(context).padding.bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(Radii.card)),
                child: arrow == null
                    ? Icon(Icons.near_me_outlined, color: c.muted)
                    : Transform.rotate(
                        angle: arrow * math.pi / 180,
                        child: Icon(Icons.arrow_upward_rounded, size: 30, color: c.ink),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FadeText(dist == null ? '– m' : distanceText(dist),
                      style: context.t.time(28).copyWith(fontWeight: FontWeight.w700, color: c.ink)),
                  OneLine(instruction, style: TextStyle(fontSize: 16, color: c.ink2)),
                ]),
              ),
            ]),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(hint, style: TextStyle(fontSize: 15, height: 1.4, color: leave != null && leave <= 0 ? c.orange : c.muted)),
            ],
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: c.onAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: t == null
                        ? null
                        : () {
                            _fitted = false;
                            _fit();
                          },
                    child: const Text('Steig zeigen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: c.fill,
                      foregroundColor: c.ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: t == null
                        ? null
                        : () => launchUrl(
                              Uri.parse('geo:${t.lat},${t.lon}?q=${t.lat},${t.lon}(${Uri.encodeComponent(headerTitle)})'),
                              mode: LaunchMode.externalApplication,
                            ),
                    child: const Text('In Karten öffnen', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ]),
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
