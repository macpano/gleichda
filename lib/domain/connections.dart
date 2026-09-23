import 'models.dart';

/// Ergebnis der Anschlussprüfung je Umstieg.
enum TransferState { safe, tight, missed }

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
List<TransferCheck> checkTransfers(Trip trip, {int transferMinutes = 3}) {
  final out = <TransferCheck>[];
  final legs = trip.legs;
  for (var i = 0; i < legs.length; i++) {
    if (legs[i].type != LegType.ride) continue;
    var j = i + 1;
    var walk = 0;
    while (j < legs.length && legs[j].type != LegType.ride) {
      walk += legs[j].durationMinutes ?? 0;
      j++;
    }
    if (j >= legs.length) break;
    final arr = legs[i].to.arrival?.best;
    final dep = legs[j].from.departure?.best;
    if (arr == null || dep == null) continue;
    final need = walk > 0 ? walk : transferMinutes;
    final slack = dep.difference(arr).inMinutes - need;
    final cancelled = legs[j].from.status == StopStatus.cancelled;
    out.add(TransferCheck(
      cancelled || slack < 0
          ? TransferState.missed
          : slack < 2
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
