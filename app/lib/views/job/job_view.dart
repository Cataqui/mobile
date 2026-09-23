import 'dart:async';

import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/illustrations.g.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/job/job_contact_button.dart';
import 'package:cataqui_app/views/job/job_state.dart';
import 'package:cataqui_app/views/job/job_view_transform_targets.dart';
import 'package:cataqui_app/widgets/offline_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class JobView extends ConsumerStatefulWidget {
  const JobView({required this.jobId, required this.feedJob, super.key});

  static Future<void> precacheImages(BuildContext context) async {
    await Future.wait([
      $IllustrationsCache.precacheSpilledCoffee(context, height: _errorIllustrationHeight),
      OfflineErrorState.precacheImages(context),
    ]);
  }

  static const _errorIllustrationHeight = 120.0;
  final String jobId;
  final FeedJobDto feedJob;

  @override
  ConsumerState<JobView> createState() => _JobViewState();
}

class _JobViewState extends ConsumerState<JobView> {
  @override
  Widget build(BuildContext context) {
    final transformTargets = ref.watch(jobViewTransformTargetsProvider(widget.jobId));
    final colorScheme = MateoTheme.of(context).colorScheme;
    final i18n = ref.watch(translationProvider);
    final jobState = ref.watch(jobStateProvider(widget.jobId));
    final jobData = jobState.asData?.value;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: InteractiveSwipeDismiss(
          direction: InteractiveSwipeDismissDirection.down,
          dragConfig: const InteractiveSwipeDismissDragConfig(freeDrag: true, sensitivity: 0.37, dismissFraction: 0.25),
          onDismiss: () {
            unawaited(ref.read(appRouterProvider.notifier).go(context, const FeedRoute()));
            return true;
          },
          child: MateoView(
            animation: .transform(target: transformTargets.surface, contentEffects: [const .crossfade()]),
            padding: const EdgeInsets.symmetric(horizontal: 28).copyWith(bottom: 28),
            header: MateoViewHeader(
              principal: InteractiveSwipeDismissHandle(
                key: const ValueKey('job_dismiss_handle'),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28, top: 12),
                  child: Center(
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: switch (MateoTheme.of(context).brightness) {
                          Brightness.light => MateoTheme.of(context).palette.neutral[6],
                          Brightness.dark => throw UnimplementedError('Dark mode color not implemented'),
                        },
                        shape: const MateoRoundedShapeBorder.capsule(),
                      ),
                      child: const SizedBox(key: ValueKey('job_dismiss_handle_visual'), width: 50, height: 7),
                    ),
                  ),
                ),
              ),
            ),
            footer: jobState.isLoading || (jobData != null && jobData.job.status == JobStatus.active)
                ? MateoViewFooter(principal: JobContactButton(jobId: widget.jobId))
                : null,
            surface: .scrollable(
              key: const ValueKey('job_surface'),
              color: colorScheme.background,
              shape: const .rounded(radius: 52),
              edgeEffect: .fade(),
              padding: const EdgeInsets.symmetric(horizontal: 32).copyWith(top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Morph(
                    targets: [transformTargets.header],
                    flightConfig: const .auto(childSwitchAt: 0.9),
                    child: Column(
                      key: ValueKey(transformTargets.header),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.feedJob.createdAt.timeAgo(
                            onNow: () => i18n.feedJob.timeAgo.now,
                            onMinutesAgo: (count) => i18n.feedJob.timeAgo.minutes(count: count),
                            onHoursAgo: (count) => i18n.feedJob.timeAgo.hours(count: count),
                            onDaysAgo: (count) => i18n.feedJob.timeAgo.days(count: count),
                            onMonthsAgo: (count) => i18n.feedJob.timeAgo.months(count: count),
                            fallback: TimeAgoFallback.finer,
                          ),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.text.tertiary),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.feedJob.title,
                            key: const ValueKey('job_title'),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.text.primary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        Text(
                          key: const ValueKey('job_payment'),
                          widget.feedJob.payment.formatPayment(i18n),
                          style: TextStyle(
                            fontSize: 30,
                            color: colorScheme.text.profit,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        if (jobData != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Motion(
                              effect: const FadeInMotionEffect(duration: Duration(milliseconds: 200)),
                              child: Text(
                                jobData.job.description,
                                key: const ValueKey('job_description'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.text.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  jobState.when(
                    data: (_) => const SizedBox.shrink(),
                    error: (error, _) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: _buildError(context, ref, i18n, error),
                      );
                    },
                    loading: () => Skeleton(
                      style: SkeletonStyle(
                        color: MateoTheme.of(context).palette.neutral[4],
                        effect: const SkeletonFadeEffect(),
                        radius: const Radius.circular(999),
                      ),
                      child: Text(
                        JobDto.fixture().description,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, color: colorScheme.text.secondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Translations i18n, Object error) {
    if (error.isOfflineConnectionDioException) {
      return OfflineErrorState(
        title: i18n.feed.offline.title,
        description: i18n.feed.offline.description,
        retry: (
          label: i18n.feed.offline.retryButtonTitle,
          onRetry: () => ref.read(jobStateProvider(widget.jobId).notifier).retry(),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          $Illustrations.spilledCoffee(height: JobView._errorIllustrationHeight),
          const SizedBox(height: 20),
          Text(
            i18n.job.error.title,
            style: TextStyle(
              fontSize: 18,
              color: MateoTheme.of(context).colorScheme.text.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: 0.8,
            child: Text(
              i18n.job.error.description,
              style: TextStyle(
                fontSize: 16,
                color: MateoTheme.of(context).colorScheme.text.secondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          MateoButton(
            presentation: .label(
              width: .fit,
              variant: .secondary,
              label: i18n.job.error.retryButtonTitle,
              leadingIcon: const MateoIcon(.arrowRotateClockwise),
            ),
            onPressed: () => ref.read(jobStateProvider(widget.jobId).notifier).retry(),
          ),
        ],
      ),
    );
  }
}
