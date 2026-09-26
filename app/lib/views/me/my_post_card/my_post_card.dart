import 'dart:async';

import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/my_post/my_post_header_flight_delegate.dart';
import 'package:cataqui_app/views/me/my_post/my_post_header_surface.dart';
import 'package:cataqui_app/views/me/my_post/my_post_morph_target.dart';
import 'package:cataqui_app/views/me/my_post/my_post_route.dart';
import 'package:cataqui_app/widgets/job_location_map/job_location_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'scroll_deferred_job_location_map.dart';

class MyPostCard extends ConsumerWidget {
  const MyPostCard({required UserJobSummaryDto this.job, super.key})
    : skeletonEffect = null,
      skeletonSemanticsLabel = null;
  const MyPostCard.skeleton({this.skeletonEffect, this.skeletonSemanticsLabel, super.key}) : job = null;

  static const aspectRatio = 0.8;
  static const _radius = 42.0;
  static const _detailsInset = 9.0;

  final UserJobSummaryDto? job;
  final SkeletonEffect? skeletonEffect;
  final String? skeletonSemanticsLabel;

  bool get skeleton => job == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skeletonColor = MateoTheme.of(context).palette.neutral[2];
    final currentJob = job;
    return MateoPress(
      animation: .scale,
      onPressed: currentJob == null
          ? null
          : (_) => unawaited(
              ref
                  .read(appRouterProvider.notifier)
                  .push(context, MyPostRoute(jobId: currentJob.jobId, $extra: currentJob)),
            ),
      child: Skeleton(
        enabled: skeleton,
        transition: const .crossfade(duration: Duration(milliseconds: 240)),
        semanticsLabel: skeletonSemanticsLabel ?? ref.watch(translationProvider).me.myPosts.loadingPostSemanticLabel,
        style: SkeletonStyle(
          color: skeletonColor,
          shape: const MateoRoundedShapeBorder(radius: _radius),
          effect: skeletonEffect,
        ),
        child: MateoSurface(
          width: const .fill(),
          color: skeletonColor,
          shape: const .rounded(radius: _radius),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Stack(
              fit: .expand,
              children: [
                if (job case final job?) ...[
                  _ScrollDeferredJobLocationMap(
                    map: JobLocationMap(
                      location: (latitude: job.location.latitude, longitude: job.location.longitude),
                      areaDiameterInMeters: job.location.areaRadius.toDouble(),
                      zoom: 13,
                      offset: const Offset(0, 92),
                    ),
                  ),
                  Positioned(
                    left: _detailsInset,
                    right: _detailsInset,
                    top: _detailsInset,
                    child: Morph(
                      targets: [ref.watch(myPostMorphTargetProvider(job.jobId))],
                      flightConfig: const .custom(MyPostHeaderFlightDelegate()),
                      child: MyPostHeaderSurface(
                        summary: job,
                        timeAgo: MyPostHeaderSurface.timeAgoFor(job, ref.watch(translationProvider)),
                        payment: job.payment ?? ref.watch(translationProvider).jobPayment.paymentFlexible,
                        expansion: 0,
                        description: job.descriptionSummary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
