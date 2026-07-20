part of 'qui_drag_resistance.dart';

class _QuiDragResistanceTransform extends SingleChildRenderObjectWidget {
  const _QuiDragResistanceTransform({required this.resistanceListenable, required super.child});

  final Listenable resistanceListenable;

  @override
  _RenderQuiDragResistanceTransform createRenderObject(BuildContext context) {
    return _RenderQuiDragResistanceTransform(resistanceListenable);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderQuiDragResistanceTransform renderObject) {
    renderObject.resistanceListenable = resistanceListenable;
  }
}
