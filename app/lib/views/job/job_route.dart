import 'dart:async';

import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/views/job/job_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'job_route.g.dart';

@TypedGoRoute<JobRoute>(path: '/job/:jobId')
class JobRoute extends GoRouteData with $JobRoute {
  JobRoute({required this.jobId, this.$extra});

  static const Duration pushDuration = Duration(milliseconds: 270);
  static const Duration popDuration = Duration(milliseconds: 230);

  final String jobId;
  final FeedJobDto? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final feedJob = $extra;
    unawaited(JobView.precacheImages(context));

    if (feedJob == null) {
      return NoTransitionPage<void>(
        key: state.pageKey,
        child: JobView(jobId: jobId),
      );
    }

    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return CustomTransitionPage<void>(
      opaque: false,
      transitionDuration: disableAnimations ? Duration.zero : pushDuration,
      reverseTransitionDuration: disableAnimations ? Duration.zero : popDuration,
      key: state.pageKey,
      barrierColor: context.mateo.colorScheme.overlay.scrim,
      child: JobView(jobId: jobId, feedJob: feedJob),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }
}
