part of 'my_posts_carousel.dart';

class _MyPostsScrollController extends ScrollController {
  _MyPostsScrollController({required this.onBallisticTargetChanged});

  final ValueChanged<double?> onBallisticTargetChanged;

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) =>
      _MyPostsScrollPosition(
        physics: physics,
        context: context,
        onBallisticTargetChanged: onBallisticTargetChanged,
        oldPosition: oldPosition,
        initialPixels: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
        debugLabel: debugLabel,
      );
}
