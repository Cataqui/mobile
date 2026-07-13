part of 'qui_skeleton.dart';

class _RenderQuiSkeleton extends RenderProxyBox {
  _RenderQuiSkeleton({
    required this._colorScheme,
    required this._style,
    required this._boneColor,
    required this._effectAnimation,
  }) {
    _solidSkeletonPaint.color = _boneColor;
  }

  final Paint _solidSkeletonPaint = Paint();
  final _QuiSkeletonLeafRegistry _leafRegistry = _QuiSkeletonLeafRegistry();

  QuiColorScheme _colorScheme;
  QuiSkeletonStyle? _style;
  Color _boneColor;
  Animation<double>? _effectAnimation;

  QuiColorScheme get colorScheme => _colorScheme;
  QuiSkeletonStyle? get style => _style;
  Color get boneColor => _boneColor;
  QuiSkeletonEffect? get effect => _style?.effect;
  Radius? get textRadius => _style?.textRadius;
  Animation<double>? get effectAnimation => _effectAnimation;

  set colorScheme(QuiColorScheme value) {
    if (value == _colorScheme) return;
    _colorScheme = value;

    markNeedsPaint();
  }

  set style(QuiSkeletonStyle? value) {
    if (value == _style) return;
    _style = value;
    markNeedsPaint();
  }

  set boneColor(Color value) {
    if (value == _boneColor) return;
    _boneColor = value;
    _solidSkeletonPaint.color = value;
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
        final skeletonContext = _QuiSkeletonPaintingContext(
          skeletonLayer,
          bounds,
          _leafRegistry,
          skeletonPaint,
          _style?.textRadius,
        );

        if (_style?.effect != null && _effectAnimation != null) skeletonContext.setWillChangeHint();

        super.paint(skeletonContext, layerOffset);
        skeletonContext.finish();
      },
      offset,
      childPaintBounds: bounds,
    );
  }

  Paint _buildSkeletonPaint(Rect bounds) {
    final effect = _style?.effect;
    if (effect == null) return _solidSkeletonPaint;

    final t = _effectAnimation?.value ?? 0.0;
    return effect.buildPaint(bounds: bounds, t: t, colorScheme: _colorScheme, style: _style!);
  }
}
