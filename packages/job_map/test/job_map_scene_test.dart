import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_map/src/job_location_map_color_scheme.dart';
import 'package:job_map/src/job_location_map_style.dart';
import 'package:job_map/src/job_map_location_area.dart';
import 'package:job_map/src/job_map_scene.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import 'test_job_map_app.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('render quality varies pixels without moving the ${platform.name} map or location', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      late JobMapScene original;
      await tester.pumpWidget(
        TestJobMapApp.screen(
          child: Builder(
            builder: (context) {
              original = JobMapScene.fromContext(
                context: context,
                location: (latitude: -23.5505, longitude: -46.6333),
                areaDiameterInMeters: 1200,
                logicalSize: const Size(320, 400),
                devicePixelRatio: 3,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final compact = original.withRenderQuality(.compact);
      final sharp = original.withRenderQuality(.sharp);
      expect(original.withRenderQuality(.balanced), same(original));
      expect(compact.estimatedCachedBytes, lessThan(original.estimatedCachedBytes));
      expect(sharp.estimatedCachedBytes, greaterThan(original.estimatedCachedBytes));
      expect((compact.widthPx, compact.heightPx, compact.nativeScale), (400, 500, 1));
      expect(compact.zoom + math.log(compact.nativeScale) / math.ln2, original.zoom);
      expect(compact.widthPx / compact.widthPoints, greaterThanOrEqualTo(1.25));
      expect((sharp.widthPx, sharp.heightPx, sharp.nativeScale), (640, 800, 1));
      for (final rendered in [compact, sharp]) {
        expect(
          (
            rendered.cameraLatitude,
            rendered.cameraLongitude,
            rendered.zoom,
            rendered.widthPoints,
            rendered.heightPoints,
            rendered.paddingBottomPoints,
            rendered.styleJson,
          ),
          (
            original.cameraLatitude,
            original.cameraLongitude,
            original.zoom,
            original.widthPoints,
            original.heightPoints,
            original.paddingBottomPoints,
            original.styleJson,
          ),
        );
        expect(JobMapLocationArea.projectedArea(rendered), JobMapLocationArea.projectedArea(original));
        expect(rendered.basemap.devicePixelRatio, 3);
      }
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('compact quality keeps low zoom inside the SDK range and never invents display pixels', (tester) async {
    debugDefaultTargetPlatformOverride = .iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    late JobMapScene original;
    await tester.pumpWidget(
      TestJobMapApp.screen(
        child: Builder(
          builder: (context) {
            original = JobMapScene.fromContext(
              context: context,
              location: (latitude: 0, longitude: 0),
              areaDiameterInMeters: 1200,
              logicalSize: const Size(286, 357.5),
              devicePixelRatio: 1,
              zoom: 0,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(original.withRenderQuality(.compact).nativeScale, 1);
    expect(original.withRenderQuality(.sharp).widthPx, 286);
    expect(original.withRenderQuality(.sharp).heightPx, 358);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('iOS keeps the full native viewport while bounding the texture resolution', (tester) async {
    debugDefaultTargetPlatformOverride = .iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    late JobMapScene scene;
    await tester.pumpWidget(
      TestJobMapApp.screen(
        child: Builder(
          builder: (context) {
            scene = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.5505, longitude: -46.6333),
              areaDiameterInMeters: 1200,
              logicalSize: const Size(320, 240),
              devicePixelRatio: 3,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect((scene.nativeScale, scene.widthPx, scene.heightPx), (1, 480, 360));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Android keeps map labels and attribution at the card scale in every quality tier', (tester) async {
    debugDefaultTargetPlatformOverride = .android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    late JobMapScene scene;
    await tester.pumpWidget(
      TestJobMapApp.screen(
        child: Builder(
          builder: (context) {
            scene = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.5505, longitude: -46.6333),
              areaDiameterInMeters: 1200,
              logicalSize: const Size(320, 400),
              devicePixelRatio: 3,
              zoom: 13,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect((scene.zoom, scene.nativeScale, scene.widthPx, scene.heightPx), (13, 1, 480, 600));
    expect((scene.withRenderQuality(.compact).nativeScale, scene.withRenderQuality(.compact).widthPx), (1, 400));
    expect((scene.withRenderQuality(.sharp).nativeScale, scene.withRenderQuality(.sharp).widthPx), (1, 640));
    expect(scene.estimatedPreviewBytes, 240 * 300 * 4);
    expect(scene.withRenderQuality(.compact).estimatedPreviewBytes, 240 * 300 * 4);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('when jobs share a neighborhood, their cameras should match while their location circles stay exact', (
    tester,
  ) async {
    late JobMapScene first;
    late JobMapScene nearby;
    await tester.pumpWidget(
      TestJobMapApp.screen(
        child: Builder(
          builder: (context) {
            first = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.5505, longitude: -46.6333),
              areaDiameterInMeters: 1200,
              logicalSize: const Size(320, 400),
              devicePixelRatio: 3,
              zoom: 13,
            );
            nearby = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.5506, longitude: -46.6332),
              areaDiameterInMeters: 800,
              logicalSize: const Size(320, 400),
              devicePixelRatio: 3,
              zoom: 13,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect((nearby.cameraLatitude, nearby.cameraLongitude), (first.cameraLatitude, first.cameraLongitude));
    expect((nearby.locationLatitude, nearby.locationLongitude, nearby.radiusMeters), (-23.5506, -46.6332, 400));
    expect(nearby, isNot(first));
  });

  testWidgets('two jobs in separate quarter-width cells share one half-width basemap and keep their locations', (
    tester,
  ) async {
    late JobMapScene first;
    late JobMapScene second;
    await tester.pumpWidget(
      TestJobMapApp.screen(
        child: Builder(
          builder: (context) {
            first = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.55, longitude: -46.63352966308594),
              areaDiameterInMeters: 1200,
              logicalSize: const Size(320, 400),
              devicePixelRatio: 2,
            );
            second = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.55, longitude: -46.62494659423828),
              areaDiameterInMeters: 1200,
              logicalSize: const Size(320, 400),
              devicePixelRatio: 2,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(first.sharesBasemapWith(second), isTrue);
    expect((first.locationLongitude, second.locationLongitude), (-46.63352966308594, -46.62494659423828));
    expect(
      JobMapLocationArea.projectedArea(first).center.dx,
      isNot(JobMapLocationArea.projectedArea(second).center.dx),
    );
  });

  testWidgets('half-width snapping keeps ordinary location circles horizontally inside varied cards', (tester) async {
    final scenes = <JobMapScene>[];
    await tester.pumpWidget(
      TestJobMapApp.screen(
        child: Builder(
          builder: (context) {
            for (final (width, height, latitude) in <(double, double, double)>[
              (286, 357.5, -34.9),
              (328, 410, -23.55),
              (370, 621, 0),
            ]) {
              final worldSize = 256 * math.pow(2, 13);
              final wideCell = width / 2;
              final baseWorldX = (-46.63 / 360 * worldSize / wideCell).round() * wideCell;
              scenes.add(
                JobMapScene.fromContext(
                  context: context,
                  location: (latitude: latitude, longitude: (baseWorldX + width / 4 - 0.25) / worldSize * 360),
                  areaDiameterInMeters: 2000,
                  logicalSize: Size(width, height),
                  devicePixelRatio: 2,
                ),
              );
              expect(scenes.last.cameraLongitude, closeTo(baseWorldX / worldSize * 360, 1e-8));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    for (final scene in scenes) {
      final area = JobMapLocationArea.projectedArea(scene);
      expect(area.center.dx - area.radiusPoints, greaterThanOrEqualTo(4));
      expect(area.center.dx + area.radiusPoints, lessThanOrEqualTo(scene.widthPoints - 4));
    }
  });

  testWidgets('a wide circle or horizontal offset keeps the original quarter-width camera', (tester) async {
    late JobMapScene ordinary;
    late JobMapScene wideCircle;
    late JobMapScene shiftedCircle;
    late double wideCameraLongitude;
    late double quarterCameraLongitude;
    late double shiftedQuarterCameraLongitude;
    await tester.pumpWidget(
      TestJobMapApp.screen(
        child: Builder(
          builder: (context) {
            final worldSize = 256 * math.pow(2, 13);
            const wideCell = 320 / 2;
            final baseWorldX = (-46.6333 / 360 * worldSize / wideCell).round() * wideCell;
            final longitude = (baseWorldX + 70) / worldSize * 360;
            wideCameraLongitude = baseWorldX / worldSize * 360;
            quarterCameraLongitude = (baseWorldX + 80) / worldSize * 360;
            shiftedQuarterCameraLongitude = (baseWorldX + 80 - 50) / worldSize * 360;
            ordinary = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.55, longitude: longitude),
              areaDiameterInMeters: 1200,
              logicalSize: const Size(320, 400),
              devicePixelRatio: 2,
            );
            wideCircle = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.55, longitude: longitude),
              areaDiameterInMeters: 3000,
              logicalSize: const Size(320, 400),
              devicePixelRatio: 2,
            );
            shiftedCircle = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.55, longitude: longitude),
              areaDiameterInMeters: 1200,
              logicalSize: const Size(320, 400),
              devicePixelRatio: 2,
              offset: const Offset(50, 0),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(ordinary.cameraLongitude, closeTo(wideCameraLongitude, 1e-8));
    expect(wideCircle.cameraLongitude, closeTo(quarterCameraLongitude, 1e-8));
    expect(shiftedCircle.cameraLongitude, closeTo(shiftedQuarterCameraLongitude, 1e-8));
    expect(ordinary.locationLongitude, wideCircle.locationLongitude);
    expect(ordinary.locationLongitude, shiftedCircle.locationLongitude);
  });

  testWidgets('Android bounds texture density without shrinking the native map viewport', (tester) async {
    debugDefaultTargetPlatformOverride = .android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    late JobMapScene highDprScene;
    late JobMapScene mediumDprScene;
    late JobMapScene standardDprScene;
    await tester.pumpWidget(
      TestJobMapApp.screen(
        child: Builder(
          builder: (context) {
            highDprScene = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.5505, longitude: -46.6333),
              areaDiameterInMeters: 1200,
              logicalSize: const Size(320, 240),
              devicePixelRatio: 3,
            );
            mediumDprScene = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.5505, longitude: -46.6333),
              areaDiameterInMeters: 1200,
              logicalSize: const Size(320, 240),
              devicePixelRatio: 1.5,
            );
            standardDprScene = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.5505, longitude: -46.6333),
              areaDiameterInMeters: 1200,
              logicalSize: const Size(320, 240),
              devicePixelRatio: 1,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      (
        highPixels: (highDprScene.widthPx, highDprScene.heightPx),
        mediumPixels: (mediumDprScene.widthPx, mediumDprScene.heightPx),
        standardPixels: (standardDprScene.widthPx, standardDprScene.heightPx),
        highPoints: (highDprScene.widthPoints, highDprScene.heightPoints),
        mediumPoints: (mediumDprScene.widthPoints, mediumDprScene.heightPoints),
        padding: (highDprScene.paddingBottomPoints, mediumDprScene.paddingBottomPoints),
      ),
      (
        highPixels: (480, 360),
        mediumPixels: (480, 360),
        standardPixels: (320, 240),
        highPoints: (320, 240),
        mediumPoints: (320, 240),
        padding: (20, 20),
      ),
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('when a job map scene is built, it should preserve camera, radius, style, and attribution geometry', (
    tester,
  ) async {
    late JobMapScene scene;
    late JobLocationMapColorScheme expectedColors;
    await tester.pumpWidget(
      TestJobMapApp.screen(
        child: Builder(
          builder: (context) {
            expectedColors = JobLocationMapColorScheme.light(palette: MateoTheme.of(context).palette);
            scene = JobMapScene.fromContext(
              context: context,
              location: (latitude: 0, longitude: 0),
              areaDiameterInMeters: 1400,
              logicalSize: const Size(320, 240),
              devicePixelRatio: 1,
              zoom: 1,
              offset: const Offset(10, -20),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      (
        camera: (scene.cameraLatitude.toStringAsFixed(7), scene.cameraLongitude.toStringAsFixed(7)),
        radius: scene.radiusMeters,
        radiusColor: scene.radiusColorArgb,
        backgroundColor: scene.backgroundColorArgb,
        style: scene.styleJson,
        padding: scene.paddingBottomPoints,
      ),
      (
        camera: ('-7.0312500', '-7.0312500'),
        radius: 700,
        radiusColor: expectedColors.locationRadius.toARGB32(),
        backgroundColor: expectedColors.background.toARGB32(),
        style: JobLocationMapStyle.fromColorScheme(colorScheme: expectedColors).googleMapsJson,
        padding: 20,
      ),
    );
  });

  testWidgets('when a job area changes, it should produce a distinct map scene identity', (tester) async {
    late JobMapScene first;
    late JobMapScene changed;
    await tester.pumpWidget(
      TestJobMapApp.screen(
        child: Builder(
          builder: (context) {
            first = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.5505, longitude: -46.6333),
              areaDiameterInMeters: 1200,
              logicalSize: const Size(320, 240),
              devicePixelRatio: 2,
            );
            changed = JobMapScene.fromContext(
              context: context,
              location: (latitude: -23.5505, longitude: -46.6333),
              areaDiameterInMeters: 1400,
              logicalSize: const Size(320, 240),
              devicePixelRatio: 2,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      (sameKey: first == changed, firstRadius: first.radiusMeters, changedRadius: changed.radiusMeters),
      (sameKey: false, firstRadius: 600, changedRadius: 700),
    );
  });
}
