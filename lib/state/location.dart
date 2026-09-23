import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/models.dart';
import 'providers.dart';

/// Pseudo-Ort „Mein Standort“. Die Koordinate wird erst bei der Suche
/// ermittelt.
const hereId = 'here';
const myLocation = Location(
  id: hereId,
  providerId: 'device',
  name: 'Mein Standort',
  type: LocationType.coordinate,
);

bool isHere(Location? l) => l?.id == hereId;

typedef LatLon = ({double lat, double lon});

enum LocationProblem { disabled, denied, deniedForever, timeout, off }

class LocationException implements Exception {
  const LocationException(this.problem);

  final LocationProblem problem;

  String get message => switch (problem) {
        LocationProblem.disabled => 'Standortdienste sind ausgeschaltet.',
        LocationProblem.denied => 'Standort nicht freigegeben.',
        LocationProblem.deniedForever =>
          'Standort dauerhaft abgelehnt. Freigabe in den Android-Einstellungen möglich.',
        LocationProblem.timeout => 'Standort nicht rechtzeitig ermittelt.',
        LocationProblem.off => 'Standort ist in Gleich.da ausgeschaltet (Mehr → Standort).',
      };
}

/// Standort nur bei Nutzung, mit kurzem Zwischenspeicher.
class LocationService {
  LocationService(this.ref);

  /// Beim ersten Start: erst die Erklärung, dann die Systemabfrage. Solange
  /// sie offen ist, wartet jede Standortabfrage hier.
  static Completer<void>? introGate;

  final Ref ref;
  LatLon? _last;
  DateTime? _at;

  LatLon? get last => _last;

  Future<LatLon> current({Duration maxAge = const Duration(seconds: 30), bool preferRecent = false}) async {
    final settings = ref.read(settingsProvider).value;
    if (settings != null && !settings.useLocation) {
      throw const LocationException(LocationProblem.off);
    }
    if (_last != null && _at != null && DateTime.now().difference(_at!) < maxAge) {
      return _last!;
    }
    LocationPermission p;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationException(LocationProblem.disabled);
      }
      p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        final gate = introGate;
        if (gate != null && !gate.isCompleted) {
          await gate.future;
          p = await Geolocator.checkPermission();
        }
      }
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    } on LocationException {
      rethrow;
    } catch (_) {
      // Plattform ohne Standortdienst (z. B. Tests).
      throw const LocationException(LocationProblem.disabled);
    }
    if (p == LocationPermission.denied) throw const LocationException(LocationProblem.denied);
    if (p == LocationPermission.deniedForever) {
      throw const LocationException(LocationProblem.deniedForever);
    }
    if (preferRecent) {
      // Für die Suche genügt eine frische letzte Position (unter 2 min, auf
      // 100 m genau) – die Suche wartet dann nicht auf einen neuen GPS-Fix.
      try {
        final known = await Geolocator.getLastKnownPosition();
        if (known != null &&
            DateTime.now().difference(known.timestamp) < const Duration(minutes: 2) &&
            known.accuracy < 100) {
          _remember(known);
          return _last!;
        }
      } catch (_) {}
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _remember(pos);
    } catch (_) {
      final known = await Geolocator.getLastKnownPosition();
      if (known == null) throw const LocationException(LocationProblem.timeout);
      _remember(known);
    }
    return _last!;
  }

  void _remember(Position p) {
    _last = (lat: p.latitude, lon: p.longitude);
    _at = DateTime.now();
  }

  /// Laufende Positionen, z. B. für „Weg zum Steig“.
  Stream<Position> watch() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 3,
        ),
      );

  /// „Mein Standort“ mit aktueller Koordinate.
  Future<Location> resolve(Location l) async {
    if (!isHere(l)) return l;
    final p = await current(preferRecent: true);
    return l.copyWith(lat: p.lat, lon: p.lon);
  }
}

final locationServiceProvider = Provider((ref) => LocationService(ref));
