import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_location_map_style.freezed.dart';
part 'job_location_map_style.g.dart';
part 'job_location_map_style_enums.dart';

@freezed
sealed class JobLocationMapStyle with _$JobLocationMapStyle {
  const factory JobLocationMapStyle({required List<JobLocationMapStyleRule> rules}) = _JobLocationMapStyle;

  const JobLocationMapStyle._();

  factory JobLocationMapStyle.fromJson(Map<String, Object?> json) => _$JobLocationMapStyleFromJson(json);

  static final JobLocationMapStyle lightMode = JobLocationMapStyle(
    rules: <JobLocationMapStyleRule>[
      _colorRule(featureType: 'all', elementType: 'geometry', color: '#F7F4F4'),
      _colorRule(featureType: 'all', elementType: 'labels.text.fill', color: '#969190'),
      _colorRule(featureType: 'all', elementType: 'labels.text.stroke', color: '#FFFFFF'),
      _visibilityRule(featureType: 'all', elementType: 'labels.icon', visibility: JobLocationMapVisibility.hidden),
      _colorRule(featureType: 'landscape', elementType: 'geometry', color: '#F7F4F4'),
      _visibilityRule(featureType: 'landscape', elementType: 'labels', visibility: JobLocationMapVisibility.hidden),
      _colorRule(featureType: 'landscape.man_made', elementType: 'geometry.fill', color: '#F7F4F4'),
      _colorRule(featureType: 'landscape.man_made', elementType: 'geometry.stroke', color: '#D3CCCB'),
      _colorRule(featureType: 'landscape.natural', elementType: 'geometry', color: '#D5F4D8'),
      _colorRule(featureType: 'administrative', elementType: 'labels.text.fill', color: '#C6BFBE'),
      _colorRule(featureType: 'administrative.country', elementType: 'labels.text.fill', color: '#969190'),
      _visibilityRule(
        featureType: 'administrative.land_parcel',
        elementType: 'labels',
        visibility: JobLocationMapVisibility.hidden,
      ),
      _colorRule(featureType: 'administrative.locality', elementType: 'labels.text.fill', color: '#969190'),
      _colorRule(featureType: 'administrative.neighborhood', elementType: 'labels.text.fill', color: '#C6BFBE'),
      _colorRule(featureType: 'administrative.province', elementType: 'labels.text.fill', color: '#C6BFBE'),
      _colorRule(featureType: 'poi', elementType: 'geometry', color: '#FDFBFB'),
      _visibilityRule(featureType: 'poi', elementType: 'labels', visibility: JobLocationMapVisibility.hidden),
      _colorRule(featureType: 'poi.attraction', elementType: 'geometry', color: '#FDFBFB'),
      _visibilityRule(
        featureType: 'poi.attraction',
        elementType: 'labels',
        visibility: JobLocationMapVisibility.visible,
      ),
      _colorRule(featureType: 'poi.attraction', elementType: 'labels.text.fill', color: '#969190'),
      _colorRule(featureType: 'poi.attraction', elementType: 'labels.icon', color: '#CABCFF'),
      _colorRule(featureType: 'poi.business', elementType: 'geometry', color: '#FDFBFB'),
      _colorRule(featureType: 'poi.business', elementType: 'labels.icon', color: '#C6BFBE'),
      _visibilityRule(featureType: 'poi.business', elementType: 'labels', visibility: JobLocationMapVisibility.visible),
      _colorRule(featureType: 'poi.government', elementType: 'geometry', color: '#FDFBFB'),
      _visibilityRule(
        featureType: 'poi.government',
        elementType: 'labels',
        visibility: JobLocationMapVisibility.visible,
      ),
      _colorRule(featureType: 'poi.government', elementType: 'labels.text.fill', color: '#FDC171'),
      _colorRule(featureType: 'poi.government', elementType: 'labels.text.stroke', color: '#FFFFFF'),
      _colorRule(featureType: 'poi.government', elementType: 'labels.icon', color: '#FFDDB2'),
      _colorRule(featureType: 'poi.medical', elementType: 'geometry', color: '#FDFBFB'),
      _visibilityRule(featureType: 'poi.medical', elementType: 'labels', visibility: JobLocationMapVisibility.hidden),
      _colorRule(featureType: 'poi.park', elementType: 'geometry', color: '#E3F5E5'),
      _visibilityRule(featureType: 'poi.park', elementType: 'labels', visibility: JobLocationMapVisibility.visible),
      _colorRule(featureType: 'poi.park', elementType: 'labels.text.fill', color: '#78E18A'),
      _colorRule(featureType: 'poi.park', elementType: 'labels.text.stroke', color: '#FFFFFF'),
      _colorRule(featureType: 'poi.park', elementType: 'labels.icon', color: '#B2F1BA'),
      _visibilityRule(
        featureType: 'poi.place_of_worship',
        elementType: 'labels',
        visibility: JobLocationMapVisibility.hidden,
      ),
      _colorRule(featureType: 'poi.school', elementType: 'geometry', color: '#FDFBFB'),
      _visibilityRule(featureType: 'poi.school', elementType: 'labels', visibility: JobLocationMapVisibility.hidden),
      _colorRule(featureType: 'poi.sports_complex', elementType: 'geometry', color: '#FDFBFB'),
      _visibilityRule(
        featureType: 'poi.sports_complex',
        elementType: 'labels',
        visibility: JobLocationMapVisibility.visible,
      ),
      _colorRule(featureType: 'poi.sports_complex', elementType: 'labels.text.fill', color: '#A585FC'),
      _colorRule(featureType: 'poi.sports_complex', elementType: 'labels.text.stroke', color: '#FFFFFF'),
      _colorRule(featureType: 'poi.sports_complex', elementType: 'labels.icon', color: '#CABCFF'),
      _colorRule(featureType: 'road', elementType: 'geometry.fill', color: '#FFFFFF'),
      _colorRule(featureType: 'road', elementType: 'geometry.stroke', color: '#FFFFFF'),
      _colorRule(featureType: 'road', elementType: 'labels.text.fill', color: '#676261'),
      _colorRule(featureType: 'road', elementType: 'labels.text.stroke', color: '#FFFFFF'),
      _colorRule(featureType: 'road.arterial', elementType: 'geometry.fill', color: '#FFFFFF'),
      _colorRule(featureType: 'road.arterial', elementType: 'geometry.stroke', color: '#FFFFFF'),
      _colorRule(featureType: 'road.arterial', elementType: 'labels.text.fill', color: '#676261'),
      _colorRule(featureType: 'road.highway', elementType: 'geometry.fill', color: '#FFFFFF'),
      // _colorRule(featureType: 'road.highway', elementType: 'geometry.stroke', color: '#FFD7D2'),
      _colorRule(featureType: 'road.highway', elementType: 'labels.text.fill', color: '#8C2223'),
      _colorRule(featureType: 'road.local', elementType: 'geometry.fill', color: '#FFFFFF'),
      // _colorRule(featureType: 'road.local', elementType: 'geometry.stroke', color: '#DCD6D5'),
      _colorRule(featureType: 'road.local', elementType: 'labels.text.fill', color: '#676261'),
      _visibilityRule(featureType: 'transit.line', elementType: 'all', visibility: JobLocationMapVisibility.hidden),
      _colorRule(featureType: 'transit.station', elementType: 'geometry', color: '#FAFBFE'),
      _visibilityRule(
        featureType: 'transit.station',
        elementType: 'labels',
        visibility: JobLocationMapVisibility.visible,
      ),
      _colorRule(featureType: 'transit.station', elementType: 'labels.text.fill', color: '#69A2FB'),
      _colorRule(featureType: 'transit.station', elementType: 'labels.text.stroke', color: '#FFFFFF'),
      _colorRule(featureType: 'transit.station', elementType: 'labels.icon', color: '#69A2FB'),
      _visibilityRule(
        featureType: 'transit.station.rail',
        elementType: 'labels',
        visibility: JobLocationMapVisibility.visible,
      ),
      _visibilityRule(
        featureType: 'transit.station.rail',
        elementType: 'labels.text',
        visibility: JobLocationMapVisibility.visible,
      ),
      _colorRule(featureType: 'transit.station.rail', elementType: 'labels.text.fill', color: '#69A2FB'),
      _colorRule(featureType: 'transit.station.rail', elementType: 'labels.text.stroke', color: '#FFFFFF'),
      _colorRule(featureType: 'transit.station.rail', elementType: 'labels.icon', color: '#BDD7FF'),
      _visibilityRule(
        featureType: 'poi.government',
        elementType: 'labels.icon',
        visibility: JobLocationMapVisibility.visible,
      ),
      _visibilityRule(
        featureType: 'poi.park',
        elementType: 'labels.icon',
        visibility: JobLocationMapVisibility.visible,
      ),
      _visibilityRule(
        featureType: 'poi.sports_complex',
        elementType: 'labels.icon',
        visibility: JobLocationMapVisibility.visible,
      ),
      _visibilityRule(
        featureType: 'transit.station',
        elementType: 'labels.icon',
        visibility: JobLocationMapVisibility.visible,
      ),
      _visibilityRule(
        featureType: 'transit.station.rail',
        elementType: 'labels.icon',
        visibility: JobLocationMapVisibility.visible,
      ),
      _colorRule(featureType: 'water', elementType: 'geometry', color: '#F5FAFB'),
      _colorRule(featureType: 'water', elementType: 'labels.text.fill', color: '#75D1EA'),
      _colorRule(featureType: 'water', elementType: 'labels.text.stroke', color: '#FFFFFF'),
    ],
  );

  static final String googleMapsJson = jsonEncode(lightMode.toJson()['rules']);

  static JobLocationMapStyleRule _colorRule({
    required String featureType,
    required String elementType,
    required String color,
  }) {
    return JobLocationMapStyleRule(
      featureType: featureType,
      elementType: elementType,
      stylers: <JobLocationMapStyleStyler>[JobLocationMapStyleStyler(color: color)],
    );
  }

  static JobLocationMapStyleRule _visibilityRule({
    required String featureType,
    required String elementType,
    required JobLocationMapVisibility visibility,
  }) {
    return JobLocationMapStyleRule(
      featureType: featureType,
      elementType: elementType,
      stylers: <JobLocationMapStyleStyler>[JobLocationMapStyleStyler(visibility: visibility)],
    );
  }
}

@freezed
sealed class JobLocationMapStyleRule with _$JobLocationMapStyleRule {
  const factory JobLocationMapStyleRule({
    required String featureType,
    required String elementType,
    required List<JobLocationMapStyleStyler> stylers,
  }) = _JobLocationMapStyleRule;

  factory JobLocationMapStyleRule.fromJson(Map<String, Object?> json) => _$JobLocationMapStyleRuleFromJson(json);
}

@freezed
sealed class JobLocationMapStyleStyler with _$JobLocationMapStyleStyler {
  @JsonSerializable(includeIfNull: false)
  const factory JobLocationMapStyleStyler({String? color, JobLocationMapVisibility? visibility}) =
      _JobLocationMapStyleStyler;

  factory JobLocationMapStyleStyler.fromJson(Map<String, Object?> json) => _$JobLocationMapStyleStylerFromJson(json);
}
