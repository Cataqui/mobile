import 'dart:async';

import 'package:cataqui_app/core/app_router/app_route_data.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'feed_route.g.dart';

@TypedGoRoute<FeedRoute>(path: '/feed')
class FeedRoute extends AppRouteData with $FeedRoute {
  const FeedRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    unawaited(FeedView.precacheImages(context));

    return MateoPage(
      transition: MateoPageTransition.push(
        duration: const Duration(milliseconds: 550),
        direction: MateoPageTransitionDirection.up,
      ),
      child: const FeedView(),
    );
  }
}
