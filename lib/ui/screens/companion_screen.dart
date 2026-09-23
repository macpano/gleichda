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
              _ProgressBar(progress: step.progress, color: color, glyph: VehicleGlyph(leg?.line?.mode, color: color, width: _ProgressBar.glyphWidth)),
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

/// Balken bis zum Ausstieg; die Marke ist das Fahrzeug. Aufbau wie das Bild
/// in der Benachrichtigung (`renderProgressBar`): das Fahrzeug steht auf dem
/// Balken, seine Front an der Spitze des gefüllten Teils, am Ende die Zielmarke.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.color, required this.glyph});

  static const glyphWidth = 46.0;
  static const _glyphHeight = glyphWidth * 36 / 62;
  static const _bar = 8.0;
  static const _target = 16.0;

  final double progress;
  final Color color;
  final Widget glyph;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const barTop = _glyphHeight + 1;
    return SizedBox(
      height: barTop + _target / 2 + _bar / 2 + 2,
      child: LayoutBuilder(builder: (context, box) {
        // Bündig mit dem Text; am Anfang steht das Fahrzeug ganz auf dem Balken.
        const left = _bar / 2;
        final right = box.maxWidth - _target / 2;
        final x = left + (right - left) * progress.clamp(0.0, 1.0);
        final duration =
            MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 400);
        return Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: left - _bar / 2,
            right: _target / 2,
            top: barTop,
            height: _bar,
            child: Container(decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(_bar))),
          ),
          AnimatedPositioned(
            duration: duration,
            left: left - _bar / 2,
            width: x - left + _bar,
            top: barTop,
            height: _bar,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(_bar))),
          ),
          Positioned(
            left: right - _target / 2,
            top: barTop + _bar / 2 - _target / 2,
            width: _target,
            height: _target,
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              alignment: Alignment.center,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.surface),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: duration,
            left: (x - glyphWidth * 0.7).clamp(0.0, right - glyphWidth),
            top: 0,
            child: glyph,
          ),
        ]);
      }),
    );
  }
}
