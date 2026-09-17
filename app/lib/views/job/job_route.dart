import 'dart:async';

import 'package:cataqui_app/core/app_router/app_route_data.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/views/job/job_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'job_route.g.dart';

@TypedGoRoute<JobRoute>(path: '/job/:jobId')
class JobRoute extends AppRouteData with $JobRoute {
  JobRoute({required this.jobId, required this.$extra});

  static const Duration pushDuration = Duration(milliseconds: 220);
  static const Duration popDuration = Duration(milliseconds: 230);

  final String jobId;
  final FeedJobDto $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final feedJob = $extra;
    unawaited(JobView.precacheImages(context));

    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return CustomTransitionPage<void>(
      opaque: false,
      transitionDuration: disableAnimations ? Duration.zero : pushDuration,
      reverseTransitionDuration: disableAnimations ? Duration.zero : popDuration,
      key: state.pageKey,
      barrierColor: Colors.black.withValues(alpha: 0.12),
      child: JobView(jobId: jobId, feedJob: feedJob),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }
}
