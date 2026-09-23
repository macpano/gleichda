import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/updates.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

/// Hinweis oben auf der Startseite, wenn eine neuere Version bereitsteht.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(updateProvider);
    final show = u.hasUpdate || u.phase == UpdatePhase.downloading || u.phase == UpdatePhase.installing;
    if (!show) return const SizedBox.shrink();
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.card),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpdateScreen())),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(children: [
              Icon(Icons.system_update_outlined, color: c.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  OneLine('Version ${u.latest?.version ?? ''} verfügbar', style: context.t.listRow),
                  OneLine(
                    switch (u.phase) {
                      UpdatePhase.downloading => 'Wird geladen … ${u.progress ?? 0} %',
                      UpdatePhase.installing => 'Installation läuft',
                      _ => 'Installiert: ${u.current}',
                    },
                    style: context.t.number(13).copyWith(color: c.muted),
                  ),
                ]),
              ),
              if (u.phase == UpdatePhase.available)
                TextButton(
                  onPressed: () => ref.read(updateProvider.notifier).install(),
                  child: const Text('Aktualisieren'),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Mehr → Aktualisierung.
class UpdateScreen extends ConsumerWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final u = ref.watch(updateProvider);
    final auto = ref.watch(updateAutoProvider).value ?? true;
    final now = DateTime.now();
    final status = switch (u.phase) {
      UpdatePhase.checking => 'Wird geprüft …',
      UpdatePhase.upToDate => 'Aktuell',
      UpdatePhase.available => 'Version ${u.latest!.version} verfügbar',
      UpdatePhase.downloading => 'Wird geladen … ${u.progress ?? 0} %',
      UpdatePhase.installing => 'Installation läuft',
      UpdatePhase.failed => u.error ?? 'Fehlgeschlagen',
      UpdatePhase.idle => 'Noch nicht geprüft',
    };
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          const SubpageHeader(title: 'Aktualisierung', backLabel: 'Mehr'),
          const SizedBox(height: 8),
          ListGroup(children: [
            _Line('Installiert', u.current.isEmpty ? '–' : u.current),
            _Line('Neueste', u.latest?.version ?? '–'),
            _Line('Stand', status,
                color: u.phase == UpdatePhase.failed
                    ? c.orange
                    : u.hasUpdate
                        ? c.accent
                        : null),
            if (u.checkedAt != null) _Line('Geprüft', '${relativeDay(u.checkedAt!, now)} ${hm(u.checkedAt!)}'),
          ]),
          const SizedBox(height: 16),
          if (u.phase == UpdatePhase.downloading)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(value: (u.progress ?? 0) / 100, color: c.accent, backgroundColor: c.fill),
            ),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
              ),
              onPressed: u.phase == UpdatePhase.checking || u.phase == UpdatePhase.downloading
                  ? null
                  : u.hasUpdate
                      ? () => ref.read(updateProvider.notifier).install()
                      : () => ref.read(updateProvider.notifier).check(),
              child: Text(u.hasUpdate ? 'Jetzt aktualisieren' : 'Nach Aktualisierung suchen',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          ListGroup(children: [
            SwitchListTile(
              title: const Text('Automatisch prüfen'),
              subtitle: const Text('Beim Start und alle 6 Stunden'),
              value: auto,
              onChanged: (v) => ref.read(updateProvider.notifier).setAuto(v),
            ),
          ]),
          if (u.hasUpdate && (u.latest?.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            const SectionTitle('Neu in dieser Version', small: true),
            ListGroup(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(u.latest!.notes!, style: context.t.secondary.copyWith(color: c.ink2, height: 1.4)),
              ),
            ]),
          ],
          const SizedBox(height: 16),
          Text(
            'Die App fragt die neueste Veröffentlichung auf GitHub ab (github.com/macpano/gleichda). '
            'Eingespielt wird nur auf Tipp; Android fragt beim ersten Mal, ob Gleichda Apps installieren darf.',
            style: context.t.secondary.copyWith(color: c.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Text(label, style: context.t.listRow),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.t.number(16).copyWith(color: color ?? context.c.muted)),
            ),
          ]),
        ),
      );
}
