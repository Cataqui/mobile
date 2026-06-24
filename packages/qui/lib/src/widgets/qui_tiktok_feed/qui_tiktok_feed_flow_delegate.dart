part of 'qui_tiktok_feed.dart';

class _QuiTikTokFeedFlowDelegate extends FlowDelegate {
  _QuiTikTokFeedFlowDelegate({
    required this.offsetListenable,
    required this.viewportHeight,
    required this.spacing,
    required this.currentIndex,
    required this.hasPreviousCard,
    required this.hasNextCard,
  }) : super(repaint: offsetListenable);

  final ValueListenable<double> offsetListenable;
  final double viewportHeight;
  final double spacing;
  final int currentIndex;
  final bool hasPreviousCard;
  final bool hasNextCard;

  @override
  BoxConstraints getConstraintsForChild(int index, BoxConstraints constraints) {
    return BoxConstraints.tight(constraints.biggest);
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final offsetY = offsetListenable.value;

    if (hasPreviousCard && offsetY > 0) {
      context.paintChild(2, transform: _translation(offsetY - viewportHeight - spacing));
    }

    if (hasNextCard && offsetY <= 0) {
      context.paintChild(1, transform: _translation(offsetY + viewportHeight + spacing));
    }

    context.paintChild(0, transform: _translation(offsetY));
  }

  Matrix4 _translation(double y) {
    return Matrix4.translationValues(0, y, 0);
  }

  @override
  bool shouldRepaint(covariant _QuiTikTokFeedFlowDelegate oldDelegate) {
    return oldDelegate.offsetListenable != offsetListenable ||
        oldDelegate.viewportHeight != viewportHeight ||
        oldDelegate.spacing != spacing ||
        oldDelegate.currentIndex != currentIndex ||
        oldDelegate.hasPreviousCard != hasPreviousCard ||
        oldDelegate.hasNextCard != hasNextCard;
  }

  @override
  bool shouldRelayout(covariant _QuiTikTokFeedFlowDelegate oldDelegate) {
    return oldDelegate.viewportHeight != viewportHeight;
  }
}
