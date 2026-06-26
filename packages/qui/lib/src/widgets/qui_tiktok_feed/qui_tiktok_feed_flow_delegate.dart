part of 'qui_tiktok_feed.dart';

class _QuiTikTokFeedFlowDelegate extends FlowDelegate {
  _QuiTikTokFeedFlowDelegate({
    required this.offsetListenable,
    required this.scaleListenable,
    required this.viewportHeight,
    required this.viewportWidth,
    required this.spacing,
    required this.currentIndex,
    required this.hasPreviousCard,
    required this.hasNextCard,
    required this.isAwaitMode,
    required this.loadingMoreOffset,
  }) : super(repaint: Listenable.merge([offsetListenable, scaleListenable]));

  final ValueListenable<double> offsetListenable;
  final ValueListenable<double> scaleListenable;
  final double viewportHeight;
  final double viewportWidth;
  final double spacing;
  final int currentIndex;
  final bool hasPreviousCard;
  final bool hasNextCard;
  final bool isAwaitMode;
  final double loadingMoreOffset;

  static const double _spinnerSize = _QuiTikTokFeedLoadingIndicator.indicatorSize;

  @override
  BoxConstraints getConstraintsForChild(int index, BoxConstraints constraints) {
    if (index == 3) return BoxConstraints.tight(const Size(_spinnerSize, _spinnerSize));

    return BoxConstraints.tight(constraints.biggest);
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final offsetY = offsetListenable.value;

    if (hasPreviousCard && offsetY > 0) {
      context.paintChild(2, transform: _translation(offsetY - viewportHeight - spacing));
    }

    if (isAwaitMode) {
      final translateY = scaleListenable.value;

      if (offsetY >= 0) {
        context.paintChild(0, transform: _translation(translateY));

        if (translateY < 0) {
          final cardBottom = viewportHeight + translateY;
          final spinnerX = (viewportWidth - _spinnerSize) * 0.5;
          final spinnerY = cardBottom;
          final opacity = (-translateY / loadingMoreOffset).clamp(0.0, 1.0);

          context.paintChild(3, transform: Matrix4.translationValues(spinnerX, spinnerY, 0), opacity: opacity);
        }
      } else {
        context.paintChild(0, transform: _translation(translateY + offsetY));

        if (hasNextCard) {
          context.paintChild(1, transform: _translation(offsetY + viewportHeight + spacing));
        }
      }
      return;
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
        oldDelegate.scaleListenable != scaleListenable ||
        oldDelegate.viewportHeight != viewportHeight ||
        oldDelegate.viewportWidth != viewportWidth ||
        oldDelegate.spacing != spacing ||
        oldDelegate.currentIndex != currentIndex ||
        oldDelegate.hasPreviousCard != hasPreviousCard ||
        oldDelegate.hasNextCard != hasNextCard ||
        oldDelegate.isAwaitMode != isAwaitMode ||
        oldDelegate.loadingMoreOffset != loadingMoreOffset;
  }

  @override
  bool shouldRelayout(covariant _QuiTikTokFeedFlowDelegate oldDelegate) {
    return oldDelegate.viewportHeight != viewportHeight;
  }
}
