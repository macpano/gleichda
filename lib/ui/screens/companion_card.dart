import 'package:flutter/material.dart';

import '../../domain/companion.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../theme.dart';
import '../trip_status.dart';
import '../trip_map.dart';
import '../widgets.dart';
import 'walk_screen.dart';

/// Unterwegs: der nächste Schritt oben in der Fahrt, dieselben Angaben wie
/// in der laufenden Benachrichtigung. Einen eigenen Bildschirm gibt es nicht –
/// Fahrtverlauf, Umstieg und Alternativen stehen direkt darunter
/// (docs/konzept.md, „Unterwegs-Modus“).
class CompanionCard extends StatelessWidget {
  const CompanionCard({super.key, required this.trip, required this.now, this.issue});

  final Trip trip;
  final DateTime now;
  final TripIssue? issue;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final step = nextStep(trip, now);
    final leg = step.leg;
    final late = (step.when?.delayMinutes ?? 0) > 0;
    final whenColor = issue?.level == IssueLevel.cancelled
        ? c.red
        : (late || issue != null)
            ? c.orange
            : (step.when?.hasRealtime ?? false)
                ? c.green
                : c.ink;
    final boarding = step.phase == CompanionPhase.toStop ||
        step.phase == CompanionPhase.transfer ||
        step.phase == CompanionPhase.waiting;
    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          LiveDot(color: c.accent),
          const SizedBox(width: 8),
          Text('Unterwegs', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.accent)),
          const SizedBox(width: 10),
          if (leg != null) ...[
            LineBadge(leg.line),
            const SizedBox(width: 8),
            Expanded(child: OneLine(leg.direction ?? '', style: TextStyle(fontSize: 15, color: c.ink2))),
          ] else
            const Spacer(),
        ]),
        const SizedBox(height: 12),
        Text(
          step.phase == CompanionPhase.arrived
              ? 'Angekommen'
              : step.phase == CompanionPhase.onBoard
                  ? 'Aussteigen'
                  : 'Einsteigen',
          style: TextStyle(fontSize: 13, color: c.muted),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Expanded(
            child: OneLine(step.where.stop.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.25)),
          ),
          if (boarding && step.where.platform != null)
            Text('Steig ${step.where.platform}', style: TextStyle(fontSize: 15, color: c.ink2)),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          FadeText(step.when == null ? '' : countdown(step.when!.best, now),
              style: context.t.time(28).copyWith(color: whenColor)),
          const SizedBox(width: 10),
          FadeText(step.when == null ? '' : hm(step.when!.best),
              style: context.t.number(16).copyWith(color: c.ink2)),
          const Spacer(),
          if (step.phase == CompanionPhase.onBoard && (step.stopsLeft ?? 0) > 0)
            Text(step.stopsLeft == 1 ? 'nächster Halt' : 'noch ${step.stopsLeft} Halte',
                style: TextStyle(fontSize: 15, color: c.muted)),
          if (boarding)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: c.accent,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      WalkScreen(target: step.where.stop, platform: step.where.platform, departure: step.when))),
              child: const Text('Weg zum Steig', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 14),
        // Wo Fahrzeug und du gerade sind; tippen öffnet die große Karte.
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.input),
          child: SizedBox(
            height: 190,
            child: Stack(children: [
              TripMap(trip: trip, now: now, interactive: false),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripMapScreen())),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
