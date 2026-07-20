part of 'qui_bottom_sheet.dart';

class _RenderQuiBottomSheetTransition extends RenderProxyBox {
  _RenderQuiBottomSheetTransition(this._animation, this._isInteractive);

  static const double _initialScale = 0.96;
  static const double _scaleRange = 1 - _initialScale;

  final Matrix4 _transform = Matrix4.identity();
  Animation<double> _animation;
  ValueGetter<bool> _isInteractive;
  double _cachedProgress = double.nan;
  Size _cachedSize = Size.zero;

  Animation<double> get animation => _animation;

  set animation(Animation<double> value) {
    if (identical(value, _animation)) return;

    if (attached) _animation.removeListener(_handleAnimationChanged);
    _animation = value;
    if (attached) _animation.addListener(_handleAnimationChanged);
    _invalidateTransform();
  }

  ValueGetter<bool> get isInteractive => _isInteractive;

  set isInteractive(ValueGetter<bool> value) {
    if (identical(value, _isInteractive)) return;

    _isInteractive = value;
    _invalidateTransform();
  }

  @visibleForTesting
  double get currentScale => _initialScale + (_scaleRange * _resolveProgress());

  @visibleForTesting
  double get currentVerticalTranslation => 1 - _resolveProgress();

  double _resolveProgress() {
    final value = _animation.value;
    if (_isInteractive()) return value;

    return Curves.easeOutCubic.transform(value);
  }

  void _handleAnimationChanged() {
    _cachedProgress = double.nan;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void _invalidateTransform() {
    _cachedProgress = double.nan;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  Matrix4 _resolveTransform() {
    final progress = _resolveProgress();
    if (_cachedProgress == progress && _cachedSize == size) return _transform;

    _cachedProgress = progress;
    _cachedSize = size;
    final scale = _initialScale + (_scaleRange * progress);
    final scaleOffset = 1 - scale;
    final storage = _transform.storage;
    storage[0] = scale;
    storage[5] = scale;
    storage[12] = scaleOffset * size.width * 0.5;
    storage[13] = (scaleOffset + 1 - progress) * size.height;
    return _transform;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(_handleAnimationChanged);
  }

  @override
  void detach() {
    _animation.removeListener(_handleAnimationChanged);
    super.detach();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintTransform(
      transform: _resolveTransform(),
      position: position,
      hitTest: (result, position) => super.hitTestChildren(result, position: position),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    final transform = _resolveTransform();
    if (_cachedProgress == 1) {
      super.paint(context, offset);
      layer = null;
      return;
    }

    layer = context.pushTransform(
      needsCompositing,
      offset,
      transform,
      super.paint,
      oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_resolveTransform());
  }
}
