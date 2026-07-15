import 'dart:async';

import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:qui/qui.dart';

class FeedJobCard extends ConsumerWidget {
  const FeedJobCard({required this.feedJob, super.key, this.skeleton = false});

  static String backgroundHeroKey(String jobId) => 'job-$jobId-surface';
  static String headerHeroKey(String jobId) => 'job-$jobId-header';

  final FeedJobDto feedJob;
  final bool skeleton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = context.qui.colorScheme;
    final i18n = ref.watch(translationProvider);

    return QuiTap(
      animation: QuiTapAnimationType.scale,
      fireHapticFeedback: false,
      onPressed: (animation) async {
        if (skeleton) return;
        unawaited(JobRoute(jobId: feedJob.jobId, $extra: feedJob).push(context));
      },
      child: QuiHeroBackground(
        tag: backgroundHeroKey(feedJob.jobId),
        width: double.infinity,
        decoration: BoxDecoration(color: colorScheme.background, borderRadius: BorderRadius.circular(38)),
        edgeFade: const QuiHeroEdgeFade(switchThreshold: 1),
        padding: const EdgeInsets.all(24),
        child: QuiSkeleton(
          style: const QuiSkeletonStyle(effect: QuiSkeletonFadeEffect(duration: Duration(seconds: 2))),
          enabled: skeleton,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              QuiHeroGroup(
                tag: headerHeroKey(feedJob.jobId),
                heroes: [
                  QuiHeroText(
                    feedJob.createdAt.timeAgo(
                      onNow: () => i18n.feedJob.timeAgo.now,
                      onMinutesAgo: (count) => i18n.feedJob.timeAgo.minutes(count: count),
                      onHoursAgo: (count) => i18n.feedJob.timeAgo.hours(count: count),
                      onDaysAgo: (count) => i18n.feedJob.timeAgo.days(count: count),
                      onMonthsAgo: (count) => i18n.feedJob.timeAgo.months(count: count),
                      fallback: TimeAgoFallback.finer,
                    ),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.text.tertiary),
                    padding: const EdgeInsets.only(bottom: 6),
                  ),
                  QuiHeroText(
                    feedJob.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    onStart: HapticFeedback.successNotification,
                    style: TextStyle(color: colorScheme.text.primary, fontWeight: FontWeight.w600, fontSize: 22),
                  ),
                  QuiHeroText(
                    padding: skeleton ? const EdgeInsets.only(top: 6) : EdgeInsets.zero,
                    feedJob.payment.formatPayment(i18n),
                    style: TextStyle(fontSize: 25, color: colorScheme.text.profit, fontWeight: FontWeight.w600),
                  ),
                  QuiHeroText(
                    padding: skeleton ? const EdgeInsets.only(top: 6) : const EdgeInsets.only(top: 4),
                    feedJob.descriptionSummary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    switchThreshold: 0.8,
                    style: TextStyle(fontSize: 16, color: colorScheme.text.secondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
