part of 'my_posts_carousel.dart';

class _MyPostsScrollPosition extends ScrollPositionWithSingleContext {
  _MyPostsScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
    super.keepScrollOffset,
    super.debugLabel,
  });

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) =>
      _MyPostsDrag(super.drag(details, dragCancelCallback));
}
