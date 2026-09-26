import 'package:cataqui_app/core/app_router/app_route_data.dart';
import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/views/me/my_post/my_post_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'my_post_route.g.dart';

@TypedGoRoute<MyPostRoute>(path: '/me/post/:jobId')
class MyPostRoute extends AppRouteData with $MyPostRoute {
  const MyPostRoute({required this.jobId, required this.$extra});

  final String jobId;
  final UserJobSummaryDto $extra;

  @override
  bool get requiresAuthentication => true;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return CustomTransitionPage<void>(
      key: state.pageKey,
      opaque: false,
      transitionDuration: disableAnimations ? Duration.zero : const Duration(milliseconds: 180),
      reverseTransitionDuration: disableAnimations ? Duration.zero : const Duration(milliseconds: 50),
      child: MyPostView(summary: $extra),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }
}
