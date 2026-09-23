import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/companion.dart';
import '../../state/companion.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme.dart';
import '../trip_status.dart';
import '../widgets.dart';
import 'trip_screen.dart';
import 'walk_screen.dart';

/// Unterwegs-Modus: oben groß nur der nächste Schritt.
class CompanionScreen extends ConsumerWidget {
  const CompanionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final s = ref.watch(lastTripProvider).value;
    final active = ref.watch(companionProvider).active;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    if (s == null) {
      return Scaffold(
        body: Padding(
          padding: pagePadding(context),
          child: const Column(children: [SubpageHeader(title: 'Unterwegs'), Notice('Keine Fahrt geöffnet.')]),
        ),
      );
    }
    final trip = s.trip;
    final step = nextStep(trip, now);
    final issue = tripIssue(trip, lost: s.lost);
    final leg = step.leg;
    final color = lineColor(context, leg?.line);
    final late = (step.when?.delayMinutes ?? 0) > 0;
    final whenColor = issue?.level == IssueLevel.cancelled
        ? c.red
        : (late || issue != null)
            ? c.orange
            : (step.when?.hasRealtime ?? false)
                ? c.green
                : c.ink;
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          SubpageHeader(
            title: 'Unterwegs',
            backLabel: 'Fahrt',
            trailing: FreshnessStamp(
              updatedAt: s.updatedAt,
              now: now,
              refreshing: s.refreshing,
              failed: s.failed,
              realtime: s.hasRealtime,
            ),
          ),
          const SizedBox(height: 8),
          if (issue != null) ...[
            IssueBanner(issue, onAlternatives: () => openAlternatives(context, trip)),
            const SizedBox(height: 14),
          ],
          Container(
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (leg != null)
                Row(children: [
                  LineBadge(leg.line),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OneLine(leg.direction ?? '', style: TextStyle(fontSize: 15, color: c.ink2)),
                  ),
                ]),
              const SizedBox(height: 14),
              Text(step.phase == CompanionPhase.onBoard ? 'Aussteigen' : 'Einsteigen',
                  style: TextStyle(fontSize: 13, color: c.muted)),
              OneLine(step.where.stop.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.25)),
              if (step.phase != CompanionPhase.onBoard && step.where.platform != null)
                Text('Steig ${step.where.platform}', style: TextStyle(fontSize: 15, color: c.ink2)),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                FadeText(step.when == null ? '' : countdown(step.when!.best, now),
                    style: context.t.time(30).copyWith(color: whenColor)),
                const SizedBox(width: 12),
                FadeText(step.when == null ? '' : hm(step.when!.best),
                    style: context.t.number(17).copyWith(color: c.ink2)),
                const Spacer(),
                if (step.phase == CompanionPhase.onBoard && (step.stopsLeft ?? 0) > 0)
                  Text(step.stopsLeft == 1 ? 'nächster Halt' : 'noch ${step.stopsLeft} Halte',
                      style: TextStyle(fontSize: 15, color: c.muted)),
              ]),
              const SizedBox(height: 16),
              _ProgressBar(progress: step.progress, color: color, glyph: VehicleGlyph(leg?.line?.mode, color: color, width: 32)),
            ]),
          ),
          const SizedBox(height: 16),
          if (step.phase == CompanionPhase.toStop || step.phase == CompanionPhase.transfer)
            ListGroup(children: [
              ListTile(
                title: const Text('Weg zum Steig'),
                trailing: Icon(Icons.chevron_right, color: c.chevron),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => WalkScreen(target: step.where.stop, platform: step.where.platform, departure: step.when))),
              ),
            ]),
          const SizedBox(height: 16),
          Text(
            active
                ? 'Die Anzeige steht auch in der Benachrichtigung. Sie endet von selbst nach der Ankunft.'
                : 'Mit „Losfahren“ steht diese Anzeige auch in der Benachrichtigung, bis du angekommen bist.',
            style: context.t.secondary.copyWith(color: c.muted),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: c.bar, border: Border(top: BorderSide(color: c.hair))),
        padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
        child: SizedBox(
          height: 50,
          child: active
              ? OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.ink,
                    side: BorderSide(color: c.hair),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
                  ),
                  onPressed: () async {
                    await ref.read(companionProvider.notifier).stop();
                    if (context.mounted) Navigator.of(context).maybePop();
                  },
                  child: const Text('Beenden', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                )
              : FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.onAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
                  ),
                  onPressed: () => ref.read(companionProvider.notifier).start(),
                  child: const Text('Losfahren', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
        ),
      ),
    );
  }
}

/// Balken bis zum Ausstieg; die Marke ist das Fahrzeug.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.color, required this.glyph});

  final double progress;
  final Color color;
  final Widget glyph;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 34,
      child: LayoutBuilder(builder: (context, box) {
        const end = 12.0;
        final w = box.maxWidth - end;
        final x = w * progress.clamp(0.0, 1.0);
        return Stack(clipBehavior: Clip.none, children: [
          Positioned(left: 0, right: end, top: 24, height: 6,
              child: Container(decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(3)))),
          Positioned(left: 0, width: x, top: 24, height: 6,
              child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)))),
          Positioned(right: 0, top: 21, width: 12, height: 12,
              child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 3), color: c.surface))),
          AnimatedPositioned(
            duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 400),
            left: (x - 24).clamp(0.0, w - 32),
            top: 0,
            child: glyph,
          ),
        ]);
      }),
    );
  }
}
