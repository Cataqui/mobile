import 'dart:convert';

import 'package:cataqui_app/widgets/job_location_map/job_location_map_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'job_location_map_style.freezed.dart';
part 'job_location_map_style.g.dart';
part 'job_location_map_style_enums.dart';

@freezed
sealed class JobLocationMapStyle with _$JobLocationMapStyle {
  const factory JobLocationMapStyle({required List<JobLocationMapStyleRule> rules}) = _JobLocationMapStyle;

  const JobLocationMapStyle._();

  factory JobLocationMapStyle.fromJson(Map<String, Object?> json) => _$JobLocationMapStyleFromJson(json);

  factory JobLocationMapStyle.fromColorScheme({required JobLocationMapColorScheme colorScheme}) => JobLocationMapStyle(
    rules: <JobLocationMapStyleRule>[
      _colorRule(featureType: 'all', elementType: 'geometry', color: colorScheme.allGeometry),
      _colorRule(featureType: 'all', elementType: 'labels.text.fill', color: colorScheme.allLabel),
      _colorRule(featureType: 'all', elementType: 'labels.text.stroke', color: colorScheme.allLabelHalo),
      _visibilityRule(featureType: 'all', elementType: 'labels.icon', visibility: JobLocationMapVisibility.hidden),
      _colorRule(featureType: 'landscape', elementType: 'geometry', color: colorScheme.landscapeGeometry),
      _visibilityRule(featureType: 'landscape', elementType: 'labels', visibility: JobLocationMapVisibility.hidden),
      _colorRule(featureType: 'landscape.man_made', elementType: 'geometry.fill', color: colorScheme.manMadeFill),
      _colorRule(featureType: 'landscape.man_made', elementType: 'geometry.stroke', color: colorScheme.manMadeStroke),
      _colorRule(featureType: 'landscape.natural', elementType: 'geometry', color: colorScheme.naturalGeometry),
      _colorRule(
        featureType: 'administrative',
        elementType: 'labels.text.fill',
        color: colorScheme.administrativeLabel,
      ),
      _colorRule(
        featureType: 'administrative.country',
        elementType: 'labels.text.fill',
        color: colorScheme.administrativeCountryLabel,
      ),
      _visibilityRule(
        featureType: 'administrative.land_parcel',
        elementType: 'labels',
        visibility: JobLocationMapVisibility.hidden,
      ),
      _colorRule(
        featureType: 'administrative.locality',
        elementType: 'labels.text.fill',
        color: colorScheme.administrativeLocalityLabel,
      ),
      _colorRule(
        featureType: 'administrative.neighborhood',
        elementType: 'labels.text.fill',
        color: colorScheme.administrativeNeighborhoodLabel,
      ),
      _colorRule(
        featureType: 'administrative.province',
        elementType: 'labels.text.fill',
        color: colorScheme.administrativeProvinceLabel,
      ),
      _colorRule(featureType: 'poi', elementType: 'geometry', color: colorScheme.pointOfInterestGeometry),
      _visibilityRule(featureType: 'poi', elementType: 'labels', visibility: JobLocationMapVisibility.hidden),
      _colorRule(featureType: 'poi.attraction', elementType: 'geometry', color: colorScheme.attractionGeometry),
      _visibilityRule(
        featureType: 'poi.attraction',
        elementType: 'labels',
        visibility: JobLocationMapVisibility.visible,
      ),
      _colorRule(featureType: 'poi.attraction', elementType: 'labels.text.fill', color: colorScheme.attractionLabel),
      _colorRule(featureType: 'poi.attraction', elementType: 'labels.icon', color: colorScheme.attractionIcon),
      _colorRule(featureType: 'poi.business', elementType: 'geometry', color: colorScheme.businessGeometry),
      _colorRule(featureType: 'poi.business', elementType: 'labels.icon', color: colorScheme.businessIcon),
      _visibilityRule(featureType: 'poi.business', elementType: 'labels', visibility: JobLocationMapVisibility.visible),
      _colorRule(featureType: 'poi.government', elementType: 'geometry', color: colorScheme.governmentGeometry),
      _visibilityRule(
        featureType: 'poi.government',
        elementType: 'labels',
        visibility: JobLocationMapVisibility.visible,
      ),
      _colorRule(featureType: 'poi.government', elementType: 'labels.text.fill', color: colorScheme.governmentLabel),
      _colorRule(
        featureType: 'poi.government',
        elementType: 'labels.text.stroke',
        color: colorScheme.governmentLabelHalo,
      ),
      _colorRule(featureType: 'poi.government', elementType: 'labels.icon', color: colorScheme.governmentIcon),
      _colorRule(featureType: 'poi.medical', elementType: 'geometry', color: colorScheme.medicalGeometry),
      _visibilityRule(featureType: 'poi.medical', elementType: 'labels', visibility: JobLocationMapVisibility.hidden),
      _colorRule(featureType: 'poi.park', elementType: 'geometry', color: colorScheme.parkGeometry),
      _visibilityRule(featureType: 'poi.park', elementType: 'labels', visibility: JobLocationMapVisibility.visible),
      _colorRule(featureType: 'poi.park', elementType: 'labels.text.fill', color: colorScheme.parkLabel),
      _colorRule(featureType: 'poi.park', elementType: 'labels.text.stroke', color: colorScheme.parkLabelHalo),
      _colorRule(featureType: 'poi.park', elementType: 'labels.icon', color: colorScheme.parkIcon),
      _visibilityRule(
        featureType: 'poi.place_of_worship',
        elementType: 'labels',
        visibility: JobLocationMapVisibility.hidden,
      ),
      _colorRule(featureType: 'poi.school', elementType: 'geometry', color: colorScheme.schoolGeometry),
      _visibilityRule(featureType: 'poi.school', elementType: 'labels', visibility: JobLocationMapVisibility.hidden),
      _colorRule(featureType: 'poi.sports_complex', elementType: 'geometry', color: colorScheme.sportsComplexGeometry),
      _visibilityRule(
        featureType: 'poi.sports_complex',
        elementType: 'labels',
        visibility: JobLocationMapVisibility.visible,
      ),
      _colorRule(
        featureType: 'poi.sports_complex',
        elementType: 'labels.text.fill',
        color: colorScheme.sportsComplexLabel,
      ),
      _colorRule(
        featureType: 'poi.sports_complex',
        elementType: 'labels.text.stroke',
        color: colorScheme.sportsComplexLabelHalo,
      ),
      _colorRule(featureType: 'poi.sports_complex', elementType: 'labels.icon', color: colorScheme.sportsComplexIcon),
      _colorRule(featureType: 'road', elementType: 'geometry.fill', color: colorScheme.roadGeometryFill),
      _colorRule(featureType: 'road', elementType: 'geometry.stroke', color: colorScheme.roadGeometryStroke),
      _colorRule(featureType: 'road', elementType: 'labels.text.fill', color: colorScheme.roadLabel),
      _colorRule(featureType: 'road', elementType: 'labels.text.stroke', color: colorScheme.roadLabelHalo),
      _colorRule(
        featureType: 'road.arterial',
        elementType: 'geometry.fill',
        color: colorScheme.arterialRoadGeometryFill,
      ),
      _colorRule(
        featureType: 'road.arterial',
        elementType: 'geometry.stroke',
        color: colorScheme.arterialRoadGeometryStroke,
      ),
      _colorRule(featureType: 'road.arterial', elementType: 'labels.text.fill', color: colorScheme.arterialRoadLabel),
      _colorRule(featureType: 'road.highway', elementType: 'geometry.fill', color: colorScheme.highwayGeometryFill),
      _colorRule(featureType: 'road.highway', elementType: 'labels.text.fill', color: colorScheme.highwayLabel),
      _colorRule(featureType: 'road.local', elementType: 'geometry.fill', color: colorScheme.localRoadGeometryFill),
      _colorRule(featureType: 'road.local', elementType: 'labels.text.fill', color: colorScheme.localRoadLabel),
      _visibilityRule(featureType: 'transit.line', elementType: 'all', visibility: JobLocationMapVisibility.hidden),
      _colorRule(featureType: 'transit.station', elementType: 'geometry', color: colorScheme.transitStationGeometry),
      _visibilityRule(
        featureType: 'transit.station',
        elementType: 'labels',
        visibility: JobLocationMapVisibility.visible,
      ),
      _colorRule(
        featureType: 'transit.station',
        elementType: 'labels.text.fill',
        color: colorScheme.transitStationLabel,
      ),
      _colorRule(
        featureType: 'transit.station',
        elementType: 'labels.text.stroke',
        color: colorScheme.transitStationLabelHalo,
      ),
      _colorRule(featureType: 'transit.station', elementType: 'labels.icon', color: colorScheme.transitStationIcon),
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
      _colorRule(
        featureType: 'transit.station.rail',
        elementType: 'labels.text.fill',
        color: colorScheme.railStationLabel,
      ),
      _colorRule(
        featureType: 'transit.station.rail',
        elementType: 'labels.text.stroke',
        color: colorScheme.railStationLabelHalo,
      ),
      _colorRule(featureType: 'transit.station.rail', elementType: 'labels.icon', color: colorScheme.railStationIcon),
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
      _colorRule(featureType: 'water', elementType: 'geometry', color: colorScheme.waterGeometry),
      _colorRule(featureType: 'water', elementType: 'labels.text.fill', color: colorScheme.waterLabel),
      _colorRule(featureType: 'water', elementType: 'labels.text.stroke', color: colorScheme.waterLabelHalo),
    ],
  );

  String get googleMapsJson => jsonEncode(toJson()['rules']);

  static JobLocationMapStyleRule _colorRule({
    required String featureType,
    required String elementType,
    required Color color,
  }) {
    return JobLocationMapStyleRule(
      featureType: featureType,
      elementType: elementType,
      stylers: <JobLocationMapStyleStyler>[JobLocationMapStyleStyler(color: color.toHex())],
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
