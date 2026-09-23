import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/efa/efa_client.dart';
import '../data/repository.dart';
import '../data/transit_provider.dart';
import '../data/trias/trias_provider.dart';
import '../data/vrr_provider.dart';
import '../domain/models.dart';

/// Wird in main() überschrieben.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

final repositoryProvider = Provider((ref) => Repository(ref.watch(databaseProvider)));

final dioProvider = Provider((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 25),
    headers: {'User-Agent': 'Gleichda/0.1 (Android; Entwicklung)'},
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
  });

  final Trip trip;

  /// Zeitpunkt des angezeigten Stands.
  final DateTime updatedAt;
  final bool refreshing;

  /// Letzte Aktualisierung fehlgeschlagen (kein Netz o. Ä.).
  final bool failed;

  /// Die Auskunft kennt die Fahrt nicht mehr.
  final bool lost;

  bool get hasRealtime => tripHasRealtime(trip);

  LastTripState copyWith({Trip? trip, DateTime? updatedAt, bool? refreshing, bool? failed, bool? lost}) =>
      LastTripState(
        trip: trip ?? this.trip,
        updatedAt: updatedAt ?? this.updatedAt,
        refreshing: refreshing ?? this.refreshing,
        failed: failed ?? this.failed,
        lost: lost ?? this.lost,
      );
}

/// „Zuletzt angesehene Fahrt“: sofort aus dem Speicher, parallel frisch
/// von der Auskunft; alle 30 s neu, solange jemand hinsieht.
class LastTripController extends AsyncNotifier<LastTripState?> {
  Timer? _timer;
  bool _busy = false;

  static const interval = Duration(seconds: 30);

  @override
  Future<LastTripState?> build() async {
    ref.onDispose(() => _timer?.cancel());
    final saved = await ref.read(repositoryProvider).lastTrip();
    if (saved == null) return null;
    // Nach Ankunft verschwindet die Karte; die Suche steht im Verlauf.
    if (saved.trip.arrival.best.isBefore(DateTime.now().subtract(const Duration(minutes: 10)))) {
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
    state = AsyncData(LastTripState(trip: trip, updatedAt: at));
    await ref.read(repositoryProvider).saveLastTrip(trip, updatedAt: at);
    _schedule(immediately: DateTime.now().difference(at) > const Duration(seconds: 20));
  }

  Future<void> refresh() async {
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
    } on ProviderException {
      final latest = state.value;
      if (latest != null) state = AsyncData(latest.copyWith(refreshing: false, failed: true));
    } finally {
      _busy = false;
    }
  }

  /// App im Hintergrund: keine Abfragen.
  void pause() => _timer?.cancel();

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
  const RouteSelection({this.from, this.to});

  final Location? from;
  final Location? to;
}

class RouteController extends Notifier<RouteSelection> {
  @override
  RouteSelection build() => const RouteSelection();

  void setFrom(Location l) => state = RouteSelection(from: l, to: state.to);
  void setTo(Location l) => state = RouteSelection(from: state.from, to: l);
  void swap() => state = RouteSelection(from: state.to, to: state.from);
}

final routeProvider = NotifierProvider<RouteController, RouteSelection>(RouteController.new);
