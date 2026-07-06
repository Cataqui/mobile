import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:cataqui_app/views/job/job_view.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:qui/qui.dart';

part 'job_route.g.dart';

@TypedGoRoute<JobRoute>(path: '/job/:jobId')
class JobRoute extends GoRouteData with $JobRoute {
  JobRoute({required this.jobId, this.$extra});

  final String jobId;
  final FeedJobDto? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final feedJob = $extra;

    if (feedJob == null) return NoTransitionPage<void>(key: state.pageKey, child: const FeedView());

    return QuiHeroPage(
      transitionDuration: const Duration(milliseconds: 400),
      key: state.pageKey,
      builder: (_) => JobView(feedJob: feedJob),
    );
  }
}
