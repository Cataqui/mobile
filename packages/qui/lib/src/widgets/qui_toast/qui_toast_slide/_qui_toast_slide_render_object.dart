part of '../qui_toast.dart';

class _RenderQuiToastSlide extends RenderProxyBox {
  _RenderQuiToastSlide({required this._position}) {
    _position?.addListener(markNeedsPaint);
  }

  Animation<Offset>? _position;

  Animation<Offset>? get position => _position;

  set position(Animation<Offset>? value) {
    if (identical(value, _position)) return;
    _position?.removeListener(markNeedsPaint);
    _position = value;
    _position?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _position?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _position?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;

    final translation = _position?.value ?? Offset.zero;
    if (translation == Offset.zero) {
      super.paint(context, offset);
      return;
    }

    super.paint(context, Offset(offset.dx + translation.dx * size.width, offset.dy + translation.dy * size.height));
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final translation = _position?.value ?? Offset.zero;
    transform.translateByDouble(translation.dx * size.width, translation.dy * size.height, 0, 1);
  }
}
