import 'dart:math' as math;

import 'package:cataqui_app/widgets/job_location_map/job_location_map.dart';
import 'package:cataqui_app/widgets/job_location_map/job_location_map_color_scheme.dart';
import 'package:cataqui_app/widgets/job_location_map/job_location_map_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../utils/test_app.dart';
import 'google_maps_test_renderer.dart';

class _JobLocationMapTestHelpers {
  _JobLocationMapTestHelpers._();

  static const testLocation = (latitude: -23.55052, longitude: -46.633308);
  static const testAreaDiameterInMeters = 1200.0;

  static Widget buildApp({
    ({double latitude, double longitude}) location = testLocation,
    double areaDiameterInMeters = testAreaDiameterInMeters,
    double zoom = 14,
    Offset offset = Offset.zero,
  }) {
    return TestApp.screen(
      child: buildBareMap(location: location, areaDiameterInMeters: areaDiameterInMeters, zoom: zoom, offset: offset),
    );
  }

  static Widget buildBareMap({
    ({double latitude, double longitude}) location = testLocation,
    double areaDiameterInMeters = testAreaDiameterInMeters,
    double zoom = 14,
    Offset offset = Offset.zero,
  }) {
    return Center(
      child: SizedBox(
        width: 320,
        height: 240,
        child: JobLocationMap(
          location: location,
          areaDiameterInMeters: areaDiameterInMeters,
          zoom: zoom,
          offset: offset,
        ),
      ),
    );
  }

  static Future<void> pumpMap({
    required WidgetTester tester,
    ({double latitude, double longitude}) location = testLocation,
    double areaDiameterInMeters = testAreaDiameterInMeters,
    double zoom = 14,
    Offset offset = Offset.zero,
  }) async {
    await tester.pumpWidget(
      buildApp(location: location, areaDiameterInMeters: areaDiameterInMeters, zoom: zoom, offset: offset),
    );
    await tester.pumpAndSettle();
  }

  static bool cameraTargetMatchesOffset({required LatLng target, required Offset offset, required double zoom}) {
    final latitudeRadians = testLocation.latitude * math.pi / 180;
    final latitudeScale = math.max(math.cos(latitudeRadians).abs(), 0.01);
    final degreesPerPixel = 360 / (256 * math.pow(2, zoom));
    final expectedLatitude = testLocation.latitude + offset.dy * degreesPerPixel * latitudeScale;
    final expectedLongitude = testLocation.longitude - offset.dx * degreesPerPixel;

    return (target.latitude - expectedLatitude).abs() < 0.0000001 &&
        (target.longitude - expectedLongitude).abs() < 0.0000001;
  }
}

void main() {
  late GoogleMapsTestRenderer renderer;

  setUp(() {
    renderer = GoogleMapsTestRenderer()..install();
  });

  tearDown(() {
    renderer.restore();
    debugDefaultTargetPlatformOverride = null;
  });

  group('JobLocationMap', () {
    testWidgets('when rendering a job area, it should show one location map', (tester) async {
      await _JobLocationMapTestHelpers.pumpMap(tester: tester);

      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('when rendering a job area, it should center the radius on the supplied location', (tester) async {
      await _JobLocationMapTestHelpers.pumpMap(tester: tester);

      expect(renderer.lastMapObjects.circles.single.center, const LatLng(-23.55052, -46.633308));
    });

    testWidgets('when rendering a job area diameter, it should draw a radius equal to half of that diameter', (
      tester,
    ) async {
      await _JobLocationMapTestHelpers.pumpMap(tester: tester, areaDiameterInMeters: 1400);

      expect(renderer.lastMapObjects.circles.single.radius, 700);
    });

    testWidgets('when rendering the approximate area, it should use the Cataquí location radius color', (tester) async {
      await _JobLocationMapTestHelpers.pumpMap(tester: tester);

      expect(
        renderer.lastMapObjects.circles.single.fillColor,
        JobLocationMapColorScheme.light(palette: MateoPalette()).locationRadius,
      );
    });

    testWidgets('when rendering the approximate area, it should omit a visible circle outline', (tester) async {
      await _JobLocationMapTestHelpers.pumpMap(tester: tester);
      final circle = renderer.lastMapObjects.circles.single;

      expect(
        (strokeColor: circle.strokeColor, strokeWidth: circle.strokeWidth),
        (
          strokeColor: JobLocationMapColorScheme.light(palette: MateoPalette()).locationRadius.withValues(alpha: 0),
          strokeWidth: 0,
        ),
      );
    });

    testWidgets('when the native map is still rendering, it should use the Cataquí map background natively', (
      tester,
    ) async {
      await _JobLocationMapTestHelpers.pumpMap(tester: tester);
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));

      expect(googleMap.backgroundColor, JobLocationMapColorScheme.light(palette: MateoPalette()).background);
    });

    testWidgets('when no visual offset is supplied, it should account for attribution padding at the default zoom', (
      tester,
    ) async {
      await _JobLocationMapTestHelpers.pumpMap(tester: tester);
      final cameraPosition = renderer.lastWidgetConfiguration.initialCameraPosition;

      expect(
        (
          targetMatches: _JobLocationMapTestHelpers.cameraTargetMatchesOffset(
            target: cameraPosition.target,
            offset: const Offset(0, 30),
            zoom: 14,
          ),
          zoom: cameraPosition.zoom,
        ),
        (targetMatches: true, zoom: 14.0),
      );
    });

    testWidgets('when a visual offset is supplied, it should shift the camera target at the selected zoom', (
      tester,
    ) async {
      const offset = Offset(30, -20);
      const zoom = 14.0;
      await _JobLocationMapTestHelpers.pumpMap(tester: tester, offset: offset, zoom: zoom);
      final target = renderer.lastWidgetConfiguration.initialCameraPosition.target;

      expect(
        _JobLocationMapTestHelpers.cameraTargetMatchesOffset(target: target, offset: const Offset(30, 10), zoom: zoom),
        isTrue,
      );
    });

    testWidgets('when rendering inside a feed card, it should reserve the approved Google attribution padding', (
      tester,
    ) async {
      await _JobLocationMapTestHelpers.pumpMap(tester: tester);

      expect(renderer.lastMapConfiguration.padding, JobLocationMap.mapPadding);
    });

    testWidgets('when bottom content overlaps the map, it should keep the job area at the requested visible offset', (
      tester,
    ) async {
      await _JobLocationMapTestHelpers.pumpMap(tester: tester, offset: const Offset(0, 18));
      final target = renderer.lastWidgetConfiguration.initialCameraPosition.target;

      expect(
        _JobLocationMapTestHelpers.cameraTargetMatchesOffset(target: target, offset: const Offset(0, 48), zoom: 14),
        isTrue,
      );
    });

    testWidgets('when rendering the decorative map, it should disable interactive and optional map features', (
      tester,
    ) async {
      await _JobLocationMapTestHelpers.pumpMap(tester: tester);
      final configuration = renderer.lastMapConfiguration;

      expect(
        (
          compass: configuration.compassEnabled,
          toolbar: configuration.mapToolbarEnabled,
          mapTypeControl: configuration.mapTypeControlEnabled,
          fullscreenControl: configuration.fullscreenControlEnabled,
          streetViewControl: configuration.streetViewControlEnabled,
          rotate: configuration.rotateGesturesEnabled,
          scroll: configuration.scrollGesturesEnabled,
          zoomControls: configuration.zoomControlsEnabled,
          zoomGestures: configuration.zoomGesturesEnabled,
          tilt: configuration.tiltGesturesEnabled,
          imagery: configuration.fortyFiveDegreeImageryEnabled,
          myLocation: configuration.myLocationEnabled,
          myLocationButton: configuration.myLocationButtonEnabled,
          indoor: configuration.indoorViewEnabled,
          traffic: configuration.trafficEnabled,
          buildings: configuration.buildingsEnabled,
        ),
        (
          compass: false,
          toolbar: false,
          mapTypeControl: false,
          fullscreenControl: false,
          streetViewControl: false,
          rotate: false,
          scroll: false,
          zoomControls: false,
          zoomGestures: false,
          tilt: false,
          imagery: false,
          myLocation: false,
          myLocationButton: false,
          indoor: false,
          traffic: false,
          buildings: false,
        ),
      );
    });

    testWidgets('when rendering on Android, it should use the low-overhead map mode', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await _JobLocationMapTestHelpers.pumpMap(tester: tester);
      final liteModeEnabled = renderer.lastMapConfiguration.liteModeEnabled;
      debugDefaultTargetPlatformOverride = null;

      expect(liteModeEnabled, isTrue);
    });

    testWidgets('when rendering the location map style, it should use the approved local style', (tester) async {
      await _JobLocationMapTestHelpers.pumpMap(tester: tester);
      final style = renderer.lastMapConfiguration.style!;

      expect(
        style,
        JobLocationMapStyle.fromColorScheme(
          colorScheme: JobLocationMapColorScheme.light(palette: MateoPalette()),
        ).googleMapsJson,
      );
    });

    testWidgets('when the active light theme changes, it should preserve the native map identity', (tester) async {
      final mateoTheme = MateoTheme.light(
        accentColor: const Color(0xFFFF4A4B),
        onAccent: const Color(0xFFFFFFFF),
      ).lightTheme;
      final theme = ValueNotifier<ThemeData>(mateoTheme);
      addTearDown(theme.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<ThemeData>(
          valueListenable: theme,
          builder: (context, value, child) => MaterialApp(theme: value, home: child),
          child: _JobLocationMapTestHelpers.buildBareMap(),
        ),
      );
      await tester.pumpAndSettle();
      theme.value = mateoTheme.copyWith(scaffoldBackgroundColor: const Color(0xFFF0F0F0));
      await tester.pumpAndSettle();

      expect(renderer.createdIds.toSet(), hasLength(1));
    });

    testWidgets('when the active theme is dark, it should reject the unsupported map appearance', (tester) async {
      final lightTheme = MateoTheme.light(
        accentColor: const Color(0xFFFF4A4B),
        onAccent: const Color(0xFFFFFFFF),
      ).lightTheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme.copyWith(colorScheme: lightTheme.colorScheme.copyWith(brightness: Brightness.dark)),
          home: _JobLocationMapTestHelpers.buildBareMap(),
        ),
      );

      expect(tester.takeException(), isA<UnsupportedError>());
    });

    testWidgets('when rendering the decorative map, it should ignore pointer input', (tester) async {
      await _JobLocationMapTestHelpers.pumpMap(tester: tester);
      final ignorePointer = tester.widget<IgnorePointer>(
        find.ancestor(of: find.byType(GoogleMap), matching: find.byType(IgnorePointer)).first,
      );

      expect(ignorePointer.ignoring, isTrue);
    });
  });
}
