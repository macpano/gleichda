import 'dart:async';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/companion.dart';
import '../domain/connections.dart';
import '../domain/models.dart';
import '../domain/product.dart';
import '../ui/format.dart';
import '../ui/screens/connections_screen.dart' show buildQuery;
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
  DateTime? _arrivedAt;
  String? _lastKey;
  StreamSubscription<Position>? _gpsSub;
  bool _shown = false;
  DateTime? _gpsUpdated;

  /// Überwachung: welches Problem zuletzt gemeldet wurde und welche
  /// Alternative dazu gefunden ist.
  String? _problemKey;
  String? _alertedKey;
  Trip? _alternative;
  DateTime? _altAt;
  bool _searching = false;

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
    Future.microtask(_resume);
    return const CompanionState();
  }

  /// Nach einem Neustart der App (Android hat sie beendet): eine laufende
  /// Begleitung fortsetzen, solange die Fahrt nicht vorbei ist.
  Future<void> _resume() async {
    try {
      final repo = ref.read(repositoryProvider);
      final id = await repo.setting('unterwegs');
      if (id == null || id.isEmpty || state.active) return;
      final s = await ref.read(lastTripProvider.future);
      if (s == null || s.trip.id != id || arrivedLongAgo(s.trip, DateTime.now())) {
        await repo.setSetting('unterwegs', '');
        return;
      }
      await start();
    } catch (_) {
      // Ohne Datenbank (Tests) nichts fortzusetzen.
    }
  }

  Future<void> start() async {
    final trip = ref.read(lastTripProvider).value?.trip;
    if (trip == null) return;
    // Doppelt getippt: läuft schon.
    if (state.active && state.tripId == trip.id) return;
    // Sofort einschalten – die Leiste erscheint mit dem Tipp. Vorher wartete
    // „Losfahren“ erst auf die Abfrage der Benachrichtigungs-Erlaubnis und
    // reagierte deshalb manchmal spürbar verzögert (Nutzerbefund 24.09.2026).
    state = CompanionState(active: true, tripId: trip.id);
    await Notifications.requestPermission();
    _problemKey = _alertedKey = null;
    _alternative = null;
    // Merken: übersteht, dass Android die App beendet.
    try {
      await ref.read(repositoryProvider).setSetting('unterwegs', trip.id);
    } catch (_) {}
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
    _shown = false;
    await _gpsSub?.cancel();
    _gpsSub = null;
    _lastKey = null;
    state = const CompanionState();
    _problemKey = _alertedKey = null;
    _alternative = null;
    try {
      await ref.read(repositoryProvider).setSetting('unterwegs', '');
    } catch (_) {}
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
      // Eine Minute „Angekommen“ zeigen, dann beenden – gezählt ab dem
      // Ankommen (per GPS an der Adresse oder nach Uhrzeit).
      _arrivedAt ??= now;
      if (now.difference(_arrivedAt!) > const Duration(minutes: 1)) {
        await stop();
        return;
      }
      // Bis zum Ende: „Angekommen“ mit vollem Balken statt des alten Stands.
      final text = companionTexts(s.trip, step, now);
      if (_lastKey == 'angekommen') return;
      _lastKey = 'angekommen';
      await Notifications.showCompanion(header: text.header, where: text.where, when: text.when, progress: 100);
      _shown = true;
      return;
    }
    // Über die Benachrichtigung beendet (Knopf „Beenden“ ohne App): Die
    // Benachrichtigung ist weg – dann nicht neu zeigen, sondern aufhören.
    if (_shown && await Notifications.companionVisible() == false) {
      await stop();
      return;
    }
    final text = companionTexts(s.trip, step, now);
    final problem = await _watch(s.trip, now);
    final issue = problem ?? tripIssue(s.trip, lost: s.lost);
    final percent = (step.progress * 100).round();
    _arrivedAt = null;
    final key = '${text.where}|${text.when}|$percent|${issue?.title}|${step.walking}';
    if (key == _lastKey) return;
    _lastKey = key;
    await Notifications.showCompanion(
      header: text.header,
      where: text.where,
      when: text.when,
      progress: percent,
      boarding: step.walking,
      alertColor: issue == null
          ? ((step.when?.delayMinutes ?? 0) > 0 ? AppColors.light.orange : null)
          : (issue.level == IssueLevel.cancelled ? AppColors.light.red : AppColors.light.orange),
      reason: issue?.title,
    );
    _shown = true;
  }

  /// Überwacht die Verbindung: Ist der nächste Umstieg nicht mehr erreichbar
  /// oder fällt eine Fahrt aus, sucht sie im Hintergrund eine Alternative ab
  /// dem nächsten Halt bzw. dem Standort (höchstens alle 2 min neu) und
  /// meldet sie einmal je Problem mit Ton.
  Future<TripIssue?> _watch(Trip trip, DateTime now) async {
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final p = ref.read(transitProvider);
    Set<int> guaranteed = const {};
    try {
      guaranteed = await p.guaranteedConnections(trip);
    } catch (_) {}
    final missed = upcomingMissed(trip, now,
        transferMinutes: settings.transferPace.transferMinutes, guaranteed: guaranteed);
    final cancelled = tripIssue(trip)?.level == IssueLevel.cancelled ? tripIssue(trip) : null;
    if (missed == null && cancelled == null) {
      _problemKey = null;
      _alternative = null;
      return null;
    }
    final title = missed != null ? 'Anschluss in ${missed.at.name} nicht erreichbar' : cancelled!.title;
    final key = '${trip.id}|$title';
    if (key != _problemKey) {
      _problemKey = key;
      _alternative = null;
      _altAt = null;
    }
    if (!_searching && (_altAt == null || now.difference(_altAt!) > const Duration(minutes: 2))) {
      _searching = true;
      _altAt = now;
      _findAlternative(trip, now).then((alt) {
        _searching = false;
        if (!state.active || _problemKey != key) return;
        _alternative = alt;
        if (alt != null && _alertedKey != key) {
          _alertedKey = key;
          Notifications.showMessage(
            id: 4711,
            title: title,
            body: 'Alternative: ${alternativeText(alt)}. Tippen für alle Alternativen.',
            payload: 'alternativen',
          );
        }
        _lastKey = null;
        _update();
      }, onError: (Object _) {
        _searching = false;
      });
    }
    final alt = _alternative;
    return TripIssue(IssueLevel.cancelled, alt == null ? title : '$title · Alternative ${alternativeShort(alt)}');
  }

  Future<Trip?> _findAlternative(Trip trip, DateTime now) async {
    final start = alternativeStart(trip, now, gps: state.freshGps(now));
    if (start == null) return null;
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    // Dieselben Einstellungen wie die normale Suche (Profil, Fußweg).
    final found = await ref
        .read(transitProvider)
        .planTrip(buildQuery(from: start.from, to: trip.destination, time: start.time, settings: settings));
    final ok = found.where((t) =>
        !t.departure.best.isBefore(start.time.subtract(const Duration(minutes: 1))) &&
        upcomingMissed(t, now, transferMinutes: settings.transferPace.transferMinutes) == null);
    if (ok.isEmpty) return null;
    return ok.reduce((a, b) => a.arrival.best.isBefore(b.arrival.best) ? a : b);
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
  final when = t == null ? '' : countdownWithTime(t, now);
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
    case CompanionPhase.toStop when step.beforeLeaving(now):
      final platform = step.where.platform == null ? '' : ', Steig ${step.where.platform}';
      final leave = step.leaveAt!;
      return (
        header: header,
        where: 'Losgehen zu ${step.where.stop.name}$platform',
        when: '${countdownWithTime(leave, now)} · Abfahrt ${t == null ? '' : hm(t)}',
        headline: 'Losgehen ${countdown(leave, now)}, $lineText Richtung ${leg?.direction ?? ''}$platform',
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
    case CompanionPhase.toDestination:
      return (
        header: 'Zu Fuß',
        where: 'Zum Ziel: ${step.where.stop.name}',
        when: when,
        headline: 'Zu Fuß zum Ziel, $mins',
      );
    case CompanionPhase.arrived:
      return (header: header, where: 'Angekommen: ${step.where.stop.name}', when: '', headline: 'Angekommen');
  }
}

/// „604 um 18:42 ab Alter Markt, an 19:10“ – die erste Fahrt der Alternative.
String alternativeText(Trip t) {
  final r = t.rides.firstOrNull;
  if (r == null) return 'zu Fuß, an ${hm(t.arrival.best)}';
  final dep = r.from.departure?.best ?? t.departure.best;
  return '${lineTitle(r.line!)} um ${hm(dep)} ab ${r.from.stop.name}, an ${hm(t.arrival.best)}';
}

/// Kurzform für die laufende Benachrichtigung: „604 18:42“.
String alternativeShort(Trip t) {
  final r = t.rides.firstOrNull;
  if (r == null) return 'zu Fuß';
  return '${r.line?.name ?? ''} ${hm(r.from.departure?.best ?? t.departure.best)}';
}
