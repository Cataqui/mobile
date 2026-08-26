import 'dart:async';

import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/views/job/widgets/job_surface/job_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class FeedJobCard extends ConsumerWidget {
  const FeedJobCard({required this.feedJob, super.key, this.skeleton = false});

  final FeedJobDto feedJob;
  final bool skeleton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = context.mateo.colorScheme;
    final i18n = ref.watch(translationProvider);
    final headerMorphTag = 'job-${feedJob.jobId}-header';

    return MateoTap(
      animation: MateoTapAnimationType.scale,
      fireHapticFeedback: false,
      onPressed: (animation) async {
        if (skeleton) return;
        unawaited(JobRoute(jobId: feedJob.jobId, $extra: feedJob).push(context));
      },
      child: JobSurface(
        jobId: feedJob.jobId,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.background,
          borderRadius: BorderRadius.circular(38),
          boxShadow: [
            BoxShadow(
              color: colorScheme.colors.neutral.solid.withValues(alpha: 0.05),
              blurRadius: 42,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: MateoSkeleton(
          effect: MateoSkeletonEffect.fade,
          enabled: skeleton,
          child: Morph(
            tag: headerMorphTag,
            curve: JobSurface.morphCurve,
            switchThreshold: 0.1,
            onStart: HapticFeedback.successNotification,
            child: Column(
              key: ValueKey(headerMorphTag),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  key: const ValueKey('job_time'),
                  feedJob.createdAt.timeAgo(
                    onNow: () => i18n.feedJob.timeAgo.now,
                    onMinutesAgo: (count) => i18n.feedJob.timeAgo.minutes(count: count),
                    onHoursAgo: (count) => i18n.feedJob.timeAgo.hours(count: count),
                    onDaysAgo: (count) => i18n.feedJob.timeAgo.days(count: count),
                    onMonthsAgo: (count) => i18n.feedJob.timeAgo.months(count: count),
                    fallback: TimeAgoFallback.finer,
                  ),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.text.tertiary),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    feedJob.title,
                    key: const ValueKey('job_title'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.text.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      height: 1.2, // arrumar height + sapcing
                    ),
                  ),
                ),
                Text(
                  key: const ValueKey('job_payment'),
                  feedJob.payment.formatPayment(i18n),
                  style: TextStyle(
                    fontSize: 26,
                    color: colorScheme.text.profit,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                Text(
                  key: const ValueKey('job_description'),
                  feedJob.descriptionSummary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: colorScheme.text.secondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
