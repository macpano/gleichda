import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/updates.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

/// Kleine Meldung über der unteren Leiste, sobald eine neue Version fertig
/// geladen ist – auf jedem Reiter. „Später“ blendet sie bis zum nächsten
/// Öffnen der App aus.
class UpdateToast extends ConsumerStatefulWidget {
  const UpdateToast({super.key});

  @override
  ConsumerState<UpdateToast> createState() => _UpdateToastState();
}

class _UpdateToastState extends ConsumerState<UpdateToast> {
  String? _dismissed;

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(updateProvider);
    final version = u.latest?.version;
    final show = (u.ready || u.phase == UpdatePhase.installing) && _dismissed != version;
    final c = context.c;
    return AnimatedSwitcher(
      duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 250),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
          child: child,
        ),
      ),
      child: !show
          ? const SizedBox.shrink()
          : Material(
              key: ValueKey(version),
              color: c.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.card),
                side: BorderSide(color: c.hair),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                child: Row(children: [
                  Icon(Icons.system_update_outlined, color: c.accent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      OneLine('Update verfügbar', style: context.t.listRow.copyWith(fontWeight: FontWeight.w600)),
                      OneLine(
                        u.error ??
                            (u.phase == UpdatePhase.installing
                                ? 'Installation läuft …'
                                : 'Version $version · bereits geladen'),
                        style: TextStyle(fontSize: 13, color: u.error != null ? c.orange : c.muted),
                      ),
                    ]),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: c.muted),
                    onPressed: () => setState(() => _dismissed = version),
                    child: const Text('Später'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: c.onAccent,
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.input)),
                    ),
                    onPressed: () => ref.read(updateProvider.notifier).install(),
                    child: const Text('Installieren', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ]),
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
      UpdatePhase.ready => 'Version ${u.latest!.version} geladen, bereit zur Installation',
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
              child: Text(u.ready ? 'Installieren' : u.hasUpdate ? 'Laden und installieren' : 'Nach Aktualisierung suchen',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          ListGroup(children: [
            SwitchListTile(
              title: const Text('Automatisch laden'),
              subtitle: const Text('Beim Öffnen und alle 6 Stunden prüfen, neue Version im Hintergrund laden'),
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
            'Die App fragt die neueste Veröffentlichung auf GitHub ab (github.com/macpano/gleichda) und lädt sie '
            'im Hintergrund. Installiert wird erst auf Tipp; Android fragt beim ersten Mal, ob Gleichda Apps '
            'installieren darf, und bestätigt jede Installation selbst. Die Daten in der App bleiben erhalten.',
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
