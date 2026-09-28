// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_location_map_style.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JobLocationMapStyle {

 List<JobLocationMapStyleRule> get rules;
/// Create a copy of JobLocationMapStyle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobLocationMapStyleCopyWith<JobLocationMapStyle> get copyWith => _$JobLocationMapStyleCopyWithImpl<JobLocationMapStyle>(this as JobLocationMapStyle, _$identity);

  /// Serializes this JobLocationMapStyle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobLocationMapStyle&&const DeepCollectionEquality().equals(other.rules, rules));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rules));

@override
String toString() {
  return 'JobLocationMapStyle(rules: $rules)';
}


}

/// @nodoc
abstract mixin class $JobLocationMapStyleCopyWith<$Res>  {
  factory $JobLocationMapStyleCopyWith(JobLocationMapStyle value, $Res Function(JobLocationMapStyle) _then) = _$JobLocationMapStyleCopyWithImpl;
@useResult
$Res call({
 List<JobLocationMapStyleRule> rules
});




}
/// @nodoc
class _$JobLocationMapStyleCopyWithImpl<$Res>
    implements $JobLocationMapStyleCopyWith<$Res> {
  _$JobLocationMapStyleCopyWithImpl(this._self, this._then);

  final JobLocationMapStyle _self;
  final $Res Function(JobLocationMapStyle) _then;

/// Create a copy of JobLocationMapStyle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rules = null,}) {
  return _then(_self.copyWith(
rules: null == rules ? _self.rules : rules // ignore: cast_nullable_to_non_nullable
as List<JobLocationMapStyleRule>,
  ));
}

}


/// Adds pattern-matching-related methods to [JobLocationMapStyle].
extension JobLocationMapStylePatterns on JobLocationMapStyle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobLocationMapStyle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobLocationMapStyle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobLocationMapStyle value)  $default,){
final _that = this;
switch (_that) {
case _JobLocationMapStyle():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobLocationMapStyle value)?  $default,){
final _that = this;
switch (_that) {
case _JobLocationMapStyle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<JobLocationMapStyleRule> rules)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobLocationMapStyle() when $default != null:
return $default(_that.rules);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<JobLocationMapStyleRule> rules)  $default,) {final _that = this;
switch (_that) {
case _JobLocationMapStyle():
return $default(_that.rules);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<JobLocationMapStyleRule> rules)?  $default,) {final _that = this;
switch (_that) {
case _JobLocationMapStyle() when $default != null:
return $default(_that.rules);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _JobLocationMapStyle extends JobLocationMapStyle {
  const _JobLocationMapStyle({required final  List<JobLocationMapStyleRule> rules}): _rules = rules,super._();
  factory _JobLocationMapStyle.fromJson(Map<String, dynamic> json) => _$JobLocationMapStyleFromJson(json);

 final  List<JobLocationMapStyleRule> _rules;
@override List<JobLocationMapStyleRule> get rules {
  if (_rules is EqualUnmodifiableListView) return _rules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rules);
}


/// Create a copy of JobLocationMapStyle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobLocationMapStyleCopyWith<_JobLocationMapStyle> get copyWith => __$JobLocationMapStyleCopyWithImpl<_JobLocationMapStyle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobLocationMapStyleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobLocationMapStyle&&const DeepCollectionEquality().equals(other._rules, _rules));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rules));

@override
String toString() {
  return 'JobLocationMapStyle(rules: $rules)';
}


}

/// @nodoc
abstract mixin class _$JobLocationMapStyleCopyWith<$Res> implements $JobLocationMapStyleCopyWith<$Res> {
  factory _$JobLocationMapStyleCopyWith(_JobLocationMapStyle value, $Res Function(_JobLocationMapStyle) _then) = __$JobLocationMapStyleCopyWithImpl;
@override @useResult
$Res call({
 List<JobLocationMapStyleRule> rules
});




}
/// @nodoc
class __$JobLocationMapStyleCopyWithImpl<$Res>
    implements _$JobLocationMapStyleCopyWith<$Res> {
  __$JobLocationMapStyleCopyWithImpl(this._self, this._then);

  final _JobLocationMapStyle _self;
  final $Res Function(_JobLocationMapStyle) _then;

/// Create a copy of JobLocationMapStyle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rules = null,}) {
  return _then(_JobLocationMapStyle(
rules: null == rules ? _self._rules : rules // ignore: cast_nullable_to_non_nullable
as List<JobLocationMapStyleRule>,
  ));
}


}


/// @nodoc
mixin _$JobLocationMapStyleRule {

 String get featureType; String get elementType; List<JobLocationMapStyleStyler> get stylers;
/// Create a copy of JobLocationMapStyleRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobLocationMapStyleRuleCopyWith<JobLocationMapStyleRule> get copyWith => _$JobLocationMapStyleRuleCopyWithImpl<JobLocationMapStyleRule>(this as JobLocationMapStyleRule, _$identity);

  /// Serializes this JobLocationMapStyleRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobLocationMapStyleRule&&(identical(other.featureType, featureType) || other.featureType == featureType)&&(identical(other.elementType, elementType) || other.elementType == elementType)&&const DeepCollectionEquality().equals(other.stylers, stylers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,featureType,elementType,const DeepCollectionEquality().hash(stylers));

@override
String toString() {
  return 'JobLocationMapStyleRule(featureType: $featureType, elementType: $elementType, stylers: $stylers)';
}


}

/// @nodoc
abstract mixin class $JobLocationMapStyleRuleCopyWith<$Res>  {
  factory $JobLocationMapStyleRuleCopyWith(JobLocationMapStyleRule value, $Res Function(JobLocationMapStyleRule) _then) = _$JobLocationMapStyleRuleCopyWithImpl;
@useResult
$Res call({
 String featureType, String elementType, List<JobLocationMapStyleStyler> stylers
});




}
/// @nodoc
class _$JobLocationMapStyleRuleCopyWithImpl<$Res>
    implements $JobLocationMapStyleRuleCopyWith<$Res> {
  _$JobLocationMapStyleRuleCopyWithImpl(this._self, this._then);

  final JobLocationMapStyleRule _self;
  final $Res Function(JobLocationMapStyleRule) _then;

/// Create a copy of JobLocationMapStyleRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? featureType = null,Object? elementType = null,Object? stylers = null,}) {
  return _then(_self.copyWith(
featureType: null == featureType ? _self.featureType : featureType // ignore: cast_nullable_to_non_nullable
as String,elementType: null == elementType ? _self.elementType : elementType // ignore: cast_nullable_to_non_nullable
as String,stylers: null == stylers ? _self.stylers : stylers // ignore: cast_nullable_to_non_nullable
as List<JobLocationMapStyleStyler>,
  ));
}

}


/// Adds pattern-matching-related methods to [JobLocationMapStyleRule].
extension JobLocationMapStyleRulePatterns on JobLocationMapStyleRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobLocationMapStyleRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobLocationMapStyleRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobLocationMapStyleRule value)  $default,){
final _that = this;
switch (_that) {
case _JobLocationMapStyleRule():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobLocationMapStyleRule value)?  $default,){
final _that = this;
switch (_that) {
case _JobLocationMapStyleRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String featureType,  String elementType,  List<JobLocationMapStyleStyler> stylers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobLocationMapStyleRule() when $default != null:
return $default(_that.featureType,_that.elementType,_that.stylers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String featureType,  String elementType,  List<JobLocationMapStyleStyler> stylers)  $default,) {final _that = this;
switch (_that) {
case _JobLocationMapStyleRule():
return $default(_that.featureType,_that.elementType,_that.stylers);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String featureType,  String elementType,  List<JobLocationMapStyleStyler> stylers)?  $default,) {final _that = this;
switch (_that) {
case _JobLocationMapStyleRule() when $default != null:
return $default(_that.featureType,_that.elementType,_that.stylers);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _JobLocationMapStyleRule implements JobLocationMapStyleRule {
  const _JobLocationMapStyleRule({required this.featureType, required this.elementType, required final  List<JobLocationMapStyleStyler> stylers}): _stylers = stylers;
  factory _JobLocationMapStyleRule.fromJson(Map<String, dynamic> json) => _$JobLocationMapStyleRuleFromJson(json);

@override final  String featureType;
@override final  String elementType;
 final  List<JobLocationMapStyleStyler> _stylers;
@override List<JobLocationMapStyleStyler> get stylers {
  if (_stylers is EqualUnmodifiableListView) return _stylers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stylers);
}


/// Create a copy of JobLocationMapStyleRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobLocationMapStyleRuleCopyWith<_JobLocationMapStyleRule> get copyWith => __$JobLocationMapStyleRuleCopyWithImpl<_JobLocationMapStyleRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobLocationMapStyleRuleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobLocationMapStyleRule&&(identical(other.featureType, featureType) || other.featureType == featureType)&&(identical(other.elementType, elementType) || other.elementType == elementType)&&const DeepCollectionEquality().equals(other._stylers, _stylers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,featureType,elementType,const DeepCollectionEquality().hash(_stylers));

@override
String toString() {
  return 'JobLocationMapStyleRule(featureType: $featureType, elementType: $elementType, stylers: $stylers)';
}


}

/// @nodoc
abstract mixin class _$JobLocationMapStyleRuleCopyWith<$Res> implements $JobLocationMapStyleRuleCopyWith<$Res> {
  factory _$JobLocationMapStyleRuleCopyWith(_JobLocationMapStyleRule value, $Res Function(_JobLocationMapStyleRule) _then) = __$JobLocationMapStyleRuleCopyWithImpl;
@override @useResult
$Res call({
 String featureType, String elementType, List<JobLocationMapStyleStyler> stylers
});




}
/// @nodoc
class __$JobLocationMapStyleRuleCopyWithImpl<$Res>
    implements _$JobLocationMapStyleRuleCopyWith<$Res> {
  __$JobLocationMapStyleRuleCopyWithImpl(this._self, this._then);

  final _JobLocationMapStyleRule _self;
  final $Res Function(_JobLocationMapStyleRule) _then;

/// Create a copy of JobLocationMapStyleRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? featureType = null,Object? elementType = null,Object? stylers = null,}) {
  return _then(_JobLocationMapStyleRule(
featureType: null == featureType ? _self.featureType : featureType // ignore: cast_nullable_to_non_nullable
as String,elementType: null == elementType ? _self.elementType : elementType // ignore: cast_nullable_to_non_nullable
as String,stylers: null == stylers ? _self._stylers : stylers // ignore: cast_nullable_to_non_nullable
as List<JobLocationMapStyleStyler>,
  ));
}


}


/// @nodoc
mixin _$JobLocationMapStyleStyler {

 String? get color; int? get lightness; JobLocationMapVisibility? get visibility; int? get weight;
/// Create a copy of JobLocationMapStyleStyler
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobLocationMapStyleStylerCopyWith<JobLocationMapStyleStyler> get copyWith => _$JobLocationMapStyleStylerCopyWithImpl<JobLocationMapStyleStyler>(this as JobLocationMapStyleStyler, _$identity);

  /// Serializes this JobLocationMapStyleStyler to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobLocationMapStyleStyler&&(identical(other.color, color) || other.color == color)&&(identical(other.lightness, lightness) || other.lightness == lightness)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.weight, weight) || other.weight == weight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,color,lightness,visibility,weight);

@override
String toString() {
  return 'JobLocationMapStyleStyler(color: $color, lightness: $lightness, visibility: $visibility, weight: $weight)';
}


}

/// @nodoc
abstract mixin class $JobLocationMapStyleStylerCopyWith<$Res>  {
  factory $JobLocationMapStyleStylerCopyWith(JobLocationMapStyleStyler value, $Res Function(JobLocationMapStyleStyler) _then) = _$JobLocationMapStyleStylerCopyWithImpl;
@useResult
$Res call({
 String? color, int? lightness, JobLocationMapVisibility? visibility, int? weight
});




}
/// @nodoc
class _$JobLocationMapStyleStylerCopyWithImpl<$Res>
    implements $JobLocationMapStyleStylerCopyWith<$Res> {
  _$JobLocationMapStyleStylerCopyWithImpl(this._self, this._then);

  final JobLocationMapStyleStyler _self;
  final $Res Function(JobLocationMapStyleStyler) _then;

/// Create a copy of JobLocationMapStyleStyler
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? color = freezed,Object? lightness = freezed,Object? visibility = freezed,Object? weight = freezed,}) {
  return _then(_self.copyWith(
color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,lightness: freezed == lightness ? _self.lightness : lightness // ignore: cast_nullable_to_non_nullable
as int?,visibility: freezed == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as JobLocationMapVisibility?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [JobLocationMapStyleStyler].
extension JobLocationMapStyleStylerPatterns on JobLocationMapStyleStyler {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobLocationMapStyleStyler value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobLocationMapStyleStyler() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobLocationMapStyleStyler value)  $default,){
final _that = this;
switch (_that) {
case _JobLocationMapStyleStyler():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobLocationMapStyleStyler value)?  $default,){
final _that = this;
switch (_that) {
case _JobLocationMapStyleStyler() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? color,  int? lightness,  JobLocationMapVisibility? visibility,  int? weight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobLocationMapStyleStyler() when $default != null:
return $default(_that.color,_that.lightness,_that.visibility,_that.weight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? color,  int? lightness,  JobLocationMapVisibility? visibility,  int? weight)  $default,) {final _that = this;
switch (_that) {
case _JobLocationMapStyleStyler():
return $default(_that.color,_that.lightness,_that.visibility,_that.weight);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? color,  int? lightness,  JobLocationMapVisibility? visibility,  int? weight)?  $default,) {final _that = this;
switch (_that) {
case _JobLocationMapStyleStyler() when $default != null:
return $default(_that.color,_that.lightness,_that.visibility,_that.weight);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _JobLocationMapStyleStyler implements JobLocationMapStyleStyler {
  const _JobLocationMapStyleStyler({this.color, this.lightness, this.visibility, this.weight});
  factory _JobLocationMapStyleStyler.fromJson(Map<String, dynamic> json) => _$JobLocationMapStyleStylerFromJson(json);

@override final  String? color;
@override final  int? lightness;
@override final  JobLocationMapVisibility? visibility;
@override final  int? weight;

/// Create a copy of JobLocationMapStyleStyler
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobLocationMapStyleStylerCopyWith<_JobLocationMapStyleStyler> get copyWith => __$JobLocationMapStyleStylerCopyWithImpl<_JobLocationMapStyleStyler>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobLocationMapStyleStylerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobLocationMapStyleStyler&&(identical(other.color, color) || other.color == color)&&(identical(other.lightness, lightness) || other.lightness == lightness)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.weight, weight) || other.weight == weight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,color,lightness,visibility,weight);

@override
String toString() {
  return 'JobLocationMapStyleStyler(color: $color, lightness: $lightness, visibility: $visibility, weight: $weight)';
}


}

/// @nodoc
abstract mixin class _$JobLocationMapStyleStylerCopyWith<$Res> implements $JobLocationMapStyleStylerCopyWith<$Res> {
  factory _$JobLocationMapStyleStylerCopyWith(_JobLocationMapStyleStyler value, $Res Function(_JobLocationMapStyleStyler) _then) = __$JobLocationMapStyleStylerCopyWithImpl;
@override @useResult
$Res call({
 String? color, int? lightness, JobLocationMapVisibility? visibility, int? weight
});




}
/// @nodoc
class __$JobLocationMapStyleStylerCopyWithImpl<$Res>
    implements _$JobLocationMapStyleStylerCopyWith<$Res> {
  __$JobLocationMapStyleStylerCopyWithImpl(this._self, this._then);

  final _JobLocationMapStyleStyler _self;
  final $Res Function(_JobLocationMapStyleStyler) _then;

/// Create a copy of JobLocationMapStyleStyler
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? color = freezed,Object? lightness = freezed,Object? visibility = freezed,Object? weight = freezed,}) {
  return _then(_JobLocationMapStyleStyler(
color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,lightness: freezed == lightness ? _self.lightness : lightness // ignore: cast_nullable_to_non_nullable
as int?,visibility: freezed == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as JobLocationMapVisibility?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
