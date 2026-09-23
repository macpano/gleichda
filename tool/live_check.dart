// ignore_for_file: avoid_print
// Prüft die Kette live gegen den VRR-Testserver: suchen, Verbindung,
// Fahrt über EFA aktualisieren.   dart run tool/live_check.dart
import 'package:dio/dio.dart';
import 'package:gleichda/data/efa/efa_client.dart';
import 'package:gleichda/data/transit_provider.dart';
import 'package:gleichda/data/trias/trias_provider.dart';
import 'package:gleichda/data/vrr_provider.dart';

Future<void> main() async {
  final dio = Dio();
  final trias = TriasProvider(dio);
  final efa = EfaClient(dio);
  final p = VrrProvider(trias, efa);
  final a = (await p.searchLocations('Wuppertal Alter Markt')).first;
  final b = (await p.searchLocations('Wuppertal Vohwinkel Bf')).first;
  print('Von ${a.name} (${a.id}) nach ${b.name} (${b.id})');
  final trips = await p.planTrip(TripQuery(from: a, to: b, time: DateTime.now()));
  final t = trips.first;
  print('${trips.length} Verbindungen, erste: ${t.rides.map((r) => r.line!.name).join(' > ')}');
  var viaEfa = 0;
  for (final l in t.rides) {
    if (await refreshLegViaEfa(efa, l) != null) viaEfa++;
  }
  print('EFA fand $viaEfa von ${t.rides.length} Abschnitten');
  final fresh = await p.refreshTrip(t);
  print('Aktualisiert: ${fresh != null}, Ankunft ${fresh?.arrival.best.toLocal()}');
  dio.close();
}
