import 'package:flutter/foundation.dart';
import 'package:job_map/src/job_map_scene.dart';

@immutable
final class MapFrame {
  const MapFrame({required this.scene, required this.textureId, required this.widthPx, required this.heightPx});

  final JobMapScene scene;
  final int textureId;
  final int widthPx;
  final int heightPx;

  int get byteCount => widthPx * heightPx * 4;
}
