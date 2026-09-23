import 'package:flutter/material.dart';

import '../../domain/companion.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../theme.dart';
import '../trip_status.dart';
import '../widgets.dart';

/// Höhe der Unterwegs-Leiste ohne unteren Bildschirmrand (Strich + Zeile).
const companionBarHeight = 64.5;

/// Unterwegs: der nächste Schritt als feste Leiste am unteren Rand – in jeder
/// Ansicht an derselben Stelle (wie der Mini-Player einer Musik-App), zusammen
/// mit „Beenden“. Oben ein feiner Fortschrittsstrich. Dieselben Angaben wie die
/// laufende Benachrichtigung (docs/konzept.md, „Unterwegs-Modus“).
class CompanionBar extends StatelessWidget {
  const CompanionBar({
    super.key,
    required this.trip,
    required this.now,
    required this.onStop,
    required this.onWalk,
    required this.onOpen,
    this.issue,
    this.gps,
    this.bottomPadding = true,
  });

  /// Unteren Bildschirmrand einrechnen (ganz unten), nicht über den Reitern.
  final bool bottomPadding;

  final Trip trip;
  final DateTime now;
  final VoidCallback onStop;

  /// Weg zum Steig des nächsten Einstiegs.
  final void Function(CompanionStep step) onWalk;

  /// Fahrt öffnen (Tipp auf die Leiste; zum Weg geht es über das Laufsymbol).
  final VoidCallback onOpen;
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
    final boarding = step.boarding;
    final walking = step.walking;
    final label = switch (step.phase) {
      CompanionPhase.arrived => 'Angekommen',
      CompanionPhase.onBoard => 'Aussteigen',
      CompanionPhase.toDestination => 'Zu Fuß zum Ziel',
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
      padding: EdgeInsets.only(bottom: bottomPadding ? MediaQuery.of(context).padding.bottom : 0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Fortschritt bis zum Ausstieg bzw. zur Abfahrt.
        LinearProgressIndicator(
          value: step.progress,
          minHeight: 2.5,
          color: lineColor(context, leg?.line),
          backgroundColor: Colors.transparent,
        ),
        InkWell(
          // Ein Tipp öffnet immer die Fahrt; vor dem Einsteigen führt das
          // Laufsymbol rechts zum Weg zum Steig.
          onTap: onOpen,
          child: SizedBox(
            height: 62,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                if (step.phase == CompanionPhase.toDestination)
                  ...[Icon(Icons.directions_walk, color: c.ink2), const SizedBox(width: 12)]
                else if (leg != null)
                  ...[LineBadge(leg.line), const SizedBox(width: 12)],
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
                // Zu Fuß (zum Einstieg, beim Umsteigen, zum Ziel): der Weg.
                if (walking)
                  IconButton(
                    tooltip: boarding ? 'Weg zum Steig' : 'Weg zum Ziel',
                    icon: Icon(Icons.directions_walk, color: c.accent),
                    onPressed: () => onWalk(step),
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
