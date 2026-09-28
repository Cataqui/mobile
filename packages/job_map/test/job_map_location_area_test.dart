import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_map/src/job_map_location_area.dart';
import 'package:job_map/src/job_map_scene.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import 'test_job_map_app.dart';

void main() {
  JobMapScene scene({
    double cameraLatitude = 0,
    double cameraLongitude = 0,
    double locationLatitude = 0,
    double locationLongitude = 0,
    double zoom = 0,
    double radiusMeters = 1000,
    double paddingBottomPoints = 20,
    int radiusColorArgb = 0,
    double nativeScale = 1,
  }) => JobMapScene(
    cameraLatitude: cameraLatitude,
    cameraLongitude: cameraLongitude,
    locationLatitude: locationLatitude,
    locationLongitude: locationLongitude,
    zoom: zoom,
    radiusMeters: radiusMeters,
    radiusColorArgb: radiusColorArgb,
    backgroundColorArgb: 0,
    styleJson: null,
    widthPoints: 320,
    heightPoints: 240,
    paddingBottomPoints: paddingBottomPoints,
    widthPx: 480,
    heightPx: 360,
    nativeScale: nativeScale,
  );

  for (final sample in [
    (nativeScale: 1.0, padding: 20.0, logo: const Offset(20, 200), legal: const Offset(300, 210)),
    (nativeScale: .5, padding: 36.0, logo: const Offset(20, 164), legal: const Offset(300, 190)),
    (nativeScale: .25, padding: 20.0, logo: const Offset(32, 140), legal: const Offset(300, 200)),
  ]) {
    testWidgets('keeps Google attribution clear at rendered scale ${sample.nativeScale} with canonical geometry', (
      tester,
    ) async {
      late int radiusColorArgb;
      await tester.pumpWidget(
        TestJobMapApp.screen(
          child: Builder(
            builder: (context) {
              radiusColorArgb = MateoTheme.of(context).colorScheme.text.primary.toARGB32();
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(2);
      JobMapLocationArea(
        scene: scene(
          zoom: 13,
          radiusMeters: 100000,
          radiusColorArgb: radiusColorArgb,
          nativeScale: 1,
          paddingBottomPoints: sample.padding,
        ),
        attributionScale: sample.nativeScale,
      ).paint(canvas, const Size(320, 240));
      final picture = recorder.endRecording();
      addTearDown(picture.dispose);
      final image = (await tester.runAsync(() => picture.toImage(640, 480)))!;
      addTearDown(image.dispose);
      final pixels = await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.rawRgba));

      for (final point in [sample.logo, sample.legal]) {
        expect(pixels!.getUint8(((point.dy * 2).round() * 640 + (point.dx * 2).round()) * 4 + 3), 0);
      }
      for (final point in [const Offset(160, 60), const Offset(300, 235)]) {
        expect(pixels!.getUint8(((point.dy * 2).round() * 640 + (point.dx * 2).round()) * 4 + 3), greaterThan(0));
      }
    });
  }

  test('projects an equatorial location using Google Maps world coordinates and padded camera center', () {
    final area = JobMapLocationArea.projectedArea(scene(locationLongitude: 90));

    expect(area.center.dx, 224);
    expect(area.center.dy, 110);
  });

  test('projects latitude through Web Mercator rather than a linear degree scale', () {
    final area = JobMapLocationArea.projectedArea(scene(locationLatitude: 66.51326044311186));

    expect(area.center.dx, 160);
    expect(area.center.dy, closeTo(46, 0.000001));
  });

  test('uses the shortest map wrap across the antimeridian', () {
    final area = JobMapLocationArea.projectedArea(scene(cameraLongitude: 179.9, locationLongitude: -179.9, zoom: 3));

    expect(area.center.dx, closeTo(161.1377777778, 0.000001));
    expect(area.center.dy, 110);
  });

  test('uses latitude and fractional zoom to project the radius in logical map points', () {
    final equator = JobMapLocationArea.projectedArea(scene(zoom: 13));
    final latitude60 = JobMapLocationArea.projectedArea(scene(locationLatitude: 60, cameraLatitude: 60, zoom: 13));
    final fractionalZoom = JobMapLocationArea.projectedArea(scene(zoom: 13.5));

    expect(equator.radiusPoints, closeTo(52.3306585, 0.0001));
    expect(latitude60.radiusPoints, closeTo(equator.radiusPoints * 2, 0.0001));
    expect(fractionalZoom.radiusPoints, closeTo(equator.radiusPoints * 1.41421356237, 0.0001));
  });

  test('repaints attribution when only render quality changes', () {
    final original = scene();
    expect(
      JobMapLocationArea(
        scene: original,
        attributionScale: .5,
      ).shouldRepaint(JobMapLocationArea(scene: original, attributionScale: 1)),
      isTrue,
    );
  });

  test('repaints when the actual job area changes on a shared basemap', () {
    final first = scene();
    final changed = scene(locationLongitude: 0.01);

    expect(JobMapLocationArea(scene: changed).shouldRepaint(JobMapLocationArea(scene: first)), isTrue);
    expect(JobMapLocationArea(scene: first).shouldRepaint(JobMapLocationArea(scene: scene())), isFalse);
  });
}
