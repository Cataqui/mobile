import 'package:cataqui_app/core/app_router/app_route_data.dart';
import 'package:cataqui_app/views/post/post_view.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'post_route.g.dart';

@TypedGoRoute<PostRoute>(path: '/post')
class PostRoute extends AppRouteData with $PostRoute {
  const PostRoute();

  @override
  bool get requiresAuthentication => true;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return MateoPage<void>(
      allowSnapshotting: false,
      key: state.pageKey,
      child: const PostView(),
      transition: MateoPageTransition.wash(
        direction: MateoPageTransitionDirection.up,
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}
