import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

part 'feed_route.g.dart';

@TypedGoRoute<FeedRoute>(path: '/')
class FeedRoute extends GoRouteData with $FeedRoute {
  const FeedRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const FeedView();
}
