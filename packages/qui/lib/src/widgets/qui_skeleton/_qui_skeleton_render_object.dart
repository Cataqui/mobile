part of 'qui_skeleton.dart';

class _RenderQuiSkeleton extends RenderProxyBox {
  _RenderQuiSkeleton({required QuiColors colors, required this._effect, required this._effectAnimation})
    : _colors = colors {
    _solidSkeletonPaint.color = colors.skeleton;
  }

  final Paint _solidSkeletonPaint = Paint();
  final _QuiSkeletonLeafRegistry _leafRegistry = _QuiSkeletonLeafRegistry();

  QuiColors _colors;
  QuiSkeletonEffect? _effect;
  Animation<double>? _effectAnimation;

  QuiColors get colors => _colors;
  QuiSkeletonEffect? get effect => _effect;
  Animation<double>? get effectAnimation => _effectAnimation;

  set colors(QuiColors value) {
    if (value == _colors) return;
    _colors = value;
    _solidSkeletonPaint.color = value.skeleton;
    markNeedsPaint();
  }

  set effect(QuiSkeletonEffect? value) {
    if (identical(value, _effect)) return;
    if (value != null && value == _effect) return;
    _effect = value;
    markNeedsPaint();
  }

  set effectAnimation(Animation<double>? value) {
    if (identical(value, _effectAnimation)) return;
    _effectAnimation?.removeListener(markNeedsPaint);
    _effectAnimation = value;
    _effectAnimation?.addListener(markNeedsPaint);
    if (value != null) markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _effectAnimation?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _effectAnimation?.removeListener(markNeedsPaint);
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

        if (_effect != null && _effectAnimation != null) skeletonContext.setWillChangeHint();

        super.paint(skeletonContext, layerOffset);
        skeletonContext.finish();
      },
      offset,
      childPaintBounds: bounds,
    );
  }

  Paint _buildSkeletonPaint(Rect bounds) {
    if (_effect == null) return _solidSkeletonPaint;

    final t = _effectAnimation?.value ?? 0.0;
    return _effect!.buildPaint(bounds: bounds, t: t, colors: _colors);
  }
}
