import 'models.dart';

/// Abo für ein ganzes Verkehrsunternehmen statt einer Linie: `lineId` ist
/// dann „netz:Kürzel“ (z. B. „netz:wsw“), `lineName` der Name.
const operatorPrefix = 'netz:';

String operatorSubId(String network) => '$operatorPrefix$network';

bool isOperatorSub(Subscription s) => s.lineId.startsWith(operatorPrefix);

/// Netzkürzel einer Linienkennung („wsw:66604“ → „wsw“).
String networkOf(String lineKey) => lineKey.split(':').first;

/// Betrifft die Meldung dieses Abo? Linie: dieselbe Linie; Unternehmen: eine
/// seiner Linien.
bool subscriptionCovers(Subscription s, Message m) {
  if (isOperatorSub(s)) {
    final net = s.lineId.substring(operatorPrefix.length);
    return m.lineIds.any((k) => networkOf(k) == net);
  }
  final p = s.lineId.split(':');
  final key = p.length >= 2 ? '${p[0]}:${p[1]}' : s.lineId;
  return m.lineIds.contains(key);
}
