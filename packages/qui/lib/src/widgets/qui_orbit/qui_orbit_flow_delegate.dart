part of 'qui_orbit.dart';

class _QuiOrbitFlowDelegate extends FlowDelegate {
  _QuiOrbitFlowDelegate({
    required Animation<double> animation,
    required this.placements,
    required this.radius,
    required this.rotationDirection,
    required this.rotateItems,
    required this.animationsDisabled,
  }) : _animation = animation,
       super(repaint: animation);

  final Animation<double> _animation;
  final List<_QuiOrbitItemData> placements;
  final double radius;
  final double rotationDirection;
  final bool rotateItems;
  final bool animationsDisabled;

  @override
  BoxConstraints getConstraintsForChild(int index, BoxConstraints constraints) {
    return BoxConstraints.tight(placements[index].size);
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final theta = animationsDisabled ? 0.0 : _animation.value * 2 * math.pi * rotationDirection;
    final cosTheta = math.cos(theta);
    final sinTheta = math.sin(theta);
    final centerX = context.size.width / 2;
    final centerY = context.size.height / 2;

    for (var index = 0; index < placements.length; index++) {
      final placement = placements[index];
      final cosTotal = cosTheta * placement.cosBase - sinTheta * placement.sinBase;
      final sinTotal = sinTheta * placement.cosBase + cosTheta * placement.sinBase;
      final childCenterX = centerX + radius * cosTotal;
      final childCenterY = centerY + radius * sinTotal;
      final transform = Matrix4.identity()
        ..translateByDouble(childCenterX - placement.size.width / 2, childCenterY - placement.size.height / 2, 0, 1);

      if (rotateItems && !animationsDisabled) {
        transform
          ..translateByDouble(placement.size.width / 2, placement.size.height / 2, 0, 1)
          ..rotateZ(theta)
          ..translateByDouble(-placement.size.width / 2, -placement.size.height / 2, 0, 1);
      }

      context.paintChild(index, transform: transform);
    }
  }

  @override
  bool shouldRepaint(covariant _QuiOrbitFlowDelegate oldDelegate) {
    return oldDelegate.placements != placements ||
        oldDelegate.radius != radius ||
        oldDelegate.rotationDirection != rotationDirection ||
        oldDelegate.rotateItems != rotateItems ||
        oldDelegate.animationsDisabled != animationsDisabled;
  }

  @override
  bool shouldRelayout(covariant _QuiOrbitFlowDelegate oldDelegate) {
    return oldDelegate.placements != placements;
  }
}
