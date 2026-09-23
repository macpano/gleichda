import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'theme.dart';

enum IssueLevel { warning, cancelled }

/// Eine Abweichung in Klartext, z. B. „Umleitung: 2 Halte entfallen“.
class TripIssue {
  const TripIssue(this.level, this.title, [this.detail]);

  final IssueLevel level;
  final String title;
  final String? detail;

  Color color(BuildContext context) =>
      level == IssueLevel.cancelled ? context.c.red : context.c.orange;
}

/// Wichtigste Abweichung einer Verbindung oder null.
TripIssue? tripIssue(Trip trip, {bool lost = false}) {
  final rides = trip.rides;
  for (final r in rides) {
    final all = [r.from, ...r.intermediates, r.to];
    if (all.every((s) => s.status == StopStatus.cancelled)) {
      return TripIssue(IssueLevel.cancelled, 'Fahrt fällt aus',
          'Die Fahrt mit ${r.line?.name ?? 'dieser Linie'} wird nicht angeboten.');
    }
    if (r.from.status == StopStatus.cancelled) {
      return TripIssue(IssueLevel.cancelled, 'Einstieg entfällt',
          '${r.from.stop.name} wird nicht bedient.');
    }
    if (r.to.status == StopStatus.cancelled) {
      return TripIssue(IssueLevel.cancelled, 'Ausstieg entfällt',
          '${r.to.stop.name} wird nicht bedient.');
    }
  }
  final skipped = rides
      .expand((r) => r.intermediates)
      .where((s) => s.status == StopStatus.cancelled)
      .toList();
  final diverted = rides
      .expand((r) => [r.from, ...r.intermediates, r.to])
      .any((s) => s.status == StopStatus.diversion);
  if (skipped.isNotEmpty) {
    final n = skipped.length;
    final names = skipped.take(3).map((s) => s.stop.name).join(', ');
    return TripIssue(
      IssueLevel.warning,
      '${diverted ? 'Umleitung: ' : ''}${n == 1 ? '1 Halt entfällt' : '$n Halte entfallen'}',
      '$names ${n == 1 ? 'wird' : 'werden'} nicht bedient. Dein Ein- und Ausstieg sind nicht betroffen.',
    );
  }
  if (diverted) return const TripIssue(IssueLevel.warning, 'Umleitung');
  if (lost) {
    return const TripIssue(IssueLevel.warning, 'Fahrt nicht mehr in der Auskunft',
        'Angezeigt wird der letzte bekannte Stand.');
  }
  return null;
}

/// Ersatzverkehr (SEV) auf diesem Abschnitt?
bool isReplacement(Leg leg) => leg.line?.mode == TransportMode.replacementBus;

/// Wo der Ersatzbus hält, aus den Meldungen der Fahrt: die Sätze, die eine
/// Ersatzhaltestelle nennen (bevorzugt mit dem Namen des Einstiegs). null,
/// wenn keine Meldung etwas dazu sagt.
String? sevStopHint(Trip trip, Leg leg) {
  final ids = leg.messageIds.toSet();
  final msgs = [
    ...trip.messages.where((m) => ids.contains(m.id)),
    ...trip.messages.where((m) => !ids.contains(m.id)),
  ];
  final stopWords = leg.from.stop.name.split(RegExp(r'[\s,/]+')).where((w) => w.length > 3).toList();
  String? best;
  var bestScore = 0;
  for (final m in msgs) {
    final text = '${m.title}. ${m.text ?? ''}';
    for (final raw in text.split(RegExp(r'(?<=[.!?])\s+|\n+'))) {
      final sentence = raw.trim();
      final lower = sentence.toLowerCase();
      if (!lower.contains('ersatzhalt') && !lower.contains('ersatzbus') && !lower.contains('ersatzverkehr')) continue;
      var score = lower.contains('ersatzhalt') ? 2 : 1;
      if (stopWords.any((w) => lower.contains(w.toLowerCase()))) score += 2;
      if (score > bestScore) {
        bestScore = score;
        best = sentence;
      }
    }
  }
  if (best == null) return null;
  return best.length > 220 ? '${best.substring(0, 217)}…' : best;
}
