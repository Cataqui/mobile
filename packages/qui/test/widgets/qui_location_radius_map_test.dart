import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

void main() {
  group('QuiMapLocation assertions', () {
    test('when latitude is below the valid range, it should assert', () {
      expect(() => QuiMapLocation(latitude: -90.1, longitude: 0), throwsAssertionError);
    });

    test('when latitude is above the valid range, it should assert', () {
      expect(() => QuiMapLocation(latitude: 90.1, longitude: 0), throwsAssertionError);
    });

    test('when longitude is below the valid range, it should assert', () {
      expect(() => QuiMapLocation(latitude: 0, longitude: -180.1), throwsAssertionError);
    });

    test('when longitude is above the valid range, it should assert', () {
      expect(() => QuiMapLocation(latitude: 0, longitude: 180.1), throwsAssertionError);
    });
  });

  group('RadiusStyle assertions', () {
    test('when borderWidth is negative, it should assert', () {
      expect(() => RadiusStyle(borderWidth: -0.1), throwsAssertionError);
    });
  });

  group('QuiLocationRadiusMap assertions', () {
    test('when radiusInMeters is negative, it should assert', () {
      expect(() => _map(radiusInMeters: -1), throwsAssertionError);
    });

    test('when tileMinZoom is negative, it should assert', () {
      expect(() => _map(tileMinZoom: -1), throwsAssertionError);
    });

    test('when tileMaxZoom is zero, it should assert', () {
      expect(() => _map(tileMaxZoom: 0), throwsAssertionError);
    });

    test('when tileMinZoom is greater than tileMaxZoom, it should assert', () {
      expect(() => _map(tileMinZoom: 15, tileMaxZoom: 14), throwsAssertionError);
    });

    test('when zoom is lower than tileMinZoom, it should assert', () {
      expect(() => _map(tileMinZoom: 12, zoom: 11.9), throwsAssertionError);
    });
  });

  group('QuiLocationRadiusMap layout', () {
    testWidgets('when parent gives a height, it should use the parent height', (tester) async {
      await _pumpMap(tester, size: const Size(320, 260));

      expect(tester.getSize(find.byType(QuiLocationRadiusMap)).height, 260);
    });

    testWidgets('when parent gives a width, it should use the parent width', (tester) async {
      await _pumpMap(tester, size: const Size(320, 260));

      expect(tester.getSize(find.byType(QuiLocationRadiusMap)).width, 320);
    });
  });

  group('QuiLocationRadiusMap radius rendering', () {
    testWidgets('when radiusInMeters is provided, it should pass half to CircleMarker as the center-to-edge radius', (tester) async {
      await _pumpMap(tester, radiusInMeters: 2000);

      expect(_circleMarker(tester).radius, 1000);
    });

    testWidgets('when radiusInMeters is provided, it should render the radius in meters', (tester) async {
      await _pumpMap(tester, radiusInMeters: 2000);

      expect(_circleMarker(tester).useRadiusInMeter, isTrue);
    });

    testWidgets('when location is provided, it should center the circle on that latitude', (tester) async {
      await _pumpMap(tester, location: const QuiMapLocation(latitude: -23.556391, longitude: -46.844076));

      expect(_circleMarker(tester).point.latitude, closeTo(-23.556391, 0.000001));
    });

    testWidgets('when location is provided, it should center the circle on that longitude', (tester) async {
      await _pumpMap(tester, location: const QuiMapLocation(latitude: -23.556391, longitude: -46.844076));

      expect(_circleMarker(tester).point.longitude, closeTo(-46.844076, 0.000001));
    });

    testWidgets('when using the default radiusStyle, it should use primary color for the fill', (tester) async {
      await _pumpMap(tester);

      expect(_circleMarker(tester).color, const Color(0xFFFF4A4B).withValues(alpha: 0.15));
    });

    testWidgets('when using the default radiusStyle, it should use primary color for the border', (tester) async {
      await _pumpMap(tester);

      expect(_circleMarker(tester).borderColor, const Color(0xFFFF4A4B).withValues(alpha: 0.4));
    });

    testWidgets('when using the default radiusStyle, it should use the default border width', (tester) async {
      await _pumpMap(tester);

      expect(_circleMarker(tester).borderStrokeWidth, 0);
    });

    testWidgets('when radiusStyle sets color, it should use the custom fill color', (tester) async {
      await _pumpMap(tester, radiusStyle: const RadiusStyle(color: Color(0xFF123456)));

      expect(_circleMarker(tester).color, const Color(0xFF123456));
    });

    testWidgets('when radiusStyle sets borderColor, it should use the custom border color', (tester) async {
      await _pumpMap(tester, radiusStyle: const RadiusStyle(borderColor: Color(0xFF654321)));

      expect(_circleMarker(tester).borderColor, const Color(0xFF654321));
    });

    testWidgets('when radiusStyle sets borderWidth, it should use the custom border width', (tester) async {
      await _pumpMap(tester, radiusStyle: const RadiusStyle(borderWidth: 4));

      expect(_circleMarker(tester).borderStrokeWidth, 4);
    });
  });

  group('QuiLocationRadiusMap camera fit', () {
    testWidgets('when zoom is omitted, it should create a camera fit around the radius', (tester) async {
      await _pumpMap(tester);

      expect(_mapOptions(tester).initialCameraFit, isA<FitBounds>());
    });

    testWidgets('when radius is 2km, it should calculate a 2km latitude diameter', (tester) async {
      await _pumpMap(tester, radiusInMeters: 2000);

      expect(_fitBounds(tester).bounds.north - _fitBounds(tester).bounds.south, closeTo(2000 / 111320, 0.000001));
    });

    testWidgets('when radius is 2km, it should calculate the longitude diameter using the latitude scale', (tester) async {
      const location = QuiMapLocation(latitude: -23.556391, longitude: -46.844076);
      final metersPerLongitudeDegree = 111320 * math.cos(location.latitude * math.pi / 180).abs();

      await _pumpMap(tester, location: location, radiusInMeters: 2000);

      expect(
        _fitBounds(tester).bounds.east - _fitBounds(tester).bounds.west,
        closeTo(2000 / metersPerLongitudeDegree, 0.000001),
      );
    });

    testWidgets('when radius is zero, it should use the minimum fit radius for latitude bounds', (tester) async {
      await _pumpMap(tester, radiusInMeters: 0);

      expect(_fitBounds(tester).bounds.north - _fitBounds(tester).bounds.south, closeTo(50 / 111320, 0.000001));
    });

    testWidgets('when location is near the north pole, it should clamp the north bound', (tester) async {
      await _pumpMap(tester, location: const QuiMapLocation(latitude: 89.999, longitude: 0), radiusInMeters: 2000);

      expect(_fitBounds(tester).bounds.north, 90);
    });

    testWidgets('when tileMinZoom is provided, it should pass it to the camera fit', (tester) async {
      await _pumpMap(tester, tileMinZoom: 12, tileMaxZoom: 14);

      expect(_fitBounds(tester).minZoom, 12);
    });

    testWidgets('when tileMaxZoom is provided, it should pass it to the camera fit', (tester) async {
      await _pumpMap(tester, tileMaxZoom: 14);

      expect(_fitBounds(tester).maxZoom, 14);
    });
  });

  group('QuiLocationRadiusMap fixed zoom', () {
    testWidgets('when zoom is provided, it should skip automatic camera fit', (tester) async {
      await _pumpMap(tester, zoom: 13);

      expect(_mapOptions(tester).initialCameraFit, isNull);
    });

    testWidgets('when zoom is provided, it should use it as the initial zoom', (tester) async {
      await _pumpMap(tester, zoom: 13);

      expect(_mapOptions(tester).initialZoom, 13);
    });

    testWidgets('when zoom is provided, it should keep the map centered on latitude', (tester) async {
      await _pumpMap(tester, zoom: 13, location: const QuiMapLocation(latitude: -23.556391, longitude: -46.844076));

      expect(_mapOptions(tester).initialCenter.latitude, closeTo(-23.556391, 0.000001));
    });

    testWidgets('when zoom is provided, it should keep the map centered on longitude', (tester) async {
      await _pumpMap(tester, zoom: 13, location: const QuiMapLocation(latitude: -23.556391, longitude: -46.844076));

      expect(_mapOptions(tester).initialCenter.longitude, closeTo(-46.844076, 0.000001));
    });

    testWidgets('when zoom is greater than tileMaxZoom, it should use zoom as the map max zoom', (tester) async {
      await _pumpMap(tester, tileMaxZoom: 14, zoom: 16);

      expect(_mapOptions(tester).maxZoom, 16);
    });

    testWidgets('when zoom is below tileMaxZoom, it should keep tileMaxZoom as the map max zoom', (tester) async {
      await _pumpMap(tester, tileMaxZoom: 14, zoom: 13);

      expect(_mapOptions(tester).maxZoom, 14);
    });
  });

  group('QuiLocationRadiusMap map configuration', () {
    testWidgets('when rendered, it should disable map gestures', (tester) async {
      await _pumpMap(tester);

      expect(_mapOptions(tester).interactionOptions.flags, InteractiveFlag.none);
    });

    testWidgets('when rendered, it should render vector tiles in raster mode', (tester) async {
      await _pumpMap(tester);

      expect(_vectorTileLayer(tester).layerMode, VectorTileLayerMode.raster);
    });

    testWidgets('when overzooming, it should pass the overzoom value to the vector layer', (tester) async {
      await _pumpMap(tester, tileMaxZoom: 14, zoom: 16);

      expect(_vectorTileLayer(tester).maximumZoom, 16);
    });

    testWidgets('when tileMinZoom is provided, it should pass it to the tile provider', (tester) async {
      await _pumpMap(tester, tileMinZoom: 12, tileMaxZoom: 14);

      expect(_networkProvider(tester).minimumZoom, 12);
    });

    testWidgets('when tileMaxZoom is provided, it should pass it to the tile provider', (tester) async {
      await _pumpMap(tester, tileMinZoom: 12, tileMaxZoom: 14);

      expect(_networkProvider(tester).maximumZoom, 14);
    });

    testWidgets('when style is still loading, it should render a white fallback', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: SizedBox.fromSize(size: const Size(320, 220), child: _map()),
        ),
      );

      final whiteBoxes = find.byWidgetPredicate((w) => w is ColoredBox && w.color == Colors.white);
      expect(whiteBoxes, findsOneWidget);
    });
  });
}

const _defaultLocation = QuiMapLocation(latitude: -23.55052, longitude: -46.633308);

QuiLocationRadiusMap _map({
  String tileUrlTemplate = 'https://tiles.example.com/{z}/{x}/{y}.mvt',
  QuiMapLocation location = _defaultLocation,
  double radiusInMeters = 500,
  RadiusStyle radiusStyle = const RadiusStyle(),
  int tileMinZoom = 1,
  int tileMaxZoom = 14,
  double? zoom,
}) {
  return QuiLocationRadiusMap(
    tileUrlTemplate: tileUrlTemplate,
    location: location,
    radiusInMeters: radiusInMeters,
    radiusStyle: radiusStyle,
    tileMinZoom: tileMinZoom,
    tileMaxZoom: tileMaxZoom,
    zoom: zoom,
  );
}

Future<void> _pumpMap(
  WidgetTester tester, {
  Size size = const Size(320, 220),
  QuiMapLocation location = _defaultLocation,
  double radiusInMeters = 500,
  RadiusStyle radiusStyle = const RadiusStyle(),
  int tileMinZoom = 1,
  int tileMaxZoom = 14,
  double? zoom,
}) async {
  await tester.pumpWidget(
    _TestApp(
      child: SizedBox.fromSize(
        size: size,
        child: _map(
          location: location,
          radiusInMeters: radiusInMeters,
          radiusStyle: radiusStyle,
          tileMinZoom: tileMinZoom,
          tileMaxZoom: tileMaxZoom,
          zoom: zoom,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
}

CircleMarker<Object> _circleMarker(WidgetTester tester) {
  return _circleLayer(tester).circles.single;
}

CircleLayer<Object> _circleLayer(WidgetTester tester) {
  return tester.widget<CircleLayer<Object>>(find.byWidgetPredicate((widget) => widget is CircleLayer<Object>));
}

MapOptions _mapOptions(WidgetTester tester) {
  return tester.widget<FlutterMap>(find.byType(FlutterMap)).options;
}

FitBounds _fitBounds(WidgetTester tester) {
  final cameraFit = _mapOptions(tester).initialCameraFit;
  if (cameraFit is FitBounds) return cameraFit;

  throw StateError('Expected initialCameraFit to be FitBounds.');
}

VectorTileLayer _vectorTileLayer(WidgetTester tester) {
  return tester.widget<VectorTileLayer>(find.byType(VectorTileLayer));
}

NetworkVectorTileProvider _networkProvider(WidgetTester tester) {
  final provider = _vectorTileLayer(tester).tileProviders.get('openmaptiles');
  if (provider is NetworkVectorTileProvider) return provider;

  throw StateError('Expected openmaptiles provider to be NetworkVectorTileProvider.');
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
      home: Scaffold(body: Center(child: child)),
    );
  }
}
