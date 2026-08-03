import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'feed_route.g.dart';

@TypedGoRoute<FeedRoute>(path: '/')
class FeedRoute extends GoRouteData with $FeedRoute {
  const FeedRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return MateoPage(
      transition: MateoPageTransition.fadeSlide(
        duration: const Duration(milliseconds: 550),
        direction: MateoPageTransitionDirection.up,
      ),
      child: const FeedView(),
    );
  }
}
