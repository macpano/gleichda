// VRR EFA OpenService (Mentz, rapidJSON). Nur dort genutzt, wo TRIAS
// nachweislich weniger liefert – hier: Fahrtverlauf einer bekannten Fahrt
// per XML_TRIPSTOPTIMES_REQUEST, den der TRIAS-Testserver (TripInfoRequest)
// nicht beantwortet.
import 'package:dio/dio.dart';

import '../../domain/models.dart';
import '../transit_provider.dart';

const _provider = 'vrr-efa';

/// Kennungen, mit denen die EFA einen Fahrtabschnitt wiederfindet.
class EfaTripKey {
  const EfaTripKey({
    required this.line,
    required this.stopId,
    required this.tripCode,
    required this.date,
    required this.time,
  });

  /// Aus der TRIAS-Fahrtreferenz: „wsw:66604::R:w25:266“ →
  /// line „wsw:66604: :R:w25“, tripCode „266“. [departure] ist die
  /// geplante Abfahrt am Einstiegshalt [stopId].
  static EfaTripKey? fromJourneyRef(
      String journeyRef, String stopId, DateTime departure) {
    final parts = journeyRef.split(':');
    if (parts.length < 3) return null;
    final code = parts.last;
    if (int.tryParse(code) == null) return null;
    final line = parts
        .sublist(0, parts.length - 1)
        .map((p) => p.isEmpty ? ' ' : p)
        .join(':');
    final l = departure.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return EfaTripKey(
      line: line,
      stopId: stopId,
      tripCode: code,
      date: '${l.year}${two(l.month)}${two(l.day)}',
      time: '${two(l.hour)}${two(l.minute)}',
    );
  }

  final String line;
  final String stopId;
  final String tripCode;

  /// JJJJMMTT
  final String date;

  /// HHMM, Ortszeit
  final String time;

  Map<String, String> toQuery() => {
        'line': line,
        'stopID': stopId,
        'tripCode': tripCode,
        'date': date,
        'time': time,
      };
}

class EfaClient {
  EfaClient(this._dio,
      {this.baseUrl = 'https://openservice-test.vrr.de/static02'});

  final Dio _dio;
  final String baseUrl;

  Future<Map<String, dynamic>> _get(
      String endpoint, Map<String, String> params) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/$endpoint',
        queryParameters: {
          'outputFormat': 'rapidJSON',
          'coordOutputFormat': 'WGS84[dd.ddddd]',
          'useRealtime': '1',
          ...params,
        },
        options: Options(responseType: ResponseType.json),
      );
      return res.data ?? const {};
    } on DioException catch (e) {
      throw ProviderException('EFA nicht erreichbar', cause: e);
    }
  }

  /// Alle Halte eines Fahrtabschnitts mit Plan- und Echtzeit. null, wenn die
  /// EFA die Fahrt nicht kennt.
  Future<List<StopTime>?> tripStopTimes(EfaTripKey key) async {
    final json = await _get('XML_TRIPSTOPTIMES_REQUEST', {
      ...key.toQuery(),
      'tStOTType': 'all',
    });
    return parseTripStopTimes(json);
  }
}

DateTime? _t(Object? s) => s is String ? DateTime.tryParse(s) : null;

EventTime? _time(Map<String, dynamic> s, String kind, bool monitored) {
  final planned = _t(s['${kind}TimePlanned']);
  if (planned == null) return null;
  final est = _t(s['${kind}TimeEstimated']);
  return EventTime(
    planned: planned,
    estimated: est,
    quality: est == null
        ? TimeQuality.planned
        : (monitored ? TimeQuality.realtime : TimeQuality.estimated),
  );
}

List<StopTime>? parseTripStopTimes(Map<String, dynamic> json) {
  final leg = json['leg'];
  if (leg is! Map<String, dynamic>) return null;
  final seq = leg['stopSequence'];
  if (seq is! List || seq.isEmpty) return null;
  final legStatus = (leg['realtimeStatus'] as List?)?.cast<String>() ?? const [];
  final monitored = legStatus.contains('MONITORED');
  final tripCancelled = legStatus.contains('TRIP_CANCELLED');
  final out = <StopTime>[];
  var i = 0;
  for (final raw in seq) {
    if (raw is! Map<String, dynamic>) continue;
    final props = (raw['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
    final parent = (raw['parent'] as Map?)?.cast<String, dynamic>();
    final locality = (parent?['parent'] as Map?)?['name'] as String?;
    final coord = raw['coord'] as List?;
    final status = (raw['realtimeStatus'] as List?)?.cast<String>() ?? const [];
    final name = (parent?['disassembledName'] ?? raw['disassembledName'] ?? raw['name']) as String;
    out.add(StopTime(
      stop: Location(
        id: raw['id'] as String,
        providerId: _provider,
        // disassembledName ist bei Steigen teils nur die Steignummer.
        name: RegExp(r'^\d+$').hasMatch(name) ? (raw['name'] as String) : name,
        place: locality,
        lat: (coord != null && coord.length == 2) ? (coord[0] as num).toDouble() : null,
        lon: (coord != null && coord.length == 2) ? (coord[1] as num).toDouble() : null,
      ),
      arrival: _time(raw, 'arrival', monitored),
      departure: _time(raw, 'departure', monitored),
      plannedPlatform: props['plannedPlatformName'] as String?,
      platform: (props['platformName'] ?? props['plannedPlatformName']) as String?,
      status: tripCancelled || status.contains('STOP_CANCELLED')
          ? StopStatus.cancelled
          : (status.contains('EXTRA_STOP') ? StopStatus.diversion : StopStatus.normal),
      sequence: i++,
    ));
  }
  return out;
}
