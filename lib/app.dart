import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/providers.dart';
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

/// Für Benachrichtigungen, die einen Screen öffnen.
final navigatorKey = GlobalKey<NavigatorState>();

/// Liegt die Startseite mit den Reitern oben? Dann steht die Unterwegs-Leiste
/// über den Reitern (die Reiter verschieben sich nie); in allen anderen
/// Ansichten ganz unten. Fenster von unten zählen nicht mit.
final homeOnTop = ValueNotifier<bool>(true);

class _PageDepth extends NavigatorObserver {
  int _depth = 0;

  void _set() => homeOnTop.value = _depth <= 1;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _depth++;
    _set();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _depth--;
    _set();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _depth--;
    _set();
  }
}

final _pageDepth = _PageDepth();

class GleichDaApp extends ConsumerWidget {
  const GleichDaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final platform = Theme.of(context).platform;
    return MaterialApp(
      title: 'Gleich.da',
      navigatorKey: navigatorKey,
      navigatorObservers: [_pageDepth],
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
/// Außerdem die Unterwegs-Leiste unten, in jeder Ansicht an derselben Stelle.
Widget appFrame(BuildContext context, Widget? child) {
  final top = MediaQuery.paddingOf(context).top;
  return Stack(children: [
    // Unterwegs-Leiste unter jeder Ansicht; die Ansicht darüber verliert
    // dann den unteren Rand (den übernimmt die Leiste).
    Consumer(builder: (context, ref, _) {
      final following = ref.watch(companionProvider).active;
      return ValueListenableBuilder<bool>(
        valueListenable: homeOnTop,
        builder: (context, home, _) {
          // Auf der Startseite übernimmt HomeShell die Leiste (über den Reitern).
          final here = following && !home;
          return Column(children: [
            Expanded(child: MediaQuery.removePadding(context: context, removeBottom: here, child: child!)),
            if (here) const GlobalCompanionBar(),
          ]);
        },
      );
    }),
    Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: top,
      child: IgnorePointer(child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor)),
    ),
  ]);
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
    _life = AppLifecycleListener(
      onResume: () {
        ref.read(lastTripProvider.notifier).resume();
        ref.read(updateProvider.notifier).resume();
      },
      onHide: () => ref.read(lastTripProvider.notifier).pause(),
    );
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
        // Unterwegs-Leiste über den Reitern; die Reiter selbst bleiben fest.
        bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
          const GlobalCompanionBar(bottomPadding: false),
          context.isIOS
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

/// Die Unterwegs-Leiste für die ganze App, solange eine Begleitung läuft.
class GlobalCompanionBar extends ConsumerWidget {
  const GlobalCompanionBar({super.key, this.bottomPadding = true});

  /// Unteren Rand (Gestenleiste) mitnehmen – nicht über den Reitern.
  final bool bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companion = ref.watch(companionProvider);
    final s = ref.watch(lastTripProvider).value;
    if (!companion.active || s == null || s.trip.id != companion.tripId) return const SizedBox.shrink();
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    return Material(
      type: MaterialType.transparency,
      child: CompanionBar(
        bottomPadding: bottomPadding,
        trip: s.trip,
        now: now,
        issue: tripIssue(s.trip, lost: s.lost),
        gps: companion.freshGps(now),
        onStop: () => ref.read(companionProvider.notifier).stop(),
        onWalk: (step) => navigatorKey.currentState?.push(MaterialPageRoute(
            builder: (_) => WalkScreen(target: step.where.stop, platform: step.where.platform, departure: step.when))),
        onOpen: () {
          if (TripScreen.open > 0) return;
          navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const TripScreen()));
        },
      ),
    );
  }
}
