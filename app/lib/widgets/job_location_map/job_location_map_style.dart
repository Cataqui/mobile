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

  factory JobLocationMapStyle.fromColorScheme({required JobLocationMapColorScheme colorScheme}) {
    final features = <({JobLocationMapFeatureColorScheme colors, String featureType})>[
      (featureType: 'all', colors: colorScheme.all),
      (featureType: 'administrative', colors: colorScheme.administrative),
      (featureType: 'administrative.country', colors: colorScheme.administrativeCountry),
      (featureType: 'administrative.land_parcel', colors: colorScheme.administrativeLandParcel),
      (featureType: 'administrative.locality', colors: colorScheme.administrativeLocality),
      (featureType: 'administrative.neighborhood', colors: colorScheme.administrativeNeighborhood),
      (featureType: 'administrative.province', colors: colorScheme.administrativeProvince),
      (featureType: 'landscape', colors: colorScheme.landscape),
      (featureType: 'landscape.man_made', colors: colorScheme.landscapeManMade),
      (featureType: 'landscape.natural', colors: colorScheme.landscapeNatural),
      (featureType: 'landscape.natural.landcover', colors: colorScheme.landscapeNaturalLandcover),
      (featureType: 'landscape.natural.terrain', colors: colorScheme.landscapeNaturalTerrain),
      (featureType: 'poi', colors: colorScheme.pointOfInterest),
      (featureType: 'poi.attraction', colors: colorScheme.pointOfInterestAttraction),
      (featureType: 'poi.business', colors: colorScheme.pointOfInterestBusiness),
      (featureType: 'poi.government', colors: colorScheme.pointOfInterestGovernment),
      (featureType: 'poi.medical', colors: colorScheme.pointOfInterestMedical),
      (featureType: 'poi.park', colors: colorScheme.pointOfInterestPark),
      (featureType: 'poi.place_of_worship', colors: colorScheme.pointOfInterestPlaceOfWorship),
      (featureType: 'poi.school', colors: colorScheme.pointOfInterestSchool),
      (featureType: 'poi.sports_complex', colors: colorScheme.pointOfInterestSportsComplex),
      (featureType: 'road', colors: colorScheme.road),
      (featureType: 'road.arterial', colors: colorScheme.roadArterial),
      (featureType: 'road.highway', colors: colorScheme.roadHighway),
      (featureType: 'road.highway.controlled_access', colors: colorScheme.roadHighwayControlledAccess),
      (featureType: 'road.local', colors: colorScheme.roadLocal),
      (featureType: 'transit', colors: colorScheme.transit),
      (featureType: 'transit.line', colors: colorScheme.transitLine),
      (featureType: 'transit.station', colors: colorScheme.transitStation),
      (featureType: 'transit.station.airport', colors: colorScheme.transitStationAirport),
      (featureType: 'transit.station.bus', colors: colorScheme.transitStationBus),
      (featureType: 'transit.station.rail', colors: colorScheme.transitStationRail),
      (featureType: 'water', colors: colorScheme.water),
    ];

    return JobLocationMapStyle(
      rules: <JobLocationMapStyleRule>[
        for (final feature in features) ...<JobLocationMapStyleRule>[
          for (final element in <({Color? color, String elementType})>[
            (elementType: 'all', color: feature.colors.all),
            (elementType: 'geometry', color: feature.colors.geometry),
            (elementType: 'geometry.fill', color: feature.colors.geometryFill),
            (elementType: 'geometry.stroke', color: feature.colors.geometryStroke),
            (elementType: 'labels', color: feature.colors.labels),
            (elementType: 'labels.icon', color: feature.colors.labelsIcon),
            (elementType: 'labels.text', color: feature.colors.labelsText),
            (elementType: 'labels.text.fill', color: feature.colors.labelsTextFill),
            (elementType: 'labels.text.stroke', color: feature.colors.labelsTextStroke),
          ])
            if (element.color case final color?)
              _colorRule(featureType: feature.featureType, elementType: element.elementType, color: color),
          if (feature.colors.geometryWeight case final weight?)
            _weightRule(featureType: feature.featureType, weight: weight),
        ],
      ],
    );
  }

  String? get googleMapsJson {
    if (rules.isEmpty) return null;

    return jsonEncode(toJson()['rules']);
  }

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

  static JobLocationMapStyleRule _weightRule({required String featureType, required int weight}) {
    return JobLocationMapStyleRule(
      featureType: featureType,
      elementType: 'geometry',
      stylers: <JobLocationMapStyleStyler>[JobLocationMapStyleStyler(weight: weight)],
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
  const factory JobLocationMapStyleStyler({String? color, JobLocationMapVisibility? visibility, int? weight}) =
      _JobLocationMapStyleStyler;

  factory JobLocationMapStyleStyler.fromJson(Map<String, Object?> json) => _$JobLocationMapStyleStylerFromJson(json);
}
