import 'package:flutter/material.dart';

import '../../domain/companion.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../theme.dart';
import '../trip_status.dart';
import '../widgets.dart';
import 'walk_screen.dart';

/// Unterwegs: der nächste Schritt als feste Leiste am unteren Rand der Fahrt,
/// zusammen mit „Beenden“ – immer sichtbar, ohne den Fahrtverlauf zu
/// verschieben. Oben ein feiner Fortschrittsstrich. Dieselben Angaben wie die
/// laufende Benachrichtigung (docs/konzept.md, „Unterwegs-Modus“).
class CompanionBar extends StatelessWidget {
  const CompanionBar({super.key, required this.trip, required this.now, required this.onStop, this.issue, this.gps});

  final Trip trip;
  final DateTime now;
  final VoidCallback onStop;
  final TripIssue? issue;

  /// Eigene Position während der Begleitung; bestimmt nächsten Halt und
  /// Fortschritt, sonst die Uhrzeit.
  final GeoPoint? gps;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final step = nextStep(trip, now, gps: gps);
    final next = step.nextBeforeExit;
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
    final label = switch (step.phase) {
      CompanionPhase.arrived => 'Angekommen',
      CompanionPhase.onBoard => 'Aussteigen',
      _ => 'Einsteigen',
    };
    final detail = [
      if (boarding && step.where.platform != null) 'Steig ${step.where.platform}',
      if (next != null)
        'nächster Halt ${next.stop.name}'
      else if (step.phase == CompanionPhase.onBoard && (step.stopsLeft ?? 0) > 1)
        'noch ${step.stopsLeft} Halte',
    ];
    const line = TextStyle(height: 1.25);
    return Container(
      decoration: BoxDecoration(color: c.bar, border: Border(top: BorderSide(color: c.hair, width: 0.5))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Fortschritt bis zum Ausstieg bzw. zur Abfahrt.
        LinearProgressIndicator(
          value: step.progress,
          minHeight: 2.5,
          color: lineColor(context, leg?.line),
          backgroundColor: Colors.transparent,
        ),
        InkWell(
          // Vor dem Einsteigen führt ein Tipp zum Weg zum Steig.
          onTap: boarding
              ? () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      WalkScreen(target: step.where.stop, platform: step.where.platform, departure: step.when)))
              : null,
          child: SizedBox(
            height: 62,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                if (leg != null) ...[LineBadge(leg.line), const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '$label ', style: TextStyle(fontSize: 13, color: c.muted)),
                          TextSpan(text: step.where.stop.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: line.copyWith(color: c.ink),
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(children: [
                          if (step.when != null) ...[
                            TextSpan(
                                text: countdown(step.when!.best, now),
                                style: context.t.time(14).copyWith(color: whenColor)),
                            TextSpan(text: ' · ${hm(step.when!.best)}', style: context.t.number(13)),
                          ],
                          for (final d in detail) TextSpan(text: ' · $d'),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: line.copyWith(fontSize: 13, color: c.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Vor dem Einsteigen (auch beim Umsteigen): Weg zum Steig.
                if (boarding)
                  IconButton(
                    tooltip: 'Weg zum Steig',
                    icon: Icon(Icons.directions_walk, color: c.accent),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            WalkScreen(target: step.where.stop, platform: step.where.platform, departure: step.when))),
                  ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: c.muted),
                  onPressed: onStop,
                  child: const Text('Beenden', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
