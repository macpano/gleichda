import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository.dart';
import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';
import 'alarms_screen.dart';
import 'design_demo_screen.dart';
import 'places_screen.dart';
import 'profile_screen.dart';
import 'subscriptions_screen.dart';
import 'update_screen.dart';
import '../../state/updates.dart';


/// Mehr: Meine Fahrten, Einstellungen, Datenschutz, Pflichtangaben.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    final alarms = ref.watch(alarmsProvider).value ?? const <Alarm>[];
    final places = ref.watch(placesProvider).value ?? const <SavedPlace>[];
    final subs = ref.watch(subscriptionsProvider).value ?? const <Subscription>[];
    final update = ref.watch(updateProvider);
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    final active = alarms.where((a) => a.enabled).length;
    return ListView(
      padding: pagePadding(context),
      children: [
        Text('Mehr', style: context.t.screenTitle),
        const SizedBox(height: 16),
        ListGroup(children: [
          _Row(label: 'Fahrtenwecker', value: active == 0 ? (alarms.isEmpty ? '' : 'aus') : '$active aktiv',
              onTap: () => push(const AlarmsScreen())),
          _Row(label: 'Meine Orte', value: places.map((p) => p.name).take(2).join(', '),
              onTap: () => push(const PlacesScreen())),
          _Row(label: 'Favoriten und Verlauf', onTap: () => push(const _FavoritesHistoryScreen())),
        ]),
        const SizedBox(height: 16),
        const SectionTitle('Allgemein', small: true),
        ListGroup(children: [
          _Row(label: 'Profil', value: s.isDefault ? 'Standard' : 'angepasst', onTap: () => push(const ProfileScreen())),
          _Row(label: 'Linienabos', value: subs.map((x) => x.lineName).take(3).join(', '),
              onTap: () => push(const SubscriptionsScreen())),
          _Row(
            label: 'Erscheinungsbild',
            value: switch (mode) {
              ThemeMode.light => 'Hell',
              ThemeMode.dark => 'Dunkel',
              ThemeMode.system => 'Wie System',
            },
            onTap: () => _pickTheme(context, ref, mode),
          ),
        ]),
        const SizedBox(height: 16),
        const SectionTitle('Suche', small: true),
        ListGroup(children: [
          _Row(label: 'Umsteigezeit', value: s.transferPace.label,
              onTap: () => _pickPace(context, ref, 'Umsteigezeit', s.transferPace, (p) => s.copyWith(transferPace: p))),
          _Row(label: 'Gehgeschwindigkeit', value: s.walkPace.label,
              onTap: () => _pickPace(context, ref, 'Gehgeschwindigkeit', s.walkPace, (p) => s.copyWith(walkPace: p))),
          _SwitchRow(label: 'Barrierefreie Wege', value: s.accessible,
              onChanged: (v) => updateSettings(ref, (x) => x.copyWith(accessible: v))),
        ]),
        const SizedBox(height: 16),
        const SectionTitle('Datenschutz', small: true),
        ListGroup(children: [
          _SwitchRow(
            label: 'Standort beim Verwenden',
            value: s.useLocation,
            onChanged: (v) => updateSettings(ref, (x) => x.copyWith(useLocation: v)),
          ),
          _Row(label: 'Verlauf löschen', color: c.red, chevron: false, onTap: () => _clearHistory(context, ref)),
        ]),
        const SizedBox(height: 16),
        const SectionTitle('Info', small: true),
        ListGroup(children: [
          _Row(label: 'Datenquellen', onTap: () => push(const _TextScreen.sources())),
          _Row(label: 'Datenschutzerklärung', onTap: () => push(const _TextScreen.privacy())),
          _Row(label: 'Impressum', onTap: () => push(const _TextScreen.imprint())),
          _Row(
            label: 'Aktualisierung',
            value: update.hasUpdate ? 'Version ${update.latest!.version} verfügbar' : update.current,
            color: null,
            onTap: () => push(const UpdateScreen()),
          ),
          _Row(label: 'Farben und Schriften', onTap: () => push(const DesignDemoScreen())),
        ]),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Fahrplandaten: VRR, DELFI e. V. Alle Angaben ohne Gewähr. Version ${update.current}',
            style: TextStyle(fontSize: 12, height: 1.5, color: c.muted),
          ),
        ),
      ],
    );
  }

  Future<void> _pickPace(BuildContext context, WidgetRef ref, String title, Pace current,
      AppSettings Function(Pace) set) async {
    final picked = await showModalBottomSheet<Pace>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: RadioGroup<Pace>(
          groupValue: current,
          onChanged: (p) => Navigator.pop(ctx, p),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(alignment: Alignment.centerLeft, child: Text(title, style: ctx.t.section)),
            ),
            for (final p in Pace.values) RadioListTile<Pace>(value: p, title: Text(p.label)),
          ]),
        ),
      ),
    );
    if (picked != null) await updateSettings(ref, (_) => set(picked));
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref, ThemeMode current) async {
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (m) => Navigator.pop(ctx, m),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final (m, l) in [
              (ThemeMode.system, 'Wie System'),
              (ThemeMode.light, 'Hell'),
              (ThemeMode.dark, 'Dunkel'),
            ])
              RadioListTile<ThemeMode>(value: m, title: Text(l)),
          ]),
        ),
      ),
    );
    if (picked != null) await ref.read(repositoryProvider).setSetting('themeMode', picked.name);
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verlauf löschen?'),
        content: const Text(
            'Alle gespeicherten Suchen und die zuletzt angesehene Fahrt werden von diesem Gerät entfernt. Favoriten, Orte und Wecker bleiben.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(repositoryProvider).clearHistory();
    await ref.read(lastTripProvider.notifier).remove();
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, this.value, this.onTap, this.color, this.chevron = true});

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Color? color;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          OneLine(label, style: context.t.listRow.copyWith(color: color ?? c.ink)),
          const SizedBox(width: 12),
          Expanded(
            child: value == null
                ? const SizedBox.shrink()
                : Text(value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: context.t.listRow.copyWith(color: c.muted)),
          ),
          if (chevron) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: c.chevron),
          ],
        ]),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Row(children: [
          Expanded(child: OneLine(label, style: context.t.listRow)),
          Switch(value: value, onChanged: onChanged),
        ]),
      );
}

/// Favoriten und Verlauf verwalten.
class _FavoritesHistoryScreen extends ConsumerWidget {
  const _FavoritesHistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final favs = ref.watch(favoritesProvider).value ?? const <FavoriteItem>[];
    final hist = ref.watch(historyProvider).value ?? const <HistoryItem>[];
    final now = DateTime.now();
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          const SubpageHeader(title: 'Favoriten und Verlauf', backLabel: 'Mehr'),
          const SizedBox(height: 8),
          const SectionTitle('Favoriten', small: true),
          if (favs.isEmpty)
            const Notice('Keine Favoriten. Stern in einer Fahrt oder im Verlauf nach rechts wischen.')
          else
            ListGroup(children: [
              for (final f in favs)
                ListTile(
                  title: OneLine(f.name),
                  trailing: IconButton(
                    tooltip: 'Entfernen',
                    icon: Icon(Icons.delete_outline, color: c.muted),
                    onPressed: () => ref.read(repositoryProvider).deleteFavorite(f.id),
                  ),
                ),
            ]),
          const SizedBox(height: 16),
          const SectionTitle('Zuletzt gesucht', small: true),
          if (hist.isEmpty)
            const Notice('Kein Verlauf.')
          else
            ListGroup(children: [
              for (final h in hist)
                ListTile(
                  title: OneLine('${h.from.name} → ${h.to.name}'),
                  subtitle: Text(dayText(h.lastUsed, now)),
                  trailing: IconButton(
                    tooltip: 'Löschen',
                    icon: Icon(Icons.delete_outline, color: c.muted),
                    onPressed: () => ref.read(repositoryProvider).deleteHistory(h.key),
                  ),
                ),
            ]),
        ],
      ),
    );
  }
}

/// Textseiten: Datenquellen, Datenschutz, Impressum.
class _TextScreen extends StatelessWidget {
  const _TextScreen.sources()
      : title = 'Datenquellen',
        items = const [
          ('VRR TRIAS (VDV 431)',
              'Haltestellensuche, Abfahrten, Verbindungen und Echtzeit. VRR OpenService, derzeit Testserver.'),
          ('VRR EFA OpenService',
              'Aktualisierung einer gespeicherten Fahrt, Steigpositionen und Störungsmeldungen. CC BY 4.0.'),
          ('OpenStreetMap', 'Karte beim Weg zum Steig. © OpenStreetMap-Mitwirkende (ODbL), Kacheln: FOSSGIS e. V.'),
          ('DELFI e. V.', 'Deutschlandweite Soll-Fahrplandaten, auf denen die Auskunft beruht.'),
        ];

  const _TextScreen.privacy()
      : title = 'Datenschutz',
        items = const [
          ('Kein Konto, kein Tracking',
              'Gleichda braucht kein Konto, zeigt keine Werbung und enthält keine Analyse- oder Tracking-Bausteine.'),
          ('Was auf dem Gerät bleibt',
              'Verlauf, Favoriten, Meine Orte, Fahrtenwecker, Linienabos, Profil und die zuletzt angesehene Fahrt '
                  'liegen nur in der App auf diesem Gerät. „Verlauf löschen“ entfernt Suchen und die letzte Fahrt.'),
          ('Was das Gerät verlässt',
              'Suchanfragen gehen an den Verkehrsverbund Rhein-Ruhr (VRR): der eingegebene Suchbegriff bzw. die '
                  'Haltestelle, bei „Mein Standort“ die Koordinate. Kartenkacheln werden bei FOSSGIS e. V. geladen; '
                  'dabei ist deine IP-Adresse sichtbar.'),
          ('Standort',
              'Nur bei Nutzung und nur, wenn du ihn freigibst: für „Mein Standort“, Haltestellen in der Nähe und '
                  'den Weg zum Steig. Unter Mehr → Standort beim Verwenden lässt er sich ganz abschalten.'),
          ('Benachrichtigungen',
              'Unterwegs-Anzeige, Fahrtenwecker und Linienabos werden auf dem Gerät erzeugt. Es gibt keinen Server '
                  'von Gleichda und kein Push-Token.'),
        ];

  // TODO: echte Daten – Name und Anschrift der verantwortlichen Person vor
  // einer Veröffentlichung eintragen (Impressumspflicht).
  const _TextScreen.imprint()
      : title = 'Impressum',
        items = const [
          ('Angaben folgen', 'Diese Testfassung wird nicht öffentlich angeboten. Vor einer Veröffentlichung steht hier das Impressum.'),
          ('Haftung', 'Alle Angaben ohne Gewähr. Fahrplandaten: VRR, DELFI e. V.'),
        ];

  final String title;
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          SubpageHeader(title: title, backLabel: 'Mehr'),
          const SizedBox(height: 8),
          ListGroup(children: [
            for (final (h, t) in items)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(h, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(t, style: context.t.secondary.copyWith(color: c.ink2, height: 1.4)),
                ]),
              ),
          ]),
          const SizedBox(height: 16),
          Text('Fahrplandaten: VRR, DELFI e. V. Alle Angaben ohne Gewähr.',
              style: TextStyle(fontSize: 12, height: 1.5, color: c.muted)),
        ],
      ),
    );
  }
}
