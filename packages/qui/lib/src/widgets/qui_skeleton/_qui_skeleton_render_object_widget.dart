part of 'qui_skeleton.dart';

class _QuiSkeletonRenderObjectWidget extends SingleChildRenderObjectWidget {
  const _QuiSkeletonRenderObjectWidget({
    required this.colors,
    required this.effect,
    required this.effectAnimation,
    required super.child,
  });

  final QuiColors colors;
  final QuiSkeletonEffect? effect;
  final Animation<double>? effectAnimation;

  @override
  _RenderQuiSkeleton createRenderObject(BuildContext context) {
    return _RenderQuiSkeleton(colors: colors, effect: effect, effectAnimation: effectAnimation);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    if (renderObject is _RenderQuiSkeleton) {
      renderObject
        ..colors = colors
        ..effect = effect
        ..effectAnimation = effectAnimation;
    }
  }
}
