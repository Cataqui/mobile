import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_map/job_map.dart';
import 'package:job_map/job_map_testing.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';
import 'google_maps_test_renderer.dart';
import 'job_map_frame_test_surface.dart';
import 'map_frame_engine_harness.dart';

void main() {
  late MapFrameEngineHarness engine;

  setUp(() {
    engine = MapFrameEngineHarness(mapFrameEngine: MockMapFrameEngine(), rendererSlotCount: 1);
    final mapRenderer = GoogleMapsTestRenderer()..install();
    addTearDown(mapRenderer.restore);
  });

  goldenTest(
    'when the map tiles have not arrived, it should show the location area on the themed background',
    fileName: 'job_map_frame_loading',
    constraints: const BoxConstraints.tightFor(width: 390, height: 300),
    builder: () => _JobMapFrameGoldenTestHelpers.buildMap(engine: engine),
    whilePerforming: (tester) async {
      await tester.pumpAndSettle();
      return null;
    },
  );

  goldenTest(
    'when the map frame arrives, it should show the styled job area',
    fileName: 'job_map_frame_ready',
    constraints: const BoxConstraints.tightFor(width: 390, height: 300),
    builder: () => JobMapFrameSurfaceOverride(
      builder: (context, scene, frame) => frame == null
          ? ColoredBox(color: Color(scene.backgroundColorArgb))
          : JobMapFrameTestSurface.build(context, scene, frame),
      child: _JobMapFrameGoldenTestHelpers.buildMap(engine: engine),
    ),
    whilePerforming: (tester) async {
      final mapWidget = tester.widget<JobMapFrame>(find.byType(JobMapFrame));
      final coordinator = ProviderScope.containerOf(
        tester.element(find.byType(JobMapFrame)),
        listen: false,
      ).read(mapFrameCoordinatorProvider);
      final lease = coordinator.openRouteLease();
      coordinator.updateViewport(
        lease,
        direction: 0,
        demands: [MapSceneDemand(scene: mapWidget.scene, visibleFraction: 1, distanceFromCurrent: 0)],
      );
      await tester.pump();
      engine.completeRequest(engine.requests.single.requestId, textureId: 7);
      await tester.pumpAndSettle();
      return null;
    },
  );
}

abstract final class _JobMapFrameGoldenTestHelpers {
  static Widget buildMap({required MapFrameEngineHarness engine}) => SizedBox(
    width: 390,
    height: 300,
    child: TestApp.screen(
      mediaQueryData: const MediaQueryData(size: Size(390, 300), devicePixelRatio: 1),
      providerOverrides: [
        mapFrameCoordinatorProvider.overrideWith((ref) {
          final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 24 * 1024 * 1024);
          ref.onDispose(coordinator.dispose);
          return coordinator;
        }),
      ],
      child: Center(
        child: SizedBox(
          width: 320,
          height: 240,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            child: Builder(
              builder: (context) => JobMapFrame(
                scene: JobMapScene.fromContext(
                  context: context,
                  location: (latitude: -23.55052, longitude: -46.633308),
                  areaDiameterInMeters: 1200,
                  offset: const Offset(0, 18),
                  logicalSize: const Size(320, 240),
                  devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
