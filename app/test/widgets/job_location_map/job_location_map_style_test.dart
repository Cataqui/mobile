import 'dart:convert';

import 'package:cataqui_app/widgets/job_location_map/job_location_map_color_scheme.dart';
import 'package:cataqui_app/widgets/job_location_map/job_location_map_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class _JobLocationMapStyleTestHelpers {
  _JobLocationMapStyleTestHelpers._();

  static final palette = MateoPalette();

  static final defaultStyle = JobLocationMapStyle.fromColorScheme(
    colorScheme: JobLocationMapColorScheme.light(palette: palette),
  );

  static bool get usesEmbeddedGoogleMapsSchema {
    const allowedRuleKeys = <String>{'elementType', 'featureType', 'stylers'};
    const allowedStylerKeys = <String>{'color', 'visibility', 'weight'};
    final decoded = jsonDecode(defaultStyle.googleMapsJson!);
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
}

void main() {
  group('JobLocationMapStyle', () {
    test('when using the light color scheme, it should emit every internally configured selector', () {
      expect(
        _JobLocationMapStyleTestHelpers.defaultStyle.rules
            .map((rule) => (elementType: rule.elementType, featureType: rule.featureType))
            .toSet(),
        <({String elementType, String featureType})>{
          (featureType: 'landscape', elementType: 'geometry'),
          (featureType: 'landscape.man_made', elementType: 'geometry'),
          (featureType: 'landscape.natural', elementType: 'geometry'),
          (featureType: 'poi.park', elementType: 'geometry.fill'),
          (featureType: 'poi.park', elementType: 'labels.icon'),
          (featureType: 'road', elementType: 'geometry.fill'),
          (featureType: 'road.arterial', elementType: 'geometry'),
          (featureType: 'road.highway', elementType: 'geometry'),
          (featureType: 'road.local', elementType: 'geometry'),
          (featureType: 'water', elementType: 'geometry.fill'),
        },
      );
    });

    test('when serializing mapped colors, it should produce the Google Maps root array', () {
      expect(jsonDecode(_JobLocationMapStyleTestHelpers.defaultStyle.googleMapsJson!), isA<List<Object?>>());
    });

    test('when serializing a geometry weight, it should emit the embedded Google Maps weight styler', () {
      const style = JobLocationMapStyle(
        rules: <JobLocationMapStyleRule>[
          JobLocationMapStyleRule(
            featureType: 'road.highway',
            elementType: 'geometry',
            stylers: <JobLocationMapStyleStyler>[JobLocationMapStyleStyler(weight: 4)],
          ),
        ],
      );

      expect(jsonDecode(style.googleMapsJson!), <Object?>[
        <String, Object?>{
          'featureType': 'road.highway',
          'elementType': 'geometry',
          'stylers': <Object?>[
            <String, Object?>{'weight': 4},
          ],
        },
      ]);
    });

    test('when encoding mapped colors, it should use the generated toJson rule output', () {
      expect(
        jsonDecode(_JobLocationMapStyleTestHelpers.defaultStyle.googleMapsJson!),
        _JobLocationMapStyleTestHelpers.defaultStyle.toJson()['rules'],
      );
    });

    test('when deserializing generated style JSON, it should restore the immutable style value', () {
      final style = _JobLocationMapStyleTestHelpers.defaultStyle;

      expect(JobLocationMapStyle.fromJson(style.toJson()), style);
    });

    test('when validating every mapped color rule, it should use the embedded Google Maps schema', () {
      expect(_JobLocationMapStyleTestHelpers.usesEmbeddedGoogleMapsSchema, isTrue);
    });

    test('when mapping the configured roles, it should preserve deterministic feature order', () {
      final rules = _JobLocationMapStyleTestHelpers.defaultStyle.rules;

      expect(
        (
          first: (featureType: rules.first.featureType, elementType: rules.first.elementType),
          last: (featureType: rules.last.featureType, elementType: rules.last.elementType),
        ),
        (
          first: (featureType: 'landscape', elementType: 'geometry'),
          last: (featureType: 'water', elementType: 'geometry.fill'),
        ),
      );
    });
  });
}
