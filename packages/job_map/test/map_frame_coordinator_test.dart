import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_map/job_map.dart';
import 'package:job_map/job_map_testing.dart';

import 'map_frame_engine_harness.dart';
import 'mocks.dart';

void main() {
  late MapFrameEngineHarness engine;

  setUp(() {
    engine = MapFrameEngineHarness(mapFrameEngine: MockMapFrameEngine());
  });

  JobMapScene scene(
    int location, {
    int? cameraLocation,
    int widthPx = 100,
    int heightPx = 100,
    double pixelRatio = 2,
    double? devicePixelRatio,
  }) => JobMapScene(
    cameraLatitude: (cameraLocation ?? location).toDouble(),
    cameraLongitude: 0,
    locationLatitude: location.toDouble(),
    locationLongitude: 0,
    zoom: 13,
    radiusMeters: 500,
    radiusColorArgb: 0x2200AA00,
    backgroundColorArgb: 0xFFFFFFFF,
    styleJson: '[]',
    widthPoints: widthPx / pixelRatio,
    heightPoints: heightPx / pixelRatio,
    paddingBottomPoints: 20,
    widthPx: widthPx,
    heightPx: heightPx,
    devicePixelRatio: devicePixelRatio,
  );

  testWidgets('resolution pressure preserves cached maps and latches the next request at dispatch', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 1000000,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    );
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        for (var index = 1; index <= 3; index++)
          MapSceneDemand(scene: scene(index), visibleFraction: index == 1 ? 1 : 0, distanceFromCurrent: index - 1),
      ],
    );
    await tester.pump();
    expect(engine.requests.length, 2);
    budget.didHaveMemoryPressure();
    await tester.pump();
    expect(engine.requests.length, 2);
    expect(engine.requests.first.scene.widthPx, 100);
    engine.complete(engine.requests.first, textureId: 10);
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    expect(coordinator.frameFor(scene(1))?.textureId, 10);
    expect(engine.requests.length, 3);
    expect(engine.requests.last.scene.widthPx, lessThan(100));
    expect(engine.requests.last.scene.nativeScale, 1);
    engine.complete(engine.requests.last, textureId: 30);
    await tester.pump();
    expect(coordinator.frameFor(scene(3))?.textureId, 30);
    coordinator.closeRouteLease(lease);
  });

  testWidgets('quality headroom never invents extra detail on a density-one display', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 1000000,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    );
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1, pixelRatio: 1), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(2, pixelRatio: 1), visibleFraction: 0, distanceFromCurrent: 1),
      ],
    );
    await tester.pump();
    for (var frame = 0; frame < 900; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 2), frameBudget: const Duration(microseconds: 16667));
    }
    await tester.pump();
    expect(budget.quality, MapRenderQuality.sharp);
    expect(engine.requests.length, 2);
    engine.complete(engine.requests.first, textureId: 10);
    await tester.pump();
    expect(engine.requests.length, 2);
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    // The source's display density is only 1, so sharper output would just upscale it.
    expect(engine.requests.length, 2);
    coordinator.closeRouteLease(lease);
  });

  testWidgets('a settled visible map gains sharp detail without losing its complete frame', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 1,
      maxCachedBytes: 1000000,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    );
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease();
    final current = scene(1, pixelRatio: 1.5, devicePixelRatio: 3);
    coordinator.updateViewport(
      lease,
      direction: 0,
      demands: [MapSceneDemand(scene: current, visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();
    engine.complete(engine.requests.single, textureId: 10);
    await tester.pump();
    for (var frame = 0; frame < 900; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 2), frameBudget: const Duration(microseconds: 16667));
    }
    await tester.pump();

    expect(engine.requests, hasLength(2));
    expect(engine.requests.last.scene.widthPx, 133);
    expect(coordinator.frameFor(current)?.textureId, 10);
    engine.complete(engine.requests.last, textureId: 20, isFinal: false);
    await tester.pump();
    expect(coordinator.frameFor(current)?.textureId, 10);
    engine.finalize(engine.requests.last, textureId: 30);
    await tester.pump();
    expect(coordinator.frameFor(current)?.textureId, 30);
    coordinator.closeRouteLease(lease);
  });

  testWidgets('a partial quality upgrade cannot replace a complete image with holes', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 1000000,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    );
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease();
    final original = scene(2, pixelRatio: 1.5, devicePixelRatio: 3);
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: original, visibleFraction: 0, distanceFromCurrent: 1),
      ],
    );
    await tester.pump();
    for (var frame = 0; frame < 900; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 2), frameBudget: const Duration(microseconds: 16667));
    }
    await tester.pump();
    expect(engine.requests.length, 2);
    engine.complete(engine.requests.first, textureId: 10);
    await tester.pump();
    expect(engine.requests.length, 2);
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    expect(engine.requests.length, 3);
    expect(engine.requests.last.scene.widthPx, 133);
    expect(coordinator.frameFor(original)?.textureId, 20);
    engine.complete(engine.requests.last, textureId: 30, isFinal: false);
    await tester.pump();
    expect(coordinator.frameFor(original)?.textureId, 20);
    expect(engine.released.map((frame) => frame.textureId), isNot(contains(20)));
    engine.progress(engine.requests.last, textureId: 40);
    await tester.pump();
    expect(coordinator.frameFor(original)?.textureId, 20);
    expect(engine.released.map((frame) => frame.textureId), containsAll([40, 1040]));
    engine.finalize(engine.requests.last);
    await tester.pump();
    expect(coordinator.frameFor(original)?.textureId, 10003);
    expect(engine.released.map((frame) => frame.textureId), containsAll([20, 1020]));
    expect(engine.requests.length, 3);
    coordinator.closeRouteLease(lease);
  });

  testWidgets('a quality capture cannot replace a visible carousel map after scrolling starts', (tester) async {
    engine.rendererSlotCount = 1;
    final budget = MapRenderBudget(
      rendererSlotCount: 1,
      maxCachedBytes: 1000000,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    );
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease(allowSlowScrollCapture: true);
    final original = scene(1, pixelRatio: 1.5, devicePixelRatio: 3);
    final neighbor = scene(2, pixelRatio: 1.5, devicePixelRatio: 3);
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: original, visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: neighbor, visibleFraction: 0, distanceFromCurrent: 1),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests.first, textureId: 10);
    await tester.pump();
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    for (var frame = 0; frame < 900; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 2), frameBudget: const Duration(microseconds: 16667));
    }
    await tester.pump();
    expect(engine.requests, hasLength(3));

    coordinator.setRouteScrolling(lease, true);
    engine.complete(engine.requests.last, textureId: 30);
    await tester.pump();
    expect(coordinator.frameFor(original)?.textureId, 10);
    expect(coordinator.frameFor(neighbor)?.textureId, 20);
    expect(engine.released.map((frame) => frame.textureId), containsAll([30, 1030]));
    expect(engine.requests, hasLength(3));

    coordinator.setRouteScrolling(lease, false);
    await tester.pump();
    expect(engine.requests, hasLength(4));
    coordinator.closeRouteLease(lease);
  });

  testWidgets('a visible map sharpens before a prepared neighbor', (tester) async {
    engine.rendererSlotCount = 1;
    final budget = MapRenderBudget(
      rendererSlotCount: 1,
      maxCachedBytes: 1000000,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    );
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease();
    final current = scene(1, pixelRatio: 1.5, devicePixelRatio: 3);
    final neighbor = scene(2, pixelRatio: 1.5, devicePixelRatio: 3);
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: current, visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: neighbor, visibleFraction: 0, distanceFromCurrent: 1),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests.first, textureId: 10);
    await tester.pump();
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    for (var frame = 0; frame < 900; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 2), frameBudget: const Duration(microseconds: 16667));
    }
    await tester.pump();

    expect(engine.requests, hasLength(3));
    expect(engine.requests.last.scene.cameraLatitude, 1);
    expect(coordinator.frameFor(current)?.textureId, 10);
    engine.complete(engine.requests.last, textureId: 30);
    await tester.pump();
    expect(coordinator.frameFor(current)?.textureId, 30);
    expect(engine.requests, hasLength(4));
    expect(engine.requests.last.scene.cameraLatitude, 2);
    engine.complete(engine.requests.last, textureId: 40);
    await tester.pump();
    expect(coordinator.frameFor(neighbor)?.textureId, 40);
    coordinator.closeRouteLease(lease);
  });

  testWidgets('a feed map keeps its labeled image when an offscreen upgrade finishes after arrival', (tester) async {
    engine.rendererSlotCount = 1;
    final budget = MapRenderBudget(
      rendererSlotCount: 1,
      maxCachedBytes: 1000000,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    );
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease();
    final current = scene(1, pixelRatio: 1, devicePixelRatio: 1);
    final neighbor = scene(2, pixelRatio: 1.5, devicePixelRatio: 3);
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: current, visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: neighbor, visibleFraction: 0, distanceFromCurrent: 1),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests.first, textureId: 10);
    await tester.pump();
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    for (var frame = 0; frame < 900; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 2), frameBudget: const Duration(microseconds: 16667));
    }
    await tester.pump();
    expect(engine.requests, hasLength(3));
    expect(engine.requests.last.scene.cameraLatitude, 2);
    final qualityRequest = engine.requests.last;

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: current, visibleFraction: 0, distanceFromCurrent: -1),
        MapSceneDemand(scene: neighbor, visibleFraction: 1, distanceFromCurrent: 0),
      ],
    );
    await tester.pump();
    engine.complete(qualityRequest, textureId: 30);
    await tester.pump();

    expect(coordinator.frameFor(neighbor)?.textureId, 20);
    expect(engine.released.map((frame) => frame.textureId), containsAll([30, 1030]));
    coordinator.closeRouteLease(lease);
  });

  testWidgets('a missing arrival preempts a quality upgrade even during a fast fling', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 1,
      maxCachedBytes: 1000000,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    );
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease();
    final original = scene(1, pixelRatio: 1, devicePixelRatio: 1);
    final neighbor = scene(2, pixelRatio: 1.5, devicePixelRatio: 3);
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: original, visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: neighbor, visibleFraction: 0, distanceFromCurrent: 1),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests.first, textureId: 10);
    await tester.pump();
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    for (var frame = 0; frame < 900; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 2), frameBudget: const Duration(microseconds: 16667));
    }
    await tester.pump();
    expect(engine.requests.length, 3);
    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        demands: [
          MapSceneDemand(scene: original, visibleFraction: .5, distanceFromCurrent: 0),
          MapSceneDemand(scene: scene(3), visibleFraction: .5, distanceFromCurrent: 2),
          MapSceneDemand(scene: neighbor, visibleFraction: 0, distanceFromCurrent: 1),
        ],
      );
    await tester.pump();
    expect(engine.requests.length, 4);
    expect(engine.requests.last.scene.cameraLatitude, 3);
    engine.complete(engine.requests[2], textureId: 30, isFinal: false);
    engine.complete(engine.requests.last, textureId: 40);
    await tester.pump();
    expect(coordinator.frameFor(original)?.textureId, 10);
    expect(engine.released.map((frame) => frame.textureId), containsAll([30, 1030]));
    coordinator.setRouteScrolling(lease, false);
    await tester.pump();
    expect(engine.requests.length, 5);
    expect(engine.requests.last.scene.cameraLatitude, 2);
    engine.complete(engine.requests.last, textureId: 50);
    await tester.pump();
    expect(coordinator.frameFor(original)?.textureId, 10);
    expect(coordinator.frameFor(neighbor)?.textureId, 50);
    coordinator.closeRouteLease(lease);
  });

  testWidgets('memory pressure plans compact frame bytes and still includes a distant explicit arrival', (
    tester,
  ) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 180000,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    )..didHaveMemoryPressure();
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 180000,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease();
    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        demands: [
          for (var index = 1; index <= 6; index++)
            MapSceneDemand(
              scene: scene(index),
              visibleFraction: index == 1 ? 1 : 0,
              distanceFromCurrent: index - 1,
              distanceFromArrival: index == 6 ? 0 : null,
            ),
        ],
      );
    await tester.pump();
    for (var index = 0; index < 6; index++) {
      expect(engine.requests.length, index + 1);
      engine.complete(engine.requests[index], textureId: 10 * (index + 1));
      await tester.pump();
    }
    expect(engine.requests.map((request) => request.scene.cameraLatitude), [1, 6, 2, 3, 4, 5]);
    expect(engine.requests.length, 6);
    expect(coordinator.cachedBytes, lessThan(180000));
    coordinator.closeRouteLease(lease);
  });

  testWidgets('memory pressure discards a pending quality image and ignores its late final event', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 1000000,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    );
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease();
    final original = scene(1, pixelRatio: 1.5, devicePixelRatio: 3);
    final neighbor = scene(2, pixelRatio: 1.5, devicePixelRatio: 3);
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: original, visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: neighbor, visibleFraction: 0, distanceFromCurrent: 1),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests.first, textureId: 10);
    await tester.pump();
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    for (var frame = 0; frame < 900; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 2), frameBudget: const Duration(microseconds: 16667));
    }
    await tester.pump();
    expect(engine.requests.length, 3);
    engine.complete(engine.requests.last, textureId: 30, isFinal: false);
    await tester.pump();
    budget.didHaveMemoryPressure();
    await tester.pump();
    engine.finalize(engine.requests.last);
    await tester.pump();
    expect(coordinator.frameFor(original)?.textureId, 10);
    expect(coordinator.frameFor(neighbor)?.textureId, 20);
    expect(engine.released.map((frame) => frame.textureId), containsAll([30, 1030]));
    expect(engine.requests.length, 3);
    coordinator.closeRouteLease(lease);
  });

  for (final size in [(width: 740, height: 1242), (width: 960, height: 1600)]) {
    testWidgets('a sharp ${size.width} pixel map under pressure still preloads without a render loop', (tester) async {
      final budget = MapRenderBudget(
        rendererSlotCount: 2,
        maxCachedBytes: 8 * 1024 * 1024,
        readCapabilities: () async => throw StateError('Telemetry unavailable'),
      );
      final coordinator = MapFrameCoordinator(
        engine: engine.mapFrameEngine,
        maxCachedBytes: 8 * 1024 * 1024,
        renderBudget: budget,
      );
      addTearDown(() {
        coordinator.dispose();
        budget.dispose();
      });
      final lease = coordinator.openRouteLease();
      final visibleScene = scene(1, widthPx: size.width, heightPx: size.height, pixelRatio: 2, devicePixelRatio: 3);
      final nextScene = scene(2, widthPx: size.width, heightPx: size.height, pixelRatio: 2, devicePixelRatio: 3);
      coordinator.updateViewport(
        lease,
        direction: 1,
        demands: [MapSceneDemand(scene: visibleScene, visibleFraction: 1, distanceFromCurrent: 0)],
      );
      await tester.pump();
      engine.complete(engine.requests.single, textureId: 10);
      await tester.pump();
      budget.didHaveMemoryPressure();
      coordinator.updateViewport(
        lease,
        direction: 1,
        demands: [
          MapSceneDemand(scene: visibleScene, visibleFraction: 1, distanceFromCurrent: 0),
          MapSceneDemand(scene: nextScene, visibleFraction: 0, distanceFromCurrent: 1),
        ],
      );
      await tester.pump();
      expect(engine.requests.length, 2);
      engine.complete(engine.requests.last, textureId: 20);
      await tester.pump();
      expect(coordinator.frameFor(visibleScene)?.textureId, 10);
      expect(coordinator.frameFor(nextScene)?.textureId, 1020);
      expect(coordinator.cachedBytes, lessThanOrEqualTo(8 * 1024 * 1024));
      expect(engine.released.map((frame) => frame.textureId), containsAll([1010, 20]));
      await tester.pump(const Duration(seconds: 1));
      expect(engine.requests.length, 2);
      coordinator.closeRouteLease(lease);
    });
  }

  testWidgets('pressure keeps the next cached preview instead of a farther cached neighbor', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 24 * 1024 * 1024,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    );
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 24 * 1024 * 1024,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease();
    final scenes = [
      for (var index = 1; index <= 3; index++)
        scene(index, widthPx: 960, heightPx: 1600, pixelRatio: 2, devicePixelRatio: 3),
    ];
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        for (var index = 0; index < scenes.length; index++)
          MapSceneDemand(scene: scenes[index], visibleFraction: index == 0 ? 1 : 0, distanceFromCurrent: index),
      ],
    );
    await tester.pump();
    for (var index = 0; index < 3; index++) {
      engine.complete(engine.requests[index], textureId: 10 * (index + 1));
      await tester.pump();
    }
    budget.didHaveMemoryPressure();
    coordinator.didHaveMemoryPressure();
    await tester.pump();
    expect(coordinator.frameFor(scenes.first)?.textureId, 10);
    expect(coordinator.frameFor(scenes[1])?.textureId, 1020);
    expect(coordinator.frameFor(scenes[2]), isNull);
    expect(engine.requests.length, 3);
    coordinator.closeRouteLease(lease);
  });

  testWidgets('pressure backoff lets in-flight maps finish and starts only one new request', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 400000,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    );
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 400000,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        for (var location = 1; location <= 5; location++)
          MapSceneDemand(
            scene: scene(location),
            visibleFraction: location == 1 ? 1 : 0,
            distanceFromCurrent: location - 1,
          ),
      ],
    );
    await tester.pump();
    expect(engine.requests.length, 2);
    budget.didHaveMemoryPressure();
    await tester.pump();
    engine.complete(engine.requests.first, textureId: 10);
    await tester.pump();
    expect(engine.requests.length, 2);
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.cameraLatitude), [1, 2, 3]);
    expect(coordinator.frameFor(scene(1))?.textureId, 10);
    coordinator.closeRouteLease(lease);
  });

  testWidgets('pressure backoff does not reuse a preview slot while another cold map is still loading', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 400000,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    );
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 400000,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease();
    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        demands: [
          MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
          MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1),
        ],
      );
    await tester.pump();
    engine.complete(engine.requests.first, textureId: 10, isFinal: false);
    budget.didHaveMemoryPressure();
    await tester.pump();
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [MapSceneDemand(scene: scene(3), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();
    expect(engine.requests.length, 2);
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.cameraLatitude), [1, 2, 3]);
    coordinator.closeRouteLease(lease);
  });

  testWidgets('when the current route scrolls, it should pause native full captures until motion ends', (tester) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 120000);
    addTearDown(coordinator.dispose);
    final feedLease = coordinator.openRouteLease();
    final meLease = coordinator.openRouteLease(visible: false);

    coordinator
      ..setRouteScrolling(feedLease, true)
      ..setRouteScrolling(meLease, true)
      ..setRouteVisible(feedLease, false)
      ..setRouteVisible(meLease, true)
      ..setRouteScrolling(meLease, false);

    expect(engine.scrollActivityChanges, [true, false, true, false]);
  });

  testWidgets('idle Feed demand prepares the next and previous cards before farther forward cards', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 300000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(5), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(6), visibleFraction: 0, distanceFromCurrent: 1),
        MapSceneDemand(scene: scene(7), visibleFraction: 0, distanceFromCurrent: 2),
        MapSceneDemand(scene: scene(4), visibleFraction: 0, distanceFromCurrent: -1),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests[0], textureId: 10);
    await tester.pump();
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();

    expect(engine.requests.map((request) => request.scene.cameraLatitude).take(3), [5, 6, 4]);
  });

  testWidgets('carousel slow motion finishes labels before finger release, while fast motion still defers', (
    tester,
  ) async {
    var elapsed = Duration.zero;
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 120000,
      readElapsedTime: () => elapsed,
    );
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease(allowSlowScrollCapture: true);

    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        position: 0,
        demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
      );
    await tester.pump();
    engine.complete(engine.requests.single, textureId: 10, isFinal: false);
    await tester.pump();
    expect(engine.scrollActivityChanges, [true]);
    expect(coordinator.frameFor(scene(1))?.textureId, 10);

    elapsed = const Duration(milliseconds: 100);
    coordinator.updateViewport(
      lease,
      direction: 1,
      position: .05,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();
    expect(engine.scrollActivityChanges, [true, false]);
    engine.finalize(engine.requests.single, textureId: 20);
    await tester.pump();
    expect(coordinator.frameFor(scene(1))?.textureId, 20);

    elapsed = const Duration(milliseconds: 150);
    coordinator.updateViewport(
      lease,
      direction: 1,
      position: .45,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    expect(engine.scrollActivityChanges, [true, false, true]);

    elapsed = const Duration(milliseconds: 270);
    await tester.pump(const Duration(milliseconds: 120));
    expect(engine.scrollActivityChanges, [true, false, true, false]);
  });

  testWidgets('SDK-ready preview replaces a partial map during an iOS drag before the final capture', (tester) async {
    var elapsed = Duration.zero;
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 120000,
      readElapsedTime: () => elapsed,
    );
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease(skipIntermediateMapsOnRapidScroll: true);
    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        position: 0,
        demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
      );
    await tester.pump();
    final request = engine.requests.single;
    engine.complete(request, textureId: 10, isFinal: false);
    await tester.pump();

    elapsed = const Duration(milliseconds: 100);
    coordinator.updateViewport(
      lease,
      direction: 1,
      position: .05,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    expect(engine.scrollActivityChanges, [true, true]);
    expect(engine.readyPreviewChanges, [false, true]);

    engine.progress(request, textureId: 20);
    await tester.pump();
    expect(coordinator.frameFor(scene(1))?.textureId, 20);

    coordinator.setRouteScrolling(lease, false);
    engine.finalize(request, textureId: 30);
    await tester.pump();
    expect(coordinator.frameFor(scene(1))?.textureId, 30);
    expect(engine.scrollActivityChanges, [true, true, false]);
  });

  testWidgets('one available renderer prioritizes the visible map over a distant fling destination', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 400000,
      readCapabilities: () async => throw StateError('Telemetry unavailable'),
    )..didHaveMemoryPressure();
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 400000,
      renderBudget: budget,
    );
    addTearDown(() {
      coordinator.dispose();
      budget.dispose();
    });
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(10), visibleFraction: 0, distanceFromCurrent: 9, distanceFromArrival: 0),
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
      ],
    );
    await tester.pump();
    expect(engine.requests.single.scene.cameraLatitude, 1);
    coordinator.closeRouteLease(lease);
  });

  testWidgets('a rejected hidden demand cannot suppress a visible job sharing its basemap', (tester) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 50000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(10), visibleFraction: 0, distanceFromCurrent: 9, distanceFromArrival: 0),
        MapSceneDemand(
          scene: scene(9, cameraLocation: 1),
          visibleFraction: 0,
          distanceFromCurrent: 8,
          distanceFromArrival: 1,
        ),
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
      ],
    );
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.cameraLatitude), [10, 1]);
  });

  testWidgets('when the splash waits for nearby maps, it should release after the first three frames arrive', (
    tester,
  ) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 160000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    var ready = false;
    final wait = coordinator.waitForPreparedScenes(count: 3, timeout: const Duration(seconds: 5)).then((value) {
      ready = value;
    });
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1),
        MapSceneDemand(scene: scene(3), visibleFraction: 0, distanceFromCurrent: 2),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests[0], textureId: 10);
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    await tester.pump();

    expect(ready, isFalse);
    expect(engine.requests.length, 3);

    engine.complete(engine.requests[2], textureId: 30);
    await tester.pump();
    await wait;

    expect(ready, isTrue);
  });

  testWidgets('when maps are demanded, it should start visible and forward scenes asynchronously', (tester) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 160000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1), visibleFraction: 0, distanceFromCurrent: -1),
        MapSceneDemand(scene: scene(2), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(3), visibleFraction: 0, distanceFromCurrent: 1),
      ],
    );
    final requestsBeforeFrame = engine.requests.length;
    await tester.pump();
    final initialOrder = engine.requests.map((request) => request.scene.locationLatitude.toInt()).join(',');

    engine.complete(engine.requests.first, textureId: 20);
    await tester.pump();
    await tester.pump();
    expect((requestsBeforeFrame, initialOrder, engine.requests.last.scene.locationLatitude), (0, '2,3', 1));
  });

  testWidgets('when planning ahead, it should budget both full and preview textures to avoid render churn', (
    tester,
  ) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 120000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1),
        MapSceneDemand(scene: scene(3), visibleFraction: 0, distanceFromCurrent: 2),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests[0], textureId: 10);
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    await tester.pump();

    expect((engine.requests.length, coordinator.cachedBytes), (2, 91552));
  });

  testWidgets('older cached previews do not make idle offscreen prefetch rerender in a loop', (tester) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 150000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    for (var location = 1; location <= 5; location++) {
      coordinator.updateViewport(
        lease,
        direction: 1,
        demands: [MapSceneDemand(scene: scene(location), visibleFraction: 1, distanceFromCurrent: 0)],
      );
      await tester.pump();
      engine.complete(engine.requests.last, textureId: location * 10);
      await tester.pump();
    }

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(5), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(6), visibleFraction: 0, distanceFromCurrent: 1),
        MapSceneDemand(scene: scene(7), visibleFraction: 0, distanceFromCurrent: 2),
      ],
    );
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2, 3, 4, 5, 6, 7]);

    engine.complete(engine.requests[5], textureId: 60);
    engine.complete(engine.requests[6], textureId: 70);
    await tester.pump();
    await tester.pump();

    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2, 3, 4, 5, 6, 7]);
    expect(coordinator.frameFor(scene(6)), isNotNull);
    expect(coordinator.frameFor(scene(7)), isNotNull);
  });

  testWidgets('when output density changes for loaded map tiles, it should reuse that native renderer slot', (
    tester,
  ) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 160000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests[0], textureId: 10);
    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(
          scene: scene(3, cameraLocation: 2, widthPx: 150, heightPx: 150, pixelRatio: 3),
          visibleFraction: 1,
          distanceFromCurrent: 0,
        ),
      ],
    );
    await tester.pump();

    expect(engine.requests.last.rendererSlot, 1);
  });

  testWidgets('when many cold jobs share a neighborhood, they should display one Google frame without rerendering', (
    tester,
  ) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 120000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    final jobs = [for (var index = 0; index < 20; index++) scene(index + 1, cameraLocation: 1)];
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        for (var index = 0; index < jobs.length; index++)
          MapSceneDemand(scene: jobs[index], visibleFraction: index == 0 ? 1 : 0, distanceFromCurrent: index),
      ],
    );
    await tester.pump();

    expect(engine.requests.length, 1);
    expect(engine.requests.single.scene.radiusMeters, 0);
    engine.complete(engine.requests.single, textureId: 10);
    await tester.pump();

    expect(jobs.map((job) => coordinator.frameFor(job)?.textureId).toSet(), {10});
    expect((engine.requests.length, coordinator.cachedBytes), (1, 45776));
  });

  testWidgets('when a viewport changes, it should start rendering without waiting for another frame', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 80000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));

    expect(engine.requests.map((request) => request.scene.locationLatitude), [1]);
  });

  testWidgets('when fast scrolling passes cold maps, it should finish requests instead of restarting every card', (
    tester,
  ) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 400000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator.setRouteScrolling(lease, true);
    for (var current = 1; current <= 4; current++) {
      coordinator.updateViewport(
        lease,
        direction: 1,
        demands: [
          for (var location = current; location < current + 6; location++)
            MapSceneDemand(
              scene: scene(location),
              visibleFraction: location == current ? 1 : 0,
              distanceFromCurrent: location - current,
            ),
        ],
      );
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(engine.requests.map((request) => request.scene.cameraLatitude), [1, 2]);
    engine.complete(engine.requests.first, textureId: 10);
    await tester.pump();
    expect(coordinator.frameFor(scene(1))?.textureId, 10);
    expect(engine.requests.last.scene.cameraLatitude, 4);
    coordinator.setRouteScrolling(lease, false);
    await tester.pump();
    expect(engine.requests.last.scene.cameraLatitude, 5);
  });

  for (final (loadDuration, expectedCameras) in [
    (const Duration(milliseconds: 80), <double>{4, 5}),
    (const Duration(milliseconds: 240), <double>{4, 6}),
  ]) {
    testWidgets('the first ${loadDuration.inMilliseconds} ms warm carousel frame predicts the next maps', (
      tester,
    ) async {
      var elapsedTime = Duration.zero;
      final coordinator = MapFrameCoordinator(
        engine: engine.mapFrameEngine,
        maxCachedBytes: 400000,
        readElapsedTime: () => elapsedTime,
      );
      addTearDown(coordinator.dispose);
      final lease = coordinator.openRouteLease();

      coordinator.updateViewport(
        lease,
        direction: 1,
        demands: [
          MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
          MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1),
        ],
      );
      await tester.pump();
      expect(engine.requests.length, 2);
      engine.complete(engine.requests[0], textureId: 10);
      engine.complete(engine.requests[1], textureId: 20);
      await tester.pump();

      coordinator.updateViewport(
        lease,
        direction: 1,
        demands: [MapSceneDemand(scene: scene(3), visibleFraction: 1, distanceFromCurrent: 0)],
      );
      await tester.pump();
      expect(engine.requests.length, 3);
      // This is a new city on an initialized renderer, not another SDK startup sample.
      elapsedTime += loadDuration;
      engine.complete(engine.requests[2], textureId: 30);
      await tester.pump();

      coordinator
        ..setRouteScrolling(lease, true)
        ..updateViewport(
          lease,
          direction: 1,
          position: 0,
          demands: [MapSceneDemand(scene: scene(3), visibleFraction: 1, distanceFromCurrent: 0)],
        );
      elapsedTime += const Duration(milliseconds: 50);
      coordinator.updateViewport(
        lease,
        direction: 1,
        position: .6,
        demands: [
          MapSceneDemand(scene: scene(3), visibleFraction: 1, distanceFromCurrent: 0),
          for (var location = 4; location <= 7; location++)
            MapSceneDemand(scene: scene(location), visibleFraction: 0, distanceFromCurrent: location - 3),
        ],
      );
      await tester.pump();

      // At 12 cards/s, use the first measured load time to choose nearby work.
      // Blending either load time with the 400 ms seed instead chooses card 7.
      expect(engine.requests.length, 5);
      expect(engine.requests.skip(3).take(2).map((request) => request.scene.cameraLatitude).toSet(), expectedCameras);
    });
  }

  testWidgets('Feed scrolling keeps the adjacent card ahead of a distant velocity prediction', (tester) async {
    engine.rendererSlotCount = 1;
    var elapsed = Duration.zero;
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      readElapsedTime: () => elapsed,
    );
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease(predictDistantMaps: false);
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [MapSceneDemand(scene: scene(0), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();
    engine.complete(engine.requests.single, textureId: 10);
    await tester.pump();

    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        position: 0,
        demands: [MapSceneDemand(scene: scene(0), visibleFraction: 1, distanceFromCurrent: 0)],
      );
    elapsed = const Duration(milliseconds: 50);
    coordinator.updateViewport(
      lease,
      direction: 1,
      position: .6,
      demands: [
        MapSceneDemand(scene: scene(0), visibleFraction: .4, distanceFromCurrent: -1),
        MapSceneDemand(scene: scene(1), visibleFraction: .6, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1),
        MapSceneDemand(scene: scene(3), visibleFraction: 0, distanceFromCurrent: 2),
        MapSceneDemand(scene: scene(6), visibleFraction: 0, distanceFromCurrent: 5),
      ],
    );
    await tester.pump();

    expect(engine.requests.last.scene.cameraLatitude, 1);
  });

  testWidgets('when a fast fling crosses cards, it should keep rendering the predicted arrival', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 120000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(9), visibleFraction: 0, distanceFromCurrent: 8, distanceFromArrival: 1),
        MapSceneDemand(scene: scene(10), visibleFraction: 0, distanceFromCurrent: 9, distanceFromArrival: 0),
      ],
    );
    await tester.pump();
    final arrivalRequest = engine.requests.single;

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(2), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(9), visibleFraction: 0, distanceFromCurrent: 7, distanceFromArrival: 1),
        MapSceneDemand(scene: scene(10), visibleFraction: 0, distanceFromCurrent: 8, distanceFromArrival: 0),
      ],
    );
    await tester.pump();
    final requestCountDuringTransit = engine.requests.length;
    engine.complete(arrivalRequest, textureId: 10);
    await tester.pump();
    await tester.pump();

    expect(
      (
        arrivalRequest.scene.locationLatitude,
        requestCountDuringTransit,
        coordinator.frameFor(scene(10))?.textureId,
        engine.requests.last.scene.locationLatitude,
      ),
      (10, 1, 10, 9),
    );
  });

  testWidgets('a fast carousel sweep prepares the landing area before transient middle cards', (tester) async {
    var elapsed = Duration.zero;
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      readElapsedTime: () => elapsed,
    );
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease(skipIntermediateMapsOnRapidScroll: true);
    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        position: 0,
        demands: [MapSceneDemand(scene: scene(0), visibleFraction: 1, distanceFromCurrent: 0)],
      );
    await tester.pump();
    engine.complete(engine.requests.single, textureId: 10);
    await tester.pump();

    elapsed = const Duration(milliseconds: 50);
    expect(coordinator.predictTravelCards(lease, position: .6), 5);
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(0), visibleFraction: .4, distanceFromCurrent: -1),
        MapSceneDemand(scene: scene(1), visibleFraction: .6, distanceFromCurrent: 0),
        for (var index = 2; index <= 8; index++)
          MapSceneDemand(scene: scene(index), visibleFraction: 0, distanceFromCurrent: index - 1),
      ],
    );
    await tester.pump();
    expect(engine.requests.skip(1).map((request) => request.scene.locationLatitude), [6, 1]);

    engine.complete(engine.requests.last, textureId: 11);
    await tester.pump();
    expect(engine.requests.last.scene.locationLatitude, anyOf(5, 7));

    elapsed = const Duration(milliseconds: 250);
    expect(coordinator.predictTravelCards(lease, position: .65), lessThan(3));
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(0), visibleFraction: .35, distanceFromCurrent: -1),
        MapSceneDemand(scene: scene(1), visibleFraction: .65, distanceFromCurrent: 0),
        for (var index = 2; index <= 8; index++)
          MapSceneDemand(scene: scene(index), visibleFraction: 0, distanceFromCurrent: index - 1),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests.last, textureId: 17);
    await tester.pump();
    expect(engine.requests.last.scene.locationLatitude, 2);
  });

  testWidgets('iOS fast carousel motion skips an uncached visible card that will pass before its map is ready', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = .iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    var elapsed = Duration.zero;
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      readElapsedTime: () => elapsed,
    );
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease(skipIntermediateMapsOnRapidScroll: true);
    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        position: 0,
        demands: [MapSceneDemand(scene: scene(0), visibleFraction: 1, distanceFromCurrent: 0)],
      );
    await tester.pump();
    engine.complete(engine.requests.single, textureId: 10);
    await tester.pump();

    elapsed = const Duration(milliseconds: 50);
    expect(coordinator.predictTravelCards(lease, position: .6), 5);
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(0), visibleFraction: .4, distanceFromCurrent: -1),
        MapSceneDemand(scene: scene(1), visibleFraction: .6, distanceFromCurrent: 0),
        for (var index = 2; index <= 8; index++)
          MapSceneDemand(scene: scene(index), visibleFraction: 0, distanceFromCurrent: index - 1),
      ],
    );
    await tester.pump();

    expect(engine.requests.skip(1).map((request) => request.scene.locationLatitude), isNot(contains(1)));
    expect(engine.requests.skip(1).map((request) => request.scene.locationLatitude), contains(6));

    coordinator.setRouteScrolling(lease, false);
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), contains(1));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a slow carousel drag still prepares each nearby card in order', (tester) async {
    engine.rendererSlotCount = 1;
    var elapsed = Duration.zero;
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      readElapsedTime: () => elapsed,
    );
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease(skipIntermediateMapsOnRapidScroll: true);
    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        position: 0,
        demands: [MapSceneDemand(scene: scene(0), visibleFraction: 1, distanceFromCurrent: 0)],
      );
    await tester.pump();
    engine.complete(engine.requests.single, textureId: 10);
    await tester.pump();

    elapsed = const Duration(milliseconds: 100);
    coordinator.updateViewport(
      lease,
      direction: 1,
      position: .3,
      demands: [
        MapSceneDemand(scene: scene(0), visibleFraction: .7, distanceFromCurrent: 0),
        for (var index = 1; index <= 6; index++)
          MapSceneDemand(scene: scene(index), visibleFraction: index == 1 ? .3 : 0, distanceFromCurrent: index),
      ],
    );
    await tester.pump();
    expect(engine.requests.last.scene.locationLatitude, 1);
    engine.complete(engine.requests.last, textureId: 11);
    await tester.pump();
    expect(engine.requests.last.scene.locationLatitude, 2);
    engine.complete(engine.requests.last, textureId: 12);
    await tester.pump();
    expect(engine.requests.last.scene.locationLatitude, 3);
  });

  testWidgets('fast carousel motion retargets one stale renderer without restarting both', (tester) async {
    var elapsed = Duration.zero;
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      readElapsedTime: () => elapsed,
    );
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease(skipIntermediateMapsOnRapidScroll: true);
    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        position: 0,
        demands: [
          MapSceneDemand(scene: scene(0), visibleFraction: 1, distanceFromCurrent: 0),
          MapSceneDemand(scene: scene(1), visibleFraction: 0, distanceFromCurrent: 1),
        ],
      );
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), [0, 1]);

    elapsed = const Duration(milliseconds: 150);
    coordinator.updateViewport(
      lease,
      direction: 1,
      position: 2.6,
      demands: [
        MapSceneDemand(scene: scene(2), visibleFraction: .4, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(3), visibleFraction: .6, distanceFromCurrent: 1),
        for (var index = 4; index <= 12; index++)
          MapSceneDemand(scene: scene(index), visibleFraction: 0, distanceFromCurrent: index - 2),
      ],
    );
    await tester.pump();
    expect(engine.requests, hasLength(3));
    expect(engine.requests.last.scene.locationLatitude, greaterThanOrEqualTo(8));

    elapsed = const Duration(milliseconds: 200);
    coordinator.updateViewport(
      lease,
      direction: 1,
      position: 3.3,
      demands: [
        MapSceneDemand(scene: scene(3), visibleFraction: .7, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(4), visibleFraction: .3, distanceFromCurrent: 1),
        for (var index = 5; index <= 12; index++)
          MapSceneDemand(scene: scene(index), visibleFraction: 0, distanceFromCurrent: index - 3),
      ],
    );
    await tester.pump();
    expect(engine.requests, hasLength(3));

    elapsed = const Duration(milliseconds: 600);
    coordinator.updateViewport(
      lease,
      direction: 1,
      position: 7,
      demands: [
        MapSceneDemand(scene: scene(7), visibleFraction: 1, distanceFromCurrent: 0),
        for (var index = 8; index <= 12; index++)
          MapSceneDemand(scene: scene(index), visibleFraction: 0, distanceFromCurrent: index - 7),
      ],
    );
    await tester.pump();
    expect(engine.requests, hasLength(4));
    expect(engine.requests.last.scene.locationLatitude, greaterThanOrEqualTo(11));
  });

  testWidgets('one renderer finishes its cold map before chasing a fast carousel prediction', (tester) async {
    engine.rendererSlotCount = 1;
    var elapsed = Duration.zero;
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 1000000,
      readElapsedTime: () => elapsed,
    );
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease(skipIntermediateMapsOnRapidScroll: true);
    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        position: 0,
        demands: [MapSceneDemand(scene: scene(0), visibleFraction: 1, distanceFromCurrent: 0)],
      );
    await tester.pump();
    expect(engine.requests, hasLength(1));

    elapsed = const Duration(milliseconds: 150);
    coordinator.updateViewport(
      lease,
      direction: 1,
      position: 2.6,
      demands: [
        MapSceneDemand(scene: scene(2), visibleFraction: .4, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(3), visibleFraction: .6, distanceFromCurrent: 1),
        for (var index = 4; index <= 12; index++)
          MapSceneDemand(scene: scene(index), visibleFraction: 0, distanceFromCurrent: index - 2),
      ],
    );
    await tester.pump();
    expect(engine.requests, hasLength(1));
    engine.complete(engine.requests.single, textureId: 10);
    await tester.pump();
    expect(engine.requests.last.scene.locationLatitude, greaterThanOrEqualTo(8));
  });

  testWidgets('when a visible map has early detail, it should keep its renderer while the spare slot prepares next', (
    tester,
  ) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 160000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1),
        MapSceneDemand(scene: scene(3), visibleFraction: 0, distanceFromCurrent: 2),
      ],
    );
    await tester.pump();
    final current = engine.requests.first;
    engine.complete(current, textureId: 10, isFinal: false);
    await tester.pump();
    await tester.pump();

    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2]);
    expect(coordinator.frameFor(scene(1))?.textureId, 10);

    engine.finalize(current);
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2, 3]);
  });

  testWidgets('while settled, the next map finishes its labels before its renderer is reused', (tester) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 1000000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        for (var index = 1; index <= 4; index++)
          MapSceneDemand(scene: scene(index), visibleFraction: index == 1 ? 1 : 0, distanceFromCurrent: index - 1),
      ],
    );
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2]);

    final next = engine.requests[1];
    engine.complete(engine.requests.first, textureId: 10);
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2, 3]);

    engine.complete(next, textureId: 20, isFinal: false);
    await tester.pump();
    expect(coordinator.frameFor(scene(2))?.textureId, 20);
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2, 3]);

    engine.finalize(next, textureId: 25);
    await tester.pump();
    expect(coordinator.frameFor(scene(2))?.textureId, 25);
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2, 3, 4]);
  });

  testWidgets('when a fast fling predicts an arrival, its neighbor should not replace the visible map', (tester) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 160000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();
    final visibleRequest = engine.requests.single;
    engine.complete(visibleRequest, textureId: 10, isFinal: false);
    await tester.pump();

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(9), visibleFraction: 0, distanceFromCurrent: 8, distanceFromArrival: 1),
        MapSceneDemand(scene: scene(10), visibleFraction: 0, distanceFromCurrent: 9, distanceFromArrival: 0),
      ],
    );
    await tester.pump();

    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 10]);
    expect(coordinator.frameFor(scene(1))?.textureId, 10);
    engine.finalize(visibleRequest);
    await tester.pump();
  });

  testWidgets('when final notification precedes the early render response, it should free the slot', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 120000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1),
      ],
    );
    await tester.pump();
    final current = engine.requests.single;
    engine
      ..finalize(current)
      ..complete(current, textureId: 10, isFinal: false);
    await tester.pump();
    await tester.pump();

    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2]);
  });

  testWidgets('when scrolling across two preview maps, it should prepare more maps before final detail arrives', (
    tester,
  ) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 240000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        demands: [
          MapSceneDemand(scene: scene(1), visibleFraction: .6, distanceFromCurrent: 0),
          MapSceneDemand(scene: scene(2), visibleFraction: .4, distanceFromCurrent: 1),
          MapSceneDemand(scene: scene(3), visibleFraction: 0, distanceFromCurrent: 2),
          MapSceneDemand(scene: scene(4), visibleFraction: 0, distanceFromCurrent: 3),
        ],
      );
    await tester.pump();
    engine.complete(engine.requests[0], textureId: 10, isFinal: false);
    engine.complete(engine.requests[1], textureId: 20, isFinal: false);
    await tester.pump();

    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2, 3, 4]);
    expect(coordinator.frameFor(scene(1))?.textureId, 10);
    expect(coordinator.frameFor(scene(2))?.textureId, 20);

    engine.complete(engine.requests[2], textureId: 30);
    engine.complete(engine.requests[3], textureId: 40);
    await tester.pump();
    coordinator.setRouteScrolling(lease, false);
    await tester.pump();

    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2, 3, 4, 1, 2]);
  });

  testWidgets('when a fling has a distant landing, it should reserve a renderer for a visible cold map', (
    tester,
  ) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 160000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        demands: [
          MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
          MapSceneDemand(scene: scene(9), visibleFraction: 0, distanceFromCurrent: 8, distanceFromArrival: 1),
          MapSceneDemand(scene: scene(10), visibleFraction: 0, distanceFromCurrent: 9, distanceFromArrival: 0),
        ],
      );
    await tester.pump();

    expect(engine.requests.map((request) => request.scene.locationLatitude), [10, 1]);
  });

  testWidgets('when an early map loses its renderer, it should refresh once visible again', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 120000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();
    engine.complete(engine.requests.single, textureId: 10, isFinal: false);
    await tester.pump();

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1, distanceFromArrival: 0),
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests.last, textureId: 20);
    await tester.pump();

    coordinator.updateViewport(
      lease,
      direction: 0,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();

    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2, 1]);
    expect(coordinator.frameFor(scene(1))?.textureId, 10);
  });

  for (final rendererSlots in [1, 2]) {
    testWidgets(
      'a settled partial uses the next free renderer without interrupting cold work (capacity $rendererSlots)',
      (tester) async {
        engine.rendererSlotCount = rendererSlots;
        final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 300000);
        addTearDown(coordinator.dispose);
        final lease = coordinator.openRouteLease();

        coordinator
          ..setRouteScrolling(lease, true)
          ..updateViewport(
            lease,
            direction: 1,
            demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
          );
        await tester.pump();
        engine.complete(engine.requests.single, textureId: 10, isFinal: false);
        await tester.pump();

        coordinator.updateViewport(
          lease,
          direction: 1,
          demands: [
            MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
            MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1),
            MapSceneDemand(scene: scene(3), visibleFraction: 0, distanceFromCurrent: 2),
            MapSceneDemand(scene: scene(4), visibleFraction: 0, distanceFromCurrent: 3),
            MapSceneDemand(scene: scene(5), visibleFraction: 0, distanceFromCurrent: 4),
          ],
        );
        await tester.pump();
        final requestsBeforeIdle = rendererSlots == 1 ? [1, 2] : [1, 2, 3];
        expect(engine.requests.map((request) => request.scene.locationLatitude), requestsBeforeIdle);

        coordinator.setRouteScrolling(lease, false);
        await tester.pump();
        expect(engine.requests.map((request) => request.scene.locationLatitude), requestsBeforeIdle);

        engine.complete(engine.requests[1], textureId: 20);
        await tester.pump();
        expect(engine.requests.map((request) => request.scene.locationLatitude), [...requestsBeforeIdle, 1]);
        expect(coordinator.frameFor(scene(1))?.textureId, 10);
        engine.complete(engine.requests.last, textureId: 40);
        await tester.pump();
        expect(engine.requests.map((request) => request.scene.locationLatitude), [
          ...requestsBeforeIdle,
          1,
          if (rendererSlots == 1) 3 else 4,
        ]);
        expect(coordinator.frameFor(scene(1))?.textureId, 40);
        expect(coordinator.frameFor(scene(2))?.textureId, 20);
        if (rendererSlots == 2) {
          engine.complete(engine.requests[2], textureId: 30);
          await tester.pump();
          expect(coordinator.frameFor(scene(3))?.textureId, 30);
          expect(engine.requests.where((request) => request.scene.locationLatitude == 3), hasLength(1));
        }
      },
    );
  }

  testWidgets('resuming scroll releases a partial refinement for a missing visible map', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 200000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
      );
    await tester.pump();
    engine.complete(engine.requests.single, textureId: 10, isFinal: false);
    await tester.pump();
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests.last, textureId: 20);
    await tester.pump();
    coordinator.setRouteScrolling(lease, false);
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2, 1]);
    final refinement = engine.requests.last;

    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        demands: [
          MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
          MapSceneDemand(scene: scene(3), visibleFraction: 0, distanceFromCurrent: 2),
        ],
      );
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2, 1]);

    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        demands: [
          MapSceneDemand(scene: scene(3), visibleFraction: 1, distanceFromCurrent: 0),
          MapSceneDemand(scene: scene(1), visibleFraction: 0, distanceFromCurrent: 2),
        ],
      );
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2, 1, 3]);
    engine.complete(refinement, textureId: 30);
    engine.complete(engine.requests.last, textureId: 40);
    await tester.pump();
    expect(coordinator.frameFor(scene(3))?.textureId, 40);
    expect(coordinator.frameFor(scene(1))?.textureId, 10);
    expect(engine.released.map((frame) => frame.textureId), containsAll([30, 1030]));
  });

  testWidgets('an idle handoff does not replace a planned cold request with an offscreen neighbor', (tester) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 160000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        demands: [
          MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
          MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1),
        ],
      );
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2]);

    coordinator
      ..setRouteScrolling(lease, false)
      ..updateViewport(
        lease,
        direction: 1,
        demands: [
          MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
          MapSceneDemand(scene: scene(3), visibleFraction: 0, distanceFromCurrent: 1),
          MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 2),
        ],
      );
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2]);

    engine.complete(engine.requests[1], textureId: 20);
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2, 3]);
    expect(coordinator.frameFor(scene(2))?.textureId, 20);
  });

  testWidgets('when final tiles never arrive, it should free the reserved renderer for the next map', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 120000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests.single, textureId: 10, isFinal: false);
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1]);

    await tester.pump(const Duration(seconds: 8));
    await tester.pump();
    expect(engine.requests.map((request) => request.scene.locationLatitude), [1, 2]);
  });

  testWidgets('when a route is covered and revealed, it should reuse its cached frame', (tester) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 120000);
    addTearDown(coordinator.dispose);
    final feedLease = coordinator.openRouteLease();
    final meLease = coordinator.openRouteLease(visible: false);

    coordinator.updateViewport(
      feedLease,
      direction: 0,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();
    engine.complete(engine.requests.single, textureId: 10);
    await tester.pump();
    final cachedBeforeCover = coordinator.frameFor(scene(1))?.textureId;

    coordinator
      ..setRouteVisible(feedLease, false)
      ..setRouteVisible(meLease, true)
      ..updateViewport(
        meLease,
        direction: 0,
        demands: [MapSceneDemand(scene: scene(2), visibleFraction: 1, distanceFromCurrent: 0)],
      );
    await tester.pump();
    engine.complete(engine.requests.last, textureId: 20);
    await tester.pump();
    coordinator
      ..setRouteVisible(meLease, false)
      ..setRouteVisible(feedLease, true);
    await tester.pump();

    expect(
      (
        cachedBeforeCover,
        coordinator.frameFor(scene(1))?.textureId,
        engine.requests.where((request) => request.scene.cameraLatitude == 1).length,
      ),
      (10, 10, 1),
    );
  });

  testWidgets('when a native request is superseded, it should discard and release the stale frame', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 80000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    var notifications = 0;
    coordinator
      ..addListener(() => notifications++)
      ..updateViewport(
        lease,
        direction: 0,
        demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
      );
    await tester.pump();
    final stale = engine.requests.single;
    coordinator.updateViewport(
      lease,
      direction: 0,
      demands: [MapSceneDemand(scene: scene(2), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();
    final current = engine.requests.last;
    final sameSlot = current.rendererSlot == stale.rendererSlot;

    engine.complete(stale, textureId: 10);
    await tester.pump();
    final staleAbsent = coordinator.frameFor(scene(1)) == null;
    final staleReleased =
        engine.released.any((frame) => frame.textureId == 10) &&
        engine.released.any((frame) => frame.textureId == 1010);
    engine.complete(current, textureId: 20);
    await tester.pump();
    expect(
      (sameSlot, staleAbsent, staleReleased, coordinator.frameFor(scene(2))?.textureId, notifications),
      (true, true, true, 20, 1),
    );
  });

  testWidgets('when the byte budget is exceeded, it should evict older full frames before previews', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 80000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    for (final location in [1, 2, 3]) {
      coordinator.updateViewport(
        lease,
        direction: 0,
        demands: [MapSceneDemand(scene: scene(location), visibleFraction: 1, distanceFromCurrent: 0)],
      );
      await tester.pump();
      engine.complete(engine.requests.last, textureId: location * 10);
      await tester.pump();
    }

    expect(
      (
        cachedBytes: coordinator.cachedBytes,
        oldestPreview: coordinator.frameFor(scene(1))?.textureId,
        previousTexture: coordinator.frameFor(scene(2))?.textureId,
        visibleTexture: coordinator.frameFor(scene(3))?.textureId,
        oldestFullReleased: engine.released.any((frame) => frame.textureId == 10),
        oldestPreviewRetained: engine.released.every((frame) => frame.textureId != 1010),
      ),
      (
        cachedBytes: 57328,
        oldestPreview: 1010,
        previousTexture: 1020,
        visibleTexture: 30,
        oldestFullReleased: true,
        oldestPreviewRetained: true,
      ),
    );
  });

  testWidgets('when a full map frame ages out, it should retain an exact-scene preview for a reverse swipe', (
    tester,
  ) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 80000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    for (final location in [1, 2, 3]) {
      coordinator.updateViewport(
        lease,
        direction: 1,
        demands: [MapSceneDemand(scene: scene(location), visibleFraction: 1, distanceFromCurrent: 0)],
      );
      await tester.pump();
      engine.complete(engine.requests.last, textureId: location * 10);
      await tester.pump();
    }

    expect(coordinator.frameFor(scene(1)), isNotNull);
  });

  testWidgets('when a preview-only card is visible during scroll, it should prepare cold maps before refining it', (
    tester,
  ) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 100000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    for (final location in [1, 2, 3]) {
      coordinator.updateViewport(
        lease,
        direction: 1,
        demands: [MapSceneDemand(scene: scene(location), visibleFraction: 1, distanceFromCurrent: 0)],
      );
      await tester.pump();
      engine.complete(engine.requests.last, textureId: location * 10);
      await tester.pump();
    }
    expect(coordinator.frameFor(scene(1))?.textureId, 1010);

    coordinator
      ..setRouteScrolling(lease, true)
      ..updateViewport(
        lease,
        direction: 1,
        demands: [
          MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
          MapSceneDemand(scene: scene(4), visibleFraction: 0, distanceFromCurrent: 1),
        ],
      );
    await tester.pump();

    expect(engine.requests.last.scene.locationLatitude, 4);
    expect(coordinator.frameFor(scene(1))?.textureId, 1010);

    engine.complete(engine.requests.last, textureId: 40);
    await tester.pump();
    coordinator.setRouteScrolling(lease, false);
    await tester.pump();
    expect(engine.requests.last.scene.locationLatitude, 1);
  });

  testWidgets('when a map is rendered again, it should refresh its cached preview', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 80000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();

    for (final (location, textureId) in [(1, 10), (2, 20), (1, 30), (3, 40)]) {
      coordinator.updateViewport(
        lease,
        direction: 1,
        demands: [MapSceneDemand(scene: scene(location), visibleFraction: 1, distanceFromCurrent: 0)],
      );
      await tester.pump();
      engine.complete(engine.requests.last, textureId: textureId);
      await tester.pump();
    }
    await tester.pump();

    expect(
      (
        coordinator.frameFor(scene(1))?.textureId,
        engine.released.any((frame) => frame.textureId == 1010),
        engine.released.every((frame) => frame.textureId != 1030),
      ),
      (1030, true, true),
    );
  });

  testWidgets('when a route closes during rendering, it should release the late frame without publishing it', (
    tester,
  ) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 80000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 0,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();
    coordinator.closeRouteLease(lease);
    engine.complete(engine.requests.single, textureId: 10);
    await tester.pump();

    expect(
      (coordinator.frameFor(scene(1)) == null, engine.released.any((frame) => frame.textureId == 10)),
      (true, true),
    );
  });

  testWidgets('when scroll direction reverses, it should replace the old prefetch with the new neighbor', (
    tester,
  ) async {
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 120000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    final demands = [
      MapSceneDemand(scene: scene(1), visibleFraction: 0, distanceFromCurrent: -1),
      MapSceneDemand(scene: scene(2), visibleFraction: 1, distanceFromCurrent: 0),
      MapSceneDemand(scene: scene(3), visibleFraction: 0, distanceFromCurrent: 1),
    ];

    coordinator.updateViewport(lease, direction: 1, demands: demands);
    await tester.pump();
    final initialOrder = engine.requests.map((request) => request.scene.locationLatitude.toInt()).join(',');
    coordinator.updateViewport(lease, direction: -1, demands: demands);
    await tester.pump();

    final replacementScene = engine.requests.last.scene.locationLatitude;
    final reusedSlot = engine.requests.last.rendererSlot == engine.requests[1].rendererSlot;
    engine.complete(engine.requests[1], textureId: 30);
    await tester.pump();
    expect(
      (initialOrder, replacementScene, reusedSlot, engine.released.any((frame) => frame.textureId == 30)),
      ('2,3', 1, true, true),
    );
  });

  testWidgets('when a visible map times out, it should retry after a delay', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 80000,
      retryDelay: const Duration(milliseconds: 100),
    );
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 0,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();
    engine.requests.single.completer.completeError(StateError('map timeout'));
    await tester.pump();
    final requestsBeforeRetry = engine.requests.length;

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect((requestsBeforeRetry, engine.requests.length), (1, 2));
  });

  testWidgets('when a failed neighbor becomes visible, it should receive a fresh retry', (tester) async {
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 120000,
      retryDelay: const Duration(milliseconds: 100),
    );
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0),
        MapSceneDemand(scene: scene(2), visibleFraction: 0, distanceFromCurrent: 1),
      ],
    );
    await tester.pump();
    engine.complete(engine.requests.first, textureId: 10);
    await tester.pump();

    for (var attempt = 1; attempt <= 3; attempt++) {
      final neighborRequest = engine.requests.where((request) => request.scene.cameraLatitude == 2).last;
      neighborRequest.completer.completeError(StateError('map timeout'));
      await tester.pump();
      if (attempt == 3) break;
      await tester.pump(Duration(milliseconds: 100 * attempt));
      await tester.pump();
    }
    final requestsWhileNeighbor = engine.requests.where((request) => request.scene.cameraLatitude == 2).length;

    coordinator.updateViewport(
      lease,
      direction: 1,
      demands: [
        MapSceneDemand(scene: scene(1), visibleFraction: 0, distanceFromCurrent: -1),
        MapSceneDemand(scene: scene(2), visibleFraction: 1, distanceFromCurrent: 0),
      ],
    );
    await tester.pump();
    expect(
      (requestsWhileNeighbor, engine.requests.where((request) => request.scene.cameraLatitude == 2).length),
      (3, 4),
    );
  });

  testWidgets('when a visible map repeatedly times out, it should keep retrying until a frame arrives', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(
      engine: engine.mapFrameEngine,
      maxCachedBytes: 80000,
      retryDelay: const Duration(milliseconds: 100),
    );
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 0,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();

    for (var failure = 1; failure <= 3; failure++) {
      engine.requests.last.completer.completeError(StateError('map timeout'));
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100 * failure));
      await tester.pump();
    }
    final requestsBeforeSuccess = engine.requests.length;
    engine.complete(engine.requests.last, textureId: 40);
    await tester.pump();
    expect((requestsBeforeSuccess, coordinator.frameFor(scene(1))?.textureId), (4, 40));
  });

  testWidgets('when frames are invalidated, it should release the old texture and request a new one', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 80000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 0,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();
    engine.complete(engine.requests.single, textureId: 10);
    await tester.pump();
    coordinator.invalidateFrames();
    final staleFrameAbsent = coordinator.frameFor(scene(1)) == null;
    final staleFrameReleased = engine.released.any((frame) => frame.textureId == 10);
    await tester.pump();
    expect((staleFrameAbsent, staleFrameReleased, engine.requests.length), (true, true, 2));
  });

  testWidgets(
    'when Android resumes from background, it should refresh old textures without resetting the initial frame',
    (tester) async {
      debugDefaultTargetPlatformOverride = .android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      engine.rendererSlotCount = 1;
      final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 80000);
      addTearDown(coordinator.dispose);
      final lease = coordinator.openRouteLease();
      coordinator.updateViewport(
        lease,
        direction: 0,
        demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
      );
      await tester.pump();
      engine.complete(engine.requests.single, textureId: 10);
      await tester.pump();

      coordinator.didChangeAppLifecycleState(.resumed);
      await tester.pump();
      final initialResumeFrame = coordinator.frameFor(scene(1))?.textureId;
      final initialResumeRequests = engine.requests.length;

      coordinator
        ..didChangeAppLifecycleState(.paused)
        ..didChangeAppLifecycleState(.resumed);
      final backgroundFrameAbsent = coordinator.frameFor(scene(1)) == null;
      final staleFrameReleased = engine.released.any((frame) => frame.textureId == 10);
      await tester.pump();
      expect(
        (initialResumeFrame, initialResumeRequests, backgroundFrameAbsent, staleFrameReleased, engine.requests.length),
        (10, 1, true, true, 2),
      );
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('when the last route closes, it should release all cached textures', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 80000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 0,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();
    engine.complete(engine.requests.single, textureId: 10);
    await tester.pump();
    coordinator.closeRouteLease(lease);

    expect(
      (
        coordinator.cachedBytes,
        engine.released.any((frame) => frame.textureId == 10),
        engine.released.any((frame) => frame.textureId == 1010),
      ),
      (0, true, true),
    );
  });

  testWidgets('when disposed during a render, it should close the native engine', (tester) async {
    engine.rendererSlotCount = 1;
    final coordinator = MapFrameCoordinator(engine: engine.mapFrameEngine, maxCachedBytes: 80000);
    addTearDown(coordinator.dispose);
    final lease = coordinator.openRouteLease();
    coordinator.updateViewport(
      lease,
      direction: 0,
      demands: [MapSceneDemand(scene: scene(1), visibleFraction: 1, distanceFromCurrent: 0)],
    );
    await tester.pump();
    final pendingRequests = engine.requests.length;

    coordinator.dispose();
    await tester.pump();
    expect((pendingRequests, engine.disposed), (1, true));
  });
}
