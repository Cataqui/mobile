part of 'qui_skeleton.dart';

class _QuiSkeletonRenderObjectWidget extends SingleChildRenderObjectWidget {
  const _QuiSkeletonRenderObjectWidget({
    required this.colors,
    required this.style,
    required this.boneColor,
    required this.effectAnimation,
    required super.child,
  });

  final QuiColors colors;
  final QuiSkeletonStyle? style;
  final Color boneColor;
  final Animation<double>? effectAnimation;

  @override
  _RenderQuiSkeleton createRenderObject(BuildContext context) {
    return _RenderQuiSkeleton(
      colors: colors,
      style: style,
      boneColor: boneColor,
      effectAnimation: effectAnimation,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    if (renderObject is _RenderQuiSkeleton) {
      renderObject
        ..colors = colors
        ..style = style
        ..boneColor = boneColor
        ..effectAnimation = effectAnimation;
    }
  }
}
