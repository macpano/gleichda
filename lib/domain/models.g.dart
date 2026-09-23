// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventTime _$EventTimeFromJson(Map<String, dynamic> json) => _EventTime(
  planned: DateTime.parse(json['planned'] as String),
  estimated: json['estimated'] == null
      ? null
      : DateTime.parse(json['estimated'] as String),
  quality:
      $enumDecodeNullable(_$TimeQualityEnumMap, json['quality']) ??
      TimeQuality.planned,
);

Map<String, dynamic> _$EventTimeToJson(_EventTime instance) =>
    <String, dynamic>{
      'planned': instance.planned.toIso8601String(),
      'estimated': ?instance.estimated?.toIso8601String(),
      'quality': _$TimeQualityEnumMap[instance.quality]!,
    };

const _$TimeQualityEnumMap = {
  TimeQuality.planned: 'planned',
  TimeQuality.realtime: 'realtime',
  TimeQuality.estimated: 'estimated',
};

_Location _$LocationFromJson(Map<String, dynamic> json) => _Location(
  id: json['id'] as String,
  providerId: json['providerId'] as String,
  name: json['name'] as String,
  place: json['place'] as String?,
  lat: (json['lat'] as num?)?.toDouble(),
  lon: (json['lon'] as num?)?.toDouble(),
  type:
      $enumDecodeNullable(_$LocationTypeEnumMap, json['type']) ??
      LocationType.stop,
  modes:
      (json['modes'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$TransportModeEnumMap, e))
          .toList() ??
      const <TransportMode>[],
  score: (json['score'] as num?)?.toDouble(),
);

Map<String, dynamic> _$LocationToJson(_Location instance) => <String, dynamic>{
  'id': instance.id,
  'providerId': instance.providerId,
  'name': instance.name,
  'place': ?instance.place,
  'lat': ?instance.lat,
  'lon': ?instance.lon,
  'type': _$LocationTypeEnumMap[instance.type]!,
  'modes': instance.modes.map((e) => _$TransportModeEnumMap[e]!).toList(),
  'score': ?instance.score,
};

const _$LocationTypeEnumMap = {
  LocationType.stop: 'stop',
  LocationType.address: 'address',
  LocationType.poi: 'poi',
  LocationType.coordinate: 'coordinate',
};

const _$TransportModeEnumMap = {
  TransportMode.bus: 'bus',
  TransportMode.tram: 'tram',
  TransportMode.subway: 'subway',
  TransportMode.suspension: 'suspension',
  TransportMode.suburbanRail: 'suburbanRail',
  TransportMode.rail: 'rail',
  TransportMode.ferry: 'ferry',
  TransportMode.replacementBus: 'replacementBus',
  TransportMode.onDemand: 'onDemand',
  TransportMode.other: 'other',
};

_Line _$LineFromJson(Map<String, dynamic> json) => _Line(
  id: json['id'] as String,
  name: json['name'] as String,
  mode: $enumDecode(_$TransportModeEnumMap, json['mode']),
  operator: json['operator'] as String?,
  longName: json['longName'] as String?,
);

Map<String, dynamic> _$LineToJson(_Line instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'mode': _$TransportModeEnumMap[instance.mode]!,
  'operator': ?instance.operator,
  'longName': ?instance.longName,
};

_StopTime _$StopTimeFromJson(Map<String, dynamic> json) => _StopTime(
  stop: Location.fromJson(json['stop'] as Map<String, dynamic>),
  arrival: json['arrival'] == null
      ? null
      : EventTime.fromJson(json['arrival'] as Map<String, dynamic>),
  departure: json['departure'] == null
      ? null
      : EventTime.fromJson(json['departure'] as Map<String, dynamic>),
  plannedPlatform: json['plannedPlatform'] as String?,
  platform: json['platform'] as String?,
  status:
      $enumDecodeNullable(_$StopStatusEnumMap, json['status']) ??
      StopStatus.normal,
  sequence: (json['sequence'] as num?)?.toInt(),
);

Map<String, dynamic> _$StopTimeToJson(_StopTime instance) => <String, dynamic>{
  'stop': instance.stop.toJson(),
  'arrival': ?instance.arrival?.toJson(),
  'departure': ?instance.departure?.toJson(),
  'plannedPlatform': ?instance.plannedPlatform,
  'platform': ?instance.platform,
  'status': _$StopStatusEnumMap[instance.status]!,
  'sequence': ?instance.sequence,
};

const _$StopStatusEnumMap = {
  StopStatus.normal: 'normal',
  StopStatus.cancelled: 'cancelled',
  StopStatus.diversion: 'diversion',
  StopStatus.replacement: 'replacement',
};

_Leg _$LegFromJson(Map<String, dynamic> json) => _Leg(
  type: $enumDecode(_$LegTypeEnumMap, json['type']),
  from: StopTime.fromJson(json['from'] as Map<String, dynamic>),
  to: StopTime.fromJson(json['to'] as Map<String, dynamic>),
  line: json['line'] == null
      ? null
      : Line.fromJson(json['line'] as Map<String, dynamic>),
  direction: json['direction'] as String?,
  intermediates:
      (json['intermediates'] as List<dynamic>?)
          ?.map((e) => StopTime.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <StopTime>[],
  journeyRef: json['journeyRef'] as String?,
  operatingDay: json['operatingDay'] as String?,
  durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
  messageIds:
      (json['messageIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$LegToJson(_Leg instance) => <String, dynamic>{
  'type': _$LegTypeEnumMap[instance.type]!,
  'from': instance.from.toJson(),
  'to': instance.to.toJson(),
  'line': ?instance.line?.toJson(),
  'direction': ?instance.direction,
  'intermediates': instance.intermediates.map((e) => e.toJson()).toList(),
  'journeyRef': ?instance.journeyRef,
  'operatingDay': ?instance.operatingDay,
  'durationMinutes': ?instance.durationMinutes,
  'messageIds': instance.messageIds,
};

const _$LegTypeEnumMap = {
  LegType.ride: 'ride',
  LegType.walk: 'walk',
  LegType.transfer: 'transfer',
};

_Trip _$TripFromJson(Map<String, dynamic> json) => _Trip(
  id: json['id'] as String,
  legs: (json['legs'] as List<dynamic>)
      .map((e) => Leg.fromJson(e as Map<String, dynamic>))
      .toList(),
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Message>[],
);

Map<String, dynamic> _$TripToJson(_Trip instance) => <String, dynamic>{
  'id': instance.id,
  'legs': instance.legs.map((e) => e.toJson()).toList(),
  'messages': instance.messages.map((e) => e.toJson()).toList(),
};

_Departure _$DepartureFromJson(Map<String, dynamic> json) => _Departure(
  stop: Location.fromJson(json['stop'] as Map<String, dynamic>),
  line: Line.fromJson(json['line'] as Map<String, dynamic>),
  direction: json['direction'] as String,
  time: EventTime.fromJson(json['time'] as Map<String, dynamic>),
  plannedPlatform: json['plannedPlatform'] as String?,
  platform: json['platform'] as String?,
  status:
      $enumDecodeNullable(_$StopStatusEnumMap, json['status']) ??
      StopStatus.normal,
  journeyRef: json['journeyRef'] as String?,
  operatingDay: json['operatingDay'] as String?,
  messageIds:
      (json['messageIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$DepartureToJson(_Departure instance) =>
    <String, dynamic>{
      'stop': instance.stop.toJson(),
      'line': instance.line.toJson(),
      'direction': instance.direction,
      'time': instance.time.toJson(),
      'plannedPlatform': ?instance.plannedPlatform,
      'platform': ?instance.platform,
      'status': _$StopStatusEnumMap[instance.status]!,
      'journeyRef': ?instance.journeyRef,
      'operatingDay': ?instance.operatingDay,
      'messageIds': instance.messageIds,
    };

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  id: json['id'] as String,
  title: json['title'] as String,
  text: json['text'] as String?,
  lineIds:
      (json['lineIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  lineNames:
      (json['lineNames'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  stopIds:
      (json['stopIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  validFrom: json['validFrom'] == null
      ? null
      : DateTime.parse(json['validFrom'] as String),
  validTo: json['validTo'] == null
      ? null
      : DateTime.parse(json['validTo'] as String),
  source: json['source'] as String?,
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'text': ?instance.text,
  'lineIds': instance.lineIds,
  'lineNames': instance.lineNames,
  'stopIds': instance.stopIds,
  'validFrom': ?instance.validFrom?.toIso8601String(),
  'validTo': ?instance.validTo?.toIso8601String(),
  'source': ?instance.source,
};

_TimeWindow _$TimeWindowFromJson(Map<String, dynamic> json) => _TimeWindow(
  weekdays:
      (json['weekdays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[1, 2, 3, 4, 5, 6, 7],
  fromMinute: (json['fromMinute'] as num?)?.toInt(),
  toMinute: (json['toMinute'] as num?)?.toInt(),
);

Map<String, dynamic> _$TimeWindowToJson(_TimeWindow instance) =>
    <String, dynamic>{
      'weekdays': instance.weekdays,
      'fromMinute': ?instance.fromMinute,
      'toMinute': ?instance.toMinute,
    };

_Subscription _$SubscriptionFromJson(Map<String, dynamic> json) =>
    _Subscription(
      lineId: json['lineId'] as String,
      providerId: json['providerId'] as String,
      lineName: json['lineName'] as String,
      window: json['window'] == null
          ? null
          : TimeWindow.fromJson(json['window'] as Map<String, dynamic>),
      pushTopic: json['pushTopic'] as String?,
    );

Map<String, dynamic> _$SubscriptionToJson(_Subscription instance) =>
    <String, dynamic>{
      'lineId': instance.lineId,
      'providerId': instance.providerId,
      'lineName': instance.lineName,
      'window': ?instance.window?.toJson(),
      'pushTopic': ?instance.pushTopic,
    };

_Alarm _$AlarmFromJson(Map<String, dynamic> json) => _Alarm(
  id: json['id'] as String,
  name: json['name'] as String,
  from: Location.fromJson(json['from'] as Map<String, dynamic>),
  to: Location.fromJson(json['to'] as Map<String, dynamic>),
  timeRef: $enumDecode(_$AlarmTimeRefEnumMap, json['timeRef']),
  minuteOfDay: (json['minuteOfDay'] as num).toInt(),
  weekdays:
      (json['weekdays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[1, 2, 3, 4, 5],
  leadMinutes: (json['leadMinutes'] as num?)?.toInt() ?? 5,
  earlierOnDisruption: json['earlierOnDisruption'] as bool? ?? true,
  startCompanion: json['startCompanion'] as bool? ?? false,
  enabled: json['enabled'] as bool? ?? true,
);

Map<String, dynamic> _$AlarmToJson(_Alarm instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'from': instance.from.toJson(),
  'to': instance.to.toJson(),
  'timeRef': _$AlarmTimeRefEnumMap[instance.timeRef]!,
  'minuteOfDay': instance.minuteOfDay,
  'weekdays': instance.weekdays,
  'leadMinutes': instance.leadMinutes,
  'earlierOnDisruption': instance.earlierOnDisruption,
  'startCompanion': instance.startCompanion,
  'enabled': instance.enabled,
};

const _$AlarmTimeRefEnumMap = {
  AlarmTimeRef.arriveBy: 'arriveBy',
  AlarmTimeRef.departAt: 'departAt',
};

_SavedPlace _$SavedPlaceFromJson(Map<String, dynamic> json) => _SavedPlace(
  id: json['id'] as String,
  name: json['name'] as String,
  kind: $enumDecode(_$PlaceKindEnumMap, json['kind']),
  location: Location.fromJson(json['location'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SavedPlaceToJson(_SavedPlace instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'kind': _$PlaceKindEnumMap[instance.kind]!,
      'location': instance.location.toJson(),
    };

const _$PlaceKindEnumMap = {
  PlaceKind.home: 'home',
  PlaceKind.work: 'work',
  PlaceKind.other: 'other',
};
