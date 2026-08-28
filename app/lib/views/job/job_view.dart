import 'dart:async';

import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/illustrations.g.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/job/job_contact_button.dart';
import 'package:cataqui_app/views/job/job_state.dart';
import 'package:cataqui_app/views/job/widgets/job_surface/job_surface.dart';
import 'package:cataqui_app/widgets/offline_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class JobView extends ConsumerWidget {
  const JobView({required this.jobId, this.feedJob, super.key});

  static Future<void> precacheImages(BuildContext context) async {
    await Future.wait([
      $IllustrationsCache.precacheSpilledCoffee(context, height: _errorIllustrationHeight),
      OfflineErrorState.precacheImages(context),
    ]);
  }

  static const _errorIllustrationHeight = 140.0;

  final String jobId;
  final FeedJobDto? feedJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = context.mateo.colorScheme;
    final i18n = ref.watch(translationProvider);
    final jobState = ref.watch(jobStateProvider(jobId));
    final jobData = jobState.asData?.value;
    final headerMorphTag = 'job-$jobId-header';

    return MateoSwipeToPopSurface(
      borderRadius: BorderRadiusGeometry.circular(34),
      sensibility: 0.15,
      swipeDown: true,
      child: MateoScrollableView(
        backgroundColor: Colors.transparent,
        edgeFade: null,
        header: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          child: Align(
            alignment: AlignmentGeometry.topLeft,
            child: _buildWhenRouteSettled(
              child: MateoFloatingActionButton(
                semanticLabel: i18n.navigation.back,
                onPressed: () {
                  unawaited(Navigator.of(context).maybePop());
                },
                iconBuilder: (state) => MateoIcon.arrowLeft(color: state.foregroundColor),
                backgroundColor: context.mateo.colorScheme.background,
                foregroundColor: context.mateo.colorScheme.text.primary,
                size: 50,
              ),
            ),
          ),
        ),
        footer: jobState.isLoading || jobData != null
            ? Center(
                child: _buildWhenRouteSettled(child: JobContactButton(jobId: jobId)),
              )
            : null,
        bodySurfaceBuilder: (context, scrollable) => JobSurface(
          jobId: jobId,
          decoration: BoxDecoration(color: colorScheme.background),
          edgeFadeStyle: MateoEdgeFadeStyle(color: colorScheme.background),
          fadeTop: true,
          fadeBottom: true,
          child: scrollable,
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
          child: feedJob == null && jobData == null
              ? SizedBox(
                  height: 0,
                  child: jobState.when(
                    loading: () => Center(
                      child: MateoDotMatrix(
                        width: 60,
                        height: 60,
                        radius: 30,
                        dotSize: 6,
                        color: context.mateo.palette.accent[9],
                      ),
                    ),
                    error: (error, _) => _buildError(context, ref, i18n, error),
                    data: (_) => const SizedBox.shrink(),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Morph(
                      tag: headerMorphTag,
                      curve: JobSurface.morphCurve,
                      switchThreshold: 0.1,
                      onEnd: HapticFeedback.lightImpact,
                      child: Column(
                        key: ValueKey(headerMorphTag),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (feedJob?.createdAt ?? jobData!.job.createdAt).timeAgo(
                              onNow: () => i18n.feedJob.timeAgo.now,
                              onMinutesAgo: (count) => i18n.feedJob.timeAgo.minutes(count: count),
                              onHoursAgo: (count) => i18n.feedJob.timeAgo.hours(count: count),
                              onDaysAgo: (count) => i18n.feedJob.timeAgo.days(count: count),
                              onMonthsAgo: (count) => i18n.feedJob.timeAgo.months(count: count),
                              fallback: TimeAgoFallback.finer,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.text.secondary,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              feedJob?.title ?? jobData!.job.title,
                              key: const ValueKey('job_title'),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.text.primary,
                                height: 1.2, // arrumar height + sapcing
                              ),
                            ),
                          ),
                          Text(
                            key: const ValueKey('job_payment'),
                            (feedJob?.payment ?? jobData!.job.payment).formatPayment(i18n),
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
                    if (feedJob != null)
                      jobState.when(
                        data: (_) => const SizedBox.shrink(),
                        error: (error, _) {
                          return _buildWhenRouteSettled(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: _buildError(context, ref, i18n, error),
                            ),
                          );
                        },
                        loading: () => Skeleton(
                          style: SkeletonStyle(
                            color: colorScheme.skeleton.bone,
                            effect: const SkeletonFadeEffect(),
                            radius: const Radius.circular(999),
                          ),
                          child: Text(
                            JobDto.fixture().description,
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.text.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
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
          onRetry: () => ref.read(jobStateProvider(jobId).notifier).retry(),
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
            style: TextStyle(fontSize: 20, color: context.mateo.colorScheme.text.primary, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: 0.8,
            child: Text(
              i18n.job.error.description,
              style: TextStyle(
                fontSize: 17,
                color: context.mateo.colorScheme.text.secondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          MateoButton(
            variant: MateoButtonVariant.secondary,
            label: i18n.job.error.retryButtonTitle,
            leadingIconBuilder: (state) =>
                MateoIcon.arrowRotateClockwise(height: 15, width: 15, color: state.foregroundColor),
            leadingIconSpacing: 10,
            onPressed: () => ref.read(jobStateProvider(jobId).notifier).retry(),
          ),
        ],
      ),
    );
  }

  Widget _buildWhenRouteSettled({required Widget child}) {
    return RouteSettled(
      showTransition: (child, animation) => FadeTransition(opacity: animation, child: child),
      hideTransition: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: child,
    );
  }
}
