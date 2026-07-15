import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/views/job/job_contact_button.dart';
import 'package:cataqui_app/views/job/job_state.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:qui/qui.dart';

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
    final colorScheme = context.qui.colorScheme;
    final i18n = ref.watch(translationProvider);
    final jobState = ref.watch(jobStateProvider(widget.jobId));
    final jobData = jobState.asData?.value;
    final feedJob = widget.feedJob;

    return QuiSwipeToPopSurface(
      borderRadius: BorderRadiusGeometry.circular(34),
      sensibility: 0.15,
      swipeDown: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            QuiHeroBackground(
              tag: FeedJobCard.backgroundHeroKey(widget.jobId),
              decoration: BoxDecoration(color: colorScheme.background),
              edgeFade: QuiHeroEdgeFade.vertical,
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
                              QuiHeroGroup(
                                tag: FeedJobCard.headerHeroKey(widget.jobId),
                                onEnd: HapticFeedback.lightImpact,
                                heroes: [
                                  QuiHeroText(
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
                                  QuiHeroText(
                                    feedJob?.title ?? jobData!.job.title,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.text.primary,
                                    ),
                                  ),
                                  QuiHeroText(
                                    (feedJob?.payment ?? jobData!.job.payment).formatPayment(i18n),
                                    style: TextStyle(
                                      fontSize: 30,
                                      color: colorScheme.text.profit,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    padding: const EdgeInsets.only(bottom: 12),
                                  ),
                                  if (jobData != null)
                                    QuiHeroText(
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
                                  error: (error, _) => QuiRouteSettled(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 40),
                                      child: _buildError(context, i18n, error),
                                    ),
                                  ),
                                  loading: () => QuiRouteSettled(
                                    child: QuiSkeleton(
                                      style: const QuiSkeletonStyle(effect: QuiSkeletonFadeEffect()),
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
                                    child: QuiDotMatrix(
                                      width: 60,
                                      height: 60,
                                      radius: 30,
                                      dotSize: 6,
                                      color: colorScheme.colors.primary.solid,
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
                  child: QuiRouteSettled(child: QuiViewBackButton(onPressed: () => Navigator.of(context).maybePop(), semanticLabel: i18n.navigation.back)),
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
                      child: QuiRouteSettled(
                        child: JobContactButton(
                          jobId: widget.jobId,
                          contactReference: jobData?.job.contactReference,
                          isLoading: jobState.isLoading,
                        ),
                      ),
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
      return QuiOfflineErrorState(
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
          Qui3d.instance.build(context, (assets) => assets.spilledCoffee, height: 140),
          const SizedBox(height: 20),
          Text(
            i18n.job.error.title,
            style: TextStyle(fontSize: 20, color: context.qui.colorScheme.text.primary, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: 0.8,
            child: Text(
              i18n.job.error.description,
              style: TextStyle(
                fontSize: 17,
                color: context.qui.colorScheme.text.secondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          QuiButton(
            variant: QuiButtonVariant.secondary,
            label: i18n.job.error.retryButtonTitle,
            leadingIconBuilder: (state) => QuiIcons.instance.build(
              (assets) => assets.arrowRotateClockwise,
              height: 15,
              width: 15,
              colorFilter: ColorFilter.mode(state.foregroundColor, BlendMode.srcIn),
            ),
            leadingIconSpacing: 10,
            onPressed: () => ref.read(jobStateProvider(widget.jobId).notifier).retry(),
          ),
        ],
      ),
    );
  }
}
