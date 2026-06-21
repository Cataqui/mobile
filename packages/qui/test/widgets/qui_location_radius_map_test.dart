import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:qui/src/widgets/qui_location_radius_map/qui_location_radius_map.dart';

void main() {
  group('RadiusStyle assertions', () {
    test('when borderWidth is negative, it should assert', () {
      expect(() => RadiusStyle(borderWidth: -1), throwsAssertionError);
    });
  });

  group('QuiLocationRadiusMap assertions', () {
    test('when latitude is below -90, it should assert', () {
      expect(
        () => QuiLocationRadiusMap(
          tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
          location: (latitude: -91, longitude: 0),
          fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
          radiusInMeters: 500,
        ),
        throwsAssertionError,
      );
    });

    test('when latitude is above 90, it should assert', () {
      expect(
        () => QuiLocationRadiusMap(
          tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
          location: (latitude: 91, longitude: 0),
          fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
          radiusInMeters: 500,
        ),
        throwsAssertionError,
      );
    });

    test('when longitude is below -180, it should assert', () {
      expect(
        () => QuiLocationRadiusMap(
          tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
          location: (latitude: 0, longitude: -181),
          fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
          radiusInMeters: 500,
        ),
        throwsAssertionError,
      );
    });

    test('when longitude is above 180, it should assert', () {
      expect(
        () => QuiLocationRadiusMap(
          tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
          location: (latitude: 0, longitude: 181),
          fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
          radiusInMeters: 500,
        ),
        throwsAssertionError,
      );
    });

    test('when radiusInMeters is negative, it should assert', () {
      expect(
        () => QuiLocationRadiusMap(
          tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
          location: (latitude: 0, longitude: 0),
          fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
          radiusInMeters: -1,
        ),
        throwsAssertionError,
      );
    });

    test('when tileMinZoom is negative, it should assert', () {
      expect(
        () => QuiLocationRadiusMap(
          tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
          location: (latitude: 0, longitude: 0),
          fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
          radiusInMeters: 500,
          tileMinZoom: -1,
        ),
        throwsAssertionError,
      );
    });

    test('when tileMaxZoom is zero, it should assert', () {
      expect(
        () => QuiLocationRadiusMap(
          tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
          location: (latitude: 0, longitude: 0),
          fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
          radiusInMeters: 500,
          tileMaxZoom: 0,
        ),
        throwsAssertionError,
      );
    });

    test('when tileMinZoom is greater than tileMaxZoom, it should assert', () {
      expect(
        () => QuiLocationRadiusMap(
          tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
          location: (latitude: 0, longitude: 0),
          fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
          radiusInMeters: 500,
          tileMinZoom: 10,
          tileMaxZoom: 5,
        ),
        throwsAssertionError,
      );
    });

    test('when zoom is lower than tileMinZoom, it should assert', () {
      expect(
        () => QuiLocationRadiusMap(
          tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
          location: (latitude: 0, longitude: 0),
          fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
          radiusInMeters: 500,
          tileMinZoom: 10,
          tileMaxZoom: 15,
          zoom: 5,
        ),
        throwsAssertionError,
      );
    });

    test('when offset dx is NaN, it should assert', () {
      expect(
        () => QuiLocationRadiusMap(
          tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
          location: (latitude: 0, longitude: 0),
          fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
          radiusInMeters: 500,
          offset: const Offset(double.nan, 0),
        ),
        throwsAssertionError,
      );
    });

    test('when offset dy is infinite, it should assert', () {
      expect(
        () => QuiLocationRadiusMap(
          tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
          location: (latitude: 0, longitude: 0),
          fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
          radiusInMeters: 500,
          offset: const Offset(0, double.infinity),
        ),
        throwsAssertionError,
      );
    });
  });

  group('QuiLocationRadiusMap layout', () {
    testWidgets('when parent gives a height and width, it should render within bounds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 400,
            width: 300,
            child: QuiLocationRadiusMap(
              tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
              location: (latitude: -23.55, longitude: -46.63),
              fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
              radiusInMeters: 2000,
            ),
          ),
        ),
      );

      expect(find.byType(QuiLocationRadiusMap), findsOneWidget);
    });
  });

  group('QuiLocationRadiusMap map configuration', () {
    testWidgets('when rendered, it should wrap the map in AnimatedOpacity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 400,
            width: 300,
            child: QuiLocationRadiusMap(
              tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
              location: (latitude: -23.55, longitude: -46.63),
              fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
              radiusInMeters: 2000,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedOpacity), findsOneWidget);
    });

    testWidgets('when rendered, it should include a MapLibreMap widget', (tester) async {
      await _pumpMap(tester);

      expect(find.byType(MapLibreMap), findsOneWidget);
    });

    testWidgets('when zoom is provided, it should use it as the initial zoom', (tester) async {
      await _pumpMap(tester, zoom: 14);

      expect(find.byType(MapLibreMap), findsOneWidget);
    });

    testWidgets('when rendered, it should pass the generated style to MapLibre', (tester) async {
      await _pumpMap(tester);

      expect(_mapStyle(tester)['version'], 8);
    });

    testWidgets('when rendered, it should include the tile URL in the MapLibre style', (tester) async {
      await _pumpMap(tester);

      final sources = _mapStyle(tester)['sources'] as Map<String, dynamic>;
      final openMapTiles = sources['openmaptiles'] as Map<String, dynamic>;
      expect(openMapTiles['tiles'], ['https://tiles.example.com/{z}/{x}/{y}.mvt']);
    });

    testWidgets('when rendered, it should include a glyphs template in the MapLibre style', (tester) async {
      await _pumpMap(tester);

      expect(
        _mapStyle(tester)['glyphs'],
        'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf',
      );
    });

    testWidgets('when rendered, it should use the bundled Inter Regular glyph font stack', (tester) async {
      await _pumpMap(tester);

      expect(_textFont(_mapStyle(tester), 'place_city_label'), ['Inter Regular']);
    });
  });

  group('QuiLocationRadiusMap offset camera target', () {
    testWidgets('when offset is zero, it should center the camera on the location', (tester) async {
      await _pumpMap(tester);

      final target = _cameraTarget(tester);
      expect(target.latitude, closeTo(-23.55, 0.001));
      expect(target.longitude, closeTo(-46.63, 0.001));
    });

    testWidgets('when offset dy is positive, it should shift the camera north of the location', (tester) async {
      const location = (latitude: -23.55, longitude: -46.63);
      await _pumpMap(tester, offset: const Offset(0, 80), zoom: 14);

      final target = _cameraTarget(tester);
      expect(target.latitude, greaterThan(location.latitude));
      expect(target.longitude, closeTo(location.longitude, 0.001));
    });

    testWidgets('when offset dx is positive, it should shift the camera west of the location', (tester) async {
      const location = (latitude: -23.55, longitude: -46.63);
      await _pumpMap(tester, offset: const Offset(80, 0), zoom: 14);

      final target = _cameraTarget(tester);
      expect(target.latitude, closeTo(location.latitude, 0.001));
      expect(target.longitude, lessThan(location.longitude));
    });

    testWidgets('when offset dx is 25.6 at zoom 0 on the equator, it should shift lng by -36 deg', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 400,
            width: 300,
            child: QuiLocationRadiusMap(
              tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
              location: (latitude: 0, longitude: 0),
              fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
              radiusInMeters: 2000,
              zoom: 0,
              offset: const Offset(25.6, 0),
              tileMinZoom: 0,
            ),
          ),
        ),
      );

      final target = _cameraTarget(tester);
      expect(target.latitude, closeTo(0, 0.001));
      expect(target.longitude, closeTo(-36, 0.001));
    });

    testWidgets('when offset dy is 25.6 at zoom 0 on the equator, it should shift lat by 36 deg', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 400,
            width: 300,
            child: QuiLocationRadiusMap(
              tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
              location: (latitude: 0, longitude: 0),
              fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
              radiusInMeters: 2000,
              zoom: 0,
              offset: const Offset(0, 25.6),
              tileMinZoom: 0,
            ),
          ),
        ),
      );

      final target = _cameraTarget(tester);
      expect(target.latitude, closeTo(36, 0.001));
      expect(target.longitude, closeTo(0, 0.001));
    });
  });
}

Future<void> _pumpMap(WidgetTester tester, {double? zoom, Offset offset = Offset.zero}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        height: 400,
        width: 300,
        child: QuiLocationRadiusMap(
          tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
          location: (latitude: -23.55, longitude: -46.63),
          fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
          radiusInMeters: 2000,
          zoom: zoom,
          offset: offset,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

LatLng _cameraTarget(WidgetTester tester) {
  final map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
  return map.initialCameraPosition!.target;
}

Map<String, dynamic> _mapStyle(WidgetTester tester) {
  final map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
  return jsonDecode(map.styleString) as Map<String, dynamic>;
}

List<dynamic> _textFont(Map<String, dynamic> style, String layerId) {
  final layers = style['layers'] as List<dynamic>;
  final layer = layers.cast<Map<String, dynamic>>().firstWhere((layer) => layer['id'] == layerId);
  final layout = layer['layout'] as Map<String, dynamic>;
  return layout['text-font'] as List<dynamic>;
}
