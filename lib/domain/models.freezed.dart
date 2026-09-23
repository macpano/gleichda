// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventTime {

 DateTime get planned; DateTime? get estimated; TimeQuality get quality;
/// Create a copy of EventTime
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventTimeCopyWith<EventTime> get copyWith => _$EventTimeCopyWithImpl<EventTime>(this as EventTime, _$identity);

  /// Serializes this EventTime to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EventTime;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventTime&&(identical(other.planned, _this.planned) || other.planned == _this.planned)&&(identical(other.estimated, _this.estimated) || other.estimated == _this.estimated)&&(identical(other.quality, _this.quality) || other.quality == _this.quality));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EventTime;
  return Object.hash(runtimeType,_this.planned,_this.estimated,_this.quality);
}

@override
String toString() {
  final _this = this as EventTime;
  return 'EventTime(planned: ${_this.planned}, estimated: ${_this.estimated}, quality: ${_this.quality})';
}


}

/// @nodoc
abstract mixin class $EventTimeCopyWith<$Res>  {
  factory $EventTimeCopyWith(EventTime value, $Res Function(EventTime) _then) = _$EventTimeCopyWithImpl;
@useResult
$Res call({
 DateTime planned, DateTime? estimated, TimeQuality quality
});




}
/// @nodoc
class _$EventTimeCopyWithImpl<$Res>
    implements $EventTimeCopyWith<$Res> {
  _$EventTimeCopyWithImpl(this._self, this._then);

  final EventTime _self;
  final $Res Function(EventTime) _then;

/// Create a copy of EventTime
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? planned = null,Object? estimated = freezed,Object? quality = null,}) {
  return _then(EventTime(
planned: null == planned ? _self.planned : planned // ignore: cast_nullable_to_non_nullable
as DateTime,estimated: freezed == estimated ? _self.estimated : estimated // ignore: cast_nullable_to_non_nullable
as DateTime?,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as TimeQuality,
  ));
}

}


/// Adds pattern-matching-related methods to [EventTime].
extension EventTimePatterns on EventTime {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventTime value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventTime() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventTime value)  $default,){
final _that = this;
switch (_that) {
case _EventTime():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventTime value)?  $default,){
final _that = this;
switch (_that) {
case _EventTime() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime planned,  DateTime? estimated,  TimeQuality quality)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventTime() when $default != null:
return $default(_that.planned,_that.estimated,_that.quality);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime planned,  DateTime? estimated,  TimeQuality quality)  $default,) {final _that = this;
switch (_that) {
case _EventTime():
return $default(_that.planned,_that.estimated,_that.quality);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime planned,  DateTime? estimated,  TimeQuality quality)?  $default,) {final _that = this;
switch (_that) {
case _EventTime() when $default != null:
return $default(_that.planned,_that.estimated,_that.quality);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventTime extends EventTime {
  const _EventTime({required this.planned, this.estimated, this.quality = TimeQuality.planned}): super._();
  factory _EventTime.fromJson(Map<String, dynamic> json) => _$EventTimeFromJson(json);

@override final  DateTime planned;
@override final  DateTime? estimated;
@override@JsonKey() final  TimeQuality quality;

/// Create a copy of EventTime
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventTimeCopyWith<_EventTime> get copyWith => __$EventTimeCopyWithImpl<_EventTime>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventTimeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventTime&&(identical(other.planned, planned) || other.planned == planned)&&(identical(other.estimated, estimated) || other.estimated == estimated)&&(identical(other.quality, quality) || other.quality == quality));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,planned,estimated,quality);
}

@override
String toString() {
    return 'EventTime(planned: $planned, estimated: $estimated, quality: $quality)';
}


}

/// @nodoc
abstract mixin class _$EventTimeCopyWith<$Res> implements $EventTimeCopyWith<$Res> {
  factory _$EventTimeCopyWith(_EventTime value, $Res Function(_EventTime) _then) = __$EventTimeCopyWithImpl;
@override @useResult
$Res call({
 DateTime planned, DateTime? estimated, TimeQuality quality
});




}
/// @nodoc
class __$EventTimeCopyWithImpl<$Res>
    implements _$EventTimeCopyWith<$Res> {
  __$EventTimeCopyWithImpl(this._self, this._then);

  final _EventTime _self;
  final $Res Function(_EventTime) _then;

/// Create a copy of EventTime
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? planned = null,Object? estimated = freezed,Object? quality = null,}) {
  return _then(_EventTime(
planned: null == planned ? _self.planned : planned // ignore: cast_nullable_to_non_nullable
as DateTime,estimated: freezed == estimated ? _self.estimated : estimated // ignore: cast_nullable_to_non_nullable
as DateTime?,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as TimeQuality,
  ));
}


}


/// @nodoc
mixin _$Location {

 String get id; String get providerId; String get name; String? get place; double? get lat; double? get lon; LocationType get type; List<TransportMode> get modes;/// Trefferqualität der Suche (0–1), falls geliefert.
 double? get score;
/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationCopyWith<Location> get copyWith => _$LocationCopyWithImpl<Location>(this as Location, _$identity);

  /// Serializes this Location to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Location;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Location&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.providerId, _this.providerId) || other.providerId == _this.providerId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.place, _this.place) || other.place == _this.place)&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lon, _this.lon) || other.lon == _this.lon)&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.modes, _this.modes)&&(identical(other.score, _this.score) || other.score == _this.score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Location;
  return Object.hash(runtimeType,_this.id,_this.providerId,_this.name,_this.place,_this.lat,_this.lon,_this.type,const DeepCollectionEquality().hash(_this.modes),_this.score);
}

@override
String toString() {
  final _this = this as Location;
  return 'Location(id: ${_this.id}, providerId: ${_this.providerId}, name: ${_this.name}, place: ${_this.place}, lat: ${_this.lat}, lon: ${_this.lon}, type: ${_this.type}, modes: ${_this.modes}, score: ${_this.score})';
}


}

/// @nodoc
abstract mixin class $LocationCopyWith<$Res>  {
  factory $LocationCopyWith(Location value, $Res Function(Location) _then) = _$LocationCopyWithImpl;
@useResult
$Res call({
 String id, String providerId, String name, String? place, double? lat, double? lon, LocationType type, List<TransportMode> modes, double? score
});




}
/// @nodoc
class _$LocationCopyWithImpl<$Res>
    implements $LocationCopyWith<$Res> {
  _$LocationCopyWithImpl(this._self, this._then);

  final Location _self;
  final $Res Function(Location) _then;

/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? providerId = null,Object? name = null,Object? place = freezed,Object? lat = freezed,Object? lon = freezed,Object? type = null,Object? modes = null,Object? score = freezed,}) {
  return _then(Location(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lon: freezed == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LocationType,modes: null == modes ? _self.modes : modes // ignore: cast_nullable_to_non_nullable
as List<TransportMode>,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [Location].
extension LocationPatterns on Location {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Location value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Location() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Location value)  $default,){
final _that = this;
switch (_that) {
case _Location():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Location value)?  $default,){
final _that = this;
switch (_that) {
case _Location() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String providerId,  String name,  String? place,  double? lat,  double? lon,  LocationType type,  List<TransportMode> modes,  double? score)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Location() when $default != null:
return $default(_that.id,_that.providerId,_that.name,_that.place,_that.lat,_that.lon,_that.type,_that.modes,_that.score);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String providerId,  String name,  String? place,  double? lat,  double? lon,  LocationType type,  List<TransportMode> modes,  double? score)  $default,) {final _that = this;
switch (_that) {
case _Location():
return $default(_that.id,_that.providerId,_that.name,_that.place,_that.lat,_that.lon,_that.type,_that.modes,_that.score);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String providerId,  String name,  String? place,  double? lat,  double? lon,  LocationType type,  List<TransportMode> modes,  double? score)?  $default,) {final _that = this;
switch (_that) {
case _Location() when $default != null:
return $default(_that.id,_that.providerId,_that.name,_that.place,_that.lat,_that.lon,_that.type,_that.modes,_that.score);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Location implements Location {
  const _Location({required this.id, required this.providerId, required this.name, this.place, this.lat, this.lon, this.type = LocationType.stop,  List<TransportMode> modes = const <TransportMode>[], this.score}): _modes = modes;
  factory _Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

@override final  String id;
@override final  String providerId;
@override final  String name;
@override final  String? place;
@override final  double? lat;
@override final  double? lon;
@override@JsonKey() final  LocationType type;
 final  List<TransportMode> _modes;
@override@JsonKey() List<TransportMode> get modes {
  if (_modes is EqualUnmodifiableListView) return _modes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modes);
}

/// Trefferqualität der Suche (0–1), falls geliefert.
@override final  double? score;

/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocationCopyWith<_Location> get copyWith => __$LocationCopyWithImpl<_Location>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Location&&(identical(other.id, id) || other.id == id)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.place, place) || other.place == place)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.modes, _modes)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,providerId,name,place,lat,lon,type,const DeepCollectionEquality().hash(_modes),score);
}

@override
String toString() {
    return 'Location(id: $id, providerId: $providerId, name: $name, place: $place, lat: $lat, lon: $lon, type: $type, modes: $modes, score: $score)';
}


}

/// @nodoc
abstract mixin class _$LocationCopyWith<$Res> implements $LocationCopyWith<$Res> {
  factory _$LocationCopyWith(_Location value, $Res Function(_Location) _then) = __$LocationCopyWithImpl;
@override @useResult
$Res call({
 String id, String providerId, String name, String? place, double? lat, double? lon, LocationType type, List<TransportMode> modes, double? score
});




}
/// @nodoc
class __$LocationCopyWithImpl<$Res>
    implements _$LocationCopyWith<$Res> {
  __$LocationCopyWithImpl(this._self, this._then);

  final _Location _self;
  final $Res Function(_Location) _then;

/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? providerId = null,Object? name = null,Object? place = freezed,Object? lat = freezed,Object? lon = freezed,Object? type = null,Object? modes = null,Object? score = freezed,}) {
  return _then(_Location(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lon: freezed == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LocationType,modes: null == modes ? _self._modes : modes // ignore: cast_nullable_to_non_nullable
as List<TransportMode>,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$Line {

/// Kennung beim Provider (TRIAS LineRef, EFA line id).
 String get id;/// Liniennummer wie angezeigt, z. B. „640“, „S8“, „60“.
 String get name; TransportMode get mode; String? get operator;/// Ausführliche Bezeichnung, z. B. „ICE 950 InterCityExpress“.
 String? get longName;/// Linienart als Name von `Product` (bus, expressBus, cityExpress …).
 String? get product;
/// Create a copy of Line
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LineCopyWith<Line> get copyWith => _$LineCopyWithImpl<Line>(this as Line, _$identity);

  /// Serializes this Line to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Line;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Line&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.operator, _this.operator) || other.operator == _this.operator)&&(identical(other.longName, _this.longName) || other.longName == _this.longName)&&(identical(other.product, _this.product) || other.product == _this.product));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Line;
  return Object.hash(runtimeType,_this.id,_this.name,_this.mode,_this.operator,_this.longName,_this.product);
}

@override
String toString() {
  final _this = this as Line;
  return 'Line(id: ${_this.id}, name: ${_this.name}, mode: ${_this.mode}, operator: ${_this.operator}, longName: ${_this.longName}, product: ${_this.product})';
}


}

/// @nodoc
abstract mixin class $LineCopyWith<$Res>  {
  factory $LineCopyWith(Line value, $Res Function(Line) _then) = _$LineCopyWithImpl;
@useResult
$Res call({
 String id, String name, TransportMode mode, String? operator, String? longName, String? product
});




}
/// @nodoc
class _$LineCopyWithImpl<$Res>
    implements $LineCopyWith<$Res> {
  _$LineCopyWithImpl(this._self, this._then);

  final Line _self;
  final $Res Function(Line) _then;

/// Create a copy of Line
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? mode = null,Object? operator = freezed,Object? longName = freezed,Object? product = freezed,}) {
  return _then(Line(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as TransportMode,operator: freezed == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as String?,longName: freezed == longName ? _self.longName : longName // ignore: cast_nullable_to_non_nullable
as String?,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Line].
extension LinePatterns on Line {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Line value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Line() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Line value)  $default,){
final _that = this;
switch (_that) {
case _Line():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Line value)?  $default,){
final _that = this;
switch (_that) {
case _Line() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  TransportMode mode,  String? operator,  String? longName,  String? product)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Line() when $default != null:
return $default(_that.id,_that.name,_that.mode,_that.operator,_that.longName,_that.product);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  TransportMode mode,  String? operator,  String? longName,  String? product)  $default,) {final _that = this;
switch (_that) {
case _Line():
return $default(_that.id,_that.name,_that.mode,_that.operator,_that.longName,_that.product);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  TransportMode mode,  String? operator,  String? longName,  String? product)?  $default,) {final _that = this;
switch (_that) {
case _Line() when $default != null:
return $default(_that.id,_that.name,_that.mode,_that.operator,_that.longName,_that.product);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Line implements Line {
  const _Line({required this.id, required this.name, required this.mode, this.operator, this.longName, this.product});
  factory _Line.fromJson(Map<String, dynamic> json) => _$LineFromJson(json);

/// Kennung beim Provider (TRIAS LineRef, EFA line id).
@override final  String id;
/// Liniennummer wie angezeigt, z. B. „640“, „S8“, „60“.
@override final  String name;
@override final  TransportMode mode;
@override final  String? operator;
/// Ausführliche Bezeichnung, z. B. „ICE 950 InterCityExpress“.
@override final  String? longName;
/// Linienart als Name von `Product` (bus, expressBus, cityExpress …).
@override final  String? product;

/// Create a copy of Line
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LineCopyWith<_Line> get copyWith => __$LineCopyWithImpl<_Line>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Line&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.longName, longName) || other.longName == longName)&&(identical(other.product, product) || other.product == product));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,mode,operator,longName,product);
}

@override
String toString() {
    return 'Line(id: $id, name: $name, mode: $mode, operator: $operator, longName: $longName, product: $product)';
}


}

/// @nodoc
abstract mixin class _$LineCopyWith<$Res> implements $LineCopyWith<$Res> {
  factory _$LineCopyWith(_Line value, $Res Function(_Line) _then) = __$LineCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, TransportMode mode, String? operator, String? longName, String? product
});




}
/// @nodoc
class __$LineCopyWithImpl<$Res>
    implements _$LineCopyWith<$Res> {
  __$LineCopyWithImpl(this._self, this._then);

  final _Line _self;
  final $Res Function(_Line) _then;

/// Create a copy of Line
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? mode = null,Object? operator = freezed,Object? longName = freezed,Object? product = freezed,}) {
  return _then(_Line(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as TransportMode,operator: freezed == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as String?,longName: freezed == longName ? _self.longName : longName // ignore: cast_nullable_to_non_nullable
as String?,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$StopTime {

 Location get stop; EventTime? get arrival; EventTime? get departure; String? get plannedPlatform; String? get platform; StopStatus get status; int? get sequence;
/// Create a copy of StopTime
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StopTimeCopyWith<StopTime> get copyWith => _$StopTimeCopyWithImpl<StopTime>(this as StopTime, _$identity);

  /// Serializes this StopTime to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StopTime;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StopTime&&(identical(other.stop, _this.stop) || other.stop == _this.stop)&&(identical(other.arrival, _this.arrival) || other.arrival == _this.arrival)&&(identical(other.departure, _this.departure) || other.departure == _this.departure)&&(identical(other.plannedPlatform, _this.plannedPlatform) || other.plannedPlatform == _this.plannedPlatform)&&(identical(other.platform, _this.platform) || other.platform == _this.platform)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.sequence, _this.sequence) || other.sequence == _this.sequence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StopTime;
  return Object.hash(runtimeType,_this.stop,_this.arrival,_this.departure,_this.plannedPlatform,_this.platform,_this.status,_this.sequence);
}

@override
String toString() {
  final _this = this as StopTime;
  return 'StopTime(stop: ${_this.stop}, arrival: ${_this.arrival}, departure: ${_this.departure}, plannedPlatform: ${_this.plannedPlatform}, platform: ${_this.platform}, status: ${_this.status}, sequence: ${_this.sequence})';
}


}

/// @nodoc
abstract mixin class $StopTimeCopyWith<$Res>  {
  factory $StopTimeCopyWith(StopTime value, $Res Function(StopTime) _then) = _$StopTimeCopyWithImpl;
@useResult
$Res call({
 Location stop, EventTime? arrival, EventTime? departure, String? plannedPlatform, String? platform, StopStatus status, int? sequence
});


$LocationCopyWith<$Res> get stop;$EventTimeCopyWith<$Res>? get arrival;$EventTimeCopyWith<$Res>? get departure;

}
/// @nodoc
class _$StopTimeCopyWithImpl<$Res>
    implements $StopTimeCopyWith<$Res> {
  _$StopTimeCopyWithImpl(this._self, this._then);

  final StopTime _self;
  final $Res Function(StopTime) _then;

/// Create a copy of StopTime
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stop = null,Object? arrival = freezed,Object? departure = freezed,Object? plannedPlatform = freezed,Object? platform = freezed,Object? status = null,Object? sequence = freezed,}) {
  return _then(StopTime(
stop: null == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as Location,arrival: freezed == arrival ? _self.arrival : arrival // ignore: cast_nullable_to_non_nullable
as EventTime?,departure: freezed == departure ? _self.departure : departure // ignore: cast_nullable_to_non_nullable
as EventTime?,plannedPlatform: freezed == plannedPlatform ? _self.plannedPlatform : plannedPlatform // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StopStatus,sequence: freezed == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of StopTime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res> get stop {
  
  return $LocationCopyWith<$Res>(_self.stop, (value) {
    return _then(_self.copyWith(stop: value));
  });
}/// Create a copy of StopTime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventTimeCopyWith<$Res>? get arrival {
    if (_self.arrival == null) {
    return null;
  }

  return $EventTimeCopyWith<$Res>(_self.arrival!, (value) {
    return _then(_self.copyWith(arrival: value));
  });
}/// Create a copy of StopTime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventTimeCopyWith<$Res>? get departure {
    if (_self.departure == null) {
    return null;
  }

  return $EventTimeCopyWith<$Res>(_self.departure!, (value) {
    return _then(_self.copyWith(departure: value));
  });
}
}


/// Adds pattern-matching-related methods to [StopTime].
extension StopTimePatterns on StopTime {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StopTime value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StopTime() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StopTime value)  $default,){
final _that = this;
switch (_that) {
case _StopTime():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StopTime value)?  $default,){
final _that = this;
switch (_that) {
case _StopTime() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Location stop,  EventTime? arrival,  EventTime? departure,  String? plannedPlatform,  String? platform,  StopStatus status,  int? sequence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StopTime() when $default != null:
return $default(_that.stop,_that.arrival,_that.departure,_that.plannedPlatform,_that.platform,_that.status,_that.sequence);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Location stop,  EventTime? arrival,  EventTime? departure,  String? plannedPlatform,  String? platform,  StopStatus status,  int? sequence)  $default,) {final _that = this;
switch (_that) {
case _StopTime():
return $default(_that.stop,_that.arrival,_that.departure,_that.plannedPlatform,_that.platform,_that.status,_that.sequence);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Location stop,  EventTime? arrival,  EventTime? departure,  String? plannedPlatform,  String? platform,  StopStatus status,  int? sequence)?  $default,) {final _that = this;
switch (_that) {
case _StopTime() when $default != null:
return $default(_that.stop,_that.arrival,_that.departure,_that.plannedPlatform,_that.platform,_that.status,_that.sequence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StopTime implements StopTime {
  const _StopTime({required this.stop, this.arrival, this.departure, this.plannedPlatform, this.platform, this.status = StopStatus.normal, this.sequence});
  factory _StopTime.fromJson(Map<String, dynamic> json) => _$StopTimeFromJson(json);

@override final  Location stop;
@override final  EventTime? arrival;
@override final  EventTime? departure;
@override final  String? plannedPlatform;
@override final  String? platform;
@override@JsonKey() final  StopStatus status;
@override final  int? sequence;

/// Create a copy of StopTime
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StopTimeCopyWith<_StopTime> get copyWith => __$StopTimeCopyWithImpl<_StopTime>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StopTimeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StopTime&&(identical(other.stop, stop) || other.stop == stop)&&(identical(other.arrival, arrival) || other.arrival == arrival)&&(identical(other.departure, departure) || other.departure == departure)&&(identical(other.plannedPlatform, plannedPlatform) || other.plannedPlatform == plannedPlatform)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.status, status) || other.status == status)&&(identical(other.sequence, sequence) || other.sequence == sequence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,stop,arrival,departure,plannedPlatform,platform,status,sequence);
}

@override
String toString() {
    return 'StopTime(stop: $stop, arrival: $arrival, departure: $departure, plannedPlatform: $plannedPlatform, platform: $platform, status: $status, sequence: $sequence)';
}


}

/// @nodoc
abstract mixin class _$StopTimeCopyWith<$Res> implements $StopTimeCopyWith<$Res> {
  factory _$StopTimeCopyWith(_StopTime value, $Res Function(_StopTime) _then) = __$StopTimeCopyWithImpl;
@override @useResult
$Res call({
 Location stop, EventTime? arrival, EventTime? departure, String? plannedPlatform, String? platform, StopStatus status, int? sequence
});


@override $LocationCopyWith<$Res> get stop;@override $EventTimeCopyWith<$Res>? get arrival;@override $EventTimeCopyWith<$Res>? get departure;

}
/// @nodoc
class __$StopTimeCopyWithImpl<$Res>
    implements _$StopTimeCopyWith<$Res> {
  __$StopTimeCopyWithImpl(this._self, this._then);

  final _StopTime _self;
  final $Res Function(_StopTime) _then;

/// Create a copy of StopTime
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stop = null,Object? arrival = freezed,Object? departure = freezed,Object? plannedPlatform = freezed,Object? platform = freezed,Object? status = null,Object? sequence = freezed,}) {
  return _then(_StopTime(
stop: null == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as Location,arrival: freezed == arrival ? _self.arrival : arrival // ignore: cast_nullable_to_non_nullable
as EventTime?,departure: freezed == departure ? _self.departure : departure // ignore: cast_nullable_to_non_nullable
as EventTime?,plannedPlatform: freezed == plannedPlatform ? _self.plannedPlatform : plannedPlatform // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StopStatus,sequence: freezed == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of StopTime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res> get stop {
  
  return $LocationCopyWith<$Res>(_self.stop, (value) {
    return _then(_self.copyWith(stop: value));
  });
}/// Create a copy of StopTime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventTimeCopyWith<$Res>? get arrival {
    if (_self.arrival == null) {
    return null;
  }

  return $EventTimeCopyWith<$Res>(_self.arrival!, (value) {
    return _then(_self.copyWith(arrival: value));
  });
}/// Create a copy of StopTime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventTimeCopyWith<$Res>? get departure {
    if (_self.departure == null) {
    return null;
  }

  return $EventTimeCopyWith<$Res>(_self.departure!, (value) {
    return _then(_self.copyWith(departure: value));
  });
}
}


/// @nodoc
mixin _$Leg {

 LegType get type; StopTime get from; StopTime get to; Line? get line; String? get direction; List<StopTime> get intermediates;/// Fahrt-Referenz des Providers (TRIAS JourneyRef).
 String? get journeyRef;/// Betriebstag der Fahrt.
 String? get operatingDay;/// Dauer bei Fuß- und Umsteigewegen.
 int? get durationMinutes;/// Umstieg ohne Umsteigen: Das Fahrzeug fährt unter neuer Linie bzw.
/// Fahrtnummer weiter (TRIAS InterchangeMode „remainInVehicle“).
 bool get staySeated; List<String> get messageIds;
/// Create a copy of Leg
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegCopyWith<Leg> get copyWith => _$LegCopyWithImpl<Leg>(this as Leg, _$identity);

  /// Serializes this Leg to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Leg;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Leg&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.to, _this.to) || other.to == _this.to)&&(identical(other.line, _this.line) || other.line == _this.line)&&(identical(other.direction, _this.direction) || other.direction == _this.direction)&&const DeepCollectionEquality().equals(other.intermediates, _this.intermediates)&&(identical(other.journeyRef, _this.journeyRef) || other.journeyRef == _this.journeyRef)&&(identical(other.operatingDay, _this.operatingDay) || other.operatingDay == _this.operatingDay)&&(identical(other.durationMinutes, _this.durationMinutes) || other.durationMinutes == _this.durationMinutes)&&(identical(other.staySeated, _this.staySeated) || other.staySeated == _this.staySeated)&&const DeepCollectionEquality().equals(other.messageIds, _this.messageIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Leg;
  return Object.hash(runtimeType,_this.type,_this.from,_this.to,_this.line,_this.direction,const DeepCollectionEquality().hash(_this.intermediates),_this.journeyRef,_this.operatingDay,_this.durationMinutes,_this.staySeated,const DeepCollectionEquality().hash(_this.messageIds));
}

@override
String toString() {
  final _this = this as Leg;
  return 'Leg(type: ${_this.type}, from: ${_this.from}, to: ${_this.to}, line: ${_this.line}, direction: ${_this.direction}, intermediates: ${_this.intermediates}, journeyRef: ${_this.journeyRef}, operatingDay: ${_this.operatingDay}, durationMinutes: ${_this.durationMinutes}, staySeated: ${_this.staySeated}, messageIds: ${_this.messageIds})';
}


}

/// @nodoc
abstract mixin class $LegCopyWith<$Res>  {
  factory $LegCopyWith(Leg value, $Res Function(Leg) _then) = _$LegCopyWithImpl;
@useResult
$Res call({
 LegType type, StopTime from, StopTime to, Line? line, String? direction, List<StopTime> intermediates, String? journeyRef, String? operatingDay, int? durationMinutes, bool staySeated, List<String> messageIds
});


$StopTimeCopyWith<$Res> get from;$StopTimeCopyWith<$Res> get to;$LineCopyWith<$Res>? get line;

}
/// @nodoc
class _$LegCopyWithImpl<$Res>
    implements $LegCopyWith<$Res> {
  _$LegCopyWithImpl(this._self, this._then);

  final Leg _self;
  final $Res Function(Leg) _then;

/// Create a copy of Leg
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? from = null,Object? to = null,Object? line = freezed,Object? direction = freezed,Object? intermediates = null,Object? journeyRef = freezed,Object? operatingDay = freezed,Object? durationMinutes = freezed,Object? staySeated = null,Object? messageIds = null,}) {
  return _then(Leg(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LegType,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as StopTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as StopTime,line: freezed == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as Line?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,intermediates: null == intermediates ? _self.intermediates : intermediates // ignore: cast_nullable_to_non_nullable
as List<StopTime>,journeyRef: freezed == journeyRef ? _self.journeyRef : journeyRef // ignore: cast_nullable_to_non_nullable
as String?,operatingDay: freezed == operatingDay ? _self.operatingDay : operatingDay // ignore: cast_nullable_to_non_nullable
as String?,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,staySeated: null == staySeated ? _self.staySeated : staySeated // ignore: cast_nullable_to_non_nullable
as bool,messageIds: null == messageIds ? _self.messageIds : messageIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of Leg
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StopTimeCopyWith<$Res> get from {
  
  return $StopTimeCopyWith<$Res>(_self.from, (value) {
    return _then(_self.copyWith(from: value));
  });
}/// Create a copy of Leg
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StopTimeCopyWith<$Res> get to {
  
  return $StopTimeCopyWith<$Res>(_self.to, (value) {
    return _then(_self.copyWith(to: value));
  });
}/// Create a copy of Leg
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LineCopyWith<$Res>? get line {
    if (_self.line == null) {
    return null;
  }

  return $LineCopyWith<$Res>(_self.line!, (value) {
    return _then(_self.copyWith(line: value));
  });
}
}


/// Adds pattern-matching-related methods to [Leg].
extension LegPatterns on Leg {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Leg value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Leg() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Leg value)  $default,){
final _that = this;
switch (_that) {
case _Leg():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Leg value)?  $default,){
final _that = this;
switch (_that) {
case _Leg() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LegType type,  StopTime from,  StopTime to,  Line? line,  String? direction,  List<StopTime> intermediates,  String? journeyRef,  String? operatingDay,  int? durationMinutes,  bool staySeated,  List<String> messageIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Leg() when $default != null:
return $default(_that.type,_that.from,_that.to,_that.line,_that.direction,_that.intermediates,_that.journeyRef,_that.operatingDay,_that.durationMinutes,_that.staySeated,_that.messageIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LegType type,  StopTime from,  StopTime to,  Line? line,  String? direction,  List<StopTime> intermediates,  String? journeyRef,  String? operatingDay,  int? durationMinutes,  bool staySeated,  List<String> messageIds)  $default,) {final _that = this;
switch (_that) {
case _Leg():
return $default(_that.type,_that.from,_that.to,_that.line,_that.direction,_that.intermediates,_that.journeyRef,_that.operatingDay,_that.durationMinutes,_that.staySeated,_that.messageIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LegType type,  StopTime from,  StopTime to,  Line? line,  String? direction,  List<StopTime> intermediates,  String? journeyRef,  String? operatingDay,  int? durationMinutes,  bool staySeated,  List<String> messageIds)?  $default,) {final _that = this;
switch (_that) {
case _Leg() when $default != null:
return $default(_that.type,_that.from,_that.to,_that.line,_that.direction,_that.intermediates,_that.journeyRef,_that.operatingDay,_that.durationMinutes,_that.staySeated,_that.messageIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Leg implements Leg {
  const _Leg({required this.type, required this.from, required this.to, this.line, this.direction,  List<StopTime> intermediates = const <StopTime>[], this.journeyRef, this.operatingDay, this.durationMinutes, this.staySeated = false,  List<String> messageIds = const <String>[]}): _intermediates = intermediates,_messageIds = messageIds;
  factory _Leg.fromJson(Map<String, dynamic> json) => _$LegFromJson(json);

@override final  LegType type;
@override final  StopTime from;
@override final  StopTime to;
@override final  Line? line;
@override final  String? direction;
 final  List<StopTime> _intermediates;
@override@JsonKey() List<StopTime> get intermediates {
  if (_intermediates is EqualUnmodifiableListView) return _intermediates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_intermediates);
}

/// Fahrt-Referenz des Providers (TRIAS JourneyRef).
@override final  String? journeyRef;
/// Betriebstag der Fahrt.
@override final  String? operatingDay;
/// Dauer bei Fuß- und Umsteigewegen.
@override final  int? durationMinutes;
/// Umstieg ohne Umsteigen: Das Fahrzeug fährt unter neuer Linie bzw.
/// Fahrtnummer weiter (TRIAS InterchangeMode „remainInVehicle“).
@override@JsonKey() final  bool staySeated;
 final  List<String> _messageIds;
@override@JsonKey() List<String> get messageIds {
  if (_messageIds is EqualUnmodifiableListView) return _messageIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messageIds);
}


/// Create a copy of Leg
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LegCopyWith<_Leg> get copyWith => __$LegCopyWithImpl<_Leg>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LegToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Leg&&(identical(other.type, type) || other.type == type)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.line, line) || other.line == line)&&(identical(other.direction, direction) || other.direction == direction)&&const DeepCollectionEquality().equals(other.intermediates, _intermediates)&&(identical(other.journeyRef, journeyRef) || other.journeyRef == journeyRef)&&(identical(other.operatingDay, operatingDay) || other.operatingDay == operatingDay)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.staySeated, staySeated) || other.staySeated == staySeated)&&const DeepCollectionEquality().equals(other.messageIds, _messageIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,from,to,line,direction,const DeepCollectionEquality().hash(_intermediates),journeyRef,operatingDay,durationMinutes,staySeated,const DeepCollectionEquality().hash(_messageIds));
}

@override
String toString() {
    return 'Leg(type: $type, from: $from, to: $to, line: $line, direction: $direction, intermediates: $intermediates, journeyRef: $journeyRef, operatingDay: $operatingDay, durationMinutes: $durationMinutes, staySeated: $staySeated, messageIds: $messageIds)';
}


}

/// @nodoc
abstract mixin class _$LegCopyWith<$Res> implements $LegCopyWith<$Res> {
  factory _$LegCopyWith(_Leg value, $Res Function(_Leg) _then) = __$LegCopyWithImpl;
@override @useResult
$Res call({
 LegType type, StopTime from, StopTime to, Line? line, String? direction, List<StopTime> intermediates, String? journeyRef, String? operatingDay, int? durationMinutes, bool staySeated, List<String> messageIds
});


@override $StopTimeCopyWith<$Res> get from;@override $StopTimeCopyWith<$Res> get to;@override $LineCopyWith<$Res>? get line;

}
/// @nodoc
class __$LegCopyWithImpl<$Res>
    implements _$LegCopyWith<$Res> {
  __$LegCopyWithImpl(this._self, this._then);

  final _Leg _self;
  final $Res Function(_Leg) _then;

/// Create a copy of Leg
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? from = null,Object? to = null,Object? line = freezed,Object? direction = freezed,Object? intermediates = null,Object? journeyRef = freezed,Object? operatingDay = freezed,Object? durationMinutes = freezed,Object? staySeated = null,Object? messageIds = null,}) {
  return _then(_Leg(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LegType,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as StopTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as StopTime,line: freezed == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as Line?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,intermediates: null == intermediates ? _self._intermediates : intermediates // ignore: cast_nullable_to_non_nullable
as List<StopTime>,journeyRef: freezed == journeyRef ? _self.journeyRef : journeyRef // ignore: cast_nullable_to_non_nullable
as String?,operatingDay: freezed == operatingDay ? _self.operatingDay : operatingDay // ignore: cast_nullable_to_non_nullable
as String?,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,staySeated: null == staySeated ? _self.staySeated : staySeated // ignore: cast_nullable_to_non_nullable
as bool,messageIds: null == messageIds ? _self._messageIds : messageIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of Leg
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StopTimeCopyWith<$Res> get from {
  
  return $StopTimeCopyWith<$Res>(_self.from, (value) {
    return _then(_self.copyWith(from: value));
  });
}/// Create a copy of Leg
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StopTimeCopyWith<$Res> get to {
  
  return $StopTimeCopyWith<$Res>(_self.to, (value) {
    return _then(_self.copyWith(to: value));
  });
}/// Create a copy of Leg
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LineCopyWith<$Res>? get line {
    if (_self.line == null) {
    return null;
  }

  return $LineCopyWith<$Res>(_self.line!, (value) {
    return _then(_self.copyWith(line: value));
  });
}
}


/// @nodoc
mixin _$Trip {

 String get id; List<Leg> get legs; List<Message> get messages;
/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripCopyWith<Trip> get copyWith => _$TripCopyWithImpl<Trip>(this as Trip, _$identity);

  /// Serializes this Trip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Trip;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Trip&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.legs, _this.legs)&&const DeepCollectionEquality().equals(other.messages, _this.messages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Trip;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.legs),const DeepCollectionEquality().hash(_this.messages));
}

@override
String toString() {
  final _this = this as Trip;
  return 'Trip(id: ${_this.id}, legs: ${_this.legs}, messages: ${_this.messages})';
}


}

/// @nodoc
abstract mixin class $TripCopyWith<$Res>  {
  factory $TripCopyWith(Trip value, $Res Function(Trip) _then) = _$TripCopyWithImpl;
@useResult
$Res call({
 String id, List<Leg> legs, List<Message> messages
});




}
/// @nodoc
class _$TripCopyWithImpl<$Res>
    implements $TripCopyWith<$Res> {
  _$TripCopyWithImpl(this._self, this._then);

  final Trip _self;
  final $Res Function(Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? legs = null,Object? messages = null,}) {
  return _then(Trip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,legs: null == legs ? _self.legs : legs // ignore: cast_nullable_to_non_nullable
as List<Leg>,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,
  ));
}

}


/// Adds pattern-matching-related methods to [Trip].
extension TripPatterns on Trip {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Trip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Trip value)  $default,){
final _that = this;
switch (_that) {
case _Trip():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Trip value)?  $default,){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  List<Leg> legs,  List<Message> messages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.legs,_that.messages);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  List<Leg> legs,  List<Message> messages)  $default,) {final _that = this;
switch (_that) {
case _Trip():
return $default(_that.id,_that.legs,_that.messages);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  List<Leg> legs,  List<Message> messages)?  $default,) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.legs,_that.messages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Trip extends Trip {
  const _Trip({required this.id, required  List<Leg> legs,  List<Message> messages = const <Message>[]}): _legs = legs,_messages = messages,super._();
  factory _Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

@override final  String id;
 final  List<Leg> _legs;
@override List<Leg> get legs {
  if (_legs is EqualUnmodifiableListView) return _legs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_legs);
}

 final  List<Message> _messages;
@override@JsonKey() List<Message> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}


/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripCopyWith<_Trip> get copyWith => __$TripCopyWithImpl<_Trip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trip&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.legs, _legs)&&const DeepCollectionEquality().equals(other.messages, _messages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_legs),const DeepCollectionEquality().hash(_messages));
}

@override
String toString() {
    return 'Trip(id: $id, legs: $legs, messages: $messages)';
}


}

/// @nodoc
abstract mixin class _$TripCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$TripCopyWith(_Trip value, $Res Function(_Trip) _then) = __$TripCopyWithImpl;
@override @useResult
$Res call({
 String id, List<Leg> legs, List<Message> messages
});




}
/// @nodoc
class __$TripCopyWithImpl<$Res>
    implements _$TripCopyWith<$Res> {
  __$TripCopyWithImpl(this._self, this._then);

  final _Trip _self;
  final $Res Function(_Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? legs = null,Object? messages = null,}) {
  return _then(_Trip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,legs: null == legs ? _self._legs : legs // ignore: cast_nullable_to_non_nullable
as List<Leg>,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,
  ));
}


}


/// @nodoc
mixin _$Departure {

 Location get stop; Line get line; String get direction; EventTime get time; String? get plannedPlatform; String? get platform; StopStatus get status; String? get journeyRef; String? get operatingDay; List<String> get messageIds;
/// Create a copy of Departure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DepartureCopyWith<Departure> get copyWith => _$DepartureCopyWithImpl<Departure>(this as Departure, _$identity);

  /// Serializes this Departure to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Departure;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Departure&&(identical(other.stop, _this.stop) || other.stop == _this.stop)&&(identical(other.line, _this.line) || other.line == _this.line)&&(identical(other.direction, _this.direction) || other.direction == _this.direction)&&(identical(other.time, _this.time) || other.time == _this.time)&&(identical(other.plannedPlatform, _this.plannedPlatform) || other.plannedPlatform == _this.plannedPlatform)&&(identical(other.platform, _this.platform) || other.platform == _this.platform)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.journeyRef, _this.journeyRef) || other.journeyRef == _this.journeyRef)&&(identical(other.operatingDay, _this.operatingDay) || other.operatingDay == _this.operatingDay)&&const DeepCollectionEquality().equals(other.messageIds, _this.messageIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Departure;
  return Object.hash(runtimeType,_this.stop,_this.line,_this.direction,_this.time,_this.plannedPlatform,_this.platform,_this.status,_this.journeyRef,_this.operatingDay,const DeepCollectionEquality().hash(_this.messageIds));
}

@override
String toString() {
  final _this = this as Departure;
  return 'Departure(stop: ${_this.stop}, line: ${_this.line}, direction: ${_this.direction}, time: ${_this.time}, plannedPlatform: ${_this.plannedPlatform}, platform: ${_this.platform}, status: ${_this.status}, journeyRef: ${_this.journeyRef}, operatingDay: ${_this.operatingDay}, messageIds: ${_this.messageIds})';
}


}

/// @nodoc
abstract mixin class $DepartureCopyWith<$Res>  {
  factory $DepartureCopyWith(Departure value, $Res Function(Departure) _then) = _$DepartureCopyWithImpl;
@useResult
$Res call({
 Location stop, Line line, String direction, EventTime time, String? plannedPlatform, String? platform, StopStatus status, String? journeyRef, String? operatingDay, List<String> messageIds
});


$LocationCopyWith<$Res> get stop;$LineCopyWith<$Res> get line;$EventTimeCopyWith<$Res> get time;

}
/// @nodoc
class _$DepartureCopyWithImpl<$Res>
    implements $DepartureCopyWith<$Res> {
  _$DepartureCopyWithImpl(this._self, this._then);

  final Departure _self;
  final $Res Function(Departure) _then;

/// Create a copy of Departure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stop = null,Object? line = null,Object? direction = null,Object? time = null,Object? plannedPlatform = freezed,Object? platform = freezed,Object? status = null,Object? journeyRef = freezed,Object? operatingDay = freezed,Object? messageIds = null,}) {
  return _then(Departure(
stop: null == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as Location,line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as Line,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as EventTime,plannedPlatform: freezed == plannedPlatform ? _self.plannedPlatform : plannedPlatform // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StopStatus,journeyRef: freezed == journeyRef ? _self.journeyRef : journeyRef // ignore: cast_nullable_to_non_nullable
as String?,operatingDay: freezed == operatingDay ? _self.operatingDay : operatingDay // ignore: cast_nullable_to_non_nullable
as String?,messageIds: null == messageIds ? _self.messageIds : messageIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of Departure
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res> get stop {
  
  return $LocationCopyWith<$Res>(_self.stop, (value) {
    return _then(_self.copyWith(stop: value));
  });
}/// Create a copy of Departure
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LineCopyWith<$Res> get line {
  
  return $LineCopyWith<$Res>(_self.line, (value) {
    return _then(_self.copyWith(line: value));
  });
}/// Create a copy of Departure
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventTimeCopyWith<$Res> get time {
  
  return $EventTimeCopyWith<$Res>(_self.time, (value) {
    return _then(_self.copyWith(time: value));
  });
}
}


/// Adds pattern-matching-related methods to [Departure].
extension DeparturePatterns on Departure {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Departure value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Departure() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Departure value)  $default,){
final _that = this;
switch (_that) {
case _Departure():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Departure value)?  $default,){
final _that = this;
switch (_that) {
case _Departure() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Location stop,  Line line,  String direction,  EventTime time,  String? plannedPlatform,  String? platform,  StopStatus status,  String? journeyRef,  String? operatingDay,  List<String> messageIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Departure() when $default != null:
return $default(_that.stop,_that.line,_that.direction,_that.time,_that.plannedPlatform,_that.platform,_that.status,_that.journeyRef,_that.operatingDay,_that.messageIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Location stop,  Line line,  String direction,  EventTime time,  String? plannedPlatform,  String? platform,  StopStatus status,  String? journeyRef,  String? operatingDay,  List<String> messageIds)  $default,) {final _that = this;
switch (_that) {
case _Departure():
return $default(_that.stop,_that.line,_that.direction,_that.time,_that.plannedPlatform,_that.platform,_that.status,_that.journeyRef,_that.operatingDay,_that.messageIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Location stop,  Line line,  String direction,  EventTime time,  String? plannedPlatform,  String? platform,  StopStatus status,  String? journeyRef,  String? operatingDay,  List<String> messageIds)?  $default,) {final _that = this;
switch (_that) {
case _Departure() when $default != null:
return $default(_that.stop,_that.line,_that.direction,_that.time,_that.plannedPlatform,_that.platform,_that.status,_that.journeyRef,_that.operatingDay,_that.messageIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Departure implements Departure {
  const _Departure({required this.stop, required this.line, required this.direction, required this.time, this.plannedPlatform, this.platform, this.status = StopStatus.normal, this.journeyRef, this.operatingDay,  List<String> messageIds = const <String>[]}): _messageIds = messageIds;
  factory _Departure.fromJson(Map<String, dynamic> json) => _$DepartureFromJson(json);

@override final  Location stop;
@override final  Line line;
@override final  String direction;
@override final  EventTime time;
@override final  String? plannedPlatform;
@override final  String? platform;
@override@JsonKey() final  StopStatus status;
@override final  String? journeyRef;
@override final  String? operatingDay;
 final  List<String> _messageIds;
@override@JsonKey() List<String> get messageIds {
  if (_messageIds is EqualUnmodifiableListView) return _messageIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messageIds);
}


/// Create a copy of Departure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DepartureCopyWith<_Departure> get copyWith => __$DepartureCopyWithImpl<_Departure>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DepartureToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Departure&&(identical(other.stop, stop) || other.stop == stop)&&(identical(other.line, line) || other.line == line)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.time, time) || other.time == time)&&(identical(other.plannedPlatform, plannedPlatform) || other.plannedPlatform == plannedPlatform)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.status, status) || other.status == status)&&(identical(other.journeyRef, journeyRef) || other.journeyRef == journeyRef)&&(identical(other.operatingDay, operatingDay) || other.operatingDay == operatingDay)&&const DeepCollectionEquality().equals(other.messageIds, _messageIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,stop,line,direction,time,plannedPlatform,platform,status,journeyRef,operatingDay,const DeepCollectionEquality().hash(_messageIds));
}

@override
String toString() {
    return 'Departure(stop: $stop, line: $line, direction: $direction, time: $time, plannedPlatform: $plannedPlatform, platform: $platform, status: $status, journeyRef: $journeyRef, operatingDay: $operatingDay, messageIds: $messageIds)';
}


}

/// @nodoc
abstract mixin class _$DepartureCopyWith<$Res> implements $DepartureCopyWith<$Res> {
  factory _$DepartureCopyWith(_Departure value, $Res Function(_Departure) _then) = __$DepartureCopyWithImpl;
@override @useResult
$Res call({
 Location stop, Line line, String direction, EventTime time, String? plannedPlatform, String? platform, StopStatus status, String? journeyRef, String? operatingDay, List<String> messageIds
});


@override $LocationCopyWith<$Res> get stop;@override $LineCopyWith<$Res> get line;@override $EventTimeCopyWith<$Res> get time;

}
/// @nodoc
class __$DepartureCopyWithImpl<$Res>
    implements _$DepartureCopyWith<$Res> {
  __$DepartureCopyWithImpl(this._self, this._then);

  final _Departure _self;
  final $Res Function(_Departure) _then;

/// Create a copy of Departure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stop = null,Object? line = null,Object? direction = null,Object? time = null,Object? plannedPlatform = freezed,Object? platform = freezed,Object? status = null,Object? journeyRef = freezed,Object? operatingDay = freezed,Object? messageIds = null,}) {
  return _then(_Departure(
stop: null == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as Location,line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as Line,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as EventTime,plannedPlatform: freezed == plannedPlatform ? _self.plannedPlatform : plannedPlatform // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StopStatus,journeyRef: freezed == journeyRef ? _self.journeyRef : journeyRef // ignore: cast_nullable_to_non_nullable
as String?,operatingDay: freezed == operatingDay ? _self.operatingDay : operatingDay // ignore: cast_nullable_to_non_nullable
as String?,messageIds: null == messageIds ? _self._messageIds : messageIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of Departure
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res> get stop {
  
  return $LocationCopyWith<$Res>(_self.stop, (value) {
    return _then(_self.copyWith(stop: value));
  });
}/// Create a copy of Departure
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LineCopyWith<$Res> get line {
  
  return $LineCopyWith<$Res>(_self.line, (value) {
    return _then(_self.copyWith(line: value));
  });
}/// Create a copy of Departure
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventTimeCopyWith<$Res> get time {
  
  return $EventTimeCopyWith<$Res>(_self.time, (value) {
    return _then(_self.copyWith(time: value));
  });
}
}


/// @nodoc
mixin _$Message {

 String get id; String get title; String? get text; List<String> get lineIds;/// Liniennummern passend zu [lineIds], für die Anzeige als Plaketten.
 List<String> get lineNames; List<String> get stopIds; DateTime? get validFrom; DateTime? get validTo;/// Datenquelle, z. B. „VRR“ oder „DB“.
 String? get source;/// Gebiete (Gemeindeschlüssel), unter denen die Auskunft sie führt.
 List<String> get regions;
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCopyWith<Message> get copyWith => _$MessageCopyWithImpl<Message>(this as Message, _$identity);

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Message;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Message&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.text, _this.text) || other.text == _this.text)&&const DeepCollectionEquality().equals(other.lineIds, _this.lineIds)&&const DeepCollectionEquality().equals(other.lineNames, _this.lineNames)&&const DeepCollectionEquality().equals(other.stopIds, _this.stopIds)&&(identical(other.validFrom, _this.validFrom) || other.validFrom == _this.validFrom)&&(identical(other.validTo, _this.validTo) || other.validTo == _this.validTo)&&(identical(other.source, _this.source) || other.source == _this.source)&&const DeepCollectionEquality().equals(other.regions, _this.regions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Message;
  return Object.hash(runtimeType,_this.id,_this.title,_this.text,const DeepCollectionEquality().hash(_this.lineIds),const DeepCollectionEquality().hash(_this.lineNames),const DeepCollectionEquality().hash(_this.stopIds),_this.validFrom,_this.validTo,_this.source,const DeepCollectionEquality().hash(_this.regions));
}

@override
String toString() {
  final _this = this as Message;
  return 'Message(id: ${_this.id}, title: ${_this.title}, text: ${_this.text}, lineIds: ${_this.lineIds}, lineNames: ${_this.lineNames}, stopIds: ${_this.stopIds}, validFrom: ${_this.validFrom}, validTo: ${_this.validTo}, source: ${_this.source}, regions: ${_this.regions})';
}


}

/// @nodoc
abstract mixin class $MessageCopyWith<$Res>  {
  factory $MessageCopyWith(Message value, $Res Function(Message) _then) = _$MessageCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? text, List<String> lineIds, List<String> lineNames, List<String> stopIds, DateTime? validFrom, DateTime? validTo, String? source, List<String> regions
});




}
/// @nodoc
class _$MessageCopyWithImpl<$Res>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._self, this._then);

  final Message _self;
  final $Res Function(Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? text = freezed,Object? lineIds = null,Object? lineNames = null,Object? stopIds = null,Object? validFrom = freezed,Object? validTo = freezed,Object? source = freezed,Object? regions = null,}) {
  return _then(Message(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,lineIds: null == lineIds ? _self.lineIds : lineIds // ignore: cast_nullable_to_non_nullable
as List<String>,lineNames: null == lineNames ? _self.lineNames : lineNames // ignore: cast_nullable_to_non_nullable
as List<String>,stopIds: null == stopIds ? _self.stopIds : stopIds // ignore: cast_nullable_to_non_nullable
as List<String>,validFrom: freezed == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,validTo: freezed == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as DateTime?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,regions: null == regions ? _self.regions : regions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Message].
extension MessagePatterns on Message {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Message value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Message value)  $default,){
final _that = this;
switch (_that) {
case _Message():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Message value)?  $default,){
final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? text,  List<String> lineIds,  List<String> lineNames,  List<String> stopIds,  DateTime? validFrom,  DateTime? validTo,  String? source,  List<String> regions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.title,_that.text,_that.lineIds,_that.lineNames,_that.stopIds,_that.validFrom,_that.validTo,_that.source,_that.regions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? text,  List<String> lineIds,  List<String> lineNames,  List<String> stopIds,  DateTime? validFrom,  DateTime? validTo,  String? source,  List<String> regions)  $default,) {final _that = this;
switch (_that) {
case _Message():
return $default(_that.id,_that.title,_that.text,_that.lineIds,_that.lineNames,_that.stopIds,_that.validFrom,_that.validTo,_that.source,_that.regions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? text,  List<String> lineIds,  List<String> lineNames,  List<String> stopIds,  DateTime? validFrom,  DateTime? validTo,  String? source,  List<String> regions)?  $default,) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.title,_that.text,_that.lineIds,_that.lineNames,_that.stopIds,_that.validFrom,_that.validTo,_that.source,_that.regions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Message implements Message {
  const _Message({required this.id, required this.title, this.text,  List<String> lineIds = const <String>[],  List<String> lineNames = const <String>[],  List<String> stopIds = const <String>[], this.validFrom, this.validTo, this.source,  List<String> regions = const <String>[]}): _lineIds = lineIds,_lineNames = lineNames,_stopIds = stopIds,_regions = regions;
  factory _Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? text;
 final  List<String> _lineIds;
@override@JsonKey() List<String> get lineIds {
  if (_lineIds is EqualUnmodifiableListView) return _lineIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lineIds);
}

/// Liniennummern passend zu [lineIds], für die Anzeige als Plaketten.
 final  List<String> _lineNames;
/// Liniennummern passend zu [lineIds], für die Anzeige als Plaketten.
@override@JsonKey() List<String> get lineNames {
  if (_lineNames is EqualUnmodifiableListView) return _lineNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lineNames);
}

 final  List<String> _stopIds;
@override@JsonKey() List<String> get stopIds {
  if (_stopIds is EqualUnmodifiableListView) return _stopIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stopIds);
}

@override final  DateTime? validFrom;
@override final  DateTime? validTo;
/// Datenquelle, z. B. „VRR“ oder „DB“.
@override final  String? source;
/// Gebiete (Gemeindeschlüssel), unter denen die Auskunft sie führt.
 final  List<String> _regions;
/// Gebiete (Gemeindeschlüssel), unter denen die Auskunft sie führt.
@override@JsonKey() List<String> get regions {
  if (_regions is EqualUnmodifiableListView) return _regions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_regions);
}


/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageCopyWith<_Message> get copyWith => __$MessageCopyWithImpl<_Message>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Message&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.lineIds, _lineIds)&&const DeepCollectionEquality().equals(other.lineNames, _lineNames)&&const DeepCollectionEquality().equals(other.stopIds, _stopIds)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.regions, _regions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,text,const DeepCollectionEquality().hash(_lineIds),const DeepCollectionEquality().hash(_lineNames),const DeepCollectionEquality().hash(_stopIds),validFrom,validTo,source,const DeepCollectionEquality().hash(_regions));
}

@override
String toString() {
    return 'Message(id: $id, title: $title, text: $text, lineIds: $lineIds, lineNames: $lineNames, stopIds: $stopIds, validFrom: $validFrom, validTo: $validTo, source: $source, regions: $regions)';
}


}

/// @nodoc
abstract mixin class _$MessageCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$MessageCopyWith(_Message value, $Res Function(_Message) _then) = __$MessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? text, List<String> lineIds, List<String> lineNames, List<String> stopIds, DateTime? validFrom, DateTime? validTo, String? source, List<String> regions
});




}
/// @nodoc
class __$MessageCopyWithImpl<$Res>
    implements _$MessageCopyWith<$Res> {
  __$MessageCopyWithImpl(this._self, this._then);

  final _Message _self;
  final $Res Function(_Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? text = freezed,Object? lineIds = null,Object? lineNames = null,Object? stopIds = null,Object? validFrom = freezed,Object? validTo = freezed,Object? source = freezed,Object? regions = null,}) {
  return _then(_Message(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,lineIds: null == lineIds ? _self._lineIds : lineIds // ignore: cast_nullable_to_non_nullable
as List<String>,lineNames: null == lineNames ? _self._lineNames : lineNames // ignore: cast_nullable_to_non_nullable
as List<String>,stopIds: null == stopIds ? _self._stopIds : stopIds // ignore: cast_nullable_to_non_nullable
as List<String>,validFrom: freezed == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,validTo: freezed == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as DateTime?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,regions: null == regions ? _self._regions : regions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$TimeWindow {

 List<int> get weekdays; int? get fromMinute; int? get toMinute;
/// Create a copy of TimeWindow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeWindowCopyWith<TimeWindow> get copyWith => _$TimeWindowCopyWithImpl<TimeWindow>(this as TimeWindow, _$identity);

  /// Serializes this TimeWindow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TimeWindow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeWindow&&const DeepCollectionEquality().equals(other.weekdays, _this.weekdays)&&(identical(other.fromMinute, _this.fromMinute) || other.fromMinute == _this.fromMinute)&&(identical(other.toMinute, _this.toMinute) || other.toMinute == _this.toMinute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TimeWindow;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.weekdays),_this.fromMinute,_this.toMinute);
}

@override
String toString() {
  final _this = this as TimeWindow;
  return 'TimeWindow(weekdays: ${_this.weekdays}, fromMinute: ${_this.fromMinute}, toMinute: ${_this.toMinute})';
}


}

/// @nodoc
abstract mixin class $TimeWindowCopyWith<$Res>  {
  factory $TimeWindowCopyWith(TimeWindow value, $Res Function(TimeWindow) _then) = _$TimeWindowCopyWithImpl;
@useResult
$Res call({
 List<int> weekdays, int? fromMinute, int? toMinute
});




}
/// @nodoc
class _$TimeWindowCopyWithImpl<$Res>
    implements $TimeWindowCopyWith<$Res> {
  _$TimeWindowCopyWithImpl(this._self, this._then);

  final TimeWindow _self;
  final $Res Function(TimeWindow) _then;

/// Create a copy of TimeWindow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekdays = null,Object? fromMinute = freezed,Object? toMinute = freezed,}) {
  return _then(TimeWindow(
weekdays: null == weekdays ? _self.weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,fromMinute: freezed == fromMinute ? _self.fromMinute : fromMinute // ignore: cast_nullable_to_non_nullable
as int?,toMinute: freezed == toMinute ? _self.toMinute : toMinute // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TimeWindow].
extension TimeWindowPatterns on TimeWindow {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimeWindow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimeWindow() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimeWindow value)  $default,){
final _that = this;
switch (_that) {
case _TimeWindow():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimeWindow value)?  $default,){
final _that = this;
switch (_that) {
case _TimeWindow() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<int> weekdays,  int? fromMinute,  int? toMinute)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimeWindow() when $default != null:
return $default(_that.weekdays,_that.fromMinute,_that.toMinute);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<int> weekdays,  int? fromMinute,  int? toMinute)  $default,) {final _that = this;
switch (_that) {
case _TimeWindow():
return $default(_that.weekdays,_that.fromMinute,_that.toMinute);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<int> weekdays,  int? fromMinute,  int? toMinute)?  $default,) {final _that = this;
switch (_that) {
case _TimeWindow() when $default != null:
return $default(_that.weekdays,_that.fromMinute,_that.toMinute);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimeWindow implements TimeWindow {
  const _TimeWindow({ List<int> weekdays = const <int>[1, 2, 3, 4, 5, 6, 7], this.fromMinute, this.toMinute}): _weekdays = weekdays;
  factory _TimeWindow.fromJson(Map<String, dynamic> json) => _$TimeWindowFromJson(json);

 final  List<int> _weekdays;
@override@JsonKey() List<int> get weekdays {
  if (_weekdays is EqualUnmodifiableListView) return _weekdays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weekdays);
}

@override final  int? fromMinute;
@override final  int? toMinute;

/// Create a copy of TimeWindow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimeWindowCopyWith<_TimeWindow> get copyWith => __$TimeWindowCopyWithImpl<_TimeWindow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimeWindowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimeWindow&&const DeepCollectionEquality().equals(other.weekdays, _weekdays)&&(identical(other.fromMinute, fromMinute) || other.fromMinute == fromMinute)&&(identical(other.toMinute, toMinute) || other.toMinute == toMinute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_weekdays),fromMinute,toMinute);
}

@override
String toString() {
    return 'TimeWindow(weekdays: $weekdays, fromMinute: $fromMinute, toMinute: $toMinute)';
}


}

/// @nodoc
abstract mixin class _$TimeWindowCopyWith<$Res> implements $TimeWindowCopyWith<$Res> {
  factory _$TimeWindowCopyWith(_TimeWindow value, $Res Function(_TimeWindow) _then) = __$TimeWindowCopyWithImpl;
@override @useResult
$Res call({
 List<int> weekdays, int? fromMinute, int? toMinute
});




}
/// @nodoc
class __$TimeWindowCopyWithImpl<$Res>
    implements _$TimeWindowCopyWith<$Res> {
  __$TimeWindowCopyWithImpl(this._self, this._then);

  final _TimeWindow _self;
  final $Res Function(_TimeWindow) _then;

/// Create a copy of TimeWindow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekdays = null,Object? fromMinute = freezed,Object? toMinute = freezed,}) {
  return _then(_TimeWindow(
weekdays: null == weekdays ? _self._weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,fromMinute: freezed == fromMinute ? _self.fromMinute : fromMinute // ignore: cast_nullable_to_non_nullable
as int?,toMinute: freezed == toMinute ? _self.toMinute : toMinute // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$Subscription {

 String get lineId; String get providerId; String get lineName; TimeWindow? get window; String? get pushTopic;
/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionCopyWith<Subscription> get copyWith => _$SubscriptionCopyWithImpl<Subscription>(this as Subscription, _$identity);

  /// Serializes this Subscription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Subscription;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subscription&&(identical(other.lineId, _this.lineId) || other.lineId == _this.lineId)&&(identical(other.providerId, _this.providerId) || other.providerId == _this.providerId)&&(identical(other.lineName, _this.lineName) || other.lineName == _this.lineName)&&(identical(other.window, _this.window) || other.window == _this.window)&&(identical(other.pushTopic, _this.pushTopic) || other.pushTopic == _this.pushTopic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Subscription;
  return Object.hash(runtimeType,_this.lineId,_this.providerId,_this.lineName,_this.window,_this.pushTopic);
}

@override
String toString() {
  final _this = this as Subscription;
  return 'Subscription(lineId: ${_this.lineId}, providerId: ${_this.providerId}, lineName: ${_this.lineName}, window: ${_this.window}, pushTopic: ${_this.pushTopic})';
}


}

/// @nodoc
abstract mixin class $SubscriptionCopyWith<$Res>  {
  factory $SubscriptionCopyWith(Subscription value, $Res Function(Subscription) _then) = _$SubscriptionCopyWithImpl;
@useResult
$Res call({
 String lineId, String providerId, String lineName, TimeWindow? window, String? pushTopic
});


$TimeWindowCopyWith<$Res>? get window;

}
/// @nodoc
class _$SubscriptionCopyWithImpl<$Res>
    implements $SubscriptionCopyWith<$Res> {
  _$SubscriptionCopyWithImpl(this._self, this._then);

  final Subscription _self;
  final $Res Function(Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lineId = null,Object? providerId = null,Object? lineName = null,Object? window = freezed,Object? pushTopic = freezed,}) {
  return _then(Subscription(
lineId: null == lineId ? _self.lineId : lineId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,lineName: null == lineName ? _self.lineName : lineName // ignore: cast_nullable_to_non_nullable
as String,window: freezed == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as TimeWindow?,pushTopic: freezed == pushTopic ? _self.pushTopic : pushTopic // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeWindowCopyWith<$Res>? get window {
    if (_self.window == null) {
    return null;
  }

  return $TimeWindowCopyWith<$Res>(_self.window!, (value) {
    return _then(_self.copyWith(window: value));
  });
}
}


/// Adds pattern-matching-related methods to [Subscription].
extension SubscriptionPatterns on Subscription {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subscription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subscription value)  $default,){
final _that = this;
switch (_that) {
case _Subscription():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subscription value)?  $default,){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String lineId,  String providerId,  String lineName,  TimeWindow? window,  String? pushTopic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.lineId,_that.providerId,_that.lineName,_that.window,_that.pushTopic);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String lineId,  String providerId,  String lineName,  TimeWindow? window,  String? pushTopic)  $default,) {final _that = this;
switch (_that) {
case _Subscription():
return $default(_that.lineId,_that.providerId,_that.lineName,_that.window,_that.pushTopic);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String lineId,  String providerId,  String lineName,  TimeWindow? window,  String? pushTopic)?  $default,) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.lineId,_that.providerId,_that.lineName,_that.window,_that.pushTopic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Subscription implements Subscription {
  const _Subscription({required this.lineId, required this.providerId, required this.lineName, this.window, this.pushTopic});
  factory _Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);

@override final  String lineId;
@override final  String providerId;
@override final  String lineName;
@override final  TimeWindow? window;
@override final  String? pushTopic;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionCopyWith<_Subscription> get copyWith => __$SubscriptionCopyWithImpl<_Subscription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subscription&&(identical(other.lineId, lineId) || other.lineId == lineId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.lineName, lineName) || other.lineName == lineName)&&(identical(other.window, window) || other.window == window)&&(identical(other.pushTopic, pushTopic) || other.pushTopic == pushTopic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,lineId,providerId,lineName,window,pushTopic);
}

@override
String toString() {
    return 'Subscription(lineId: $lineId, providerId: $providerId, lineName: $lineName, window: $window, pushTopic: $pushTopic)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionCopyWith<$Res> implements $SubscriptionCopyWith<$Res> {
  factory _$SubscriptionCopyWith(_Subscription value, $Res Function(_Subscription) _then) = __$SubscriptionCopyWithImpl;
@override @useResult
$Res call({
 String lineId, String providerId, String lineName, TimeWindow? window, String? pushTopic
});


@override $TimeWindowCopyWith<$Res>? get window;

}
/// @nodoc
class __$SubscriptionCopyWithImpl<$Res>
    implements _$SubscriptionCopyWith<$Res> {
  __$SubscriptionCopyWithImpl(this._self, this._then);

  final _Subscription _self;
  final $Res Function(_Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lineId = null,Object? providerId = null,Object? lineName = null,Object? window = freezed,Object? pushTopic = freezed,}) {
  return _then(_Subscription(
lineId: null == lineId ? _self.lineId : lineId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,lineName: null == lineName ? _self.lineName : lineName // ignore: cast_nullable_to_non_nullable
as String,window: freezed == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as TimeWindow?,pushTopic: freezed == pushTopic ? _self.pushTopic : pushTopic // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeWindowCopyWith<$Res>? get window {
    if (_self.window == null) {
    return null;
  }

  return $TimeWindowCopyWith<$Res>(_self.window!, (value) {
    return _then(_self.copyWith(window: value));
  });
}
}


/// @nodoc
mixin _$Alarm {

 String get id; String get name; Location get from; Location get to; AlarmTimeRef get timeRef;/// Minuten nach Mitternacht.
 int get minuteOfDay; List<int> get weekdays; int get leadMinutes; bool get earlierOnDisruption; bool get startCompanion; bool get enabled;
/// Create a copy of Alarm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlarmCopyWith<Alarm> get copyWith => _$AlarmCopyWithImpl<Alarm>(this as Alarm, _$identity);

  /// Serializes this Alarm to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Alarm;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Alarm&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.to, _this.to) || other.to == _this.to)&&(identical(other.timeRef, _this.timeRef) || other.timeRef == _this.timeRef)&&(identical(other.minuteOfDay, _this.minuteOfDay) || other.minuteOfDay == _this.minuteOfDay)&&const DeepCollectionEquality().equals(other.weekdays, _this.weekdays)&&(identical(other.leadMinutes, _this.leadMinutes) || other.leadMinutes == _this.leadMinutes)&&(identical(other.earlierOnDisruption, _this.earlierOnDisruption) || other.earlierOnDisruption == _this.earlierOnDisruption)&&(identical(other.startCompanion, _this.startCompanion) || other.startCompanion == _this.startCompanion)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Alarm;
  return Object.hash(runtimeType,_this.id,_this.name,_this.from,_this.to,_this.timeRef,_this.minuteOfDay,const DeepCollectionEquality().hash(_this.weekdays),_this.leadMinutes,_this.earlierOnDisruption,_this.startCompanion,_this.enabled);
}

@override
String toString() {
  final _this = this as Alarm;
  return 'Alarm(id: ${_this.id}, name: ${_this.name}, from: ${_this.from}, to: ${_this.to}, timeRef: ${_this.timeRef}, minuteOfDay: ${_this.minuteOfDay}, weekdays: ${_this.weekdays}, leadMinutes: ${_this.leadMinutes}, earlierOnDisruption: ${_this.earlierOnDisruption}, startCompanion: ${_this.startCompanion}, enabled: ${_this.enabled})';
}


}

/// @nodoc
abstract mixin class $AlarmCopyWith<$Res>  {
  factory $AlarmCopyWith(Alarm value, $Res Function(Alarm) _then) = _$AlarmCopyWithImpl;
@useResult
$Res call({
 String id, String name, Location from, Location to, AlarmTimeRef timeRef, int minuteOfDay, List<int> weekdays, int leadMinutes, bool earlierOnDisruption, bool startCompanion, bool enabled
});


$LocationCopyWith<$Res> get from;$LocationCopyWith<$Res> get to;

}
/// @nodoc
class _$AlarmCopyWithImpl<$Res>
    implements $AlarmCopyWith<$Res> {
  _$AlarmCopyWithImpl(this._self, this._then);

  final Alarm _self;
  final $Res Function(Alarm) _then;

/// Create a copy of Alarm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? from = null,Object? to = null,Object? timeRef = null,Object? minuteOfDay = null,Object? weekdays = null,Object? leadMinutes = null,Object? earlierOnDisruption = null,Object? startCompanion = null,Object? enabled = null,}) {
  return _then(Alarm(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as Location,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as Location,timeRef: null == timeRef ? _self.timeRef : timeRef // ignore: cast_nullable_to_non_nullable
as AlarmTimeRef,minuteOfDay: null == minuteOfDay ? _self.minuteOfDay : minuteOfDay // ignore: cast_nullable_to_non_nullable
as int,weekdays: null == weekdays ? _self.weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,leadMinutes: null == leadMinutes ? _self.leadMinutes : leadMinutes // ignore: cast_nullable_to_non_nullable
as int,earlierOnDisruption: null == earlierOnDisruption ? _self.earlierOnDisruption : earlierOnDisruption // ignore: cast_nullable_to_non_nullable
as bool,startCompanion: null == startCompanion ? _self.startCompanion : startCompanion // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Alarm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res> get from {
  
  return $LocationCopyWith<$Res>(_self.from, (value) {
    return _then(_self.copyWith(from: value));
  });
}/// Create a copy of Alarm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res> get to {
  
  return $LocationCopyWith<$Res>(_self.to, (value) {
    return _then(_self.copyWith(to: value));
  });
}
}


/// Adds pattern-matching-related methods to [Alarm].
extension AlarmPatterns on Alarm {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Alarm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Alarm() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Alarm value)  $default,){
final _that = this;
switch (_that) {
case _Alarm():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Alarm value)?  $default,){
final _that = this;
switch (_that) {
case _Alarm() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Location from,  Location to,  AlarmTimeRef timeRef,  int minuteOfDay,  List<int> weekdays,  int leadMinutes,  bool earlierOnDisruption,  bool startCompanion,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Alarm() when $default != null:
return $default(_that.id,_that.name,_that.from,_that.to,_that.timeRef,_that.minuteOfDay,_that.weekdays,_that.leadMinutes,_that.earlierOnDisruption,_that.startCompanion,_that.enabled);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Location from,  Location to,  AlarmTimeRef timeRef,  int minuteOfDay,  List<int> weekdays,  int leadMinutes,  bool earlierOnDisruption,  bool startCompanion,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _Alarm():
return $default(_that.id,_that.name,_that.from,_that.to,_that.timeRef,_that.minuteOfDay,_that.weekdays,_that.leadMinutes,_that.earlierOnDisruption,_that.startCompanion,_that.enabled);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Location from,  Location to,  AlarmTimeRef timeRef,  int minuteOfDay,  List<int> weekdays,  int leadMinutes,  bool earlierOnDisruption,  bool startCompanion,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _Alarm() when $default != null:
return $default(_that.id,_that.name,_that.from,_that.to,_that.timeRef,_that.minuteOfDay,_that.weekdays,_that.leadMinutes,_that.earlierOnDisruption,_that.startCompanion,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Alarm implements Alarm {
  const _Alarm({required this.id, required this.name, required this.from, required this.to, required this.timeRef, required this.minuteOfDay,  List<int> weekdays = const <int>[1, 2, 3, 4, 5], this.leadMinutes = 5, this.earlierOnDisruption = true, this.startCompanion = false, this.enabled = true}): _weekdays = weekdays;
  factory _Alarm.fromJson(Map<String, dynamic> json) => _$AlarmFromJson(json);

@override final  String id;
@override final  String name;
@override final  Location from;
@override final  Location to;
@override final  AlarmTimeRef timeRef;
/// Minuten nach Mitternacht.
@override final  int minuteOfDay;
 final  List<int> _weekdays;
@override@JsonKey() List<int> get weekdays {
  if (_weekdays is EqualUnmodifiableListView) return _weekdays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weekdays);
}

@override@JsonKey() final  int leadMinutes;
@override@JsonKey() final  bool earlierOnDisruption;
@override@JsonKey() final  bool startCompanion;
@override@JsonKey() final  bool enabled;

/// Create a copy of Alarm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlarmCopyWith<_Alarm> get copyWith => __$AlarmCopyWithImpl<_Alarm>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlarmToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Alarm&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.timeRef, timeRef) || other.timeRef == timeRef)&&(identical(other.minuteOfDay, minuteOfDay) || other.minuteOfDay == minuteOfDay)&&const DeepCollectionEquality().equals(other.weekdays, _weekdays)&&(identical(other.leadMinutes, leadMinutes) || other.leadMinutes == leadMinutes)&&(identical(other.earlierOnDisruption, earlierOnDisruption) || other.earlierOnDisruption == earlierOnDisruption)&&(identical(other.startCompanion, startCompanion) || other.startCompanion == startCompanion)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,from,to,timeRef,minuteOfDay,const DeepCollectionEquality().hash(_weekdays),leadMinutes,earlierOnDisruption,startCompanion,enabled);
}

@override
String toString() {
    return 'Alarm(id: $id, name: $name, from: $from, to: $to, timeRef: $timeRef, minuteOfDay: $minuteOfDay, weekdays: $weekdays, leadMinutes: $leadMinutes, earlierOnDisruption: $earlierOnDisruption, startCompanion: $startCompanion, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$AlarmCopyWith<$Res> implements $AlarmCopyWith<$Res> {
  factory _$AlarmCopyWith(_Alarm value, $Res Function(_Alarm) _then) = __$AlarmCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Location from, Location to, AlarmTimeRef timeRef, int minuteOfDay, List<int> weekdays, int leadMinutes, bool earlierOnDisruption, bool startCompanion, bool enabled
});


@override $LocationCopyWith<$Res> get from;@override $LocationCopyWith<$Res> get to;

}
/// @nodoc
class __$AlarmCopyWithImpl<$Res>
    implements _$AlarmCopyWith<$Res> {
  __$AlarmCopyWithImpl(this._self, this._then);

  final _Alarm _self;
  final $Res Function(_Alarm) _then;

/// Create a copy of Alarm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? from = null,Object? to = null,Object? timeRef = null,Object? minuteOfDay = null,Object? weekdays = null,Object? leadMinutes = null,Object? earlierOnDisruption = null,Object? startCompanion = null,Object? enabled = null,}) {
  return _then(_Alarm(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as Location,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as Location,timeRef: null == timeRef ? _self.timeRef : timeRef // ignore: cast_nullable_to_non_nullable
as AlarmTimeRef,minuteOfDay: null == minuteOfDay ? _self.minuteOfDay : minuteOfDay // ignore: cast_nullable_to_non_nullable
as int,weekdays: null == weekdays ? _self._weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,leadMinutes: null == leadMinutes ? _self.leadMinutes : leadMinutes // ignore: cast_nullable_to_non_nullable
as int,earlierOnDisruption: null == earlierOnDisruption ? _self.earlierOnDisruption : earlierOnDisruption // ignore: cast_nullable_to_non_nullable
as bool,startCompanion: null == startCompanion ? _self.startCompanion : startCompanion // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Alarm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res> get from {
  
  return $LocationCopyWith<$Res>(_self.from, (value) {
    return _then(_self.copyWith(from: value));
  });
}/// Create a copy of Alarm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res> get to {
  
  return $LocationCopyWith<$Res>(_self.to, (value) {
    return _then(_self.copyWith(to: value));
  });
}
}


/// @nodoc
mixin _$SavedPlace {

 String get id; String get name; PlaceKind get kind; Location get location;
/// Create a copy of SavedPlace
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedPlaceCopyWith<SavedPlace> get copyWith => _$SavedPlaceCopyWithImpl<SavedPlace>(this as SavedPlace, _$identity);

  /// Serializes this SavedPlace to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SavedPlace;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedPlace&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.location, _this.location) || other.location == _this.location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SavedPlace;
  return Object.hash(runtimeType,_this.id,_this.name,_this.kind,_this.location);
}

@override
String toString() {
  final _this = this as SavedPlace;
  return 'SavedPlace(id: ${_this.id}, name: ${_this.name}, kind: ${_this.kind}, location: ${_this.location})';
}


}

/// @nodoc
abstract mixin class $SavedPlaceCopyWith<$Res>  {
  factory $SavedPlaceCopyWith(SavedPlace value, $Res Function(SavedPlace) _then) = _$SavedPlaceCopyWithImpl;
@useResult
$Res call({
 String id, String name, PlaceKind kind, Location location
});


$LocationCopyWith<$Res> get location;

}
/// @nodoc
class _$SavedPlaceCopyWithImpl<$Res>
    implements $SavedPlaceCopyWith<$Res> {
  _$SavedPlaceCopyWithImpl(this._self, this._then);

  final SavedPlace _self;
  final $Res Function(SavedPlace) _then;

/// Create a copy of SavedPlace
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? location = null,}) {
  return _then(SavedPlace(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PlaceKind,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Location,
  ));
}
/// Create a copy of SavedPlace
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res> get location {
  
  return $LocationCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [SavedPlace].
extension SavedPlacePatterns on SavedPlace {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedPlace value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedPlace() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedPlace value)  $default,){
final _that = this;
switch (_that) {
case _SavedPlace():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedPlace value)?  $default,){
final _that = this;
switch (_that) {
case _SavedPlace() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  PlaceKind kind,  Location location)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedPlace() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.location);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  PlaceKind kind,  Location location)  $default,) {final _that = this;
switch (_that) {
case _SavedPlace():
return $default(_that.id,_that.name,_that.kind,_that.location);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  PlaceKind kind,  Location location)?  $default,) {final _that = this;
switch (_that) {
case _SavedPlace() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.location);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedPlace implements SavedPlace {
  const _SavedPlace({required this.id, required this.name, required this.kind, required this.location});
  factory _SavedPlace.fromJson(Map<String, dynamic> json) => _$SavedPlaceFromJson(json);

@override final  String id;
@override final  String name;
@override final  PlaceKind kind;
@override final  Location location;

/// Create a copy of SavedPlace
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedPlaceCopyWith<_SavedPlace> get copyWith => __$SavedPlaceCopyWithImpl<_SavedPlace>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedPlaceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedPlace&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.location, location) || other.location == location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,kind,location);
}

@override
String toString() {
    return 'SavedPlace(id: $id, name: $name, kind: $kind, location: $location)';
}


}

/// @nodoc
abstract mixin class _$SavedPlaceCopyWith<$Res> implements $SavedPlaceCopyWith<$Res> {
  factory _$SavedPlaceCopyWith(_SavedPlace value, $Res Function(_SavedPlace) _then) = __$SavedPlaceCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, PlaceKind kind, Location location
});


@override $LocationCopyWith<$Res> get location;

}
/// @nodoc
class __$SavedPlaceCopyWithImpl<$Res>
    implements _$SavedPlaceCopyWith<$Res> {
  __$SavedPlaceCopyWithImpl(this._self, this._then);

  final _SavedPlace _self;
  final $Res Function(_SavedPlace) _then;

/// Create a copy of SavedPlace
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? location = null,}) {
  return _then(_SavedPlace(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PlaceKind,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Location,
  ));
}

/// Create a copy of SavedPlace
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res> get location {
  
  return $LocationCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}

// dart format on
