part of 'qui_skeleton.dart';

class _QuiSkeletonRenderObjectWidget extends SingleChildRenderObjectWidget {
  const _QuiSkeletonRenderObjectWidget({
    required this.skeletonColor,
    required this.shimmerGlowColor,
    required this.shimmerAnimation,
    required this.shimmer,
    required super.child,
  });

  final Color skeletonColor;
  final Color shimmerGlowColor;
  final Animation<double>? shimmerAnimation;
  final bool shimmer;

  @override
  _RenderQuiSkeleton createRenderObject(BuildContext context) {
    return _RenderQuiSkeleton(
      skeletonColor: skeletonColor,
      shimmerGlowColor: shimmerGlowColor,
      shimmerAnimation: shimmerAnimation,
      shimmer: shimmer,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    if (renderObject is _RenderQuiSkeleton) {
      renderObject
        ..skeletonColor = skeletonColor
        ..shimmerGlowColor = shimmerGlowColor
        ..shimmerAnimation = shimmerAnimation
        ..shimmer = shimmer;
    }
  }
}
