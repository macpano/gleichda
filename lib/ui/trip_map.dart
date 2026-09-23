import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../domain/connections.dart';
import '../domain/models.dart';
import '../domain/settings.dart';
import '../state/location.dart';
import '../state/providers.dart';
import 'screens/walk_screen.dart' show tileUrl;
import 'theme.dart';
import 'widgets.dart';

/// Geschätzte Position eines Fahrzeugs auf einem Abschnitt: zwischen dem
/// zuletzt passierten und dem nächsten Halt, anteilig nach Zeit (Echtzeit,
/// sonst Fahrplan). Null, wenn der Abschnitt noch nicht begonnen hat oder
/// vorbei ist, oder Koordinaten fehlen.
({LatLng point, Leg leg})? estimateVehicle(Trip trip, DateTime now) {
  for (final l in trip.rides) {
    final stops = [l.from, ...l.intermediates, l.to];
    if (!isPassed(l.from, now) || isPassed(l.to, now)) continue;
    var k = 0;
    for (var i = 0; i < stops.length; i++) {
      if (isPassed(stops[i], now)) k = i;
    }
    if (k >= stops.length - 1) return null;
    final a = stops[k], b = stops[k + 1];
    if (a.stop.lat == null || b.stop.lat == null) return null;
    final t0 = (a.departure ?? a.arrival)?.best;
    final t1 = (b.arrival ?? b.departure)?.best;
    var f = 0.0;
    if (t0 != null && t1 != null && t1.isAfter(t0)) {
      f = (now.difference(t0).inSeconds / t1.difference(t0).inSeconds).clamp(0.0, 1.0);
    }
    return (
      point: LatLng(
        a.stop.lat! + (b.stop.lat! - a.stop.lat!) * f,
        a.stop.lon! + (b.stop.lon! - a.stop.lon!) * f,
      ),
      leg: l,
    );
  }
  return null;
}

LatLng? _ll(StopTime s) => s.stop.lat == null || s.stop.lon == null ? null : LatLng(s.stop.lat!, s.stop.lon!);

/// Karte einer Verbindung: Linien in Linienfarbe über die Haltestellen,
/// Fußwege gepunktet, das Fahrzeug an der geschätzten Position und – wenn
/// freigegeben – der eigene Standort.
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
    final vehicle = estimateVehicle(trip, widget.now);
    // Linienwege aus der EFA; bis sie da sind (oder wo sie fehlen), verbindet
    // die Karte die Haltestellen gerade.
    final paths = ref.watch(legPathsProvider(TripPathKey(trip))).value;
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
        // Fußweg: vom Ende des vorigen zum Anfang des nächsten Abschnitts.
        final a = i > 0 ? _ll(trip.legs[i - 1].to) : _ll(l.from);
        final b = i + 1 < trip.legs.length ? _ll(trip.legs[i + 1].from) : _ll(l.to);
        if (a != null && b != null) {
          lines.add(Polyline(points: [a, b], color: c.muted, strokeWidth: 4, pattern: StrokePattern.dotted()));
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
          if (vehicle != null)
            Marker(
              point: vehicle.point,
              width: 30,
              height: 30,
              child: Center(child: PositionDot(color: lineColor(context, vehicle.leg.line))),
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
    final vehicle = s == null ? null : estimateVehicle(s.trip, now);
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
        Container(
          color: c.surface,
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
          child: Row(children: [
            Expanded(
              child: Text(
                vehicle == null
                    ? 'Fahrzeugposition erscheint, sobald die Fahrt läuft.'
                    : 'Fahrzeug geschätzt aus Fahrplan und Echtzeit, nicht per GPS.',
                style: TextStyle(fontSize: 13, color: c.muted, height: 1.35),
              ),
            ),
          ]),
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
