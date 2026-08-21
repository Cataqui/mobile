import 'dart:convert';

import 'package:cataqui_app/widgets/job_location_map/job_location_map_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../utils/test_app.dart';

class _JobLocationMapStyleTestHelpers {
  _JobLocationMapStyleTestHelpers._();

  static List<JobLocationMapStyleRule> get rules => JobLocationMapStyle.lightMode.rules;

  static Set<({String elementType, String featureType})> get selectors {
    return rules.map((rule) => (elementType: rule.elementType, featureType: rule.featureType)).toSet();
  }

  static Set<String> get styleColors {
    return {
      for (final rule in rules)
        for (final styler in rule.stylers)
          if (styler.color case final String color) color,
    };
  }

  static bool get usesEmbeddedGoogleMapsSchema {
    const allowedRuleKeys = <String>{'elementType', 'featureType', 'stylers'};
    const allowedStylerKeys = <String>{'color', 'visibility'};
    final decoded = jsonDecode(JobLocationMapStyle.googleMapsJson);
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

  static String colorHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static Set<Color> paletteColors(BuildContext context) {
    final palette = context.mateo.palette;
    final colors = <Color>{context.mateo.colorScheme.map.labelHalo};

    for (var step = 1; step <= 12; step++) {
      colors.addAll([
        palette.accent[step],
        palette.neutral[step],
        palette.green[step],
        palette.amber[step],
        palette.red[step],
        palette.blue[step],
        palette.whatsapp[step],
        palette.cyan[step],
        palette.violet[step],
        palette.teal[step],
        palette.orange[step],
        palette.pink[step],
        palette.yellow[step],
      ]);
    }

    return colors;
  }

  static bool styleColorsBelongToPalette(BuildContext context) {
    final colors = paletteColors(context);
    return styleColors.every((styleHex) {
      final styleColor = Color(int.parse('FF${styleHex.substring(1)}', radix: 16));
      return colors.any((paletteColor) => _colorsMatchWithinGamutRounding(styleColor, paletteColor));
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

  static bool _colorsMatchWithinGamutRounding(Color first, Color second) {
    final firstArgb = first.toARGB32();
    final secondArgb = second.toARGB32();

    return <int>[16, 8, 0].every((shift) {
      final firstChannel = (firstArgb >> shift) & 0xFF;
      final secondChannel = (secondArgb >> shift) & 0xFF;
      return (firstChannel - secondChannel).abs() <= 1;
    });
  }
}

void main() {
  group('JobLocationMapStyle', () {
    test('when serializing the local light style, it should produce the Google Maps root array', () {
      expect(jsonDecode(JobLocationMapStyle.googleMapsJson), isA<List<Object?>>());
    });

    test('when encoding the local light style, it should use the generated toJson rule output', () {
      expect(jsonDecode(JobLocationMapStyle.googleMapsJson), JobLocationMapStyle.lightMode.toJson()['rules']);
    });

    test('when deserializing generated light-style JSON, it should restore the immutable style value', () {
      expect(JobLocationMapStyle.fromJson(JobLocationMapStyle.lightMode.toJson()), JobLocationMapStyle.lightMode);
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

    test('when reducing map noise, it should hide landscape, land-parcel, and worship labels', () {
      expect(
        (
          landscape: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
            featureType: 'landscape',
            elementType: 'labels',
            visibility: JobLocationMapVisibility.hidden,
          ),
          landParcel: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
            featureType: 'administrative.land_parcel',
            elementType: 'labels',
            visibility: JobLocationMapVisibility.hidden,
          ),
          worship: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
            featureType: 'poi.place_of_worship',
            elementType: 'labels',
            visibility: JobLocationMapVisibility.hidden,
          ),
        ),
        (landscape: true, landParcel: true, worship: true),
      );
    });

    test('when emphasizing useful reference points, it should retain their map pins', () {
      const visiblePinFeatures = <String>{
        'poi.government',
        'poi.park',
        'poi.sports_complex',
        'transit.station',
        'transit.station.rail',
      };

      expect(
        visiblePinFeatures.every(
          (featureType) => _JobLocationMapStyleTestHelpers.hasVisibilityRule(
            featureType: featureType,
            elementType: 'labels.icon',
            visibility: JobLocationMapVisibility.visible,
          ),
        ),
        isTrue,
      );
    });

    test('when locating train access, it should show rail stations without transit paths', () {
      expect(
        (
          labels: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
            featureType: 'transit.station.rail',
            elementType: 'labels',
            visibility: JobLocationMapVisibility.visible,
          ),
          names: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
            featureType: 'transit.station.rail',
            elementType: 'labels.text',
            visibility: JobLocationMapVisibility.visible,
          ),
          pins: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
            featureType: 'transit.station.rail',
            elementType: 'labels.icon',
            visibility: JobLocationMapVisibility.visible,
          ),
          pathsHidden: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
            featureType: 'transit.line',
            elementType: 'all',
            visibility: JobLocationMapVisibility.hidden,
          ),
        ),
        (labels: true, names: true, pins: true, pathsHidden: true),
      );
    });

    test('when preserving useful tourist context, it should show attraction names', () {
      expect(
        _JobLocationMapStyleTestHelpers.hasVisibilityRule(
          featureType: 'poi.attraction',
          elementType: 'labels',
          visibility: JobLocationMapVisibility.visible,
        ),
        isTrue,
      );
    });

    test(
      'when reducing point-of-interest clutter, it should retain business labels and hide medical and school labels',
      () {
        expect(
          (
            business: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
              featureType: 'poi.business',
              elementType: 'labels',
              visibility: JobLocationMapVisibility.visible,
            ),
            medical: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
              featureType: 'poi.medical',
              elementType: 'labels',
              visibility: JobLocationMapVisibility.hidden,
            ),
            school: _JobLocationMapStyleTestHelpers.hasVisibilityRule(
              featureType: 'poi.school',
              elementType: 'labels',
              visibility: JobLocationMapVisibility.hidden,
            ),
          ),
          (business: true, medical: true, school: true),
        );
      },
    );

    testWidgets('when resolving local style colors, it should use only the Cataquí and Mateo palettes', (tester) async {
      var usesOnlyPaletteColors = false;
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) {
              usesOnlyPaletteColors = _JobLocationMapStyleTestHelpers.styleColorsBelongToPalette(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(usesOnlyPaletteColors, isTrue);
    });

    testWidgets('when rendering geographic place names, it should use the approved Mateo neutral hierarchy', (
      tester,
    ) async {
      var expectedColors = (administrative: '', country: '', locality: '', neighborhood: '', province: '');
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) {
              expectedColors = (
                administrative: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.neutral[7]),
                country: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.neutral[8]),
                locality: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.neutral[8]),
                neighborhood: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.neutral[7]),
                province: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.neutral[7]),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect((
        administrative: _JobLocationMapStyleTestHelpers.ruleColor(
          featureType: 'administrative',
          elementType: 'labels.text.fill',
        ),
        country: _JobLocationMapStyleTestHelpers.ruleColor(
          featureType: 'administrative.country',
          elementType: 'labels.text.fill',
        ),
        locality: _JobLocationMapStyleTestHelpers.ruleColor(
          featureType: 'administrative.locality',
          elementType: 'labels.text.fill',
        ),
        neighborhood: _JobLocationMapStyleTestHelpers.ruleColor(
          featureType: 'administrative.neighborhood',
          elementType: 'labels.text.fill',
        ),
        province: _JobLocationMapStyleTestHelpers.ruleColor(
          featureType: 'administrative.province',
          elementType: 'labels.text.fill',
        ),
      ), expectedColors);
    });

    testWidgets('when styling point-of-interest labels, it should use the approved palette hierarchy', (tester) async {
      var expectedColors = (
        attractionText: '',
        attractionIcon: '',
        governmentText: '',
        governmentIcon: '',
        parkText: '',
        parkIcon: '',
        sportsText: '',
        sportsIcon: '',
      );
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) {
              expectedColors = (
                attractionText: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.neutral[8]),
                attractionIcon: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.violet[7]),
                governmentText: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.amber[8]),
                governmentIcon: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.amber[7]),
                parkText: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.green[8]),
                parkIcon: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.green[7]),
                sportsText: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.violet[8]),
                sportsIcon: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.violet[7]),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect((
        attractionText: _JobLocationMapStyleTestHelpers.ruleColor(
          featureType: 'poi.attraction',
          elementType: 'labels.text.fill',
        ),
        attractionIcon: _JobLocationMapStyleTestHelpers.ruleColor(
          featureType: 'poi.attraction',
          elementType: 'labels.icon',
        ),
        governmentText: _JobLocationMapStyleTestHelpers.ruleColor(
          featureType: 'poi.government',
          elementType: 'labels.text.fill',
        ),
        governmentIcon: _JobLocationMapStyleTestHelpers.ruleColor(
          featureType: 'poi.government',
          elementType: 'labels.icon',
        ),
        parkText: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'poi.park', elementType: 'labels.text.fill'),
        parkIcon: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'poi.park', elementType: 'labels.icon'),
        sportsText: _JobLocationMapStyleTestHelpers.ruleColor(
          featureType: 'poi.sports_complex',
          elementType: 'labels.text.fill',
        ),
        sportsIcon: _JobLocationMapStyleTestHelpers.ruleColor(
          featureType: 'poi.sports_complex',
          elementType: 'labels.icon',
        ),
      ), expectedColors);
    });

    testWidgets('when rendering neutral map surfaces, it should make POI geometry lighter than the base map', (
      tester,
    ) async {
      late String neutralSurface;
      late String poiSurface;
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) {
              neutralSurface = _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.neutral[2]);
              poiSurface = _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.neutral[1]);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        (
          base: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'all', elementType: 'geometry'),
          landscape: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'landscape', elementType: 'geometry'),
          manMade: _JobLocationMapStyleTestHelpers.ruleColor(
            featureType: 'landscape.man_made',
            elementType: 'geometry.fill',
          ),
          poi: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'poi', elementType: 'geometry'),
          attraction: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'poi.attraction', elementType: 'geometry'),
          business: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'poi.business', elementType: 'geometry'),
          government: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'poi.government', elementType: 'geometry'),
          medical: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'poi.medical', elementType: 'geometry'),
          school: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'poi.school', elementType: 'geometry'),
          sports: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'poi.sports_complex', elementType: 'geometry'),
        ),
        (
          base: neutralSurface,
          landscape: neutralSurface,
          manMade: neutralSurface,
          poi: poiSurface,
          attraction: poiSurface,
          business: poiSurface,
          government: poiSurface,
          medical: poiSurface,
          school: poiSurface,
          sports: poiSurface,
        ),
      );
    });

    testWidgets('when rendering roads and streets, it should keep their surfaces white', (tester) async {
      late String roadSurface;
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) {
              roadSurface = _JobLocationMapStyleTestHelpers.colorHex(context.mateo.colorScheme.map.labelHalo);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        (
          road: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'road', elementType: 'geometry.fill'),
          arterial: _JobLocationMapStyleTestHelpers.ruleColor(
            featureType: 'road.arterial',
            elementType: 'geometry.fill',
          ),
          highway: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'road.highway', elementType: 'geometry.fill'),
          localRoad: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'road.local', elementType: 'geometry.fill'),
        ),
        (road: roadSurface, arterial: roadSurface, highway: roadSurface, localRoad: roadSurface),
      );
    });

    testWidgets('when rendering geographic reference surfaces, it should preserve their semantic colors', (
      tester,
    ) async {
      late ({String natural, String park, String transit, String water}) semanticSurfaces;
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) {
              semanticSurfaces = (
                natural: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.green[5]),
                park: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.green[4]),
                transit: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.blue[1]),
                water: _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.cyan[2]),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect((
        natural: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'landscape.natural', elementType: 'geometry'),
        park: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'poi.park', elementType: 'geometry'),
        transit: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'transit.station', elementType: 'geometry'),
        water: _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'water', elementType: 'geometry'),
      ), semanticSurfaces);
    });

    testWidgets('when labeling local streets, it should use the legible Cataquí neutral step', (tester) async {
      late String expectedStreetLabelColor;
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) {
              expectedStreetLabelColor = _JobLocationMapStyleTestHelpers.colorHex(context.mateo.palette.neutral[10]);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _JobLocationMapStyleTestHelpers.ruleColor(featureType: 'road.local', elementType: 'labels.text.fill'),
        expectedStreetLabelColor,
      );
    });
  });
}
