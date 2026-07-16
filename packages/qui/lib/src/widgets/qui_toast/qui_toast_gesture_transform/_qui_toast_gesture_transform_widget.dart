part of '../qui_toast.dart';

class _QuiToastGestureTransformWidget extends SingleChildRenderObjectWidget {
  const _QuiToastGestureTransformWidget({
    required this.resistanceListenable,
    required this.pressScaleAnimation,
    required super.child,
    super.key,
  });

  final Listenable? resistanceListenable;
  final Animation<double>? pressScaleAnimation;

  @override
  _RenderQuiToastGestureTransform createRenderObject(BuildContext context) {
    return _RenderQuiToastGestureTransform(
      resistanceListenable: resistanceListenable,
      pressScaleAnimation: pressScaleAnimation,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderQuiToastGestureTransform renderObject) {
    renderObject
      ..resistanceListenable = resistanceListenable
      ..pressScaleAnimation = pressScaleAnimation;
  }
}
