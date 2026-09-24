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

/// Animation der Seite direkt über der Startseite: Die Unterwegs-Leiste
/// gleitet genau mit ihr zwischen „über den Reitern“ und „ganz unten“ –
/// beim Öffnen, Zurückgehen und bei der Zurück-Geste.
final firstPageAnimation = ValueNotifier<Animation<double>?>(null);

/// Höhe der Reiterleiste (mit dem Rand unten): So weit über dem unteren Rand
/// steht die Unterwegs-Leiste.
final tabBarHeight = ValueNotifier<double>(0);

/// Gewählter Reiter der Startseite. Die Reiterleiste liegt im App-Rahmen und
/// bleibt auf jeder Ansicht stehen (Nutzerwunsch 24.09.2026) – ein Tipp führt
/// von überall zu diesem Reiter zurück.
final currentTab = ValueNotifier<int>(0);

/// Die Startseite mit den Reitern liegt unten im Stapel (in Bildschirmfotos
/// einzelner Ansichten nicht) – nur dann gibt es die Reiterleiste.
final shellMounted = ValueNotifier<bool>(false);

const shellTabs = [
  (Icons.search, 'Suche'),
  (Icons.schedule, 'Abfahrten'),
  (Icons.map_outlined, 'Karte'),
  (Icons.notifications_none, 'Meldungen'),
  (Icons.more_horiz, 'Mehr'),
];

/// Reiter wählen – aus einer geöffneten Ansicht zurück zur Startseite.
void selectTab(int i) {
  navigatorKey.currentState?.popUntil((r) => r.isFirst);
  currentTab.value = i;
}

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
    final pages = _routes.whereType<PageRoute<dynamic>>().toList();
    homeOnTop.value = pages.length <= 1;
    // Über jedem Blatt von unten, Dialog oder Menü tritt die Leiste zurück –
    // die Ansicht hat die volle Höhe, das Blatt läge sonst unter ihr.
    popupOnHome.value = _routes.any((r) => r is PopupRoute);
    // Die Seite über der Startseite: ihre Animation steuert die Leiste. Nach
    // dem Zurückgehen bleibt sie stehen, bis sie ganz zurückgelaufen ist.
    if (pages.length >= 2) {
      final a = pages[1].animation;
      if (a != null && firstPageAnimation.value != a) {
        firstPageAnimation.value = a;
        a.addStatusListener((s) {
          if (s == AnimationStatus.dismissed && firstPageAnimation.value == a) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (firstPageAnimation.value == a) firstPageAnimation.value = null;
            });
          }
        });
      }
    }
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
      listenable: Listenable.merge([shellMounted, tabBarHeight, popupOnHome]),
      builder: (context, _) {
        final shell = shellMounted.value;
        // Platz unter jeder geöffneten Ansicht: Unterwegs-Leiste und Reiter
        // (nach dem Bild setzen, nicht im Aufbau).
        final reserve = (shown ? companionBarHeight : 0.0) + (shell ? tabBarHeight.value : (shown ? inset : 0.0));
        if (companionReserve.value != reserve) {
          WidgetsBinding.instance.addPostFrameCallback((_) => companionReserve.value = reserve);
        }
        final hidden = popupOnHome.value;
        return Stack(children: [
          Positioned.fill(child: child!),
          // Unten: Unterwegs-Leiste und darunter die Reiter – auf jeder Ansicht.
          // Über Blättern von unten und Dialogen treten beide zurück.
          if (shell || shown)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: hidden,
                child: AnimatedSlide(
                  duration: Motion.of(context, Motion.short),
                  curve: Motion.curve,
                  offset: hidden ? const Offset(0, 1) : Offset.zero,
                  child: ColoredBox(
                    color: context.c.bar,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (shown) const _SlideIn(child: GlobalCompanionBar()),
                      if (shell)
                        const _TabBar()
                      else if (shown)
                        SizedBox(height: inset),
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

/// Reiterleiste für die ganze App.
class _TabBar extends StatelessWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context) => _MeasureHeight(
        onHeight: (h) => tabBarHeight.value = h,
        child: ValueListenableBuilder<int>(
          valueListenable: currentTab,
          builder: (context, tab, _) => Material(
            type: MaterialType.transparency,
            child: context.isIOS
                ? _IosTabBar(index: tab, onTap: selectTab, tabs: shellTabs)
                : NavigationBar(
                    selectedIndex: tab,
                    onDestinationSelected: selectTab,
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      // Ohne Tooltip: Die Beschriftung steht darunter, und über dem
                      // Navigator (App-Rahmen) gibt es keine Ebene für Tooltips.
                      for (final t in shellTabs) NavigationDestination(icon: Icon(t.$1), label: t.$2, tooltip: ''),
                    ],
                  ),
          ),
        ),
      );
}

/// Die Leiste erscheint beim Losfahren von unten statt plötzlich.
class _SlideIn extends StatelessWidget {
  const _SlideIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: Motion.of(context, Motion.medium),
        curve: Motion.curve,
        child: child,
        builder: (context, v, child) =>
            ClipRect(child: FractionalTranslation(translation: Offset(0, v), child: child)),
      );
}

/// Platzhalter über den Reitern wächst beim Losfahren mit der Leiste.
const companionMove = Motion.medium;

/// Läuft eine Begleitung für die zuletzt angesehene Fahrt?
bool companionShown(WidgetRef ref) {
  final companion = ref.watch(companionProvider);
  final s = ref.watch(lastTripProvider).value;
  return companion.active && s != null && s.trip.id == companion.tripId;
}

/// Fünf feste Reiter: Suche, Abfahrten, Karte, Meldungen, Mehr (Nutzervorgabe 23.09.2026).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int get _tab => currentTab.value;
  final _visited = <int>{0};

  void _onTab() => setState(() => _visited.add(currentTab.value));
  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    currentTab.addListener(_onTab);
    _visited.add(currentTab.value);
    WidgetsBinding.instance.addPostFrameCallback((_) => shellMounted.value = true);
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
    currentTab.removeListener(_onTab);
    shellMounted.value = false;
    _life.dispose();
    super.dispose();
  }

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
          _FadeTabs(
            index: _tab,
            children: [
              const HomeScreen(),
              // Erst beim ersten Öffnen aufbauen: keine Standortabfrage und keine
              // Meldungsabfrage, bevor der Tab gebraucht wird.
              // Karte erst beim ersten Öffnen (Standort, Kacheln).
              _visited.contains(1) ? const DeparturesScreen() : const SizedBox.shrink(),
              _visited.contains(2) ? const MapScreen() : const SizedBox.shrink(),
              _visited.contains(3) ? const MessagesScreen() : const SizedBox.shrink(),
              const MoreScreen(),
            ],
          ),
          const Positioned(left: 12, right: 12, bottom: 12, child: UpdateToast()),
        ]),
        // Platz für Unterwegs-Leiste und Reiter – beide liegen im App-Rahmen
        // und bleiben auf jeder Ansicht stehen.
        bottomNavigationBar: ValueListenableBuilder<double>(
          valueListenable: tabBarHeight,
          builder: (context, tabs, _) => AnimatedContainer(
            duration: companionMove,
            curve: Motion.curve,
            height: (companionShown(ref) ? companionBarHeight : 0) + tabs,
          ),
        ),
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

/// Reiter wie ein IndexedStack (Zustand bleibt erhalten): Der alte Reiter
/// verschwindet sofort, der neue blendet kurz ein und rückt dabei ein kleines
/// Stück nach oben. Nie liegen zwei Reiter übereinander – die Reiter haben
/// keinen eigenen Hintergrund, eine Überblendung sah deshalb wie ein Fehler
/// aus (Nutzerbefund 24.09.2026).
class _FadeTabs extends StatelessWidget {
  const _FadeTabs({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        for (var i = 0; i < children.length; i++)
          Offstage(
            offstage: i != index,
            child: TickerMode(enabled: i == index, child: _TabFadeIn(active: i == index, child: children[i])),
          ),
      ]);
}

class _TabFadeIn extends StatefulWidget {
  const _TabFadeIn({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_TabFadeIn> createState() => _TabFadeInState();
}

class _TabFadeInState extends State<_TabFadeIn> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Motion.medium, value: 1);
  late final _fade = CurvedAnimation(parent: _c, curve: Motion.curve);
  late final _slide = Tween(begin: const Offset(0, 0.012), end: Offset.zero).animate(_fade);

  @override
  void didUpdateWidget(_TabFadeIn old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      if (MediaQuery.of(context).disableAnimations) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: widget.child));
}
