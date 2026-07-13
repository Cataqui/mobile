part of 'qui_skeleton.dart';

class _QuiSkeletonRenderObjectWidget extends SingleChildRenderObjectWidget {
  const _QuiSkeletonRenderObjectWidget({
    required this.colorScheme,
    required this.style,
    required this.boneColor,
    required this.effectAnimation,
    required super.child,
  });

  final QuiColorScheme colorScheme;
  final QuiSkeletonStyle? style;
  final Color boneColor;
  final Animation<double>? effectAnimation;

  @override
  _RenderQuiSkeleton createRenderObject(BuildContext context) {
    return _RenderQuiSkeleton(
      colorScheme: colorScheme,
      style: style,
      boneColor: boneColor,
      effectAnimation: effectAnimation,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    if (renderObject is _RenderQuiSkeleton) {
      renderObject
        ..colorScheme = colorScheme
        ..style = style
        ..boneColor = boneColor
        ..effectAnimation = effectAnimation;
    }
  }
}
