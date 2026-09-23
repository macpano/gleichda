// Holt Rohantworten vom VRR-Testserver und legt sie als Fixtures ab.
//
//   dart run tool/fixtures.dart
//
// TRIAS: openservice-test.vrr.de/static02/trias
// EFA:   openservice-test.vrr.de/static02/XML_…_REQUEST (rapidJSON)
//
// Die Tests laufen danach nur gegen diese Dateien, nie gegen den Server.
import 'dart:convert';
import 'dart:io';

import 'package:gleichda/data/trias/trias_requests.dart';

const base = 'https://openservice-test.vrr.de/static02';
final out = Directory('test/fixtures');
final http = HttpClient()..userAgent = 'Gleich.da/0.1 (Entwicklung)';

Future<String> trias(String body) async {
  final req = await http.postUrl(Uri.parse('$base/trias'));
  req.headers.contentType = ContentType('text', 'xml', charset: 'utf-8');
  req.add(utf8.encode(body));
  final res = await req.close();
  final text = await res.transform(utf8.decoder).join();
  if (res.statusCode != 200) return 'HTTP ${res.statusCode}\n$text';
  return text;
}

Future<String> efa(String endpoint, Map<String, String> params) async {
  final uri = Uri.parse('$base/$endpoint').replace(queryParameters: {
    'outputFormat': 'rapidJSON',
    'coordOutputFormat': 'WGS84[dd.ddddd]',
    'useRealtime': '1',
    ...params,
  });
  final req = await http.getUrl(uri);
  final res = await req.close();
  return res.transform(utf8.decoder).join();
}

void save(String name, String content) {
  File('${out.path}/$name').writeAsStringSync(content);
  stdout.writeln('  $name  ${content.length} Zeichen');
}

String firstStopRef(String xml) =>
    RegExp(r'<trias:StopPointRef>([^<]+)</trias:StopPointRef>')
        .firstMatch(xml)!
        .group(1)!;

Future<void> main() async {
  out.createSync(recursive: true);
  const r = TriasRequests();

  stdout.writeln('TRIAS');
  final hbf = await trias(r.locationInformation('Wuppertal Hauptbahnhof', limit: 5));
  save('trias_lir_hbf.xml', hbf);
  final hbfRef = firstStopRef(hbf);

  save('trias_lir_markt.xml', await trias(r.locationInformation('Markt', limit: 10)));

  final am = await trias(r.locationInformation('Wuppertal Alter Markt', limit: 3));
  save('trias_lir_alter_markt.xml', am);
  final amRef = firstStopRef(am);

  save('trias_lir_near.xml', await trias(r.locationsNear(51.27193, 7.19853, radiusMeters: 600)));

  final vw = await trias(r.locationInformation('Wuppertal Vohwinkel Bf', limit: 3));
  final vwRef = firstStopRef(vw);

  final now = DateTime.now();
  save('trias_se_hbf.xml', await trias(r.stopEvent(hbfRef, time: now, limit: 12)));
  save('trias_se_alter_markt.xml', await trias(r.stopEvent(amRef, time: now, limit: 12)));
  save('trias_se_onward.xml',
      await trias(r.stopEvent(amRef, time: now, limit: 3, onwardCalls: true)));

  final trip = await trias(r.trip(TriasStop(amRef), TriasStop(vwRef), time: now, limit: 4));
  save('trias_trip_alter_markt_vohwinkel.xml', trip);
  save('trias_trip_coord.xml', await trias(r.trip(
      const TriasCoord(51.26420, 7.17840, 'Mein Standort'), TriasStop(hbfRef),
      time: now, limit: 3)));

  // TripInfoRequest mit einer echten Fahrt aus der Verbindungsantwort.
  final jr = RegExp(r'<trias:JourneyRef>([^<]+)</trias:JourneyRef>').firstMatch(trip);
  if (jr != null) {
    save('trias_tripinfo.txt', await trias(r.tripInfo(jr.group(1)!, now)));
  }

  stdout.writeln('EFA');
  save('efa_dm_alter_markt.json', await efa('XML_DM_REQUEST', {
    'type_dm': 'any',
    'name_dm': amRef,
    'mode': 'direct',
    'limit': '12',
  }));
  save('efa_addinfo.json', await efa('XML_ADDINFO_REQUEST', {
    'filterPublished': '1',
    'filterValidDay': '1',
    'itdLPxx_selLine': '',
  }));
  // TripStopTimes für den ersten Fahrtabschnitt der Verbindung.
  final leg = RegExp(
          r'<trias:TimedLeg><trias:LegBoard><trias:StopPointRef>([^<]+)</trias:StopPointRef>.*?<trias:TimetabledTime>([^<]+)</trias:TimetabledTime>.*?<trias:JourneyRef>([^<]+)</trias:JourneyRef>',
          dotAll: true)
      .firstMatch(trip);
  if (leg != null) {
    final parts = leg.group(3)!.split(':');
    final dep = DateTime.parse(leg.group(2)!).toLocal();
    two(int v) => v.toString().padLeft(2, '0');
    save('efa_tripstoptimes.json', await efa('XML_TRIPSTOPTIMES_REQUEST', {
      'line': parts.sublist(0, parts.length - 1).join(':'),
      'stopID': leg.group(1)!,
      'tripCode': parts.last,
      'date': '${dep.year}${two(dep.month)}${two(dep.day)}',
      'time': '${two(dep.hour)}${two(dep.minute)}',
      'tStOTType': 'all',
    }));
  }
  http.close();
}
