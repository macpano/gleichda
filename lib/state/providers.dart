import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;

import '../data/db/database.dart';
import '../data/efa/efa_client.dart';
import '../data/repository.dart';
import '../data/transit_provider.dart';
import '../data/walk_route.dart';
import '../data/trias/trias_provider.dart';
import '../data/vrr_provider.dart';
import '../domain/models.dart';
import '../domain/settings.dart';
import 'location.dart';

/// Wird in main() überschrieben.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

final repositoryProvider = Provider((ref) => Repository(ref.watch(databaseProvider)));

final dioProvider = Provider((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 25),
    headers: {'User-Agent': 'Gleich.da/0.1 (Android; Entwicklung)'},
  ));
  ref.onDispose(dio.close);
  return dio;
});

/// Die eine Datenquelle der App. Ein anderer Provider (EFA, MOTIS …) wird
/// nur hier eingehängt.
final transitProvider = Provider<TransitProvider>((ref) {
  final dio = ref.watch(dioProvider);
  return VrrProvider(TriasProvider(dio), EfaClient(dio));
});

/// Sekundentakt für Countdown und „vor 12 s“.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

final themeModeProvider = StreamProvider<ThemeMode>((ref) => ref
    .watch(repositoryProvider)
    .watchSetting('themeMode')
    .map((v) => ThemeMode.values.firstWhere((m) => m.name == v, orElse: () => ThemeMode.system)));

/// Profil und Einstellungen (nur auf dem Gerät).
final settingsProvider = StreamProvider<AppSettings>((ref) => ref
    .watch(repositoryProvider)
    .watchSetting('settings')
    .map(AppSettings.decode));

Future<void> updateSettings(WidgetRef ref, AppSettings Function(AppSettings) change) async {
  final cur = ref.read(settingsProvider).value ?? const AppSettings();
  await ref.read(repositoryProvider).setSetting('settings', change(cur).encode());
}

final historyProvider =
    StreamProvider<List<HistoryItem>>((ref) => ref.watch(repositoryProvider).watchHistory());

final favoritesProvider =
    StreamProvider<List<FavoriteItem>>((ref) => ref.watch(repositoryProvider).watchFavorites());

/// Zustand der zuletzt angesehenen Fahrt.
class LastTripState {
  const LastTripState({
    required this.trip,
    required this.updatedAt,
    this.refreshing = false,
    this.failed = false,
    this.lost = false,
    this.offline = false,
  });

  final Trip trip;

  /// Letzte Aktualisierung scheiterte am fehlenden Netz.
  final bool offline;

  /// Zeitpunkt des angezeigten Stands.
  final DateTime updatedAt;
  final bool refreshing;

  /// Letzte Aktualisierung fehlgeschlagen (kein Netz o. Ä.).
  final bool failed;

  /// Die Auskunft kennt die Fahrt nicht mehr.
  final bool lost;

  bool get hasRealtime => tripHasRealtime(trip);

  LastTripState copyWith({Trip? trip, DateTime? updatedAt, bool? refreshing, bool? failed, bool? lost, bool? offline}) =>
      LastTripState(
        trip: trip ?? this.trip,
        updatedAt: updatedAt ?? this.updatedAt,
        refreshing: refreshing ?? this.refreshing,
        failed: failed ?? this.failed,
        lost: lost ?? this.lost,
        offline: offline ?? this.offline,
      );
}

/// „Zuletzt angesehene Fahrt“: sofort aus dem Speicher, parallel frisch
/// von der Auskunft; alle 30 s neu, solange jemand hinsieht.
/// 2 Minuten nach der (Echtzeit-)Ankunft gilt eine Fahrt als erledigt.
bool arrivedLongAgo(Trip trip, DateTime now) => now.isAfter(tripEnd(trip).add(const Duration(minutes: 2)));

/// Ankunft am Ziel: letzte Fahrt (mit Echtzeit) plus Fußweg danach. Der
/// Fußweg zur Zieladresse hat nur Planzeiten – bei Verspätung stünde die
/// Fahrt sonst zu früh als angekommen da und verschwände von der Startseite.
DateTime tripEnd(Trip trip) {
  var end = trip.arrival.best;
  final i = trip.legs.lastIndexWhere((l) => l.type == LegType.ride);
  final arr = i < 0 ? null : trip.legs[i].to.arrival?.best;
  if (arr != null) {
    final walk = trip.legs.skip(i + 1).fold<int>(0, (m, l) => m + (l.durationMinutes ?? 0));
    final byRide = arr.add(Duration(minutes: walk));
    if (byRide.isAfter(end)) end = byRide;
  }
  return end;
}

/// Wie viele Fahrtansichten gerade offen sind. Solange man eine Fahrt
/// ansieht, wird sie nicht als „angekommen“ weggeräumt – sonst stand etwa
/// bei einem reinen Fußweg nach Hause nach zwei Minuten „Keine Fahrt
/// geöffnet“ mitten in der Ansicht.
int tripViewers = 0;

class LastTripController extends AsyncNotifier<LastTripState?> {
  Timer? _timer;
  bool _busy = false;

  /// Beim Öffnen schon angekommen (z. B. über „Früher“): Sie bleibt, solange
  /// man sie ansieht, und verschwindet erst beim nächsten Start. Vorher
  /// räumte die erste Aktualisierung sie sofort weg – „Keine Fahrt geöffnet“.
  bool _openedPast = false;

  static const interval = Duration(seconds: 30);

  @override
  Future<LastTripState?> build() async {
    ref.onDispose(() => _timer?.cancel());
    final saved = await ref.read(repositoryProvider).lastTrip();
    if (saved == null) return null;
    // Nach Ankunft verschwindet die Karte; die Suche steht im Verlauf.
    if (arrivedLongAgo(saved.trip, DateTime.now())) {
      await ref.read(repositoryProvider).clearLastTrip();
      return null;
    }
    _schedule(immediately: true);
    return LastTripState(trip: saved.trip, updatedAt: saved.updatedAt, refreshing: true);
  }

  void _schedule({bool immediately = false}) {
    _timer?.cancel();
    if (immediately) Future.microtask(refresh);
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  /// Öffnet eine Fahrt: sie wird sofort die zuletzt angesehene.
  Future<void> open(Trip trip, {DateTime? updatedAt}) async {
    final at = updatedAt ?? DateTime.now();
    _openedPast = arrivedLongAgo(trip, DateTime.now());
    state = AsyncData(LastTripState(trip: trip, updatedAt: at));
    await ref.read(repositoryProvider).saveLastTrip(trip, updatedAt: at);
    // Sofort aktualisieren: bringt Echtzeit und die Lage der Haltestellen
    // (TRIAS liefert in der Verbindungssuche keine Koordinaten).
    _schedule(immediately: true);
  }

  /// Ziel erreicht: Die Fahrt verschwindet von der Startseite, auch wenn
  /// die App die ganze Zeit offen war.
  Future<bool> _dropIfArrived() async {
    final cur = state.value;
    if (cur == null || _openedPast || tripViewers > 0 || !arrivedLongAgo(cur.trip, DateTime.now())) return false;
    _timer?.cancel();
    state = const AsyncData(null);
    await ref.read(repositoryProvider).clearLastTrip();
    return true;
  }

  Future<void> refresh() async {
    if (await _dropIfArrived()) return;
    final cur = state.value;
    if (cur == null || _busy) return;
    _busy = true;
    state = AsyncData(cur.copyWith(refreshing: true));
    try {
      final fresh = await ref.read(transitProvider).refreshTrip(cur.trip);
      final latest = state.value;
      if (latest == null || latest.trip.id != cur.trip.id) return; // inzwischen andere Fahrt
      if (fresh == null) {
        state = AsyncData(latest.copyWith(refreshing: false, failed: true, lost: true));
        return;
      }
      // Die Kennung der gespeicherten Fahrt bleibt, auch wenn die Suche eine
      // neue vergibt.
      final trip = fresh.copyWith(id: cur.trip.id);
      final now = DateTime.now();
      state = AsyncData(LastTripState(trip: trip, updatedAt: now));
      await ref.read(repositoryProvider).saveLastTrip(trip, updatedAt: now);
    } on ProviderException catch (e) {
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(refreshing: false, failed: true, offline: e.offline));
      }
    } finally {
      _busy = false;
    }
  }

  /// Im Unterwegs-Modus läuft die Aktualisierung auch im Hintergrund weiter.
  bool keepAlive = false;

  /// App im Hintergrund: keine Abfragen (außer im Unterwegs-Modus).
  void pause() {
    if (!keepAlive) _timer?.cancel();
  }

  /// App wieder sichtbar: sofort aktualisieren, dann im Takt.
  void resume() {
    if (state.value != null) _schedule(immediately: true);
  }

  Future<void> remove() async {
    _timer?.cancel();
    state = const AsyncData(null);
    await ref.read(repositoryProvider).clearLastTrip();
  }
}

final lastTripProvider =
    AsyncNotifierProvider<LastTripController, LastTripState?>(LastTripController.new);

/// Ausgewählte Suchzeit auf der Startseite.
class SearchTime {
  const SearchTime({this.time, this.arriveBy = false});

  /// null = jetzt (laufend).
  final DateTime? time;
  final bool arriveBy;

  bool get isNow => time == null;
}

class SearchTimeController extends Notifier<SearchTime> {
  @override
  SearchTime build() => const SearchTime();

  void set(SearchTime t) => state = t;
}

final searchTimeProvider =
    NotifierProvider<SearchTimeController, SearchTime>(SearchTimeController.new);

/// Start und Ziel auf der Startseite. Bleiben erhalten, wenn man zurückgeht.
class RouteSelection {
  const RouteSelection({this.from, this.to, this.via});

  final Location? from;
  final Location? to;

  /// Zwischenhalt aus den Suchoptionen.
  final Location? via;
}

class RouteController extends Notifier<RouteSelection> {
  @override
  RouteSelection build() => const RouteSelection(from: myLocation);

  void setFrom(Location l) => state = RouteSelection(from: l, to: state.to, via: state.via);
  void setTo(Location l) => state = RouteSelection(from: state.from, to: l, via: state.via);
  void setVia(Location? l) => state = RouteSelection(from: state.from, to: state.to, via: l);
  /// Start und Ziel tauschen. „Mein Standort“ ist als Ziel sinnlos – dann
  /// bleibt das Ziel leer und will neu gewählt werden.
  void swap() => state = RouteSelection(from: state.to, to: isHere(state.from) ? null : state.from, via: state.via);
}

final routeProvider = NotifierProvider<RouteController, RouteSelection>(RouteController.new);

final subscriptionsProvider =
    StreamProvider<List<Subscription>>((ref) => ref.watch(repositoryProvider).watchSubscriptions());

final placesProvider = StreamProvider<List<SavedPlace>>((ref) => ref.watch(repositoryProvider).watchPlaces());

final alarmsProvider = StreamProvider<List<Alarm>>((ref) => ref.watch(repositoryProvider).watchAlarms());

/// Meldungsliste mit Zeitpunkt des Abrufs.
class MessagesState {
  const MessagesState(this.messages, this.at,
      {this.failed = false,
      this.error,
      this.nearLines = const {},
      this.homeRegion,
      this.areaNetworks = const {},
      this.operators = const {}});

  final List<Message> messages;
  final DateTime at;
  final bool failed;
  final String? error;

  /// Linien (Schlüssel wie „wsw:66604“), die in der Nähe halten.
  final Set<String> nearLines;

  /// Eigener Ort (Gemeindeschlüssel).
  final String? homeRegion;

  /// Verkehrsunternehmen der Umgebung (Netzkürzel wie „hst“, „wsw“, „ddb“).
  final Set<String> areaNetworks;

  /// Name je Netzkürzel („hst“ → „Hagener Straßenbahn“).
  final Map<String, String> operators;

  /// Betrifft eine Linie, die in der Nähe hält.
  bool isNear(Message m) => m.lineIds.any(nearLines.contains);

  /// Verkehrsunternehmen der Umgebung; ohne Umgebungsdaten die der Linien
  /// in der Nähe.
  Set<String> get networks =>
      areaNetworks.isNotEmpty ? areaNetworks : {for (final k in nearLines) k.split(':').first};

  /// Erstes Unternehmen der Umgebung, das die Meldung betrifft.
  String? networkOf(Message m) =>
      m.lineIds.map((k) => k.split(':').first).where(networks.contains).firstOrNull;

  /// Gehört in die Liste „Alle“: betrifft eine Linie in der Nähe, eine Linie
  /// eines Verkehrsunternehmens der Umgebung oder ist eine allgemeine Meldung
  /// des eigenen Orts. Fremde Netze fallen heraus.
  bool isRelevant(Message m) {
    if (nearLines.isEmpty && areaNetworks.isEmpty) return true; // ohne Standort: alles
    if (isNear(m)) return true;
    if (m.lineIds.isEmpty) return homeRegion == null || m.regions.contains(homeRegion);
    return networkOf(m) != null;
  }
}

/// Zuletzt genutzte Gebiete für Meldungen (auch für die Hintergrundprüfung).
Future<List<String>> savedMessageRegions(Repository repo) async {
  final s = await repo.setting('messagesRegions');
  return s == null || s.isEmpty ? const [] : s.split(',');
}

/// Meldungen für den Ort, an dem man ist (Gebiet der nächsten Haltestelle).
/// Das Gebiet wird gemerkt – ohne Standort und in der Hintergrundprüfung der
/// Linienabos gilt das zuletzt genutzte.
class MessagesController extends AsyncNotifier<MessagesState> {
  @override
  Future<MessagesState> build() => _load();

  Future<MessagesState> _load() async {
    final p = ref.read(transitProvider);
    final repo = ref.read(repositoryProvider);
    var regions = <String>[];
    var near = <String>{};
    final networks = <String>{};
    final operators = <String, String>{};
    try {
      final here = await ref.read(locationServiceProvider).current(preferRecent: true);
      final at = (lat: here.lat, lon: here.lon);
      final results = await Future.wait([p.regionsOf(at), p.linesNear(at), p.linesAround(at)]);
      regions = results[0] as List<String>;
      near = {for (final l in results[1] as List<Line>) lineKey(l.id)};
      for (final l in [...results[1] as List<Line>, ...results[2] as List<Line>]) {
        final net = lineKey(l.id).split(':').first;
        networks.add(net);
        operators.putIfAbsent(net, () => net == 'ddb' ? 'Deutsche Bahn' : (l.operator ?? net.toUpperCase()));
      }
      if (regions.isNotEmpty) await repo.setSetting('messagesRegions', regions.join(','));
    } catch (_) {
      // Ohne Standort: zuletzt genutzte Gebiete.
    }
    if (regions.isEmpty) regions = await savedMessageRegions(repo);
    final list = await p.messages(regions: regions);
    return MessagesState(list, DateTime.now(),
        nearLines: near, homeRegion: regions.firstOrNull, areaNetworks: networks, operators: operators);
  }

  Future<void> refresh() async {
    final old = state.value;
    try {
      state = AsyncData(await _load());
    } on ProviderException catch (e) {
      state = old == null
          ? AsyncError(e, StackTrace.current)
          : AsyncData(MessagesState(old.messages, old.at,
              failed: true,
              error: e.message,
              nearLines: old.nearLines,
              homeRegion: old.homeRegion,
              areaNetworks: old.areaNetworks,
              operators: old.operators));
    }
  }
}

final messagesProvider = AsyncNotifierProvider<MessagesController, MessagesState>(MessagesController.new);

/// Schlüssel für Linienwege: eine Verbindung, gleich über ihre ID (die
/// Echtzeit-Aktualisierung ändert die Zeiten, nicht den Weg).
class TripPathKey {
  const TripPathKey(this.trip);

  final Trip trip;

  @override
  bool operator ==(Object other) => other is TripPathKey && other.trip.id == trip.id;

  @override
  int get hashCode => trip.id.hashCode;
}

/// Gesicherte Anschlüsse der Fahrt (Indizes in `trip.legs`).
final guaranteedProvider = FutureProvider.family<Set<int>, TripPathKey>(
    (ref, key) => ref.watch(transitProvider).guaranteedConnections(key.trip));

/// Schlüssel für die Gehwege: Fahrt und Lage aller Fußweg-Enden. Die Lage
/// der Haltestellen kommt erst mit der ersten Aktualisierung (EFA) – dann
/// werden die Gehwege neu gerechnet statt leer gemerkt.
class WalkPathKey {
  WalkPathKey(this.trip)
      : _sig = '${trip.id}|${[for (var i = 0; i < trip.legs.length; i++) walkEnds(trip, i)].join(';')}';

  final Trip trip;
  final String _sig;

  @override
  bool operator ==(Object other) => other is WalkPathKey && other._sig == _sig;

  @override
  int get hashCode => _sig.hashCode;
}

/// Anfang und Ende eines Fußwegs: vom Ausstieg davor zum Einstieg danach
/// (bzw. vom Start / bis zum Ziel). null ohne Koordinaten.
(GeoPoint, GeoPoint)? walkEnds(Trip trip, int i) {
  final l = trip.legs[i];
  if (l.type == LegType.ride || l.staySeated) return null;
  final a = i > 0 ? trip.legs[i - 1].to.stop : l.from.stop;
  final b = i + 1 < trip.legs.length ? trip.legs[i + 1].from.stop : l.to.stop;
  if (a.lat == null || a.lon == null || b.lat == null || b.lon == null) return null;
  return ((lat: a.lat!, lon: a.lon!), (lat: b.lat!, lon: b.lon!));
}

/// Fußwege der Fahrt als Gehweg (FOSSGIS); null, wo keiner nötig oder
/// abrufbar ist – dann zeichnet die Karte eine gerade gepunktete Linie.
final walkPathsProvider = FutureProvider.family<List<List<GeoPoint>?>, WalkPathKey>((ref, key) {
  final router = ref.watch(walkRouterProvider);
  final trip = key.trip;
  Future<List<GeoPoint>?> one(int i) async {
    final ends = walkEnds(trip, i);
    if (ends == null) return null;
    final (a, b) = ends;
    if (Geolocator.distanceBetween(a.lat, a.lon, b.lat, b.lon) < 20) return null;
    try {
      return (await router.route(a, b))?.points;
    } catch (_) {
      return null;
    }
  }

  return Future.wait([for (var i = 0; i < trip.legs.length; i++) one(i)]);
});

/// Linienwege je Abschnitt; null, wo keiner bekannt ist.
final legPathsProvider = FutureProvider.family<List<List<GeoPoint>?>, TripPathKey>(
    (ref, key) => ref.watch(transitProvider).legPaths(key.trip));

/// Fußwege entlang von Gehwegen (FOSSGIS-Router).
final walkRouterProvider = Provider((ref) => WalkRouter(ref.watch(dioProvider)));
