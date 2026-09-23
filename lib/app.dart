import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/providers.dart';
import 'state/location.dart';
import 'ui/trip_status.dart';
import 'ui/screens/walk_screen.dart';
import 'ui/screens/trip_screen.dart';
import 'ui/screens/companion_card.dart';
import 'state/companion.dart';
import 'state/updates.dart';
import 'ui/screens/update_screen.dart';
import 'ui/screens/departures_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/map_screen.dart';
import 'ui/screens/messages_screen.dart';
import 'ui/screens/more_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart' show buttonShape;

/// Für Benachrichtigungen, die einen Screen öffnen.
final navigatorKey = GlobalKey<NavigatorState>();

/// Liegt die Startseite mit den Reitern oben? Dann steht die Unterwegs-Leiste
/// über den Reitern (die Reiter verschieben sich nie); in allen anderen
/// Ansichten ganz unten. Fenster von unten zählen nicht mit.
final homeOnTop = ValueNotifier<bool>(true);

/// Ein Fenster (Blatt von unten, Dialog, Menü) liegt über der Startseite –
/// dann tritt die Leiste dort zurück, statt es zu verdecken.
final popupOnHome = ValueNotifier<bool>(false);

/// Höhe der Reiterleiste: So weit über dem unteren Rand steht die
/// Unterwegs-Leiste auf der Startseite.
final tabBarHeight = ValueNotifier<double>(0);

/// Merkt sich den Stapel der Ansichten: für [homeOnTop] und dafür, dass
/// [pushOnce] keine Ansicht doppelt öffnet.
class PageStack extends NavigatorObserver {
  final _routes = <Route<dynamic>>[];

  void _set() {
    // Der Navigator meldet die erste Ansicht mitten im Aufbau – dann erst
    // nach diesem Bild weitergeben (sonst „setState during build“).
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _apply());
    } else {
      _apply();
    }
  }

  void _apply() {
    final pages = _routes.whereType<PageRoute<dynamic>>().length;
    homeOnTop.value = pages <= 1;
    popupOnHome.value = pages <= 1 && _routes.any((r) => r is PopupRoute);
  }

  /// Die Ansicht mit diesem Namen, falls sie im Stapel liegt.
  Route<dynamic>? named(String name) => _routes.where((r) => r.settings.name == name).lastOrNull;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _set();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _set();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _set();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) {
      _routes[i] = newRoute;
    } else if (newRoute != null) {
      _routes.add(newRoute);
    }
    _set();
  }
}

final pageStack = PageStack();

/// Öffnet eine Ansicht nur einmal: Liegt [name] schon im Stapel, geht es
/// dorthin zurück. Vorher stapelten sich Karte und Fahrt bei mehrfachem
/// Tippen (Leiste, Benachrichtigung, Kartensymbol) – man musste mehrmals
/// zurück.
void pushOnce(NavigatorState? nav, String name, WidgetBuilder builder) {
  if (nav == null) return;
  final existing = pageStack.named(name);
  if (existing != null) {
    if (!existing.isCurrent) nav.popUntil((r) => r == existing);
    return;
  }
  nav.push(MaterialPageRoute(settings: RouteSettings(name: name), builder: builder));
}

class GleichDaApp extends ConsumerWidget {
  const GleichDaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final platform = Theme.of(context).platform;
    return MaterialApp(
      title: 'Gleich.da',
      navigatorKey: navigatorKey,
      navigatorObservers: [pageStack],
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: buildTheme(Brightness.light, platform),
      darkTheme: buildTheme(Brightness.dark, platform),
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeShell(),
      builder: appFrame,
    );
  }
}

/// Rahmen um jede Ansicht:
/// Die Statusleiste ist durchsichtig; ein Streifen in Hintergrundfarbe
/// darunter verhindert, dass beim Scrollen Inhalte hinter Uhrzeit und
/// Symbolen durchscheinen.
/// Außerdem die Unterwegs-Leiste: eine einzige für die ganze App. Auf der
/// Startseite steht sie über den Reitern, sonst ganz unten; beim Wechsel
/// gleitet sie kurz an den neuen Platz.
Widget appFrame(BuildContext context, Widget? child) {
  final top = MediaQuery.paddingOf(context).top;
  final inset = MediaQuery.paddingOf(context).bottom;
  return Consumer(builder: (context, ref, _) {
    final shown = companionShown(ref);
    return ListenableBuilder(
      listenable: Listenable.merge([homeOnTop, popupOnHome, tabBarHeight]),
      builder: (context, _) {
        // Startseite mit Reitern oben (Reiterleiste gemessen).
        final home = homeOnTop.value && tabBarHeight.value > 0;
        final atBottom = shown && !home;
        return Stack(children: [
          Column(children: [
            // Unten verliert die Ansicht ihren Rand; den übernimmt die Leiste.
            Expanded(child: MediaQuery.removePadding(context: context, removeBottom: atBottom, child: child!)),
            AnimatedContainer(
              duration: companionMove,
              curve: Curves.easeOutCubic,
              height: atBottom ? companionBarHeight + inset : 0,
              color: context.c.bar,
            ),
          ]),
          if (shown)
            AnimatedPositioned(
              duration: companionMove,
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: home ? tabBarHeight.value : 0,
              child: IgnorePointer(
                ignoring: home && popupOnHome.value,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: home && popupOnHome.value ? 0 : 1,
                  child: ColoredBox(
                    color: context.c.bar,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const GlobalCompanionBar(),
                      AnimatedContainer(
                          duration: companionMove, curve: Curves.easeOutCubic, height: home ? 0 : inset),
                    ]),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top,
            child: IgnorePointer(child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor)),
          ),
        ]);
      },
    );
  });
}

/// Dauer, mit der die Unterwegs-Leiste den Platz wechselt.
const companionMove = Duration(milliseconds: 260);

/// Läuft eine Begleitung für die zuletzt angesehene Fahrt?
bool companionShown(WidgetRef ref) {
  final companion = ref.watch(companionProvider);
  final s = ref.watch(lastTripProvider).value;
  return companion.active && s != null && s.trip.id == companion.tripId;
}

/// Fünf feste Reiter: Suche, Karte, Abfahrten, Meldungen, Mehr.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;
  final _visited = <int>{0};
  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    // Versionsabgleich beim Start anstoßen.
    Future.microtask(() => ref.read(updateProvider));
    // Erster Start: erklären, wofür der Standort gebraucht wird – bevor
    // Android fragt (Standortabfragen warten so lange).
    LocationService.introGate = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locationIntro());
    _life = AppLifecycleListener(
      onResume: () {
        ref.read(lastTripProvider.notifier).resume();
        ref.read(updateProvider.notifier).resume();
      },
      onHide: () => ref.read(lastTripProvider.notifier).pause(),
    );
  }

  Future<void> _locationIntro() async {
    final gate = LocationService.introGate!;
    try {
      final repo = ref.read(repositoryProvider);
      if (await repo.setting('standortErklaert') != null) return;
      if (await Geolocator.checkPermission() != LocationPermission.denied) {
        await repo.setSetting('standortErklaert', '1');
        return;
      }
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isDismissible: false,
        builder: (context) => const LocationIntroSheet(),
      );
      await repo.setSetting('standortErklaert', '1');
    } catch (_) {
      // Ohne Standortdienst (z. B. in Tests): nichts zu erklären.
    } finally {
      if (!gate.isCompleted) gate.complete();
    }
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  void _select(int i) => setState(() {
        _tab = i;
        _visited.add(i);
      });

  static const _tabs = [
    (Icons.search, 'Suche'),
    (Icons.map_outlined, 'Karte'),
    (Icons.schedule, 'Abfahrten'),
    (Icons.notifications_none, 'Meldungen'),
    (Icons.more_horiz, 'Mehr'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: c.bar,
      ),
      child: Scaffold(
        body: Stack(children: [
          IndexedStack(
            index: _tab,
            children: [
              const HomeScreen(),
              // Erst beim ersten Öffnen aufbauen: keine Standortabfrage und keine
              // Meldungsabfrage, bevor der Tab gebraucht wird.
              // Karte erst beim ersten Öffnen (Standort, Kacheln).
              _visited.contains(1) ? const MapScreen() : const SizedBox.shrink(),
              _visited.contains(2) ? const DeparturesScreen() : const SizedBox.shrink(),
              _visited.contains(3) ? const MessagesScreen() : const SizedBox.shrink(),
              const MoreScreen(),
            ],
          ),
          const Positioned(left: 12, right: 12, bottom: 12, child: UpdateToast()),
        ]),
        // Platz für die Unterwegs-Leiste über den Reitern (sie selbst liegt
        // in appFrame und gleitet beim Ansichtwechsel); die Reiter bleiben fest.
        bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: companionMove,
            curve: Curves.easeOutCubic,
            height: companionShown(ref) ? companionBarHeight : 0,
          ),
          _MeasureHeight(
            onHeight: (h) => tabBarHeight.value = h,
            child: context.isIOS
            ? _IosTabBar(index: _tab, onTap: _select, tabs: _tabs)
            : NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: _select,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  for (final t in _tabs)
                    NavigationDestination(icon: Icon(t.$1), label: t.$2),
                ],
              ),
          ),
        ]),
      ),
    );
  }
}

class _IosTabBar extends StatelessWidget {
  const _IosTabBar({required this.index, required this.onTap, required this.tabs});

  final int index;
  final ValueChanged<int> onTap;
  final List<(IconData, String)> tabs;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.bar,
        border: Border(top: BorderSide(color: c.hair)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      height: 58 + MediaQuery.of(context).padding.bottom,
      child: Row(children: [
        for (var i = 0; i < tabs.length; i++)
          Expanded(
            child: InkResponse(
              onTap: () => onTap(i),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(tabs[i].$1, color: i == index ? c.accent : c.muted),
                const SizedBox(height: 3),
                Text(tabs[i].$2,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                        color: i == index ? c.accent : c.muted)),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// Meldet die Höhe seines Inhalts nach dem Aufbau (für die Reiterleiste).
class _MeasureHeight extends SingleChildRenderObjectWidget {
  const _MeasureHeight({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasure(onHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasure renderObject) => renderObject.onHeight = onHeight;
}

class _RenderMeasure extends RenderProxyBox {
  _RenderMeasure(this.onHeight);

  ValueChanged<double> onHeight;
  double? _last;

  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if (h != _last) {
      _last = h;
      WidgetsBinding.instance.addPostFrameCallback((_) => onHeight(h));
    }
  }
}

/// Die Unterwegs-Leiste für die ganze App, solange eine Begleitung läuft.
class GlobalCompanionBar extends ConsumerWidget {
  const GlobalCompanionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companion = ref.watch(companionProvider);
    final s = ref.watch(lastTripProvider).value;
    if (!companion.active || s == null || s.trip.id != companion.tripId) return const SizedBox.shrink();
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    return Material(
      type: MaterialType.transparency,
      child: CompanionBar(
        bottomPadding: false,
        trip: s.trip,
        now: now,
        issue: tripIssue(s.trip, lost: s.lost),
        gps: companion.freshGps(now),
        onStop: () => ref.read(companionProvider.notifier).stop(),
        onWalk: (step) => pushOnce(navigatorKey.currentState, 'weg:${step.where.stop.id}',
            (_) => WalkScreen(target: step.where.stop, platform: step.where.platform, departure: step.when)),
        onOpen: () => pushOnce(navigatorKey.currentState, 'fahrt', (_) => const TripScreen()),
      ),
    );
  }
}

/// Erklärung zum Standort beim ersten Start.
class LocationIntroSheet extends StatelessWidget {
  const LocationIntroSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget point(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 22, color: c.accent),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: TextStyle(fontSize: 15, height: 1.35, color: c.ink))),
          ]),
        );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Wofür Gleich.da deinen Standort braucht', style: context.t.screenTitle.copyWith(fontSize: 20)),
          const SizedBox(height: 16),
          point(Icons.near_me_outlined, '„Mein Standort“ als Start – ohne Adresse eintippen.'),
          point(Icons.schedule, 'Abfahrten an den Haltestellen in deiner Nähe.'),
          point(Icons.directions_walk, 'Der Weg zum Steig und unterwegs der nächste Halt.'),
          point(Icons.lock_outline, 'Der Standort bleibt auf dem Gerät. Kein Konto, kein Tracking.'),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(shape: buttonShape(context)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Weiter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 4),
          Text('Danach fragt Android, ob die App den Standort nutzen darf. Ohne ihn geht alles über die Suche.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.muted)),
        ]),
      ),
    );
  }
}
