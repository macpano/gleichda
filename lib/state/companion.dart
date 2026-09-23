import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/companion.dart';
import '../domain/models.dart';
import '../ui/format.dart';
import '../ui/progress_bitmap.dart';
import '../ui/theme.dart';
import '../ui/trip_status.dart';
import 'notifications.dart';
import 'providers.dart';

class CompanionState {
  const CompanionState({this.active = false, this.tripId});

  final bool active;
  final String? tripId;
}

/// Unterwegs-Modus: begleitet die zuletzt angesehene Fahrt und hält die
/// laufende Benachrichtigung aktuell. Läuft über Fahrplan- und Echtzeit-
/// daten; GPS ist nicht nötig.
class CompanionController extends Notifier<CompanionState> {
  Timer? _timer;
  String? _lastKey;

  @override
  CompanionState build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(lastTripProvider, (_, next) {
      if (state.active) _update();
    });
    return const CompanionState();
  }

  Future<void> start() async {
    final trip = ref.read(lastTripProvider).value?.trip;
    if (trip == null) return;
    await Notifications.requestPermission();
    state = CompanionState(active: true, tripId: trip.id);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _update());
    // Während der Begleitung auch im Hintergrund aktualisieren.
    ref.read(lastTripProvider.notifier).keepAlive = true;
    await _update();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _lastKey = null;
    state = const CompanionState();
    ref.read(lastTripProvider.notifier).keepAlive = false;
    await Notifications.stopCompanion();
  }

  Future<void> _update() async {
    final s = ref.read(lastTripProvider).value;
    if (s == null || s.trip.id != state.tripId) {
      await stop();
      return;
    }
    final now = DateTime.now();
    final step = nextStep(s.trip, now);
    if (step.phase == CompanionPhase.arrived) {
      if (now.difference(s.trip.arrival.best) > const Duration(minutes: 1)) await stop();
      return;
    }
    final text = companionTexts(s.trip, step, now);
    final issue = tripIssue(s.trip, lost: s.lost);
    final percent = (step.progress * 100).round();
    final key = '${text.where}|${text.when}|$percent|${issue?.title}';
    if (key == _lastKey) return;
    _lastKey = key;
    final bar = await renderProgressBar(
      progress: step.progress,
      mode: step.leg?.line?.mode,
      color: AppColors.light.accent,
      track: const Color(0xFFD5D9DD),
    );
    await Notifications.showCompanion(
      header: text.header,
      where: text.where,
      when: text.when,
      progress: percent,
      bar: bar,
      alertColor: issue == null
          ? ((step.when?.delayMinutes ?? 0) > 0 ? AppColors.light.orange : null)
          : (issue.level == IssueLevel.cancelled ? AppColors.light.red : AppColors.light.orange),
      reason: issue?.title,
    );
  }
}

final companionProvider = NotifierProvider<CompanionController, CompanionState>(CompanionController.new);

/// Texte für Anzeige und Benachrichtigung.
({String header, String where, String when, String headline}) companionTexts(
    Trip trip, CompanionStep step, DateTime now) {
  final leg = step.leg;
  final line = leg?.line;
  final lineText = line == null ? '' : [_modeWord(line.mode), line.name].where((x) => x.isNotEmpty).join(' ');
  final header = [if (lineText.isNotEmpty) lineText, if (leg?.direction != null) leg!.direction!].join(' · ');
  final t = step.when?.best;
  final mins = t == null ? '' : countdown(t, now);
  final when = t == null ? '' : '$mins · ${hm(t)}';
  switch (step.phase) {
    case CompanionPhase.onBoard:
      final n = step.stopsLeft ?? 0;
      return (
        header: header,
        where: 'Aussteigen: ${step.where.stop.name}',
        when: when,
        headline: n <= 1 ? 'Nächster Halt: aussteigen' : 'Aussteigen in $n Halten',
      );
    case CompanionPhase.transfer:
    case CompanionPhase.toStop:
    case CompanionPhase.waiting:
      final platform = step.where.platform == null ? '' : ', Steig ${step.where.platform}';
      return (
        header: header,
        where: 'Einsteigen: ${step.where.stop.name}$platform',
        when: when,
        headline: '$lineText Richtung ${leg?.direction ?? ''}$platform, $mins',
      );
    case CompanionPhase.arrived:
      return (header: header, where: 'Angekommen: ${step.where.stop.name}', when: '', headline: 'Angekommen');
  }
}

String _modeWord(TransportMode m) => switch (m) {
      TransportMode.bus || TransportMode.onDemand => 'Bus',
      TransportMode.replacementBus => 'SEV',
      TransportMode.suspension => 'Schwebebahn',
      TransportMode.tram => 'Tram',
      TransportMode.subway => 'U-Bahn',
      TransportMode.suburbanRail => '',
      TransportMode.rail => '',
      TransportMode.ferry => 'Fähre',
      TransportMode.other => '',
    }
        .trim();
