part of 'qui_drag_resistance.dart';

class _RenderQuiDragResistanceTransform extends RenderProxyBox {
  _RenderQuiDragResistanceTransform(this._resistanceListenable);

  Listenable _resistanceListenable;

  Listenable get resistanceListenable => _resistanceListenable;

  set resistanceListenable(Listenable value) {
    if (identical(value, _resistanceListenable)) return;

    if (attached) _resistanceListenable.removeListener(markNeedsPaint);
    _resistanceListenable = value;
    if (attached) _resistanceListenable.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @visibleForTesting
  Offset get currentResistanceOffset {
    final listenable = _resistanceListenable;
    if (listenable is ValueListenable<Offset>) return listenable.value;
    return Offset.zero;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _resistanceListenable.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _resistanceListenable.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;

    final resistanceOffset = currentResistanceOffset;
    if (resistanceOffset == Offset.zero) {
      super.paint(context, offset);
      return;
    }

    super.paint(context, offset + resistanceOffset);
  }
}
