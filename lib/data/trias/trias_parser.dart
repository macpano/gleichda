// Liest TRIAS-Antworten (VDV 431) in die eigenen Modelle.
import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../../domain/models.dart';
import '../../domain/product.dart';
import '../transit_provider.dart';

const _provider = 'vrr-trias';

/// Heimatort: Wo die Auskunft keinen Ort mitliefert (Halte einer Fahrt),
/// wird er nur bei diesem Ort vom Namen abgetrennt.
// TODO: aus den Einstellungen (Heimatregion) übernehmen.
const homePlace = 'Wuppertal';

// --- Hilfsfunktionen: Elemente über den lokalen Namen, Präfix egal. ---

extension _X on XmlElement {
  XmlElement? el(String local) {
    for (final c in childElements) {
      if (c.localName == local) return c;
    }
    return null;
  }

  Iterable<XmlElement> els(String local) =>
      childElements.where((c) => c.localName == local);

  XmlElement? path(List<String> locals) {
    XmlElement? cur = this;
    for (final l in locals) {
      cur = cur?.el(l);
      if (cur == null) return null;
    }
    return cur;
  }

  /// Text eines Kindes; bei internationalisierten Texten (`Text`) dessen Inhalt.
  String? txt(String local) {
    final e = el(local);
    if (e == null) return null;
    final inner = e.el('Text');
    final v = (inner ?? e).innerText.trim();
    return v.isEmpty ? null : v;
  }

  Iterable<XmlElement> deep(String local) =>
      descendantElements.where((d) => d.localName == local);
}

DateTime? _time(String? s) => s == null ? null : DateTime.parse(s);

/// Wirft bei Fehlerantworten; liefert sonst das DeliveryPayload-Element.
XmlElement _payload(String xml) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlException catch (e) {
    throw ProviderException('Antwort der Auskunft nicht lesbar', cause: e);
  }
  final root = doc.rootElement;
  final delivery = root.el('ServiceDelivery');
  if (delivery == null) {
    throw const ProviderException('Unerwartete Antwort der Auskunft');
  }
  final status = delivery.el('Status')?.innerText.trim();
  if (status == 'false') {
    final msg = delivery.deep('ErrorMessage').map((e) => e.txt('Text') ?? e.innerText).join('; ');
    throw ProviderException(msg.isEmpty ? 'Auskunft meldet einen Fehler' : msg);
  }
  final payload = delivery.el('DeliveryPayload');
  if (payload == null) {
    throw const ProviderException('Auskunft lieferte keine Daten');
  }
  return payload;
}

/// Fehlercodes im Ergebnis (z. B. „TRIP_NOTRIPFOUND“).
List<String> _errorCodes(XmlElement response) => response
    .els('ErrorMessage')
    .map((e) => e.txt('Code') ?? e.innerText.trim())
    .toList();

// --- Namen und Linien ---

/// Entfernt den vorangestellten Ort („Wuppertal Alter Markt“ → „Alter Markt“),
/// wenn danach ein brauchbarer Name bleibt.
String displayName(String name, String? place) {
  if (place == null || place.isEmpty) return name;
  for (final prefix in ['$place, ', '$place ']) {
    if (name.startsWith(prefix)) {
      final rest = name.substring(prefix.length).trim();
      if (rest.length >= 5) return rest;
    }
  }
  return name;
}

/// Haltestellenname mit Ort, wie ihn die Auskunft schreibt, nur ohne Komma
/// („Wuppertal, Alter Markt“ → „Wuppertal Alter Markt“).
String fullStopName(String name) =>
    name.replaceFirstMapped(RegExp(r'^([^,]{2,30}), '), (m) => '${m[1]} ').trim();

ProductInfo _productOf(XmlElement? mode, {String? published, String? lineRef}) {
  String? submode;
  for (final e in mode?.childElements ?? const <XmlElement>[]) {
    if (e.localName.endsWith('Submode')) submode = e.innerText.trim();
  }
  return classifyLine(
    ptMode: mode?.el('PtMode')?.innerText.trim(),
    submode: submode,
    modeName: mode?.txt('Name'),
    published: published,
    lineRef: lineRef,
  );
}

TransportMode _mode(XmlElement? mode) => _productOf(mode).product.mode;

Line _line(XmlElement service) {
  final mode = service.el('Mode');
  final lineRef = service.el('LineRef')?.innerText.trim();
  final info = _productOf(mode, published: service.txt('PublishedLineName'), lineRef: lineRef);
  return Line(
    id: lineRef ?? '',
    name: info.name,
    mode: info.product.mode,
    operator: service.el('OperatorRef')?.innerText.trim(),
    longName: mode?.txt('Name'),
    product: info.product.name,
  );
}

EventTime? _eventTime(XmlElement? e) {
  if (e == null) return null;
  final planned = _time(e.el('TimetabledTime')?.innerText.trim());
  if (planned == null) return null;
  final est = _time(e.el('EstimatedTime')?.innerText.trim());
  return EventTime(
    planned: planned,
    estimated: est,
    quality: est == null ? TimeQuality.planned : TimeQuality.realtime,
  );
}

StopStatus _callStatus(XmlElement call, {bool serviceCancelled = false}) {
  if (serviceCancelled) return StopStatus.cancelled;
  if (call.el('NotServicedStop')?.innerText.trim() == 'true') {
    return StopStatus.cancelled;
  }
  if (call.el('UnplannedStop')?.innerText.trim() == 'true') {
    return StopStatus.diversion;
  }
  return StopStatus.normal;
}

/// Haltestellen-Kennung ohne Steig: „de:05124:11376:2:5“ → „de:05124:11376“.
String stopAreaId(String ref) {
  final parts = ref.split(':');
  return parts.length > 3 ? parts.sublist(0, 3).join(':') : ref;
}

StopTime _call(XmlElement call, {bool serviceCancelled = false}) {
  final ref = call.el('StopPointRef')?.innerText.trim() ?? '';
  final name = call.txt('StopPointName') ?? call.txt('LocationName') ?? '';
  return StopTime(
    stop: Location(
      id: ref,
      providerId: _provider,
      // Voller Name mit Ort („Wuppertal Hbf“): „Hbf“ allein könnte überall sein.
      name: fullStopName(name),
      type: LocationType.stop,
    ),
    arrival: _eventTime(call.el('ServiceArrival')),
    departure: _eventTime(call.el('ServiceDeparture')),
    plannedPlatform: call.txt('PlannedBay'),
    platform: call.txt('EstimatedBay') ?? call.txt('PlannedBay'),
    status: _callStatus(call, serviceCancelled: serviceCancelled),
    sequence: int.tryParse(call.el('StopSeqNumber')?.innerText.trim() ?? ''),
  );
}

// --- Meldungen ---

List<Message> _situations(XmlElement? context) {
  if (context == null) return const [];
  final out = <Message>[];
  for (final s in context.deep('PtSituation')) {
    final number = s.el('SituationNumber')?.innerText.trim() ?? '';
    final summary = s.el('Summary')?.innerText.trim() ?? '';
    if (number.isEmpty || summary.isEmpty) continue;
    final detail = s.el('Detail')?.innerText.trim();
    final description = s.el('Description')?.innerText.trim();
    out.add(Message(
      id: number,
      title: summary.replaceAll(RegExp(r'\.$'), ''),
      text: (detail != null && detail.isNotEmpty) ? detail : description,
      lineIds: s.deep('LineRef').map((e) => e.innerText.trim()).toSet().toList(),
      stopIds: s.deep('StopPointRef').map((e) => e.innerText.trim()).toSet().toList(),
      validFrom: _time(s.path(['ValidityPeriod', 'StartTime'])?.innerText.trim()),
      validTo: _time(s.path(['ValidityPeriod', 'EndTime'])?.innerText.trim()),
      source: s.el('ParticipantRef')?.innerText.trim(),
    ));
  }
  return out;
}

List<String> _situationRefs(XmlElement service) => service
    .els('SituationFullRef')
    .map((e) => e.el('SituationNumber')?.innerText.trim() ?? '')
    .where((s) => s.isNotEmpty)
    .toList();

// --- Öffentliche Parser ---

double _distance(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  final p1 = lat1 * math.pi / 180, p2 = lat2 * math.pi / 180;
  final dp = p2 - p1, dl = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dp / 2) * math.sin(dp / 2) +
      math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// Entfernung in Metern zwischen zwei Orten mit Koordinaten.
double? distanceBetween(Location a, ({double lat, double lon}) b) {
  if (a.lat == null || a.lon == null) return null;
  return _distance(a.lat!, a.lon!, b.lat, b.lon);
}

List<Location> parseLocations(String xml) {
  final payload = _payload(xml);
  final res = payload.el('LocationInformationResponse');
  if (res == null) return const [];
  final out = <Location>[];
  for (final result in res.els('Location')) {
    final loc = result.el('Location');
    if (loc == null) continue;
    final place = loc.txt('LocationName');
    final geo = loc.el('GeoPosition');
    final lat = double.tryParse(geo?.el('Latitude')?.innerText ?? '');
    final lon = double.tryParse(geo?.el('Longitude')?.innerText ?? '');
    final modes = result.els('Mode').map(_mode).toSet().toList();
    final score = double.tryParse(result.el('Probability')?.innerText ?? '');
    final sp = loc.el('StopPoint');
    final addr = loc.el('Address');
    final poi = loc.el('PointOfInterest');
    final locality = loc.el('Locality');
    if (sp != null) {
      out.add(Location(
        id: sp.el('StopPointRef')!.innerText.trim(),
        providerId: _provider,
        name: displayName(sp.txt('StopPointName') ?? '', place),
        place: place,
        lat: lat,
        lon: lon,
        type: LocationType.stop,
        modes: modes,
        score: score,
      ));
    } else if (addr != null) {
      out.add(Location(
        id: addr.el('AddressCode')?.innerText.trim() ?? '',
        providerId: _provider,
        name: displayName(addr.txt('AddressName') ?? '', place),
        place: place,
        lat: lat,
        lon: lon,
        type: LocationType.address,
        score: score,
      ));
    } else if (poi != null) {
      out.add(Location(
        id: poi.el('PointOfInterestCode')?.innerText.trim() ?? '',
        providerId: _provider,
        name: displayName(poi.txt('PointOfInterestName') ?? '', place),
        place: place,
        lat: lat,
        lon: lon,
        type: LocationType.poi,
        score: score,
      ));
    } else if (locality != null && lat != null && lon != null) {
      out.add(Location(
        id: 'coord:$lat:$lon',
        providerId: _provider,
        name: locality.txt('LocalityName') ?? place ?? '',
        place: place,
        lat: lat,
        lon: lon,
        type: LocationType.coordinate,
        score: score,
      ));
    }
  }
  return out;
}

DepartureBoard parseStopEvents(String xml, Location stop) {
  final payload = _payload(xml);
  final res = payload.el('StopEventResponse');
  if (res == null) return const DepartureBoard([], []);
  final messages = _situations(res.el('StopEventResponseContext'));
  final deps = <Departure>[];
  for (final r in res.els('StopEventResult')) {
    final ev = r.el('StopEvent');
    final call = ev?.path(['ThisCall', 'CallAtStop']);
    final service = ev?.el('Service');
    if (call == null || service == null) continue;
    final time = _eventTime(call.el('ServiceDeparture'));
    if (time == null) continue;
    final cancelled = service.el('Cancelled')?.innerText.trim() == 'true';
    final deviation = service.el('Deviation')?.innerText.trim() == 'true';
    final line = _line(service);
    var status = _callStatus(call, serviceCancelled: cancelled);
    if (status == StopStatus.normal && deviation) status = StopStatus.diversion;
    if (status == StopStatus.normal && line.mode == TransportMode.replacementBus) {
      status = StopStatus.replacement;
    }
    deps.add(Departure(
      stop: stop,
      line: line,
      direction: displayName(service.txt('DestinationText') ?? '', homePlace),
      time: time,
      plannedPlatform: call.txt('PlannedBay'),
      platform: call.txt('EstimatedBay') ?? call.txt('PlannedBay'),
      status: status,
      journeyRef: service.el('JourneyRef')?.innerText.trim(),
      operatingDay: service.el('OperatingDayRef')?.innerText.trim(),
      messageIds: _situationRefs(service),
    ));
  }
  deps.sort((a, b) => a.time.best.compareTo(b.time.best));
  return DepartureBoard(deps, messages);
}

/// Halte einer Fahrt aus einer Abfahrtsantwort mit Folgehalten, gefunden
/// über die Fahrt-Referenz. Liefert null, wenn die Fahrt nicht enthalten ist.
List<StopTime>? parseOnwardCalls(String xml, String journeyRef) {
  final payload = _payload(xml);
  final res = payload.el('StopEventResponse');
  if (res == null) return null;
  for (final r in res.els('StopEventResult')) {
    final ev = r.el('StopEvent');
    final service = ev?.el('Service');
    if (service?.el('JourneyRef')?.innerText.trim() != journeyRef) continue;
    final cancelled = service!.el('Cancelled')?.innerText.trim() == 'true';
    final calls = <StopTime>[];
    for (final part in ['PreviousCall', 'ThisCall', 'OnwardCall']) {
      for (final c in ev!.els(part)) {
        final cs = c.el('CallAtStop');
        if (cs != null) calls.add(_call(cs, serviceCancelled: cancelled));
      }
    }
    return calls;
  }
  return null;
}

Duration? _isoDuration(String? s) {
  if (s == null) return null;
  final m = RegExp(r'^P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$').firstMatch(s.trim());
  if (m == null) return null;
  int g(int i) => int.tryParse(m[i] ?? '') ?? 0;
  return Duration(days: g(1), hours: g(2), minutes: g(3), seconds: g(4));
}

StopTime _legEnd(XmlElement e, DateTime? time, {required bool isStart}) {
  final ref = e.el('StopPointRef')?.innerText.trim();
  final name = e.txt('LocationName') ?? e.txt('StopPointName') ?? '';
  final geo = e.el('GeoPosition');
  final lat = double.tryParse(geo?.el('Latitude')?.innerText ?? '');
  final lon = double.tryParse(geo?.el('Longitude')?.innerText ?? '');
  final et = time == null ? null : EventTime(planned: time);
  return StopTime(
    stop: Location(
      id: ref ?? 'coord:$lat:$lon',
      providerId: _provider,
      name: ref != null ? fullStopName(name) : name,
      lat: lat,
      lon: lon,
      type: ref != null ? LocationType.stop : LocationType.coordinate,
    ),
    departure: isStart ? et : null,
    arrival: isStart ? null : et,
  );
}

Leg _walkLeg(XmlElement leg, LegType type) {
  final start = _time(leg.el('TimeWindowStart')?.innerText.trim());
  final end = _time(leg.el('TimeWindowEnd')?.innerText.trim());
  final d = _isoDuration(leg.el('Duration')?.innerText) ??
      _isoDuration(leg.el('WalkDuration')?.innerText);
  return Leg(
    type: type,
    from: _legEnd(leg.el('LegStart')!, start, isStart: true),
    to: _legEnd(leg.el('LegEnd')!, end ?? start?.add(d ?? Duration.zero), isStart: false),
    durationMinutes: d?.inMinutes,
  );
}

Leg _timedLeg(XmlElement leg) {
  final service = leg.el('Service')!;
  final cancelled = service.el('Cancelled')?.innerText.trim() == 'true';
  final line = _line(service);
  return Leg(
    type: LegType.ride,
    from: _call(leg.el('LegBoard')!, serviceCancelled: cancelled),
    to: _call(leg.el('LegAlight')!, serviceCancelled: cancelled),
    intermediates: leg
        .els('LegIntermediates')
        .map((c) => _call(c, serviceCancelled: cancelled))
        .toList(),
    line: line,
    direction: displayName(service.txt('DestinationText') ?? '', homePlace),
    journeyRef: service.el('JourneyRef')?.innerText.trim(),
    operatingDay: service.el('OperatingDayRef')?.innerText.trim(),
    messageIds: _situationRefs(service),
  );
}

/// Verbindungen aus einer TripResponse. Meldungen werden an die Fahrten
/// gehängt, die sie betreffen.
List<Trip> parseTrips(String xml) {
  final payload = _payload(xml);
  final res = payload.el('TripResponse');
  if (res == null) return const [];
  final codes = _errorCodes(res);
  final messages = _situations(res.el('TripResponseContext'));
  final byId = {for (final m in messages) m.id: m};
  final trips = <Trip>[];
  for (final r in res.els('TripResult')) {
    final t = r.el('Trip');
    if (t == null) continue;
    final legs = <Leg>[];
    for (final tl in t.els('TripLeg')) {
      final timed = tl.el('TimedLeg');
      final cont = tl.el('ContinuousLeg');
      final inter = tl.el('InterchangeLeg') ?? tl.el('TransferLeg');
      if (timed != null) {
        legs.add(_timedLeg(timed));
      } else if (cont != null) {
        legs.add(_walkLeg(cont, LegType.walk));
      } else if (inter != null) {
        final stay = inter.txt('InterchangeMode') == 'remainInVehicle' ||
            inter.el('InterchangeMode')?.innerText.trim() == 'remainInVehicle';
        legs.add(_walkLeg(inter, LegType.transfer).copyWith(staySeated: stay));
      }
    }
    if (legs.isEmpty) continue;
    final ids = legs.expand((l) => l.messageIds).toSet();
    trips.add(Trip(
      id: t.el('TripId')?.innerText.trim() ?? r.el('ResultId')!.innerText.trim(),
      legs: legs,
      messages: [for (final id in ids) if (byId[id] != null) byId[id]!],
    ));
  }
  // „-4000“ heißt ebenfalls „keine Verbindung“ (gemessen 23.09.2026: Standort
  // 150 m vor der Zieladresse, Fußweg-Grenze 3 min – der Fußweg selbst ist länger).
  if (trips.isEmpty && codes.isNotEmpty && !codes.any((c) => c.contains('NOTRIPFOUND') || c.trim() == '-4000')) {
    throw ProviderException('Auskunft meldet: ${codes.join(', ')}');
  }
  return trips;
}
