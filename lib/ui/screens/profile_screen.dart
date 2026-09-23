import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/settings.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

/// Persönliches Profil: gilt für jede Suche automatisch.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    Widget pace(String label, String hint, Pace value, AppSettings Function(Pace) set) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(label, style: context.t.listRow),
            const SizedBox(height: 2),
            Text(hint, style: TextStyle(fontSize: 13, color: c.muted)),
            const SizedBox(height: 10),
            Segmented<Pace>(
              options: [for (final p in Pace.values) (p, p.label)],
              value: value,
              onChanged: (v) => updateSettings(ref, (_) => set(v)),
            ),
          ]),
        );
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          const SubpageHeader(title: 'Profil', backLabel: 'Mehr'),
          const SizedBox(height: 8),
          ListGroup(children: [
            pace('Gehgeschwindigkeit', 'Für Fußwege und „Loslaufen in …“', s.walkPace,
                (p) => s.copyWith(walkPace: p)),
            pace('Umsteigezeit', 'Mindestzeit am selben Halt: ${s.transferPace.transferMinutes} min',
                s.transferPace, (p) => s.copyWith(transferPace: p)),
          ]),
          const SizedBox(height: 16),
          ListGroup(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Fußweg höchstens', style: context.t.listRow),
                const SizedBox(height: 2),
                OneLine(
                  'Zum ersten und vom letzten Halt · In der Nähe: ${distanceText(s.walkRadiusMeters.toDouble())}',
                  style: TextStyle(fontSize: 13, color: c.muted),
                ),
                const SizedBox(height: 10),
                Segmented<int>(
                  options: [for (final m in walkLimitChoices) (m, '$m min')],
                  value: s.maxWalkMinutes,
                  onChanged: (v) => updateSettings(ref, (x) => x.copyWith(maxWalkMinutes: v)),
                ),
              ]),
            ),
          ]),
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
          Text(
            'Das Profil gilt für jede Suche. In den Verbindungen zeigt „Profil an“, dass es aktiv ist; '
            'ein Tipp schaltet es für diese Suche ab. Die Umsteigezeit bestimmt, wann ein Anschluss als knapp '
            'oder nicht erreichbar gilt.',
            style: context.t.secondary.copyWith(color: c.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
