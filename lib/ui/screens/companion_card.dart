import 'package:flutter/material.dart';

import '../../domain/companion.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../theme.dart';
import '../trip_status.dart';
import '../widgets.dart';
import 'walk_screen.dart';

/// Unterwegs: der nächste Schritt als schmale Zeile oben in der Fahrt –
/// dieselben Angaben wie die laufende Benachrichtigung. Fahrtverlauf,
/// Umstieg und Alternativen stehen direkt darunter, die Karte hinter dem
/// Kartensymbol (docs/konzept.md, „Unterwegs-Modus“). Mit [onHide] lässt sie
/// sich ausblenden.
class CompanionCard extends StatelessWidget {
  const CompanionCard({super.key, required this.trip, required this.now, this.issue, this.gps, this.onHide});

  final Trip trip;
  final DateTime now;
  final TripIssue? issue;

  /// Eigene Position während der Begleitung; bestimmt nächsten Halt und
  /// Fortschritt, sonst die Uhrzeit.
  final GeoPoint? gps;
  final VoidCallback? onHide;

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
    ].join(' · ');
    final color = lineColor(context, leg?.line);
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          // Vor dem Einsteigen führt ein Tipp zum Weg zum Steig.
          onTap: boarding
              ? () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      WalkScreen(target: step.where.stop, platform: step.where.platform, departure: step.when)))
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            child: Row(children: [
              if (leg != null) ...[LineBadge(leg.line), const SizedBox(width: 10)],
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('$label ', style: TextStyle(fontSize: 13, color: c.muted)),
                    Expanded(
                      child: OneLine(step.where.stop.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    FadeText(step.when == null ? '' : countdown(step.when!.best, now),
                        style: context.t.time(14).copyWith(color: whenColor)),
                    if (step.when != null)
                      Text(' · ${hm(step.when!.best)}', style: context.t.number(13).copyWith(color: c.muted)),
                    if (detail.isNotEmpty)
                      Expanded(child: OneLine(' · $detail', style: TextStyle(fontSize: 13, color: c.muted)))
                    else
                      const Spacer(),
                  ]),
                ]),
              ),
              if (onHide != null)
                IconButton(
                  tooltip: 'Ausblenden',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.expand_less, size: 20, color: c.muted),
                  onPressed: onHide,
                ),
            ]),
          ),
        ),
        // Fortschritt bis zum Ausstieg bzw. zur Abfahrt als feiner Strich.
        LinearProgressIndicator(value: step.progress, minHeight: 2.5, color: color, backgroundColor: c.fill),
      ]),
    );
  }
}

/// Ausgeblendete Unterwegs-Anzeige: eine schmale Zeile zum Wiedereinblenden.
class CompanionCollapsed extends StatelessWidget {
  const CompanionCollapsed({super.key, required this.onShow});

  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.input),
      onTap: onShow,
      child: SizedBox(
        height: 32,
        child: Row(children: [
          const SizedBox(width: 4),
          LiveDot(color: c.accent),
          const SizedBox(width: 8),
          Text('Unterwegs', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.accent)),
          const Spacer(),
          Text('einblenden', style: TextStyle(fontSize: 13, color: c.muted)),
          Icon(Icons.expand_more, size: 18, color: c.muted),
        ]),
      ),
    );
  }
}
