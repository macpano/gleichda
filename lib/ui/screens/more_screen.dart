import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../theme.dart';
import '../widgets.dart';
import 'design_demo_screen.dart';

const appVersion = '0.1.0';

/// Mehr: Einstellungen, Datenschutz, Pflichtangaben.
// TODO: Fahrtenwecker, Meine Orte, Profil, Linienabos, Umsteigezeit,
// Gehgeschwindigkeit, barrierefreie Wege, Standort (Schritte 12–16).
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    return ListView(
      padding: pagePadding(context),
      children: [
        Text('Mehr', style: context.t.screenTitle),
        const SizedBox(height: 16),
        const SectionTitle('Allgemein', small: true),
        ListGroup(children: [
          _Row(
            label: 'Erscheinungsbild',
            value: switch (mode) {
              ThemeMode.light => 'Hell',
              ThemeMode.dark => 'Dunkel',
              ThemeMode.system => 'Wie System',
            },
            onTap: () => _pickTheme(context, ref, mode),
          ),
          _Row(
            label: 'Farben und Schriften',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DesignDemoScreen())),
          ),
        ]),
        const SizedBox(height: 16),
        const SectionTitle('Datenschutz', small: true),
        ListGroup(children: [
          _Row(
            label: 'Verlauf löschen',
            color: c.red,
            chevron: false,
            onTap: () => _clearHistory(context, ref),
          ),
        ]),
        const SizedBox(height: 16),
        const SectionTitle('Info', small: true),
        ListGroup(children: [
          _Row(
            label: 'Datenquellen',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const _SourcesScreen())),
          ),
        ]),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Fahrplandaten: VRR, DELFI e. V. Alle Angaben ohne Gewähr. Version $appVersion',
            style: TextStyle(fontSize: 12, height: 1.5, color: c.muted),
          ),
        ),
      ],
    );
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
        content: const Text('Alle gespeicherten Suchen und die zuletzt angesehene Fahrt werden von diesem Gerät entfernt. Favoriten bleiben.'),
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
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: OneLine(label, style: context.t.listRow.copyWith(color: color ?? c.ink))),
          if (value != null) Text(value!, style: context.t.listRow.copyWith(color: c.muted)),
          if (chevron) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: c.chevron),
          ],
        ]),
      ),
    );
  }
}

class _SourcesScreen extends StatelessWidget {
  const _SourcesScreen();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget item(String title, String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(text, style: context.t.secondary.copyWith(color: c.ink2, height: 1.4)),
          ]),
        );
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          const SubpageHeader(title: 'Datenquellen', backLabel: 'Mehr'),
          const SizedBox(height: 8),
          ListGroup(children: [
            item('VRR TRIAS (VDV 431)',
                'Haltestellensuche, Abfahrten, Verbindungen und Echtzeit. VRR OpenService, derzeit Testserver.'),
            item('VRR EFA OpenService',
                'Aktualisierung einer gespeicherten Fahrt (Fahrtverlauf mit Echtzeit). CC BY 4.0.'),
            item('Was das Gerät verlässt',
                'Nur die Suchanfragen an den VRR. Verlauf, Favoriten und die zuletzt angesehene Fahrt bleiben auf diesem Gerät. Kein Konto, keine Werbung, kein Tracking.'),
          ]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('Fahrplandaten: VRR, DELFI e. V. Alle Angaben ohne Gewähr.',
                style: TextStyle(fontSize: 12, height: 1.5, color: c.muted)),
          ),
        ],
      ),
    );
  }
}
