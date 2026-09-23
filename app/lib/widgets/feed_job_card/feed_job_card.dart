import 'dart:async';

import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/views/job/job_view_transform_targets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class FeedJobCard extends ConsumerStatefulWidget {
  const FeedJobCard({required this.feedJob, super.key, this.skeleton = false});

  final FeedJobDto feedJob;
  final bool skeleton;

  @override
  ConsumerState<FeedJobCard> createState() => _FeedJobCardState();
}

class _FeedJobCardState extends ConsumerState<FeedJobCard> {
  @override
  Widget build(BuildContext context) {
    final transformTargets = ref.watch(jobViewTransformTargetsProvider(widget.feedJob.jobId));
    final colorScheme = MateoTheme.of(context).colorScheme;
    final i18n = ref.watch(translationProvider);

    return MateoPress(
      animation: MateoPressAnimationType.scale,
      fireHapticFeedback: true,
      onPressed: (animation) async {
        if (widget.skeleton) return;
        unawaited(
          ref
              .read(appRouterProvider.notifier)
              .push(context, JobRoute(jobId: widget.feedJob.jobId, $extra: widget.feedJob)),
        );
      },
      child: MateoSurface(
        width: const .fill(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),

        color: colorScheme.background,
        shape: const .rounded(radius: 42),
        elevation: MateoElevation(level: 0.6),
        animation: .transform(target: transformTargets.surface, contentEffects: [const .crossfade()]),
        child: Skeleton(
          enabled: widget.skeleton,
          style: SkeletonStyle(
            color: MateoTheme.of(context).colorScheme.skeleton.bone,
            effect: const SkeletonFadeEffect(),
            radius: const Radius.circular(999),
          ),
          child: Morph(
            targets: [transformTargets.header],
            flightConfig: const .auto(childSwitchAt: 0.01),
            child: Column(
              key: ValueKey(transformTargets.header),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  key: const ValueKey('job_time'),
                  widget.feedJob.createdAt.timeAgo(
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
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.feedJob.title,
                    key: const ValueKey('job_title'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.text.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      height: 1.2,
                    ),
                  ),
                ),
                Text(
                  key: const ValueKey('job_payment'),
                  widget.feedJob.payment ?? i18n.jobPayment.paymentFlexible,
                  style: TextStyle(
                    fontSize: 26,
                    color: colorScheme.text.profit,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    key: const ValueKey('job_description'),
                    widget.feedJob.descriptionSummary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.text.secondary,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
