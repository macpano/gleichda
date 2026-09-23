import 'models.dart';

/// Ergebnis der Anschlussprüfung je Umstieg.
enum TransferState { safe, tight, missed, staySeated, guaranteed }

class TransferCheck {
  const TransferCheck(this.state, this.slackMinutes, this.at);

  final TransferState state;

  /// Puffer nach Umsteigeweg und persönlicher Umsteigezeit.
  final int slackMinutes;

  /// Halt, an dem umgestiegen wird.
  final Location at;
}

/// Prüft jeden Umstieg: erwartete Ankunft plus Umsteigeweg (bzw. die
/// persönliche Umsteigezeit am selben Halt) gegen die erwartete Abfahrt.
///
/// [guaranteed]: Indizes der Fahrtabschnitte, auf die ein gesicherter
/// Anschluss führt – dort wartet der Anschluss in der Regel.
List<TransferCheck> checkTransfers(Trip trip, {int transferMinutes = 3, Set<int> guaranteed = const {}}) {
  final out = <TransferCheck>[];
  final legs = trip.legs;
  for (var i = 0; i < legs.length; i++) {
    if (legs[i].type != LegType.ride) continue;
    var j = i + 1;
    var walk = 0;
    var stay = false;
    while (j < legs.length && legs[j].type != LegType.ride) {
      walk += legs[j].durationMinutes ?? 0;
      stay = stay || legs[j].staySeated;
      j++;
    }
    if (j >= legs.length) break;
    // Im selben Fahrzeug sitzen bleiben: kein Anschluss, den man verpassen kann.
    if (stay) {
      out.add(TransferCheck(TransferState.staySeated, 0, legs[i].to.stop));
      continue;
    }
    final arr = legs[i].to.arrival?.best;
    final dep = legs[j].from.departure?.best;
    if (arr == null || dep == null) continue;
    // Nicht erreichbar erst, wenn die Zeit nicht einmal für den Umsteigeweg
    // reicht (am selben Halt: mindestens 1 min). Die persönliche
    // Umsteigezeit entscheidet nur zwischen „sicher“ und „knapp“ – eine
    // Verbindung mit 2 min Umstieg, die die Auskunft selbst anbietet, ist
    // machbar.
    final buffer = dep.difference(arr).inMinutes;
    final need = walk > 0 ? walk : 1;
    final slack = buffer - (walk > 0 ? walk : 0);
    final cancelled = legs[j].from.status == StopStatus.cancelled;
    out.add(TransferCheck(
      !cancelled && guaranteed.contains(j)
          ? TransferState.guaranteed
          : cancelled || buffer < need
          ? TransferState.missed
          : slack < transferMinutes
              ? TransferState.tight
              : TransferState.safe,
      slack,
      legs[i].to.stop,
    ));
  }
  return out;
}

bool isReachable(Trip trip, {int transferMinutes = 3}) =>
    !checkTransfers(trip, transferMinutes: transferMinutes)
        .any((c) => c.state == TransferState.missed);

/// Halt gilt als passiert, wenn seine beste bekannte Abfahrt (bzw. Ankunft)
/// vor [now] liegt.
bool isPassed(StopTime s, DateTime now) {
  final t = (s.departure ?? s.arrival)?.best;
  return t != null && t.isBefore(now);
}
