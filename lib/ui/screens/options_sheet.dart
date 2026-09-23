import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets.dart';
import 'location_search_screen.dart';
import 'profile_screen.dart';

/// Suchoptionen: Zwischenhalt, Profil, Verkehrsmittel, barrierefreie Wege.
/// Der Zeitbezug steht beim Zeit-Schalter.
Future<void> showOptionsSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _OptionsSheet(),
    );

bool optionsActive(RouteSelection r, AppSettings s) => r.via != null || !s.isDefault;

class _OptionsSheet extends ConsumerWidget {
  const _OptionsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final route = ref.watch(routeProvider);
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text('Suchoptionen', style: context.t.section)),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fertig')),
          ]),
          const SizedBox(height: 8),
          ListGroup(children: [
            ListTile(
              title: const Text('Zwischenhalt'),
              subtitle: route.via == null ? null : Text(route.via!.name),
              trailing: route.via == null
                  ? Text('Hinzufügen', style: TextStyle(color: c.accent))
                  : IconButton(
                      tooltip: 'Entfernen',
                      icon: Icon(Icons.close, color: c.muted),
                      onPressed: () => ref.read(routeProvider.notifier).setVia(null),
                    ),
              onTap: () async {
                final l = await Navigator.of(context).push<Location>(MaterialPageRoute(
                    builder: (_) => const LocationSearchScreen(title: 'Zwischenhalt', stopsOnly: true, allowHere: false)));
                if (l != null) ref.read(routeProvider.notifier).setVia(l);
              },
            ),
            ListTile(
              title: const Text('Profil'),
              subtitle: Text(s.summary),
              trailing: Icon(Icons.chevron_right, color: c.chevron),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ]),
          const SizedBox(height: 16),
          const SectionTitle('Verkehrsmittel', small: true),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final g in ModeGroup.values)
              ChoiceChipX(
                label: g.label,
                icon: s.excludedModes.contains(g) ? Icons.close : Icons.check,
                selected: !s.excludedModes.contains(g),
                onTap: () => updateSettings(ref, (x) => x.copyWith(
                      excludedModes: x.excludedModes.contains(g)
                          ? ({...x.excludedModes}..remove(g))
                          : {...x.excludedModes, g},
                    )),
              ),
          ]),
          const SizedBox(height: 16),
          ListGroup(children: [
            SwitchListTile(
              title: const Text('Barrierefreie Wege'),
              subtitle: const Text('Ohne Stufen und Treppen'),
              value: s.accessible,
              onChanged: (v) => updateSettings(ref, (x) => x.copyWith(accessible: v)),
            ),
          ]),
          const SizedBox(height: 12),
          Text('Verkehrsmittel und barrierefreie Wege gehören zum Profil und gelten für jede Suche. '
              'In den Verbindungen lässt sich das Profil für eine Suche abschalten.',
              style: TextStyle(fontSize: 13, color: c.muted, height: 1.4)),
        ]),
      ),
    );
  }
}
