import 'package:flutter/foundation.dart';
import 'package:job_map/src/job_map_scene.dart';
import 'package:job_map/src/map_frame.dart';
import 'package:job_map/src/map_frame_engine_types.dart';

abstract interface class MapFrameEngine {
  int get rendererSlotCount;

  void setFrameFinalListener(ValueChanged<MapFrameFinalEvent>? listener);

  void setFrameProgressListener(ValueChanged<MapFrameFinalEvent>? listener);

  void setRendererResetListener(VoidCallback? listener);

  Future<void> setScrollActive(bool active, {bool allowReadyPreview = false});

  Future<({MapFrame full, MapFrame preview, bool isFinal})> render(
    JobMapScene scene, {
    required int requestId,
    required int rendererSlot,
  });

  Future<void> release(MapFrame frame);

  Future<void> dispose();
}
