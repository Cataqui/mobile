import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_map/src/map_frame_coordinator.dart';
import 'package:job_map/src/map_render_budget.dart';
import 'package:job_map/src/pigeon_map_frame_engine.dart';

final mapFrameCoordinatorProvider = Provider<MapFrameCoordinator>((ref) {
  final engine = PigeonMapFrameEngine();
  final renderBudget = MapRenderBudget(
    rendererSlotCount: engine.rendererSlotCount,
    maxCachedBytes: MapRenderBudget.defaultMaxCachedBytes,
    readCapabilities: engine.readRenderCapabilities,
  );
  final coordinator = MapFrameCoordinator(
    engine: engine,
    maxCachedBytes: renderBudget.maxCachedBytes,
    renderBudget: renderBudget,
  );
  ref.onDispose(() {
    coordinator.dispose();
    renderBudget.dispose();
  });
  return coordinator;
});
