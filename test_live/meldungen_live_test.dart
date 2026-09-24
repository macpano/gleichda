// Live gegen den VRR-Testserver (nicht Teil der normalen Tests):
// flutter test test_live/meldungen_live_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/trias/trias_provider.dart';
import 'package:gleichda/data/vrr_provider.dart';
import 'package:gleichda/state/providers.dart' show MessagesState;

void main() {
  for (final (name, at) in [
    ('Hagen-Boele', (lat: 51.3895, lon: 7.4705)),
    ('Hagen-Vorhalle', (lat: 51.3810, lon: 7.4390)),
    ('Herdecke', (lat: 51.3990, lon: 7.4330)),
  ]) {
    test('Meldungen $name', () async {
      final dio = Dio();
      final p = VrrProvider(TriasProvider(dio), EfaClient(dio));
      final regions = await p.regionsOf(at);
      final near = await p.linesNear(at);
      final around = await p.linesAround(at);
      final nets = {for (final l in [...near, ...around]) lineKey(l.id).split(':').first};
      final list = await p.messages(regions: regions.keys.toList());
      final s = MessagesState(list, DateTime.now(),
          nearLines: {for (final l in near) lineKey(l.id)}, homeRegion: regions.keys.firstOrNull, areaNetworks: nets);
      // ignore: avoid_print
      print('$name: Gebiete $regions, Netze $nets, ${list.length} Meldungen, relevant ${list.where(s.isRelevant).length}');
      for (final m in list.where((m) => m.lineNames.contains('511') || m.title.contains('511') || (m.text ?? '').contains('511'))) {
        // ignore: avoid_print
        print('  511: ${m.title} | ${m.text} | ${m.validFrom} – ${m.validTo} · Netz ${s.networkOf(m)} · relevant ${s.isRelevant(m)}');
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
}
