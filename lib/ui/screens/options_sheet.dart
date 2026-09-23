import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets.dart';
import 'location_search_screen.dart';
import 'profile_screen.dart';

/// Suchoptionen wie im Entwurf: Zwischenhalt, Profil, Verkehrsmittel,
/// barrierefreie Wege. Der Zeitbezug steht beim Zeit-Schalter.
Future<void> showOptionsSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _OptionsSheet(),
    );

bool optionsActive(RouteSelection r, AppSettings s) => r.via != null || !s.isDefault;

class _OptionsSheet extends ConsumerWidget {
  const _OptionsSheet();

  static const _modes = [
    ModeGroup.bus,
    ModeGroup.suspension,
    ModeGroup.suburbanRail,
    ModeGroup.regional,
    ModeGroup.longDistance,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final route = ref.watch(routeProvider);
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SheetHeader('Suchoptionen'),
          const SizedBox(height: 12),
          ListGroup(children: [
            ValueRow(
              label: 'Zwischenhalt',
              value: route.via?.name ?? 'Hinzufügen',
              valueColor: route.via == null ? c.accent : c.muted,
              chevron: false,
              trailing: route.via == null
                  ? null
                  : IconButton(
                      tooltip: 'Entfernen',
                      icon: Icon(Icons.close, size: 20, color: c.muted),
                      onPressed: () => ref.read(routeProvider.notifier).setVia(null),
                    ),
              onTap: () async {
                final l = await Navigator.of(context).push<Location>(MaterialPageRoute(
                    builder: (_) => const LocationSearchScreen(title: 'Zwischenhalt', stopsOnly: true, allowHere: false, showNearby: false)));
                if (l != null) ref.read(routeProvider.notifier).setVia(l);
              },
            ),
            ValueRow(
              label: 'Profil',
              value: s.isDefault ? 'Standard' : 'angepasst',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ]),
          const SizedBox(height: 16),
          const SectionTitle('Verkehrsmittel', small: true),
          ListGroup(children: [
            for (final g in _modes)
              InkWell(
                onTap: () => updateSettings(ref, (x) => x.copyWith(
                      excludedModes: x.excludedModes.contains(g)
                          ? ({...x.excludedModes}..remove(g))
                          : {...x.excludedModes, g},
                    )),
                child: SizedBox(
                  height: 46,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Expanded(child: Text(g.label, style: const TextStyle(fontSize: 16))),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: s.excludedModes.contains(g) ? 0 : 1,
                        child: Icon(Icons.check, size: 22, color: c.accent),
                      ),
                    ]),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          const SectionTitle('Fußweg höchstens', small: true),
          Segmented<int>(
            options: [for (final m in walkLimitChoices) (m, '$m min')],
            value: s.maxWalkMinutes,
            onChanged: (v) => updateSettings(ref, (x) => x.copyWith(maxWalkMinutes: v)),
          ),
          const SizedBox(height: 16),
          ListGroup(children: [
            ValueRow(
              label: 'Barrierefreie Wege',
              trailing: Switch(
                value: s.accessible,
                onChanged: (v) => updateSettings(ref, (x) => x.copyWith(accessible: v)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
