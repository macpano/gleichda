import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/transit_provider.dart';
import '../../data/walk_route.dart';
import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../../state/compass.dart';
import '../../state/location.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../trip_map.dart' show MapButton, MapCredit;
import '../widgets.dart';
import '../base_map.dart';

/// Kartenkacheln: FOSSGIS (tile.openstreetmap.de). Der Kachelserver von
/// openstreetmap.org selbst darf von Apps nicht dauerhaft genutzt werden.
// TODO: Kachelanbieter endgültig festlegen (offene Entscheidung im Konzept).
const tileUrl = 'https://tile.openstreetmap.de/{z}/{x}/{y}.png';

/// „Letzte Meter“: Karte mit Standort, Ziel-Steig und Richtung.
class WalkScreen extends ConsumerStatefulWidget {
  const WalkScreen({super.key, required this.target, this.platform, this.departure, this.origin});

  final Location target;

  /// Beim Umsteigen: der Ankunftshalt. Ist man noch weit weg, zeigt die
  /// Ansicht den Umsteigeweg von dort statt einer Führung vom Standort.
  final Location? origin;

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

  /// Gehweg zum Steig; neu berechnet, wenn man mehr als 35 m davon abweicht.
  WalkRoute? _route;
  DateTime? _routedAt;
  bool _routing = false;

  /// Zuletzt erreichter Wegpunkt; gesucht wird nur vorwärts.
  int _routeIndex = 0;

  /// Karte folgt der eigenen Position (nach „Zentrieren“), bis man sie selbst
  /// verschiebt.
  bool _follow = false;

  /// Blickrichtung aus dem Kompass (0 = Norden), geglättet; null ohne Sensor.
  double? _heading;
  StreamSubscription<double>? _compassSub;

  /// Beim Folgen dreht sich die Karte mit der Blickrichtung; der
  /// Kompassknopf stellt Norden wieder nach oben.
  bool _headingUp = true;

  void _center() {
    final p = _pos;
    if (p == null) return;
    setState(() => _follow = true);
    _map.moveAndRotate(
      LatLng(p.latitude, p.longitude),
      math.max(_map.camera.zoom, 17.5),
      _headingUp && _heading != null ? -_heading! : 0,
    );
  }

  void _onHeading(double raw) {
    final prev = _heading;
    final next = prev == null ? raw : smoothHeading(prev, raw);
    // Kleine Zitterbewegungen nicht zeichnen.
    if (prev != null && (((next - prev + 540) % 360) - 180).abs() < 1.5) return;
    setState(() => _heading = next);
    if (_follow && _headingUp) {
      try {
        _map.rotate(-next);
      } catch (_) {
        // Karte noch nicht bereit.
      }
    }
  }

  void _toggleNorth() {
    setState(() => _headingUp = !_headingUp);
    try {
      _map.rotate(_headingUp && _follow && _heading != null ? -_heading! : 0);
    } catch (_) {}
  }

  /// Mehr als 2 km entfernt: keine Führung vom Standort (sonst „333 min zu
  /// Fuß“ beim Blick auf einen späteren Umstieg), sondern eine Vorschau.
  static const _farMeters = 2000.0;

  bool get _far {
    final t = _target, p = _pos;
    return t != null && p != null && _dist(p.latitude, p.longitude, t.lat, t.lon) > _farMeters;
  }

  /// Umsteigeweg vom Ankunftshalt zum Steig, solange man weit weg ist.
  WalkRoute? _preview;
  bool _previewTried = false;

  Future<void> _loadPreview() async {
    final o = widget.origin, t = _target;
    if (_previewTried || o?.lat == null || t == null) return;
    _previewTried = true;
    try {
      final r = await ref.read(walkRouterProvider).route((lat: o!.lat!, lon: o.lon!), (lat: t.lat, lon: t.lon));
      if (mounted && r != null) {
        setState(() => _preview = r);
        _fitted = false;
        _fit();
      }
    } on ProviderException {
      // Ohne Router: nur die Steige auf der Karte.
    }
  }

  Future<void> _maybeRoute() async {
    final t = _target, p = _pos;
    if (t == null || p == null || _routing) return;
    if (_far) {
      await _loadPreview();
      return;
    }
    final here = (lat: p.latitude, lon: p.longitude);
    final r = _route;
    final off = r == null ? double.infinity : r.locate(here, from: _routeIndex).off;
    final recent = _routedAt != null && DateTime.now().difference(_routedAt!) < const Duration(seconds: 10);
    if (off <= 25 || (r != null && recent)) return;
    _routing = true;
    try {
      final route = await ref.read(walkRouterProvider).route(here, (lat: t.lat, lon: t.lon));
      if (mounted && route != null) {
        setState(() {
          _route = route;
          _routeIndex = 0;
        });
      }
    } on ProviderException {
      // Ohne Router bleibt die Luftlinie.
    } finally {
      _routing = false;
      _routedAt = DateTime.now();
    }
  }

  static IconData _maneuverIcon(WalkStep s) => switch ((s.type, s.modifier)) {
        ('arrive', _) => Icons.place_outlined,
        (_, 'left') => Icons.turn_left,
        (_, 'right') => Icons.turn_right,
        (_, 'slight left') => Icons.turn_slight_left,
        (_, 'slight right') => Icons.turn_slight_right,
        (_, 'sharp left') => Icons.turn_sharp_left,
        (_, 'sharp right') => Icons.turn_sharp_right,
        (_, 'uturn') => Icons.u_turn_left,
        _ => Icons.straight,
      };

  @override
  void initState() {
    super.initState();
    _loadPlatforms();
    _startLocation();
    _compassSub = compassHeadings().listen(_onHeading);
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadPlatforms() async {
    try {
      final list = await ref.read(transitProvider).platforms(widget.target);
      if (!mounted) return;
      // Zuerst der genaue Haltepunkt der Fahrt („de:05124:11376:98:4“ =
      // Gleis 4). Erst danach die Nummer allein: Am Hbf gibt es Bussteig 4
      // und Gleis 4, die Nummer führte zum Bus nach Lüttringhausen statt zur S8.
      final tg = widget.target;
      Platform? t = list.where((p) => p.id == tg.id).firstOrNull;
      if (t == null && tg.id.split(':').length >= 5 && tg.lat != null) {
        t = Platform(id: tg.id, stopId: tg.id, name: widget.platform, lat: tg.lat!, lon: tg.lon!);
      }
      if (t == null && widget.platform != null) {
        t = list.where((p) => p.name == widget.platform).firstOrNull;
      }
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
      _maybeRoute();
    } on ProviderException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// Sofort loslegen: nur die Erlaubnis prüfen, die zuletzt bekannte
  /// Position zeigen und den Positionsstrom starten. Vorher wartete die
  /// Ansicht auf einen frischen, genauen GPS-Fix (bis zu 12 s), bevor sie
  /// überhaupt etwas zeigte.
  Future<void> _startLocation() async {
    final loc = ref.read(locationServiceProvider);
    try {
      await loc.ensureAllowed();
    } on LocationException catch (e) {
      if (mounted) setState(() => _error = e.message);
      return;
    }
    void take(Position p) {
      if (!mounted) return;
      setState(() => _pos = p);
      _fit();
      if (_follow) _map.move(LatLng(p.latitude, p.longitude), _map.camera.zoom);
      _maybeRoute();
    }

    _sub = loc.watch().listen(take, onError: (Object _) {});
    final last = await loc.lastKnown();
    if (last != null && _pos == null) take(last);
  }

  void _fit() {
    if (_fitted || _target == null) return;
    final o = widget.origin;
    final pts = _far
        ? [
            LatLng(_target!.lat, _target!.lon),
            if (_preview != null) for (final q in _preview!.points) LatLng(q.lat, q.lon),
            if (_preview == null && o?.lat != null) LatLng(o!.lat!, o.lon!),
          ]
        : [LatLng(_target!.lat, _target!.lon), if (_pos != null) LatLng(_pos!.latitude, _pos!.longitude)];
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
    // Blickrichtung: Kompass, sonst beim Gehen der GPS-Kurs.
    final facing = _heading ?? (p != null && p.speed > 0.6 && p.heading > 0 ? p.heading : null);
    double? dist;
    String? direction;
    double? bearing;
    // Weit weg: Vorschau des Umsteigewegs statt Führung.
    final far = _far;
    // Mit Gehweg: Restweg entlang des Wegs und das nächste Abbiegen.
    final route = far ? _preview : _route;
    final at = !far && route != null && p != null
        ? route.locate((lat: p.latitude, lon: p.longitude), from: _routeIndex)
        : null;
    if (at != null && at.off < 40) _routeIndex = at.index;
    final turn = at == null ? null : route!.nextStep(at.index);
    final o = widget.origin;
    if (far && t != null && p != null) {
      final away = _dist(p.latitude, p.longitude, t.lat, t.lon);
      dist = route?.meters ?? (o?.lat != null ? _dist(o!.lat!, o.lon!, t.lat, t.lon) : away);
      direction = o != null ? 'Umsteigeweg ab ${o.label}' : 'Noch ${distanceText(away)} entfernt';
    } else if (t != null && p != null) {
      dist = at != null ? route!.remainingFrom(at.index) + at.off : _dist(p.latitude, p.longitude, t.lat, t.lon);
      bearing = _bearing(p.latitude, p.longitude, t.lat, t.lon);
      direction = turn != null
          ? (turn.step.type == 'arrive'
              ? 'Ziel in ${distanceText(turn.meters)}'
              : 'In ${distanceText(turn.meters)}: ${turn.step.text}')
          : facing != null
              ? _relative(bearing, facing)
              : 'Richtung ${_compass(bearing)}';
    }
    // Gehzeit: Weg (sonst Luftlinie × 1,3) bei 1,3 m/s, angepasst an die
    // Gehgeschwindigkeit.
    final walkMinutes = dist == null || (far && o == null)
        ? null
        : ((at != null || (far && route != null) ? dist : dist * 1.3) / (1.3 * settings.walkPace.walkPercent / 100) / 60)
            .ceil();
    final dep = widget.departure?.best;
    final leave = (!far && dep != null && walkMinutes != null)
        ? dep.subtract(Duration(minutes: walkMinutes)).difference(now).inMinutes
        : null;
    final platformName = t?.name ?? widget.platform;
    final headerTitle = platformName != null ? 'Zu Steig $platformName' : 'Zur Haltestelle';
    final minutesLeft = dep?.difference(now).inMinutes;
    final arrow = facing != null && bearing != null ? bearing - facing : bearing;
    final instruction = dist == null
        ? (_error ?? 'Standort wird ermittelt')
        : direction![0].toUpperCase() + direction.substring(1);
    final hint = [
      if (t?.direction != null) '${platformName != null ? 'Steig $platformName' : 'Der Halt'} fährt Richtung ${t!.direction}.',
      if (far)
        [
          if (walkMinutes != null) 'Etwa $walkMinutes min vom Ankunfts- zum Abfahrtssteig.',
          'Die Führung startet, wenn du in der Nähe bist.',
        ].join(' ')
      else if (leave != null)
        leave <= 0 ? 'Jetzt loslaufen, $walkMinutes min zu Fuß.' : 'Loslaufen in $leave min, $walkMinutes min zu Fuß.'
      else if (walkMinutes != null)
        route != null ? 'Etwa $walkMinutes min zu Fuß.' : 'Etwa $walkMinutes min zu Fuß, gepunktet die Luftlinie.',
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
                        onPositionChanged: (_, gesture) {
                          if (gesture && _follow) setState(() => _follow = false);
                        },
                      ),
                      children: [
                        const BaseMapLayer(),
                        if (route != null)
                          PolylineLayer(polylines: [
                            Polyline(
                              points: [for (final q in route.points) LatLng(q.lat, q.lon)],
                              color: c.accent,
                              strokeWidth: 5,
                              borderColor: c.surface,
                              borderStrokeWidth: 1.5,
                            ),
                          ])
                        else if (p != null)
                          PolylineLayer(polylines: [
                            Polyline(
                              points: [LatLng(p.latitude, p.longitude), LatLng(t.lat, t.lon)],
                              color: c.accent,
                              strokeWidth: 4,
                              pattern: StrokePattern.dotted(),
                            ),
                          ]),
                        // Steigschilder bleiben beim Drehen der Karte aufrecht.
                        // Nur der Steig, zu dem es geht – andere Steige und
                        // Haltestellen lenken in der Navigation nur ab.
                        MarkerLayer(rotate: true, markers: [
                          Marker(
                            point: LatLng(t.lat, t.lon),
                            width: 30,
                            height: 30,
                            child: _PlatformDot(label: platformName ?? 'H', color: c.onAccent, bg: c.accent, big: true),
                          ),
                        ]),
                        // Eigener Pfeil: dreht mit der Karte, zeigt also immer
                        // in die echte Blickrichtung.
                        MarkerLayer(markers: [
                          if (p != null)
                            Marker(
                              point: LatLng(p.latitude, p.longitude),
                              width: 34,
                              height: 34,
                              // Pfeil in Blickrichtung (Kompass, sonst GPS-Kurs
                              // beim Gehen), ohne beides ein Punkt.
                              child: facing != null
                                  ? Transform.rotate(
                                      angle: facing * math.pi / 180,
                                      child: const Icon(Icons.navigation, size: 30, color: Color(0xFF1D5FD1),
                                          shadows: [Shadow(color: Colors.white, blurRadius: 3)]),
                                    )
                                  : Center(
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D5FD1),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                        ),
                                      ),
                                    ),
                            ),
                        ]),
                        const MapCredit(),
                        // Auf die eigene Position zentrieren und ihr folgen.
                        if (p != null)
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                MapButton(
                                  icon: _follow ? Icons.my_location : Icons.location_searching,
                                  tooltip: 'Auf mich zentrieren',
                                  active: _follow,
                                  onTap: _center,
                                ),
                                // Kompass: Blickrichtung oben ↔ Norden oben.
                                if (_heading != null) ...[
                                  const SizedBox(height: 10),
                                  MapButton(
                                    icon: _headingUp ? Icons.explore : Icons.explore_outlined,
                                    tooltip: _headingUp ? 'Norden oben' : 'Blickrichtung oben',
                                    active: _headingUp,
                                    onTap: _toggleNorth,
                                  ),
                                ],
                              ]),
                            ),
                          ),
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
                child: far
                    ? Icon(Icons.transfer_within_a_station, size: 28, color: c.ink)
                    : turn != null
                    ? Icon(_maneuverIcon(turn.step), size: 30, color: c.ink)
                    : arrow == null
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
                      style: context.t.time(26).copyWith(color: c.ink)),
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
                      shape: buttonShape(context),
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
                      shape: buttonShape(context),
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
