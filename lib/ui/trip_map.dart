import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../domain/companion.dart';
import '../domain/connections.dart';
import '../domain/models.dart';
import '../domain/settings.dart';
import '../state/companion.dart';
import '../state/location.dart';
import '../state/providers.dart';
import 'screens/walk_screen.dart' show tileUrl;
import 'theme.dart';
import 'widgets.dart';

LatLng? _ll(StopTime s) => s.stop.lat == null || s.stop.lon == null ? null : LatLng(s.stop.lat!, s.stop.lon!);

/// Karte einer Verbindung: Linienwege in Linienfarbe, Fußwege gepunktet und –
/// wenn freigegeben – der eigene Standort. Während der Begleitung im
/// Fahrzeug ist der eigene Standort das Fahrzeug (Punkt in Linienfarbe).
///
/// Der VRR liefert keinen Linienverlauf (TRIAS ohne LegProjection, geprüft
/// 23.09.2026); die Linie verbindet deshalb die Haltestellen gerade.
class TripMap extends ConsumerStatefulWidget {
  const TripMap({super.key, required this.trip, required this.now, this.interactive = true});

  final Trip trip;
  final DateTime now;
  final bool interactive;

  @override
  ConsumerState<TripMap> createState() => _TripMapState();
}

class _TripMapState extends ConsumerState<TripMap> {
  final _map = MapController();
  StreamSubscription<Position>? _sub;
  LatLng? _me;

  @override
  void initState() {
    super.initState();
    _startLocation();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _startLocation() async {
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    if (!settings.useLocation) return;
    try {
      final loc = ref.read(locationServiceProvider);
      await loc.current();
      _sub = loc.watch().listen((p) {
        if (mounted) setState(() => _me = LatLng(p.latitude, p.longitude));
      });
    } catch (_) {
      // Ohne Standort zeigt die Karte nur Fahrt und Fahrzeug.
    }
  }

  List<LatLng> get _points => [
        for (final l in widget.trip.legs)
          for (final s in [l.from, ...l.intermediates, l.to]) ?_ll(s),
      ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final trip = widget.trip;
    final pts = _points;
    if (pts.length < 2) {
      return Container(
        color: c.fill,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Text('Karte folgt, sobald die Haltestellen geladen sind.',
            textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
      );
    }
    // Fahrzeug = eigene GPS-Position, wenn man mit „Losfahren“ in einem
    // Fahrzeug unterwegs ist (Fahrzeugdaten der Betriebe sind nicht offen).
    final companion = ref.watch(companionProvider);
    final following = companion.active && companion.tripId == trip.id;
    final me = _me == null ? null : (lat: _me!.latitude, lon: _me!.longitude);
    final step = following && me != null ? nextStep(trip, widget.now, gps: me) : null;
    final riding = step?.phase == CompanionPhase.onBoard ? step!.leg : null;
    // Linienwege aus der EFA; bis sie da sind (oder wo sie fehlen), verbindet
    // die Karte die Haltestellen gerade.
    final paths = ref.watch(legPathsProvider(TripPathKey(trip))).value;
    final walks = ref.watch(walkPathsProvider(WalkPathKey(trip))).value;
    final lines = <Polyline>[];
    final stops = <Marker>[];
    for (var i = 0; i < trip.legs.length; i++) {
      final l = trip.legs[i];
      final seq = [l.from, ...l.intermediates, l.to];
      final known = paths != null && i < paths.length ? paths[i] : null;
      final path = known != null
          ? [for (final p in known) LatLng(p.lat, p.lon)]
          : [for (final s in seq) ?_ll(s)];
      if (l.type != LegType.ride) {
        // Fußweg als Gehweg (FOSSGIS), bis er da ist gerade: vom Ende des
        // vorigen zum Anfang des nächsten Abschnitts, auch vom Start und
        // bis zur Zieladresse.
        final ends = walkEnds(trip, i);
        if (ends == null) continue;
        final walk = walks != null && i < walks.length ? walks[i] : null;
        final pts = walk != null && walk.length >= 2
            ? [for (final p in walk) LatLng(p.lat, p.lon)]
            : [LatLng(ends.$1.lat, ends.$1.lon), LatLng(ends.$2.lat, ends.$2.lon)];
        lines.add(Polyline(points: pts, color: c.walkText, strokeWidth: 4, pattern: StrokePattern.dotted()));
        // Start- bzw. Zieladresse als Punkt in Schrift­farbe.
        final end = i == 0 ? _ll(l.from) : (i == trip.legs.length - 1 ? _ll(l.to) : null);
        if (end != null && (i == 0 ? l.from : l.to).stop.type != LocationType.stop) {
          stops.add(Marker(
            point: end,
            width: 16,
            height: 16,
            child: Container(
              decoration: BoxDecoration(
                color: i == 0 ? c.surface : c.ink,
                shape: BoxShape.circle,
                border: Border.all(color: c.ink, width: 3),
              ),
            ),
          ));
        }
        continue;
      }
      final color = lineColor(context, l.line);
      if (path.length >= 2) {
        lines.add(Polyline(points: path, color: color, strokeWidth: 5, borderColor: c.surface, borderStrokeWidth: 1.5));
      }
      for (var k = 0; k < seq.length; k++) {
        final p = _ll(seq[k]);
        if (p == null) continue;
        final end = k == 0 || k == seq.length - 1;
        final passed = isPassed(seq[k], widget.now);
        stops.add(Marker(
          point: p,
          width: end ? 16 : 10,
          height: end ? 16 : 10,
          child: Container(
            decoration: BoxDecoration(
              color: passed && !end ? color : c.surface,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: end ? 3.5 : 2.5),
            ),
          ),
        ));
      }
    }

    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(coordinates: pts, padding: const EdgeInsets.all(40), maxZoom: 16),
        interactionOptions: InteractionOptions(
          flags: widget.interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(urlTemplate: tileUrl, userAgentPackageName: 'de.gleichda.app', maxZoom: 19),
        PolylineLayer(polylines: lines),
        MarkerLayer(markers: [
          ...stops,
          if (_me != null)
            Marker(
              point: _me!,
              width: 30,
              height: 30,
              child: riding != null
                  ? Center(child: PositionDot(color: lineColor(context, riding.line)))
                  : Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D5FD1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
            ),
        ]),
        const MapCredit(),
        if (widget.interactive && _me != null)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: MapButton(
                icon: Icons.my_location,
                tooltip: 'Auf mich zentrieren',
                onTap: () => _map.move(_me!, _map.camera.zoom < 15 ? 16 : _map.camera.zoom),
              ),
            ),
          ),
      ],
    );
  }
}

/// Karte der geöffneten Fahrt, bildschirmfüllend.
class TripMapScreen extends ConsumerWidget {
  const TripMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final s = ref.watch(lastTripProvider).value;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 8),
          child: const SubpageHeader(title: 'Karte', backLabel: 'Fahrt'),
        ),
        Divider(height: 1, color: c.hair),
        Expanded(
          child: s == null
              ? Center(child: Text('Keine Fahrt geöffnet.', style: TextStyle(color: c.muted)))
              : TripMap(trip: s.trip, now: now),
        ),
      ]),
    );
  }
}

/// Namensnennung der Karte: klein und zurückhaltend in der Ecke, aber immer
/// sichtbar (ODbL verlangt „© OpenStreetMap-Mitwirkende“).
class MapCredit extends StatelessWidget {
  const MapCredit({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text('© OpenStreetMap-Mitwirkende',
            textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 9, color: c.muted)),
      ),
    );
  }
}

/// Runder Knopf auf der Karte (z. B. „Auf mich zentrieren“).
class MapButton extends StatelessWidget {
  const MapButton({super.key, required this.icon, required this.onTap, this.tooltip, this.active = false});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surface,
      shape: CircleBorder(side: BorderSide(color: c.hair, width: 0.5)),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 21, color: active ? c.accent : c.ink)),
        ),
      ),
    );
  }
}
