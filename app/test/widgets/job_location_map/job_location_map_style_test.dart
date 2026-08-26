import 'dart:convert';

import 'package:cataqui_app/widgets/job_location_map/job_location_map_color_scheme.dart';
import 'package:cataqui_app/widgets/job_location_map/job_location_map_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class _JobLocationMapStyleTestHelpers {
  _JobLocationMapStyleTestHelpers._();

  static final colorScheme = JobLocationMapColorScheme.light(palette: MateoPalette());
  static final style = JobLocationMapStyle.fromColorScheme(colorScheme: colorScheme);

  static List<JobLocationMapStyleRule> get rules => style.rules;

  static Set<({String elementType, String featureType})> get selectors {
    return rules.map((rule) => (elementType: rule.elementType, featureType: rule.featureType)).toSet();
  }

  static bool get usesEmbeddedGoogleMapsSchema {
    const allowedRuleKeys = <String>{'elementType', 'featureType', 'stylers'};
    const allowedStylerKeys = <String>{'color', 'visibility'};
    final decoded = jsonDecode(style.googleMapsJson);
    if (decoded is! List<Object?>) return false;

    return decoded.every((rawRule) {
      if (rawRule is! Map<String, Object?>) return false;

      final stylers = rawRule['stylers'];
      if (stylers is! List<Object?> || stylers.length != 1) return false;

      final styler = stylers.single;
      return styler is Map<String, Object?> &&
          rawRule.keys.toSet().difference(allowedRuleKeys).isEmpty &&
          rawRule['elementType'] is String &&
          rawRule['featureType'] is String &&
          styler.length == 1 &&
          styler.keys.toSet().difference(allowedStylerKeys).isEmpty;
    });
  }

  static bool hasVisibilityRule({
    required String featureType,
    required String elementType,
    required JobLocationMapVisibility visibility,
  }) {
    return rules.any((rule) {
      if (rule.featureType != featureType || rule.elementType != elementType) return false;

      return rule.stylers.single.visibility == visibility;
    });
  }

  static String? ruleColor({required String featureType, required String elementType}) {
    for (final rule in rules.reversed) {
      if (rule.featureType != featureType || rule.elementType != elementType) continue;

      final color = rule.stylers.single.color;
      if (color != null) return color;
    }
    return null;
  }
}

void main() {
  group('JobLocationMapStyle', () {
    test('when serializing the local light style, it should produce the Google Maps root array', () {
      expect(jsonDecode(_JobLocationMapStyleTestHelpers.style.googleMapsJson), isA<List<Object?>>());
    });

    test('when encoding the local light style, it should use the generated toJson rule output', () {
      expect(
        jsonDecode(_JobLocationMapStyleTestHelpers.style.googleMapsJson),
        _JobLocationMapStyleTestHelpers.style.toJson()['rules'],
      );
    });

    test('when deserializing generated light-style JSON, it should restore the immutable style value', () {
      final style = _JobLocationMapStyleTestHelpers.style;

      expect(JobLocationMapStyle.fromJson(style.toJson()), style);
    });

    test('when validating every local style rule, it should use the embedded Google Maps schema', () {
      expect(_JobLocationMapStyleTestHelpers.usesEmbeddedGoogleMapsSchema, isTrue);
    });

    test('when reviewing the visual hierarchy, it should retain useful streets, places, and transit references', () {
      const requiredSelectors = <({String elementType, String featureType})>{
        (featureType: 'administrative.locality', elementType: 'labels.text.fill'),
        (featureType: 'administrative.neighborhood', elementType: 'labels.text.fill'),
        (featureType: 'poi.government', elementType: 'labels'),
        (featureType: 'poi.park', elementType: 'labels'),
        (featureType: 'poi.sports_complex', elementType: 'labels'),
        (featureType: 'road.arterial', elementType: 'labels.text.fill'),
        (featureType: 'road.highway', elementType: 'labels.text.fill'),
        (featureType: 'road.local', elementType: 'labels.text.fill'),
        (featureType: 'transit.line', elementType: 'all'),
        (featureType: 'transit.station', elementType: 'labels'),
        (featureType: 'transit.station.rail', elementType: 'labels'),
        (featureType: 'water', elementType: 'geometry'),
      };

      expect(_JobLocationMapStyleTestHelpers.selectors.containsAll(requiredSelectors), isTrue);
    });

    test('when resolving label visibility, it should retain the approved local map hierarchy', () {
      expect(
        (
          landscapeHidden: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
            featureType: 'landscape',
            elementType: 'labels',
            visibility: JobLocationMapVisibility.hidden,
          ),
          businessVisible: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
            featureType: 'poi.business',
            elementType: 'labels',
            visibility: JobLocationMapVisibility.visible,
          ),
          medicalHidden: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
            featureType: 'poi.medical',
            elementType: 'labels',
            visibility: JobLocationMapVisibility.hidden,
          ),
          railVisible: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
            featureType: 'transit.station.rail',
            elementType: 'labels',
            visibility: JobLocationMapVisibility.visible,
          ),
          transitLineHidden: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
            featureType: 'transit.line',
            elementType: 'all',
            visibility: JobLocationMapVisibility.hidden,
          ),
        ),
        (landscapeHidden: true, businessVisible: true, medicalHidden: true, railVisible: true, transitLineHidden: true),
      );
    });

    test('when encoding light map colors, it should preserve the Cataquí-owned palette', () {
      final colors = _JobLocationMapStyleTestHelpers.colorScheme;

      expect(
        (
          background: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'all', elementType: 'geometry'),
          natural: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'landscape.natural', elementType: 'geometry'),
          poi: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'poi', elementType: 'geometry'),
          administrative: _JobLocationMapStyleTestHelpers.ruleColor(
            featureType: 'administrative',
            elementType: 'labels.text.fill',
          ),
          businessIcon: _JobLocationMapStyleTestHelpers.ruleColor(
            featureType: 'poi.business',
            elementType: 'labels.icon',
          ),
          government: _JobLocationMapStyleTestHelpers.ruleColor(
            featureType: 'poi.government',
            elementType: 'labels.text.fill',
          ),
          park: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'poi.park', elementType: 'geometry'),
          sports: _JobLocationMapStyleTestHelpers.ruleColor(
            featureType: 'poi.sports_complex',
            elementType: 'labels.text.fill',
          ),
          road: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'road', elementType: 'geometry.fill'),
          highway: _JobLocationMapStyleTestHelpers.ruleColor(
            featureType: 'road.highway',
            elementType: 'labels.text.fill',
          ),
          transit: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'transit.station', elementType: 'geometry'),
          water: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'water', elementType: 'geometry'),
        ),
        (
          background: colors.allGeometry.toHex(),
          natural: colors.naturalGeometry.toHex(),
          poi: colors.pointOfInterestGeometry.toHex(),
          administrative: colors.administrativeLabel.toHex(),
          businessIcon: colors.businessIcon.toHex(),
          government: colors.governmentLabel.toHex(),
          park: colors.parkGeometry.toHex(),
          sports: colors.sportsComplexLabel.toHex(),
          road: colors.roadGeometryFill.toHex(),
          highway: colors.highwayLabel.toHex(),
          transit: colors.transitStationGeometry.toHex(),
          water: colors.waterGeometry.toHex(),
        ),
      );
    });
  });
}
