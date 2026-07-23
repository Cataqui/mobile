import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/three_d.g.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/views/job/job_contact_button.dart';
import 'package:cataqui_app/views/job/job_state.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:cataqui_app/widgets/offline_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class JobView extends ConsumerStatefulWidget {
  const JobView({required this.jobId, this.feedJob, super.key});

  final String jobId;
  final FeedJobDto? feedJob;

  @override
  ConsumerState<JobView> createState() => _JobViewState();
}

class _JobViewState extends ConsumerState<JobView> {
  static const double _contactButtonBottomSpacing = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.mateo.colorScheme;
    final i18n = ref.watch(translationProvider);
    final jobState = ref.watch(jobStateProvider(widget.jobId));
    final jobData = jobState.asData?.value;
    final feedJob = widget.feedJob;

    return MateoSwipeToPopSurface(
      borderRadius: BorderRadiusGeometry.circular(34),
      sensibility: 0.15,
      swipeDown: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            MateoHeroBackground(
              tag: FeedJobCard.backgroundHeroKey(widget.jobId),
              decoration: BoxDecoration(color: colorScheme.background),
              edgeFade: MateoHeroEdgeFade.vertical,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: (const EdgeInsets.symmetric(horizontal: 28)).copyWith(
                          top: 90,
                          bottom:
                              JobContactButton.estimatedButtonHeight +
                              _contactButtonBottomSpacing +
                              MediaQuery.of(context).padding.bottom +
                              40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (feedJob != null || jobData != null) ...[
                              MateoHeroGroup(
                                tag: FeedJobCard.headerHeroKey(widget.jobId),
                                onEnd: HapticFeedback.lightImpact,
                                heroes: [
                                  MateoHeroText(
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
                                    padding: const EdgeInsets.only(bottom: 6),
                                  ),
                                  MateoHeroText(
                                    feedJob?.title ?? jobData!.job.title,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.text.primary,
                                    ),
                                  ),
                                  MateoHeroText(
                                    (feedJob?.payment ?? jobData!.job.payment).formatPayment(i18n),
                                    style: TextStyle(
                                      fontSize: 30,
                                      color: colorScheme.text.profit,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    padding: const EdgeInsets.only(bottom: 12),
                                  ),
                                  if (jobData != null)
                                    MateoHeroText(
                                      jobData.job.description,
                                      switchThreshold: 0.97,
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: colorScheme.text.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (feedJob != null)
                                jobState.when(
                                  data: (_) => const SizedBox.shrink(),
                                  error: (error, _) => _buildWhenRouteSettled(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 40),
                                      child: _buildError(context, i18n, error),
                                    ),
                                  ),
                                  loading: () => _buildWhenRouteSettled(
                                    child: MateoSkeleton(
                                      style: const MateoSkeletonStyle(effect: MateoSkeletonFadeEffect()),
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
                                ),
                            ] else ...[
                              jobState.when(
                                loading: () => SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.7,
                                  child: Center(
                                    child: MateoDotMatrix(
                                      width: 60,
                                      height: 60,
                                      radius: 30,
                                      dotSize: 6,
                                      color: context.mateo.palette.primary[9],
                                    ),
                                  ),
                                ),
                                error: (error, _) => SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.6,
                                  child: _buildError(context, i18n, error),
                                ),
                                data: (_) => const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Align(
                alignment: AlignmentGeometry.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildWhenRouteSettled(
                    child: MateoViewBackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      semanticLabel: i18n.navigation.back,
                    ),
                  ),
                ),
              ),
            ),
            if (jobState.isLoading || jobData != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: _contactButtonBottomSpacing),
                    child: Center(
                      child: _buildWhenRouteSettled(child: JobContactButton(jobId: widget.jobId)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Translations i18n, Object error) {
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
          $ThreeD.spilledCoffee(height: 140),
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
            onPressed: () => ref.read(jobStateProvider(widget.jobId).notifier).retry(),
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
