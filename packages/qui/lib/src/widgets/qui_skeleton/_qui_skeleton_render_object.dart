part of 'qui_skeleton.dart';

class _RenderQuiSkeleton extends RenderProxyBox {
  _RenderQuiSkeleton({
    required Color skeletonColor,
    required Color shimmerGlowColor,
    required this._shimmerAnimation,
    required this._shimmer,
  }) : _skeletonColor = skeletonColor,
       _shimmerGlowColor = shimmerGlowColor,
       _shimmerColors = <Color>[skeletonColor, shimmerGlowColor, skeletonColor] {
    _solidSkeletonPaint.color = skeletonColor;
  }

  static const _shimmerStops = <double>[0.1, 0.3, 0.4];

  final Paint _solidSkeletonPaint = Paint();
  final Paint _shimmerSkeletonPaint = Paint()..color = const Color(0xFFFFFFFF);
  final List<Color> _shimmerColors;
  final _QuiSkeletonLeafRegistry _leafRegistry = _QuiSkeletonLeafRegistry();

  Color _skeletonColor;
  Color _shimmerGlowColor;
  Animation<double>? _shimmerAnimation;
  bool _shimmer;

  Color get skeletonColor => _skeletonColor;
  Color get shimmerGlowColor => _shimmerGlowColor;
  Animation<double>? get shimmerAnimation => _shimmerAnimation;
  bool get shimmer => _shimmer;

  set skeletonColor(Color value) {
    if (value == _skeletonColor) return;

    _skeletonColor = value;
    _shimmerColors[0] = value;
    _shimmerColors[2] = value;
    _solidSkeletonPaint.color = value;

    markNeedsPaint();
  }

  set shimmerGlowColor(Color value) {
    if (value == _shimmerGlowColor) return;

    _shimmerGlowColor = value;
    _shimmerColors[1] = value;

    markNeedsPaint();
  }

  set shimmerAnimation(Animation<double>? value) {
    if (identical(value, _shimmerAnimation)) return;

    _shimmerAnimation?.removeListener(markNeedsPaint);
    _shimmerAnimation = value;
    _shimmerAnimation?.addListener(markNeedsPaint);

    if (value != null) markNeedsPaint();
  }

  set shimmer(bool value) {
    if (value == _shimmer) return;
    _shimmer = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _shimmerAnimation?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _shimmerAnimation?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final bounds = offset & size;
    _leafRegistry.clear();

    final skeletonPaint = _buildSkeletonPaint(bounds);
    final skeletonLayer = OffsetLayer();

    context.pushLayer(
      skeletonLayer,
      (layerContext, layerOffset) {
        final skeletonContext = _QuiSkeletonPaintingContext(skeletonLayer, bounds, _leafRegistry, skeletonPaint);

        if (_shimmer) skeletonContext.setWillChangeHint();

        super.paint(skeletonContext, layerOffset);
        skeletonContext.finish();
      },

      offset,
      childPaintBounds: bounds,
    );
  }

  Paint _buildSkeletonPaint(Rect bounds) {
    if (!_shimmer) return _solidSkeletonPaint;

    final t = _shimmerAnimation?.value ?? 0.0;
    final dx = bounds.width * t;
    final centerY = bounds.center.dy;
    final shader = ui.Gradient.linear(
      Offset(bounds.left + dx, centerY),
      Offset(bounds.right + dx, centerY),
      _shimmerColors,
      _shimmerStops,
      TileMode.clamp,
    );

    return _shimmerSkeletonPaint..shader = shader;
  }
}
