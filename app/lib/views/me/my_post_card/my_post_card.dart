import 'dart:async';

import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/my_post/my_post_header_flight_delegate.dart';
import 'package:cataqui_app/views/me/my_post/my_post_header_surface.dart';
import 'package:cataqui_app/views/me/my_post/my_post_morph_target.dart';
import 'package:cataqui_app/views/me/my_post/my_post_route.dart';
import 'package:cataqui_app/widgets/job_location_image/job_location_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

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
                if (currentJob != null) ...[
                  JobLocationImage(imageUrl: currentJob.location.imageUrl, size: .pixels960x960),
                  Positioned(
                    left: _detailsInset,
                    right: _detailsInset,
                    top: _detailsInset,
                    child: Morph(
                      targets: [ref.watch(myPostMorphTargetProvider(currentJob.jobId))],
                      flightConfig: const .custom(MyPostHeaderFlightDelegate()),
                      child: MyPostHeaderSurface(
                        summary: currentJob,
                        timeAgo: MyPostHeaderSurface.timeAgoFor(currentJob, ref.watch(translationProvider)),
                        payment: currentJob.payment ?? ref.watch(translationProvider).jobPayment.paymentFlexible,
                        expansion: 0,
                        description: currentJob.descriptionSummary,
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
