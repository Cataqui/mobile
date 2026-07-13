part of 'qui_tiktok_feed.dart';

class _QuiTikTokFeedFlowDelegate extends FlowDelegate {
  _QuiTikTokFeedFlowDelegate({
    required this.offsetListenable,
    required this.loadingLiftListenable,
    required this.viewportHeight,
    required this.viewportWidth,
    required this.spacing,
    required this.hasPreviousCard,
    required this.hasNextCard,
    required this.isAwaitMode,
    required this.loadingMoreOffset,
  }) : super(repaint: Listenable.merge([offsetListenable, loadingLiftListenable]));

  final ValueListenable<double> offsetListenable;
  final ValueListenable<double> loadingLiftListenable;
  final double viewportHeight;
  final double viewportWidth;
  final double spacing;
  final bool hasPreviousCard;
  final bool hasNextCard;
  final bool isAwaitMode;
  final double loadingMoreOffset;

  static const double _spinnerSize = _QuiTikTokFeedLoadingIndicator.indicatorBoxSize;

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
      _paintAwaitModeChildren(context: context, offsetY: offsetY);
      return;
    }

    if (hasNextCard && offsetY <= 0) {
      context.paintChild(1, transform: _translation(offsetY + viewportHeight + spacing));
    }

    context.paintChild(0, transform: _translation(offsetY));
  }

  void _paintAwaitModeChildren({required FlowPaintingContext context, required double offsetY}) {
    final translateY = loadingLiftListenable.value;

    if (offsetY >= 0) {
      _paintAwaitCurrentCard(context: context, translateY: translateY);
      return;
    }

    context.paintChild(0, transform: _translation(translateY + offsetY));

    if (hasNextCard) {
      context.paintChild(1, transform: _translation(offsetY + viewportHeight + spacing));
    }
  }

  void _paintAwaitCurrentCard({required FlowPaintingContext context, required double translateY}) {
    context.paintChild(0, transform: _translation(translateY));

    if (translateY >= 0) return;

    final cardBottom = viewportHeight + translateY;
    final spinnerX = (viewportWidth - _spinnerSize) * 0.5;
    final spinnerY = cardBottom;
    final opacity = _loadingOpacityFor(translateY);

    context.paintChild(3, transform: Matrix4.translationValues(spinnerX, spinnerY, 0), opacity: opacity);
  }

  Matrix4 _translation(double y) {
    return Matrix4.translationValues(0, y, 0);
  }

  double _loadingOpacityFor(double translateY) {
    if (loadingMoreOffset == 0) return 0;

    return (-translateY / loadingMoreOffset).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant _QuiTikTokFeedFlowDelegate oldDelegate) {
    return oldDelegate.offsetListenable != offsetListenable ||
        oldDelegate.loadingLiftListenable != loadingLiftListenable ||
        oldDelegate.viewportHeight != viewportHeight ||
        oldDelegate.viewportWidth != viewportWidth ||
        oldDelegate.spacing != spacing ||
        oldDelegate.hasPreviousCard != hasPreviousCard ||
        oldDelegate.hasNextCard != hasNextCard ||
        oldDelegate.isAwaitMode != isAwaitMode ||
        oldDelegate.loadingMoreOffset != loadingMoreOffset;
  }

  @override
  bool shouldRelayout(covariant _QuiTikTokFeedFlowDelegate oldDelegate) {
    return oldDelegate.viewportHeight != viewportHeight || oldDelegate.viewportWidth != viewportWidth;
  }
}
