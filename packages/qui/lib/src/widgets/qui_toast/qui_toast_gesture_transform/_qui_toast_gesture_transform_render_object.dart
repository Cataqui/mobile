part of '../qui_toast.dart';

class _RenderQuiToastGestureTransform extends RenderProxyBox {
  _RenderQuiToastGestureTransform({required this._resistanceListenable, required this._pressScaleAnimation}) {
    _resistanceListenable?.addListener(_handleResistanceChanged);
    _pressScaleAnimation?.addListener(markNeedsPaint);
  }

  Listenable? _resistanceListenable;
  Animation<double>? _pressScaleAnimation;

  Listenable? get resistanceListenable => _resistanceListenable;

  set resistanceListenable(Listenable? value) {
    if (identical(value, _resistanceListenable)) return;
    _resistanceListenable?.removeListener(_handleResistanceChanged);
    _resistanceListenable = value;
    _resistanceListenable?.addListener(_handleResistanceChanged);
    markNeedsPaint();
  }

  Animation<double>? get pressScaleAnimation => _pressScaleAnimation;

  set pressScaleAnimation(Animation<double>? value) {
    if (identical(value, _pressScaleAnimation)) return;
    _pressScaleAnimation?.removeListener(markNeedsPaint);
    _pressScaleAnimation = value;
    _pressScaleAnimation?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  void _handleResistanceChanged() => markNeedsPaint();

  @visibleForTesting
  Offset get currentResistanceOffset {
    final listenable = _resistanceListenable;
    if (listenable is ValueListenable<Offset>) return listenable.value;
    return Offset.zero;
  }

  @visibleForTesting
  double get currentScale => _pressScaleAnimation?.value ?? 1;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _resistanceListenable?.addListener(_handleResistanceChanged);
    _pressScaleAnimation?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _resistanceListenable?.removeListener(_handleResistanceChanged);
    _pressScaleAnimation?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;

    final resistanceOffset = currentResistanceOffset;
    final scale = currentScale;

    if (resistanceOffset == Offset.zero && scale == 1) {
      super.paint(context, offset);
      return;
    }

    final matrix = Matrix4.identity()
      ..translateByDouble(resistanceOffset.dx, resistanceOffset.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);

    final childOffset = MatrixUtils.getAsTranslation(matrix);
    if (childOffset != null) {
      super.paint(context, offset + childOffset);
      return;
    }

    final det = matrix.determinant();
    if (det == 0 || !det.isFinite) {
      layer = null;
      return;
    }

    layer = context.pushTransform(
      needsCompositing,
      offset,
      matrix,
      super.paint,
      oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
    );
  }
}
