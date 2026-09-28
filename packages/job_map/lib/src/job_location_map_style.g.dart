// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_location_map_style.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JobLocationMapStyle _$JobLocationMapStyleFromJson(Map<String, dynamic> json) =>
    _JobLocationMapStyle(
      rules: (json['rules'] as List<dynamic>)
          .map(
            (e) => JobLocationMapStyleRule.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$JobLocationMapStyleToJson(
  _JobLocationMapStyle instance,
) => <String, dynamic>{'rules': instance.rules.map((e) => e.toJson()).toList()};

_JobLocationMapStyleRule _$JobLocationMapStyleRuleFromJson(
  Map<String, dynamic> json,
) => _JobLocationMapStyleRule(
  featureType: json['featureType'] as String,
  elementType: json['elementType'] as String,
  stylers: (json['stylers'] as List<dynamic>)
      .map((e) => JobLocationMapStyleStyler.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$JobLocationMapStyleRuleToJson(
  _JobLocationMapStyleRule instance,
) => <String, dynamic>{
  'featureType': instance.featureType,
  'elementType': instance.elementType,
  'stylers': instance.stylers.map((e) => e.toJson()).toList(),
};

_JobLocationMapStyleStyler _$JobLocationMapStyleStylerFromJson(
  Map<String, dynamic> json,
) => _JobLocationMapStyleStyler(
  color: json['color'] as String?,
  lightness: (json['lightness'] as num?)?.toInt(),
  visibility: $enumDecodeNullable(
    _$JobLocationMapVisibilityEnumMap,
    json['visibility'],
  ),
  weight: (json['weight'] as num?)?.toInt(),
);

Map<String, dynamic> _$JobLocationMapStyleStylerToJson(
  _JobLocationMapStyleStyler instance,
) => <String, dynamic>{
  'color': ?instance.color,
  'lightness': ?instance.lightness,
  'visibility': ?_$JobLocationMapVisibilityEnumMap[instance.visibility],
  'weight': ?instance.weight,
};

const _$JobLocationMapVisibilityEnumMap = {
  JobLocationMapVisibility.hidden: 'off',
  JobLocationMapVisibility.visible: 'on',
  JobLocationMapVisibility.simplified: 'simplified',
};
