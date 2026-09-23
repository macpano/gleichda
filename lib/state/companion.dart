import 'dart:async';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/companion.dart';
import '../domain/models.dart';
import '../domain/product.dart';
import '../ui/format.dart';
import '../ui/theme.dart';
import '../ui/trip_status.dart';
import '../domain/settings.dart';
import 'location.dart';
import 'notifications.dart';
import 'providers.dart';

class CompanionState {
  const CompanionState({this.active = false, this.tripId, this.gps, this.gpsAt});

  final bool active;
  final String? tripId;

  /// Letzte GPS-Position während der Begleitung (nur, wenn der Standort
  /// erlaubt ist). Älter als 2 min gilt sie nicht mehr.
  final GeoPoint? gps;
  final DateTime? gpsAt;

  GeoPoint? freshGps(DateTime now) =>
      gps != null && gpsAt != null && now.difference(gpsAt!) < const Duration(minutes: 2) ? gps : null;

  CompanionState withGps(GeoPoint p) => CompanionState(active: active, tripId: tripId, gps: p, gpsAt: DateTime.now());
}

/// Unterwegs-Modus: begleitet die zuletzt angesehene Fahrt und hält die
/// laufende Benachrichtigung aktuell. Mit Standort bestimmt GPS, wo man auf
/// der Strecke ist (nächster Halt, Fortschritt); ohne ihn Fahrplan und
/// Echtzeit.
class CompanionController extends Notifier<CompanionState> {
  Timer? _timer;
  String? _lastKey;
  StreamSubscription<Position>? _gpsSub;
  DateTime? _gpsUpdated;

  final _port = ReceivePort();

  @override
  CompanionState build() {
    // „Beenden“ aus der Benachrichtigung kommt über diesen Port, ohne dass
    // die App dafür geöffnet wird (notificationActionInBackground).
    IsolateNameServer.removePortNameMapping(companionPortName);
    IsolateNameServer.registerPortWithName(_port.sendPort, companionPortName);
    final sub = _port.listen((m) {
      if (m == 'stop') stop();
    });
    ref.onDispose(() {
      _timer?.cancel();
      _gpsSub?.cancel();
      sub.cancel();
      IsolateNameServer.removePortNameMapping(companionPortName);
    });
    ref.listen(lastTripProvider, (_, next) {
      if (state.active) _update();
    });
    return const CompanionState();
  }

  Future<void> start() async {
    final trip = ref.read(lastTripProvider).value?.trip;
    if (trip == null) return;
    await Notifications.requestPermission();
    state = CompanionState(active: true, tripId: trip.id);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _update());
    // Während der Begleitung auch im Hintergrund aktualisieren.
    ref.read(lastTripProvider.notifier).keepAlive = true;
    await _startGps();
    await _update();
  }

  Future<void> _startGps() async {
    await _gpsSub?.cancel();
    _gpsSub = null;
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    if (!settings.useLocation) return;
    try {
      final loc = ref.read(locationServiceProvider);
      await loc.current();
      Notifications.locationAllowed = true;
      _gpsSub = loc.watch().listen((p) {
        if (!state.active || p.accuracy > 80) return;
        state = state.withGps((lat: p.latitude, lon: p.longitude));
        // Benachrichtigung höchstens alle 5 s neu rechnen.
        final now = DateTime.now();
        if (_gpsUpdated == null || now.difference(_gpsUpdated!) > const Duration(seconds: 5)) {
          _gpsUpdated = now;
          _update();
        }
      }, onError: (Object _) {});
    } catch (_) {
      // Ohne Standort läuft die Begleitung über die Uhrzeit.
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    await _gpsSub?.cancel();
    _gpsSub = null;
    _lastKey = null;
    state = const CompanionState();
    ref.read(lastTripProvider.notifier).keepAlive = false;
    await Notifications.stopCompanion();
  }

  Future<void> _update() async {
    final s = ref.read(lastTripProvider).value;
    if (s == null || s.trip.id != state.tripId) {
      await stop();
      return;
    }
    final now = DateTime.now();
    final step = nextStep(s.trip, now, gps: state.freshGps(now));
    if (step.phase == CompanionPhase.arrived) {
      if (now.difference(s.trip.arrival.best) > const Duration(minutes: 1)) await stop();
      return;
    }
    final text = companionTexts(s.trip, step, now);
    final issue = tripIssue(s.trip, lost: s.lost);
    final percent = (step.progress * 100).round();
    final key = '${text.where}|${text.when}|$percent|${issue?.title}';
    if (key == _lastKey) return;
    _lastKey = key;
    await Notifications.showCompanion(
      header: text.header,
      where: text.where,
      when: text.when,
      progress: percent,
      alertColor: issue == null
          ? ((step.when?.delayMinutes ?? 0) > 0 ? AppColors.light.orange : null)
          : (issue.level == IssueLevel.cancelled ? AppColors.light.red : AppColors.light.orange),
      reason: issue?.title,
    );
  }
}

final companionProvider = NotifierProvider<CompanionController, CompanionState>(CompanionController.new);

/// Texte für Anzeige und Benachrichtigung.
({String header, String where, String when, String headline}) companionTexts(
    Trip trip, CompanionStep step, DateTime now) {
  final leg = step.leg;
  final line = leg?.line;
  final lineText = line == null ? '' : lineTitle(line);
  final header = [if (lineText.isNotEmpty) lineText, if (leg?.direction != null) leg!.direction!].join(' · ');
  final t = step.when?.best;
  final mins = t == null ? '' : countdown(t, now);
  final when = t == null ? '' : '$mins · ${hm(t)}';
  switch (step.phase) {
    case CompanionPhase.onBoard:
      final n = step.stopsLeft ?? 0;
      final next = step.nextBeforeExit;
      return (
        header: header,
        where: 'Aussteigen: ${step.where.stop.name}',
        when: next == null ? when : '$when · nächster Halt ${next.stop.name}',
        headline: n <= 1 ? 'Nächster Halt: aussteigen' : 'Aussteigen in $n Halten',
      );
    case CompanionPhase.transfer:
    case CompanionPhase.toStop:
    case CompanionPhase.waiting:
      final platform = step.where.platform == null ? '' : ', Steig ${step.where.platform}';
      return (
        header: header,
        where: 'Einsteigen: ${step.where.stop.name}$platform',
        when: when,
        headline: '$lineText Richtung ${leg?.direction ?? ''}$platform, $mins',
      );
    case CompanionPhase.arrived:
      return (header: header, where: 'Angekommen: ${step.where.stop.name}', when: '', headline: 'Angekommen');
  }
}
