part of 'my_posts_carousel.dart';

class _MyPostsFlickPhysics extends BouncingScrollPhysics {
  const _MyPostsFlickPhysics({super.parent});

  @override
  _MyPostsFlickPhysics applyTo(ScrollPhysics? ancestor) => _MyPostsFlickPhysics(parent: buildParent(ancestor));

  @override
  double get minFlingVelocity => kMinFlingVelocity;
}
