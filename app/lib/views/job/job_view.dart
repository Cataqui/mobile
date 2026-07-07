import 'dart:async';

import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/views/job/job_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:qui/qui.dart';

class JobView extends ConsumerStatefulWidget {
  const JobView({required this.feedJob, super.key});

  final FeedJobDto feedJob;

  @override
  ConsumerState<JobView> createState() => _JobViewState();
}

class _JobViewState extends ConsumerState<JobView> {
  final QuiAppearController _backButtonAppearController = QuiAppearController();
  final QuiAppearController _descriptionAppearController = QuiAppearController();
  final ScrollController _scrollController = ScrollController();

  bool _hasInitiatedAppear = false;
  Timer? _appearTimer;

  @override
  void dispose() {
    _appearTimer?.cancel();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitiatedAppear) return;
    _hasInitiatedAppear = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _backButtonAppearController.appear();
      _descriptionAppearController.appear();
    } else {
      _appearTimer = Timer(QuiHeroPage.defaultTransitionDuration, () {
        if (mounted) {
          _backButtonAppearController.appear();
          _descriptionAppearController.appear();
        }
      });
    }
  }

  void _popAfterHidingChrome() {
    _backButtonAppearController.destroy();
    _descriptionAppearController.destroy();

    if (MediaQuery.disableAnimationsOf(context)) {
      unawaited(Navigator.of(context).maybePop());
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(Navigator.of(context).maybePop());
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.qui.colors;
    final i18n = ref.watch(translationProvider);
    final jobState = ref.watch(jobStateProvider(widget.feedJob.jobId));
    final jobData = jobState.asData?.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          QuiHeroBackground(
            tag: 'job-${widget.feedJob.jobId}-surface',
            decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(50)),
            edgeFade: QuiHeroEdgeFade(bottom: QuiEdgeFadeStyle(color: colors.background)),
            onStart: () {
              _backButtonAppearController.destroy();
              _descriptionAppearController.destroy();
            },

            extensions: [
              QuiHeroSwipeToPopExtension(
                scrollController: _scrollController,
                sensibility: 0.85,
                onSwipeStateChanged: (state) {
                  if (state == QuiHeroSwipeToPopState.idle) {
                    _backButtonAppearController.appear();
                    _descriptionAppearController.appear();
                  }
                },
              ),
            ],
            child: SafeArea(
              bottom: false,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20).copyWith(top: 90),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          QuiHeroGroup(
                            tag: 'job-${widget.feedJob.jobId}-header',
                            onEnd: HapticFeedback.lightImpact,
                            heroes: [
                              QuiHeroText(
                                widget.feedJob.formatCreatedAtAgo(i18n, now: clock.now()),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.placeholder),
                                padding: const EdgeInsets.only(bottom: 6),
                              ),
                              QuiHeroText(
                                widget.feedJob.title,
                                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: colors.textPrimary),
                              ),
                              QuiHeroText(
                                widget.feedJob.payment.formatPayment(i18n),
                                style: TextStyle(fontSize: 30, color: colors.money, fontWeight: FontWeight.w600),
                                padding: const EdgeInsets.only(bottom: 8),
                              ),
                              if (jobData != null)
                                QuiHeroText(
                                  jobData.job.description,
                                  switchThreshold: 0.97,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          jobState.when(
                            data: (_) => const SizedBox.shrink(),
                            error: (error, _) => QuiAppear(
                              controller: _descriptionAppearController,
                              destroyDuration: Duration.zero,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: _buildError(context, i18n, error),
                              ),
                            ),
                            loading: () => QuiAppear(
                              controller: _descriptionAppearController,
                              destroyDuration: Duration.zero,
                              child: QuiSkeleton(
                                style: const QuiSkeletonStyle(effect: QuiSkeletonShimmerEffect()),
                                child: Text(
                                  JobDto.fixture().description,
                                  style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: AlignmentGeometry.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: QuiAppear(
                  controller: _backButtonAppearController,
                  destroyDuration: Duration.zero,
                  child: QuiViewBackButton(onPressed: _popAfterHidingChrome),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Translations i18n, Object error) {
    if (error.isOmfOfflineConnectionDioException) {
      return QuiOfflineErrorState(
        title: i18n.feed.offline.title,
        description: i18n.feed.offline.description,
        retry: (
          label: i18n.feed.offline.retryButtonTitle,
          onRetry: () => ref.read(jobStateProvider(widget.feedJob.jobId).notifier).retry(),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Qui3d.spilledCoffee.downsampledImage(context, height: 140),
          const SizedBox(height: 20),
          Text(
            i18n.job.error.title,
            style: TextStyle(fontSize: 20, color: context.qui.colors.textPrimary, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: 0.8,
            child: Text(
              i18n.job.error.description,
              style: TextStyle(fontSize: 17, color: context.qui.colors.textSecondary, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          QuiSecondaryButton(
            label: i18n.job.error.retryButtonTitle,
            leadingIconBuilder: (state) => QuiIcons.arrowRotateClockwise.svg(
              height: 15,
              width: 15,
              colorFilter: ColorFilter.mode(state.recommendedIconColor, BlendMode.srcIn),
            ),
            leadingIconSpacing: 10,
            onPressed: () => ref.read(jobStateProvider(widget.feedJob.jobId).notifier).retry(),
          ),
        ],
      ),
    );
  }
}
