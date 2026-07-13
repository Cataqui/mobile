part of 'qui_location_radius_map.dart';

/// Test-only view of the retained wobble animation contract.
@visibleForTesting
abstract interface class QuiLocationRadiusMapDebugPainter {
  /// Animation that drives wobble paint frames.
  Animation<double> get animation;

  /// Curve applied to each wobble movement.
  Curve get curve;

  /// Current destination of the wobble movement.
  ({double latitude, double longitude}) get targetLocation;
}

class _QuiLocationRadiusMapRadiusPainter extends CustomPainter implements QuiLocationRadiusMapDebugPainter {
  _QuiLocationRadiusMapRadiusPainter({required this.animation, required this.curve, required this.frameProvider})
    : super(repaint: animation);

  @override
  final Animation<double> animation;

  @override
  final Curve curve;
  final _QuiLocationRadiusMapRadiusFrame Function() frameProvider;

  @override
  ({double latitude, double longitude}) get targetLocation => frameProvider().toLocation;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = frameProvider();
    if (!frame.isVisible) return;

    final progress = curve.transform(frame.animationValue);
    final latitude = ui.lerpDouble(frame.fromLocation.latitude, frame.toLocation.latitude, progress)!;
    final longitude = ui.lerpDouble(frame.fromLocation.longitude, frame.toLocation.longitude, progress)!;
    final radius = ui.lerpDouble(frame.fromRadius, frame.toRadius, progress)!.clamp(1, double.infinity).toDouble();
    final center = _projectLocation(
      location: (latitude: latitude, longitude: longitude),
      cameraTarget: frame.cameraTarget,
      zoom: frame.zoom,
      viewport: size,
    );

    canvas.drawCircle(center, radius, Paint()..color = frame.fillColor);
  }

  Offset _projectLocation({
    required ({double latitude, double longitude}) location,
    required LatLng cameraTarget,
    required double zoom,
    required Size viewport,
  }) {
    final worldSize = (512 * math.pow(2, zoom)).toDouble();
    final locationWorld = _worldPoint(latitude: location.latitude, longitude: location.longitude, worldSize: worldSize);
    final cameraWorld = _worldPoint(
      latitude: cameraTarget.latitude,
      longitude: cameraTarget.longitude,
      worldSize: worldSize,
    );

    return Offset(
      viewport.width / 2 + locationWorld.dx - cameraWorld.dx,
      viewport.height / 2 + locationWorld.dy - cameraWorld.dy,
    );
  }

  Offset _worldPoint({required double latitude, required double longitude, required double worldSize}) {
    final latitudeRadians = latitude.clamp(-85.05112878, 85.05112878) * math.pi / 180;
    final x = (longitude + 180) / 360 * worldSize;
    final y = (1 - math.log(math.tan(latitudeRadians) + 1 / math.cos(latitudeRadians)) / math.pi) / 2 * worldSize;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _QuiLocationRadiusMapRadiusPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.curve != curve ||
        oldDelegate.frameProvider != frameProvider;
  }
}

@immutable
class _QuiLocationRadiusMapRadiusFrame {
  const _QuiLocationRadiusMapRadiusFrame({
    required this.isVisible,
    required this.animationValue,
    required this.fromLocation,
    required this.toLocation,
    required this.fromRadius,
    required this.toRadius,
    required this.cameraTarget,
    required this.zoom,
    required this.fillColor,
  });

  final bool isVisible;
  final double animationValue;
  final ({double latitude, double longitude}) fromLocation;
  final ({double latitude, double longitude}) toLocation;
  final double fromRadius;
  final double toRadius;
  final LatLng cameraTarget;
  final double zoom;
  final Color fillColor;
}
