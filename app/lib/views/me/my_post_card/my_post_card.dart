import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/widgets/post_status_dot.dart';
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
    return Skeleton(
      enabled: skeleton,
      transition: const .crossfade(duration: Duration(milliseconds: 240)),
      semanticsLabel: skeletonSemanticsLabel ?? ref.watch(translationProvider).me.myPosts.loadingPostSemanticLabel,
      style: SkeletonStyle(color: skeletonColor, radius: const Radius.circular(_radius), effect: skeletonEffect),
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
                  child: _buildDetails(context, ref, job),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, WidgetRef ref, UserJobSummaryDto job) {
    final i18n = ref.watch(translationProvider);
    final colorScheme = MateoTheme.of(context).colorScheme;
    return MateoSurface(
      color: colorScheme.background,
      shape: const .rounded(radius: _radius - _detailsInset),
      width: const .fill(),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                job.createdAt.timeAgo(
                  onNow: () => i18n.feedJob.timeAgo.now,
                  onMinutesAgo: (count) => i18n.feedJob.timeAgo.minutes(count: count),
                  onHoursAgo: (count) => i18n.feedJob.timeAgo.hours(count: count),
                  onDaysAgo: (count) => i18n.feedJob.timeAgo.days(count: count),
                  onMonthsAgo: (count) => i18n.feedJob.timeAgo.months(count: count),
                  fallback: TimeAgoFallback.finer,
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.text.tertiary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                job.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.text.primary,
                  height: 1.2,
                ),
              ),
              Text(
                job.payment ?? i18n.jobPayment.paymentFlexible,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.text.profit,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                job.descriptionSummary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.text.secondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
          Positioned(top: 0, right: 0, child: MyPostStatusDot(status: job.status)),
        ],
      ),
    );
  }
}
