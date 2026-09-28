import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:job_map/src/job_map_scene.dart';

final class JobMapLocationArea extends CustomPainter {
  const JobMapLocationArea({required this.scene, this.attributionScale});

  final JobMapScene scene;
  final double? attributionScale;

  static ({Offset center, double radiusPoints}) projectedArea(JobMapScene scene) {
    final worldSize = 256 * math.pow(2, scene.zoom).toDouble();
    final cameraX = scene.cameraLongitude / 360 * worldSize;
    final locationX = scene.locationLongitude / 360 * worldSize;
    var deltaX = locationX - cameraX;
    if (deltaX > worldSize / 2) deltaX -= worldSize;
    if (deltaX < -worldSize / 2) deltaX += worldSize;

    final cameraY = _mercatorY(latitude: scene.cameraLatitude, worldSize: worldSize);
    final locationY = _mercatorY(latitude: scene.locationLatitude, worldSize: worldSize);
    final radiusPoints = JobMapScene.projectedRadiusPoints(
      radiusMeters: scene.radiusMeters,
      latitude: scene.locationLatitude,
      zoom: scene.zoom,
    );

    return (
      center: Offset(
        scene.widthPoints / 2 + deltaX,
        (scene.heightPoints - scene.paddingBottomPoints) / 2 + locationY - cameraY,
      ),
      radiusPoints: radiusPoints,
    );
  }

  static double _mercatorY({required double latitude, required double worldSize}) {
    final radians = latitude.clamp(-85.05112878, 85.05112878) * math.pi / 180;
    return -math.log(math.tan(math.pi / 4 + radians / 2)) / (2 * math.pi) * worldSize;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (scene.radiusMeters <= 0) return;
    final area = projectedArea(scene);
    final nativeScale = attributionScale ?? scene.nativeScale;
    canvas
      ..save()
      ..scale(size.width / scene.widthPoints, size.height / scene.heightPoints)
      ..clipRect(Rect.fromLTWH(0, 0, scene.widthPoints, scene.heightPoints))
      ..clipRect(
        Rect.fromLTWH(
          4 / nativeScale,
          scene.heightPoints - scene.paddingBottomPoints - 26 / nativeScale,
          62 / nativeScale,
          20 / nativeScale,
        ),
        clipOp: .difference,
        doAntiAlias: false,
      )
      ..clipRect(
        Rect.fromLTWH(
          scene.widthPoints - 160 / nativeScale,
          scene.heightPoints - scene.paddingBottomPoints - 14 / nativeScale,
          160 / nativeScale,
          12 / nativeScale,
        ),
        clipOp: .difference,
        doAntiAlias: false,
      )
      ..drawCircle(area.center, area.radiusPoints, Paint()..color = Color(scene.radiusColorArgb))
      ..restore();
  }

  @override
  bool shouldRepaint(covariant JobMapLocationArea oldDelegate) =>
      scene != oldDelegate.scene || attributionScale != oldDelegate.attributionScale;
}
