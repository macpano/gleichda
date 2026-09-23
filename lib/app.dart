import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/providers.dart';
import 'state/updates.dart';
import 'ui/screens/update_screen.dart';
import 'ui/screens/departures_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/messages_screen.dart';
import 'ui/screens/more_screen.dart';
import 'ui/theme.dart';

/// Für Benachrichtigungen, die einen Screen öffnen.
final navigatorKey = GlobalKey<NavigatorState>();

class GleichDaApp extends ConsumerWidget {
  const GleichDaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final platform = Theme.of(context).platform;
    return MaterialApp(
      title: 'Gleich.da',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: buildTheme(Brightness.light, platform),
      darkTheme: buildTheme(Brightness.dark, platform),
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeShell(),
    );
  }
}

/// Vier feste Tabs: Suche, Abfahrten, Meldungen, Mehr.
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
              _visited.contains(1) ? const DeparturesScreen() : const SizedBox.shrink(),
              _visited.contains(2) ? const MessagesScreen() : const SizedBox.shrink(),
              const MoreScreen(),
            ],
          ),
          const Positioned(left: 12, right: 12, bottom: 12, child: UpdateToast()),
        ]),
        bottomNavigationBar: context.isIOS
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
