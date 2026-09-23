// Aufbau der TRIAS-Anfragen (VDV 431, Version 1.1).
import 'package:xml/xml.dart';

const triasNs = 'http://www.vdv.de/trias';
const siriNs = 'http://www.siri.org.uk/siri';

String _utc(DateTime t) =>
    '${t.toUtc().toIso8601String().split('.').first}Z';

String _day(DateTime t) {
  final l = t.toLocal();
  return '${l.year.toString().padLeft(4, '0')}-'
      '${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
}

/// Ort für Anfragen: Haltestelle über ihre Kennung oder eine Koordinate.
sealed class TriasPlace {
  const TriasPlace();
}

class TriasStop extends TriasPlace {
  const TriasStop(this.ref);
  final String ref;
}

class TriasCoord extends TriasPlace {
  const TriasCoord(this.lat, this.lon, [this.name]);
  final double lat;
  final double lon;
  final String? name;
}

class TriasAddress extends TriasPlace {
  const TriasAddress(this.ref);
  final String ref;
}

class TriasPoi extends TriasPlace {
  const TriasPoi(this.ref);
  final String ref;
}

class TriasRequests {
  const TriasRequests({this.requestorRef = 'gleichda', DateTime Function()? clock})
      : _clock = clock; // ignore: prefer_initializing_formals

  final String requestorRef;
  final DateTime Function()? _clock;

  DateTime get _now => (_clock ?? DateTime.now)();

  String _envelope(void Function(XmlBuilder b) payload) {
    final b = XmlBuilder();
    b.processing('xml', 'version="1.0" encoding="UTF-8"');
    b.element('Trias', namespaceUris: {null: triasNs, 'siri': siriNs}, attributes: {
      'version': '1.1',
    }, nest: () {
      b.element('ServiceRequest', nest: () {
        b.element('siri:RequestTimestamp', nest: _utc(_now));
        b.element('siri:RequestorRef', nest: requestorRef);
        b.element('RequestPayload', nest: () => payload(b));
      });
    });
    return b.buildDocument().toXmlString();
  }

  void _locationRef(XmlBuilder b, TriasPlace p) {
    b.element('LocationRef', nest: () {
      switch (p) {
        case TriasStop(:final ref):
          b.element('StopPointRef', nest: ref);
        case TriasAddress(:final ref):
          b.element('AddressRef', nest: ref);
        case TriasPoi(:final ref):
          b.element('PointOfInterestRef', nest: ref);
        case TriasCoord(:final lat, :final lon, :final name):
          b.element('GeoPosition', nest: () {
            b.element('Longitude', nest: lon.toStringAsFixed(6));
            b.element('Latitude', nest: lat.toStringAsFixed(6));
          });
          b.element('LocationName', nest: () {
            b.element('Text', nest: name ?? 'Standort');
            b.element('Language', nest: 'de');
          });
      }
    });
  }

  /// Orts- und Haltestellensuche.
  String locationInformation(String query, {int limit = 10}) =>
      _envelope((b) {
        b.element('LocationInformationRequest', nest: () {
          b.element('InitialInput', nest: () {
            b.element('LocationName', nest: query);
          });
          b.element('Restrictions', nest: () {
            b.element('Type', nest: 'stop');
            b.element('Type', nest: 'address');
            b.element('Type', nest: 'poi');
            b.element('NumberOfResults', nest: '$limit');
            b.element('IncludePtModes', nest: 'true');
          });
        });
      });

  /// Haltestellen im Umkreis einer Koordinate.
  String locationsNear(double lat, double lon,
          {int radiusMeters = 1000, int limit = 10}) =>
      _envelope((b) {
        b.element('LocationInformationRequest', nest: () {
          b.element('InitialInput', nest: () {
            b.element('GeoRestriction', nest: () {
              b.element('Circle', nest: () {
                b.element('Center', nest: () {
                  b.element('Longitude', nest: lon.toStringAsFixed(6));
                  b.element('Latitude', nest: lat.toStringAsFixed(6));
                });
                b.element('Radius', nest: '$radiusMeters');
              });
            });
          });
          b.element('Restrictions', nest: () {
            b.element('Type', nest: 'stop');
            b.element('NumberOfResults', nest: '$limit');
            b.element('IncludePtModes', nest: 'true');
          });
        });
      });

  /// Abfahrten (bzw. mit [onwardCalls] auch die folgenden Halte je Fahrt).
  String stopEvent(String stopRef,
          {DateTime? time, int limit = 20, bool onwardCalls = false}) =>
      _envelope((b) {
        b.element('StopEventRequest', nest: () {
          b.element('Location', nest: () {
            _locationRef(b, TriasStop(stopRef));
            b.element('DepArrTime', nest: _utc(time ?? _now));
          });
          b.element('Params', nest: () {
            b.element('NumberOfResults', nest: '$limit');
            b.element('StopEventType', nest: 'departure');
            b.element('IncludePreviousCalls', nest: 'false');
            b.element('IncludeOnwardCalls', nest: '$onwardCalls');
            b.element('IncludeRealtimeData', nest: 'true');
          });
        });
      });

  /// Verbindungssuche. [modes]: PtMode-Werte („bus“, „rail“ …), mit
  /// [excludeModes] ausgeschlossen, sonst ausschließlich.
  String trip(TriasPlace from, TriasPlace to,
          {required DateTime time,
          bool arriveBy = false,
          int limit = 5,
          TriasPlace? via,
          List<String> modes = const [],
          bool excludeModes = true,
          bool accessible = false,
          int walkSpeed = 100,
          int? interchangeLimit,
          int? maxWalkMinutes,
          String? algorithm}) =>
      _envelope((b) {
        b.element('TripRequest', nest: () {
          b.element('Origin', nest: () {
            _locationRef(b, from);
            if (!arriveBy) b.element('DepArrTime', nest: _utc(time));
            _walkLimit(b, maxWalkMinutes);
          });
          b.element('Destination', nest: () {
            _locationRef(b, to);
            if (arriveBy) b.element('DepArrTime', nest: _utc(time));
            _walkLimit(b, maxWalkMinutes);
          });
          if (via is TriasStop) {
            b.element('Via', nest: () {
              b.element('ViaPoint', nest: () => b.element('StopPointRef', nest: via.ref));
            });
          }
          b.element('Params', nest: () {
            if (modes.isNotEmpty) {
              b.element('PtModeFilter', nest: () {
                b.element('Exclude', nest: '$excludeModes');
                for (final m in modes) {
                  b.element('PtMode', nest: m);
                }
              });
            }
            if (accessible) {
              b.element('NoSingleStep', nest: 'true');
              b.element('NoStairs', nest: 'true');
              b.element('LevelEntrance', nest: 'true');
            }
            if (walkSpeed != 100) b.element('WalkSpeed', nest: '$walkSpeed');
            b.element('NumberOfResults', nest: '$limit');
            b.element('IncludeTrackSections', nest: 'false');
            b.element('IncludeLegProjection', nest: 'false');
            b.element('IncludeIntermediateStops', nest: 'true');
            if (interchangeLimit != null) {
              b.element('InterchangeLimit', nest: '$interchangeLimit');
            }
            if (algorithm != null) b.element('AlgorithmType', nest: algorithm);
          });
        });
      });

  /// Längster Fußweg am Start bzw. Ziel (geprüft 23.09.2026: ohne Grenze
  /// schlug der Server bis zu 25 min vor, mit 3 min höchstens 4 min).
  void _walkLimit(XmlBuilder b, int? minutes) {
    if (minutes == null) return;
    b.element('IndividualTransportOptions', nest: () {
      b.element('Mode', nest: 'walk');
      b.element('MaxDuration', nest: 'PT${minutes}M');
    });
  }

  /// Fahrtverlauf einer Fahrt. Hinweis: Der VRR-Testserver lehnt diese
  /// Anfrage mit HTTP 400 ab (geprüft 23.09.2026), siehe docs/konzept.md.
  String tripInfo(String journeyRef, DateTime operatingDay) => _envelope((b) {
        b.element('TripInfoRequest', nest: () {
          b.element('JourneyRef', nest: journeyRef);
          b.element('OperatingDayRef', nest: _day(operatingDay));
          b.element('Params', nest: () {
            b.element('IncludeCalls', nest: 'true');
            b.element('IncludeService', nest: 'true');
          });
        });
      });
}
