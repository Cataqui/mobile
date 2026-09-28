import 'package:flutter_test/flutter_test.dart';
import 'package:job_map/src/enums/map_render_quality.dart';
import 'package:job_map/src/map_render_budget.dart';
import 'package:job_map/src/map_render_capabilities.dart';

void main() {
  const normal = MapRenderCapabilities(
    lowMemory: false,
    lowRamDevice: false,
    availableMemoryBytes: 256 * 1024 * 1024,
    totalMemoryBytes: 2 * 1024 * 1024 * 1024,
    processorCount: 4,
    thermalState: .nominal,
    maxRendererSlots: 2,
  );

  testWidgets('uses memory capacity as a prefetch limit without inferring render speed from core count', (
    tester,
  ) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 24 * 1024 * 1024,
      readCapabilities: () async => normal,
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();

    expect(
      (budget.quality, budget.concurrentRenders, budget.cacheBytes),
      (MapRenderQuality.balanced, 2, 24 * 1024 * 1024),
    );
    expect(budget.maxOffscreenPrefetchScenes, 2);
    budget.applyCapabilities(
      const MapRenderCapabilities(
        lowMemory: false,
        lowRamDevice: false,
        availableMemoryBytes: 2 * 1024 * 1024 * 1024,
        totalMemoryBytes: 4 * 1024 * 1024 * 1024,
        processorCount: 12,
        thermalState: .nominal,
        maxRendererSlots: 2,
      ),
    );
    expect(budget.quality, MapRenderQuality.balanced);
    budget.applyCapabilities(
      const MapRenderCapabilities(
        lowMemory: false,
        lowRamDevice: false,
        availableMemoryBytes: 64 * 1024 * 1024,
        totalMemoryBytes: 512 * 1024 * 1024,
        processorCount: 2,
        thermalState: .nominal,
        maxRendererSlots: 2,
      ),
    );
    expect(
      (budget.quality, budget.concurrentRenders, budget.cacheBytes),
      (MapRenderQuality.balanced, 2, 8 * 1024 * 1024),
    );
    budget.setActive(false);
  });

  testWidgets('a roomy device earns sharper visible maps and deeper prefetch after measured headroom', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 48 * 1024 * 1024,
      readCapabilities: () async => normal,
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();
    budget.applyCapabilities(
      const MapRenderCapabilities(
        lowMemory: false,
        lowRamDevice: false,
        availableMemoryBytes: 1024 * 1024 * 1024,
        totalMemoryBytes: 8 * 1024 * 1024 * 1024,
        processorCount: 8,
        thermalState: .nominal,
        maxRendererSlots: 2,
      ),
    );
    expect((budget.quality, budget.maxOffscreenPrefetchScenes), (MapRenderQuality.balanced, 4));

    for (var frame = 0; frame < 190; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 4), frameBudget: const Duration(microseconds: 16667));
    }
    expect((budget.quality, budget.maxOffscreenPrefetchScenes), (MapRenderQuality.sharp, 6));
    budget.setActive(false);
  });

  testWidgets('a capable device can sharpen after a quiet dwell with no animation frames', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 48 * 1024 * 1024,
      readCapabilities: () async => const MapRenderCapabilities(
        lowMemory: false,
        lowRamDevice: false,
        availableMemoryBytes: 1024 * 1024 * 1024,
        totalMemoryBytes: 4 * 1024 * 1024 * 1024,
        processorCount: 6,
        thermalState: .nominal,
        maxRendererSlots: 2,
      ),
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();

    await tester.pump(const Duration(seconds: 2));
    expect(budget.quality, MapRenderQuality.balanced);
    await tester.pump(const Duration(seconds: 1));
    expect(budget.quality, MapRenderQuality.sharp);
    budget.setActive(false);
  });

  testWidgets('a capable phone recovers compact quality during a quiet map dwell', (tester) async {
    const capable = MapRenderCapabilities(
      lowMemory: false,
      lowRamDevice: false,
      availableMemoryBytes: 1024 * 1024 * 1024,
      totalMemoryBytes: 6 * 1024 * 1024 * 1024,
      processorCount: 6,
      thermalState: .nominal,
      maxRendererSlots: 2,
    );
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 48 * 1024 * 1024,
      readCapabilities: () async => capable,
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();
    for (var frame = 0; frame < 3; frame++) {
      budget.recordFrameWork(
        work: const Duration(milliseconds: 100),
        frameBudget: const Duration(microseconds: 16667),
        frameVsyncStartMicros: frame * 100000,
      );
    }
    expect(budget.quality, MapRenderQuality.compact);

    await tester.pump(const Duration(seconds: 3));
    expect(budget.quality, MapRenderQuality.balanced);
    await tester.pump(const Duration(seconds: 3));
    expect(budget.quality, MapRenderQuality.sharp);
    budget.setActive(false);
  });

  testWidgets('a device flagged low RAM keeps nearby prefetch and a bounded texture cache', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 48 * 1024 * 1024,
      readCapabilities: () async => normal,
    );
    addTearDown(budget.dispose);
    budget.applyCapabilities(
      const MapRenderCapabilities(
        lowMemory: false,
        lowRamDevice: true,
        availableMemoryBytes: 1024 * 1024 * 1024,
        totalMemoryBytes: 8 * 1024 * 1024 * 1024,
        processorCount: 8,
        thermalState: .nominal,
        maxRendererSlots: 2,
      ),
    );
    expect(
      (budget.quality, budget.maxOffscreenPrefetchScenes, budget.cacheBytes),
      (MapRenderQuality.balanced, 2, 16 * 1024 * 1024),
    );
  });

  for (final refreshRate in [60, 90, 120]) {
    for (final costlyWork in [const Duration(milliseconds: 100), const Duration(milliseconds: 500)]) {
      testWidgets('consecutive ${costlyWork.inMilliseconds} ms frames step down at $refreshRate Hz', (tester) async {
        final budget = MapRenderBudget(
          rendererSlotCount: 2,
          maxCachedBytes: 24 * 1024 * 1024,
          readCapabilities: () async => normal,
        )..setActive(true);
        addTearDown(budget.dispose);
        await tester.pump();
        final frameBudget = Duration(microseconds: (1000000 / refreshRate).round());
        final framesPerStep = costlyWork.inMilliseconds == 100 ? 3 : 2;
        var vsyncStartMicros = 0;

        for (var frame = 0; frame < framesPerStep; frame++) {
          budget.recordFrameWork(work: costlyWork, frameBudget: frameBudget, frameVsyncStartMicros: vsyncStartMicros);
          vsyncStartMicros += costlyWork.inMicroseconds;
        }
        expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 2));
        for (var frame = 0; frame < framesPerStep; frame++) {
          budget.recordFrameWork(work: costlyWork, frameBudget: frameBudget, frameVsyncStartMicros: vsyncStartMicros);
          vsyncStartMicros += costlyWork.inMicroseconds;
        }
        expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 1));
        budget.setActive(false);
      });
    }

    testWidgets('one 500 ms frame followed by healthy work is isolated at $refreshRate Hz', (tester) async {
      final budget = MapRenderBudget(
        rendererSlotCount: 2,
        maxCachedBytes: 24 * 1024 * 1024,
        readCapabilities: () async => normal,
      )..setActive(true);
      addTearDown(budget.dispose);
      await tester.pump();
      final frameBudget = Duration(microseconds: (1000000 / refreshRate).round());
      budget
        ..recordFrameWork(work: const Duration(milliseconds: 500), frameBudget: frameBudget)
        ..recordFrameWork(work: const Duration(milliseconds: 4), frameBudget: frameBudget)
        ..recordFrameWork(work: const Duration(milliseconds: 500), frameBudget: frameBudget);
      expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.balanced, 2));
      budget.setActive(false);
    });

    testWidgets('a five-frame 50 ms cluster stays one downgrade signal at $refreshRate Hz', (tester) async {
      final budget = MapRenderBudget(
        rendererSlotCount: 2,
        maxCachedBytes: 24 * 1024 * 1024,
        readCapabilities: () async => normal,
      )..setActive(true);
      addTearDown(budget.dispose);
      await tester.pump();
      final frameBudget = Duration(microseconds: (1000000 / refreshRate).round());
      for (var frame = 0; frame < 5; frame++) {
        budget.recordFrameWork(work: const Duration(milliseconds: 50), frameBudget: frameBudget);
      }
      for (var frame = 0; frame < 40; frame++) {
        budget.recordFrameWork(work: const Duration(milliseconds: 4), frameBudget: frameBudget);
      }
      expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.balanced, 2));
      budget.setActive(false);
    });
  }

  testWidgets('raster queueing does not turn consecutive costly frames into idle', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 24 * 1024 * 1024,
      readCapabilities: () async => normal,
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();

    for (final sample in [
      (vsyncMicros: 0, workMillis: 150, totalSpanMillis: 150),
      (vsyncMicros: 150000, workMillis: 52, totalSpanMillis: 259),
      (vsyncMicros: 366000, workMillis: 100, totalSpanMillis: 100),
    ]) {
      budget.recordFrameWork(
        work: Duration(milliseconds: sample.workMillis),
        frameBudget: const Duration(microseconds: 16667),
        frameVsyncStartMicros: sample.vsyncMicros,
        frameTotalSpan: Duration(milliseconds: sample.totalSpanMillis),
      );
    }

    expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 2));
    budget.setActive(false);
  });

  testWidgets('two slow frames separated by an idle gap are not consecutive', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 24 * 1024 * 1024,
      readCapabilities: () async => normal,
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();
    const frameBudget = Duration(microseconds: 16667);
    budget
      ..recordFrameWork(work: const Duration(milliseconds: 500), frameBudget: frameBudget, frameVsyncStartMicros: 0)
      ..recordFrameWork(
        work: const Duration(milliseconds: 500),
        frameBudget: frameBudget,
        frameVsyncStartMicros: 5000000,
      );
    expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.balanced, 2));
    budget.recordFrameWork(
      work: const Duration(milliseconds: 500),
      frameBudget: frameBudget,
      frameVsyncStartMicros: 5500000,
    );
    expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 2));
    budget.setActive(false);
  });

  for (final refreshRate in [60, 120]) {
    testWidgets('misses at $refreshRate Hz lower quality before renderer concurrency', (tester) async {
      final budget = MapRenderBudget(
        rendererSlotCount: 2,
        maxCachedBytes: 24 * 1024 * 1024,
        readCapabilities: () async => normal,
      )..setActive(true);
      addTearDown(budget.dispose);
      await tester.pump();
      final frameBudget = Duration(microseconds: (1000000 / refreshRate).round());
      final framesPerWindow = (150000 + frameBudget.inMicroseconds - 1) ~/ frameBudget.inMicroseconds;
      for (var frame = 0; frame < framesPerWindow * 2; frame++) {
        budget.recordFrameWork(work: frameBudget + const Duration(microseconds: 1), frameBudget: frameBudget);
      }
      expect(
        (budget.quality, budget.concurrentRenders, budget.maxOffscreenPrefetchScenes),
        (MapRenderQuality.compact, 2, 2),
      );
      for (var frame = 0; frame < framesPerWindow * 2; frame++) {
        budget.recordFrameWork(work: frameBudget + const Duration(microseconds: 1), frameBudget: frameBudget);
      }
      expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 1));
      budget.setActive(false);
    });

    testWidgets('recurring 30 ms stalls at $refreshRate Hz lower quality before renderer concurrency', (tester) async {
      final budget = MapRenderBudget(
        rendererSlotCount: 2,
        maxCachedBytes: 24 * 1024 * 1024,
        readCapabilities: () async => normal,
      )..setActive(true);
      addTearDown(budget.dispose);
      await tester.pump();
      final frameBudget = Duration(microseconds: (1000000 / refreshRate).round());
      final framesPerWindow = (150000 + frameBudget.inMicroseconds - 1) ~/ frameBudget.inMicroseconds;
      final windowMicros = framesPerWindow * frameBudget.inMicroseconds;
      final windowsForTwoSeconds = (2000000 + windowMicros - 1) ~/ windowMicros;
      final framesPerInterval = refreshRate ~/ 4;

      for (var frame = 0; frame < framesPerWindow * windowsForTwoSeconds; frame++) {
        budget.recordFrameWork(
          work: frame % framesPerInterval == 0 ? const Duration(milliseconds: 30) : const Duration(milliseconds: 4),
          frameBudget: frameBudget,
        );
      }
      expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 2));
      for (var frame = 0; frame < framesPerWindow * windowsForTwoSeconds; frame++) {
        budget.recordFrameWork(
          work: frame % framesPerInterval == 0 ? const Duration(milliseconds: 30) : const Duration(milliseconds: 4),
          frameBudget: frameBudget,
        );
      }
      expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 1));
      budget.setActive(false);
    });

    testWidgets('one isolated 100 ms stall at $refreshRate Hz does not lower quality', (tester) async {
      final budget = MapRenderBudget(
        rendererSlotCount: 2,
        maxCachedBytes: 24 * 1024 * 1024,
        readCapabilities: () async => normal,
      )..setActive(true);
      addTearDown(budget.dispose);
      await tester.pump();
      final frameBudget = Duration(microseconds: (1000000 / refreshRate).round());
      final framesPerWindow = (150000 + frameBudget.inMicroseconds - 1) ~/ frameBudget.inMicroseconds;
      final windowMicros = framesPerWindow * frameBudget.inMicroseconds;
      final windowsForTwoSeconds = (2000000 + windowMicros - 1) ~/ windowMicros;
      for (var frame = 0; frame < framesPerWindow * windowsForTwoSeconds; frame++) {
        budget.recordFrameWork(
          work: frame == 0 ? const Duration(milliseconds: 100) : const Duration(milliseconds: 4),
          frameBudget: frameBudget,
        );
      }
      expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.balanced, 2));
      budget.setActive(false);
    });

    testWidgets('one clustered bad window at $refreshRate Hz does not lower quality', (tester) async {
      final budget = MapRenderBudget(
        rendererSlotCount: 2,
        maxCachedBytes: 24 * 1024 * 1024,
        readCapabilities: () async => normal,
      )..setActive(true);
      addTearDown(budget.dispose);
      await tester.pump();
      final frameBudget = Duration(microseconds: (1000000 / refreshRate).round());
      final framesPerWindow = (150000 + frameBudget.inMicroseconds - 1) ~/ frameBudget.inMicroseconds;
      final windowMicros = framesPerWindow * frameBudget.inMicroseconds;
      final windowsForTwoSeconds = (2000000 + windowMicros - 1) ~/ windowMicros;
      final clusteredFrames = refreshRate == 60 ? 4 : 5;
      for (var frame = 0; frame < framesPerWindow * windowsForTwoSeconds; frame++) {
        budget.recordFrameWork(
          work: frame < clusteredFrames ? const Duration(milliseconds: 50) : const Duration(milliseconds: 4),
          frameBudget: frameBudget,
        );
      }
      expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.balanced, 2));
      budget.setActive(false);
    });

    testWidgets('active healthy $refreshRate Hz frames restore slots, then quality, then sharpness', (tester) async {
      final budget = MapRenderBudget(
        rendererSlotCount: 2,
        maxCachedBytes: 24 * 1024 * 1024,
        readCapabilities: () async => normal,
      )..setActive(true);
      addTearDown(budget.dispose);
      await tester.pump();
      final frameBudget = Duration(microseconds: (1000000 / refreshRate).round());
      final framesPerWindow = (150000 + frameBudget.inMicroseconds - 1) ~/ frameBudget.inMicroseconds;
      final windowMicros = framesPerWindow * frameBudget.inMicroseconds;
      final windowsForThreeSeconds = (3000000 + windowMicros - 1) ~/ windowMicros;
      final windowsForTenSeconds = (10000000 + windowMicros - 1) ~/ windowMicros;
      for (var frame = 0; frame < framesPerWindow * 4; frame++) {
        budget.recordFrameWork(work: frameBudget + const Duration(microseconds: 1), frameBudget: frameBudget);
      }
      expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 1));

      for (var frame = 0; frame < framesPerWindow * windowsForThreeSeconds; frame++) {
        budget.recordFrameWork(work: const Duration(milliseconds: 4), frameBudget: frameBudget);
      }
      expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 2));
      for (var frame = 0; frame < framesPerWindow * windowsForThreeSeconds; frame++) {
        budget.recordFrameWork(work: const Duration(milliseconds: 4), frameBudget: frameBudget);
      }
      expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.balanced, 2));
      for (var frame = 0; frame < framesPerWindow * windowsForTenSeconds - framesPerWindow; frame++) {
        budget.recordFrameWork(work: const Duration(milliseconds: 4), frameBudget: frameBudget);
      }
      expect(budget.quality, MapRenderQuality.balanced);
      for (var frame = 0; frame < framesPerWindow; frame++) {
        budget.recordFrameWork(work: const Duration(milliseconds: 4), frameBudget: frameBudget);
      }
      expect(
        (budget.quality, budget.concurrentRenders, budget.maxOffscreenPrefetchScenes),
        (MapRenderQuality.sharp, 2, 2),
      );
      budget.setActive(false);
    });
  }

  for (final refreshRate in [60, 120]) {
    testWidgets('isolated misses at $refreshRate Hz do not strand a renderer slot', (tester) async {
      final budget = MapRenderBudget(
        rendererSlotCount: 2,
        maxCachedBytes: 24 * 1024 * 1024,
        readCapabilities: () async => normal,
      )..setActive(true);
      addTearDown(budget.dispose);
      await tester.pump();
      final frameBudget = Duration(microseconds: (1000000 / refreshRate).round());
      final framesPerWindow = (150000 + frameBudget.inMicroseconds - 1) ~/ frameBudget.inMicroseconds;
      final windowMicros = framesPerWindow * frameBudget.inMicroseconds;
      final windowsForThreeSeconds = (3000000 + windowMicros - 1) ~/ windowMicros;
      for (var frame = 0; frame < framesPerWindow * 4; frame++) {
        budget.recordFrameWork(work: frameBudget + const Duration(microseconds: 1), frameBudget: frameBudget);
      }
      expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 1));
      for (var frame = 0; frame < framesPerWindow * windowsForThreeSeconds; frame++) {
        budget.recordFrameWork(
          work: frame == framesPerWindow
              ? frameBudget + const Duration(microseconds: 1)
              : const Duration(milliseconds: 4),
          frameBudget: frameBudget,
        );
      }
      expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 2));
      budget.setActive(false);
    });
  }

  testWidgets('recent costly stalls block recovery before the two-second trend closes', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 24 * 1024 * 1024,
      readCapabilities: () async => normal,
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();

    for (var frame = 0; frame < 18; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 20), frameBudget: const Duration(microseconds: 16667));
    }
    expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 2));

    for (var window = 0; window < 20; window++) {
      for (var frame = 0; frame < 9; frame++) {
        final costlyStall = (window == 14 || window == 16 || window == 18) && frame == 0;
        budget.recordFrameWork(
          work: costlyStall ? const Duration(milliseconds: 100) : const Duration(milliseconds: 4),
          frameBudget: const Duration(microseconds: 16667),
        );
      }
    }
    expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 2));
    budget.setActive(false);
  });

  testWidgets('sharp quality requires measured frame headroom rather than merely meeting deadlines', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 24 * 1024 * 1024,
      readCapabilities: () async => normal,
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();
    for (var frame = 0; frame < 630; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 15), frameBudget: const Duration(microseconds: 16667));
    }
    expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.balanced, 2));
    for (var frame = 0; frame < 603; frame++) {
      budget.recordFrameWork(
        work: frame == 300 ? const Duration(milliseconds: 20) : const Duration(milliseconds: 4),
        frameBudget: const Duration(microseconds: 16667),
      );
    }
    expect(budget.quality, MapRenderQuality.sharp);
    budget.setActive(false);
  });

  testWidgets('time passing without measured frames cannot promote quality', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 24 * 1024 * 1024,
      readCapabilities: () async => normal,
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();
    for (var frame = 0; frame < 18; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 20), frameBudget: const Duration(microseconds: 16667));
    }
    expect(budget.quality, MapRenderQuality.compact);
    await tester.pump(const Duration(seconds: 30));
    expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 2));
    budget.setActive(false);
  });

  testWidgets('pressure takes compact quality, one slot, and four MiB until fresh memory telemetry', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 24 * 1024 * 1024,
      readCapabilities: () async => normal,
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();
    budget.didHaveMemoryPressure();
    expect(
      (budget.quality, budget.concurrentRenders, budget.cacheBytes),
      (MapRenderQuality.compact, 1, 4 * 1024 * 1024),
    );
    budget.applyCapabilities(normal);
    expect(
      (budget.quality, budget.concurrentRenders, budget.cacheBytes),
      (MapRenderQuality.compact, 1, 4 * 1024 * 1024),
    );
    budget.applyCapabilities(normal);
    expect(
      (budget.quality, budget.concurrentRenders, budget.cacheBytes),
      (MapRenderQuality.compact, 1, 24 * 1024 * 1024),
    );
    for (var frame = 0; frame < 180; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 4), frameBudget: const Duration(microseconds: 16667));
    }
    expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 2));
    budget.setActive(false);
  });

  testWidgets('serious thermal state compacts quality and lowers the renderer ceiling', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 24 * 1024 * 1024,
      readCapabilities: () async => normal,
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();
    budget.applyCapabilities(
      const MapRenderCapabilities(
        lowMemory: false,
        availableMemoryBytes: 256 * 1024 * 1024,
        totalMemoryBytes: 2 * 1024 * 1024 * 1024,
        processorCount: 4,
        thermalState: .serious,
        maxRendererSlots: 2,
      ),
    );
    expect(
      (budget.quality, budget.concurrentRenders, budget.maxOffscreenPrefetchScenes),
      (MapRenderQuality.compact, 1, 2),
    );
    budget.applyCapabilities(normal);
    expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 1));
    for (var frame = 0; frame < 180; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 4), frameBudget: const Duration(microseconds: 16667));
    }
    expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.compact, 2));
    budget.setActive(false);
  });

  testWidgets('available memory bounds cache only and rising headroom waits for a second read', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 48 * 1024 * 1024,
      readCapabilities: () async => normal,
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();
    expect((budget.quality, budget.cacheBytes), (MapRenderQuality.balanced, 24 * 1024 * 1024));
    budget.applyCapabilities(normal);
    expect((budget.quality, budget.cacheBytes), (MapRenderQuality.balanced, 32 * 1024 * 1024));
    budget.applyCapabilities(
      const MapRenderCapabilities(
        lowMemory: false,
        availableMemoryBytes: 64 * 1024 * 1024,
        totalMemoryBytes: 512 * 1024 * 1024,
        processorCount: 2,
        thermalState: .nominal,
        maxRendererSlots: 2,
      ),
    );
    expect((budget.quality, budget.cacheBytes), (MapRenderQuality.balanced, 8 * 1024 * 1024));
    budget.applyCapabilities(
      const MapRenderCapabilities(
        lowMemory: false,
        availableMemoryBytes: 296 * 1024 * 1024,
        totalMemoryBytes: 2 * 1024 * 1024 * 1024,
        processorCount: 2,
        thermalState: .nominal,
        maxRendererSlots: 2,
      ),
    );
    expect(budget.cacheBytes, 8 * 1024 * 1024);
    budget.applyCapabilities(
      const MapRenderCapabilities(
        lowMemory: false,
        availableMemoryBytes: 304 * 1024 * 1024,
        totalMemoryBytes: 2 * 1024 * 1024 * 1024,
        processorCount: 12,
        thermalState: .nominal,
        maxRendererSlots: 2,
      ),
    );
    expect((budget.quality, budget.cacheBytes), (MapRenderQuality.balanced, 32 * 1024 * 1024));
    budget.applyCapabilities(
      const MapRenderCapabilities(
        lowMemory: false,
        availableMemoryBytes: 512 * 1024 * 1024,
        totalMemoryBytes: 2 * 1024 * 1024 * 1024,
        processorCount: 12,
        thermalState: .nominal,
        maxRendererSlots: 2,
      ),
    );
    expect(budget.cacheBytes, 32 * 1024 * 1024);
    budget.applyCapabilities(
      const MapRenderCapabilities(
        lowMemory: false,
        availableMemoryBytes: 480 * 1024 * 1024,
        totalMemoryBytes: 2 * 1024 * 1024 * 1024,
        processorCount: 12,
        thermalState: .nominal,
        maxRendererSlots: 2,
      ),
    );
    expect((budget.quality, budget.cacheBytes), (MapRenderQuality.balanced, 48 * 1024 * 1024));
    budget.setActive(false);
  });

  testWidgets('capability polling stops while maps are inactive and resumes when visible', (tester) async {
    var reads = 0;
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 24 * 1024 * 1024,
      readCapabilities: () async {
        reads++;
        return normal;
      },
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();
    expect(reads, 1);
    budget.setActive(false);
    await tester.pump(const Duration(seconds: 10));
    expect(reads, 1);
    budget.setActive(true);
    await tester.pump();
    expect(reads, 2);
    budget.setActive(false);
  });

  testWidgets('inactive visits and isolated short spikes cannot accumulate a downgrade', (tester) async {
    final budget = MapRenderBudget(
      rendererSlotCount: 2,
      maxCachedBytes: 24 * 1024 * 1024,
      readCapabilities: () async => normal,
    )..setActive(true);
    addTearDown(budget.dispose);
    await tester.pump();
    for (var frame = 0; frame < 9; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 20), frameBudget: const Duration(microseconds: 16667));
    }
    budget
      ..setActive(false)
      ..setActive(true);
    await tester.pump();
    for (var frame = 0; frame < 9; frame++) {
      budget.recordFrameWork(work: const Duration(milliseconds: 20), frameBudget: const Duration(microseconds: 16667));
    }
    expect((budget.quality, budget.concurrentRenders), (MapRenderQuality.balanced, 2));
    budget.setActive(false);
  });
}
