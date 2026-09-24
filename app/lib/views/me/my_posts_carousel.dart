import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/illustrations.g.dart';
import 'package:cataqui_app/views/me/my_post_card/my_post_card.dart';
import 'package:cataqui_app/views/me/my_posts_data.dart';
import 'package:cataqui_app/views/me/my_posts_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class MyPostsCarousel extends ConsumerStatefulWidget {
  const MyPostsCarousel({required this.viewportWidth, super.key});

  static const _cardPeek = 30.0;
  static const _cardSpacing = 12.0;

  final double viewportWidth;

  @override
  ConsumerState<MyPostsCarousel> createState() => _MyPostsWidgetState();
}

class _MyPostsWidgetState extends ConsumerState<MyPostsCarousel> {
  final ScrollController _jobsScrollController = ScrollController();

  void _loadNextPage() {
    final data = ref.read(myPostsStateProvider).value;
    if (!_jobsScrollController.hasClients) return;
    if (data == null || !data.hasMore || data.isLoadingMore || data.paginationError != null) return;

    final position = _jobsScrollController.position;
    final cardExtent = position.viewportDimension - MyPostsCarousel._cardPeek + MyPostsCarousel._cardSpacing;
    if (position.pixels + position.viewportDimension < (data.jobs.length - 3) * cardExtent) return;

    unawaited(ref.read(myPostsStateProvider.notifier).loadNextPage());
  }

  void _checkPaginationAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadNextPage();
    });
  }

  @override
  void initState() {
    super.initState();
    _jobsScrollController.addListener(_checkPaginationAfterLayout);
  }

  @override
  void dispose() {
    _jobsScrollController
      ..removeListener(_checkPaginationAfterLayout)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(myPostsStateProvider);

    return jobsState.when(
      skipLoadingOnRefresh: false,
      data: (data) => _buildJobs(context, data),
      error: (_, _) => _buildMessage(context, ref.watch(translationProvider).me.postsError, retry: true),
      loading: () => _buildCarousel(context),
    );
  }

  Widget _buildJobs(BuildContext context, MyPostsData? data) {
    if (data == null) return const SizedBox.shrink();
    if (data.jobs.isEmpty) return _buildMessage(context, ref.watch(translationProvider).me.emptyPosts);
    return _buildCarousel(context, data: data);
  }

  Widget _buildCarousel(BuildContext context, {MyPostsData? data}) {
    final loading = data == null;
    final cardWidth = widget.viewportWidth - MyPostsCarousel._cardPeek;
    return Motion.list(
      key: const ValueKey('me_posts_entrance'),
      interactive: true,
      effects: const [
        MoveMotionEffect(
          begin: Offset(240, 0),
          end: Offset.zero,
          duration: Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          delay: Duration(milliseconds: 100),
        ),
        FadeInMotionEffect(
          duration: Duration(milliseconds: 450),
          delay: Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
        ),
      ],
      child: SizedBox(
        height: cardWidth / MyPostCard.aspectRatio,
        child: ListView.builder(
          key: const ValueKey('me_posts_list'),
          controller: _jobsScrollController,
          scrollDirection: .horizontal,
          clipBehavior: Clip.none,
          itemExtent: cardWidth + MyPostsCarousel._cardSpacing,
          itemCount: loading ? 2 : data.jobs.length + (data.hasMore || data.paginationError != null ? 1 : 0),
          itemBuilder: (context, index) {
            Widget card;
            if (!loading && index == data.jobs.length) {
              card = data.paginationError != null
                  ? _buildPaginationError(context, cardWidth)
                  : MyPostCard.skeleton(
                      skeletonEffect: const SkeletonFadeEffect(
                        duration: Duration(milliseconds: 850),
                        opacity: (end: 0.3, start: 1),
                      ),
                      skeletonSemanticsLabel: ref.watch(translationProvider).me.loadingMorePostsSemanticLabel,
                    );
            } else {
              card = loading ? const MyPostCard.skeleton() : MyPostCard(job: data.jobs[index]);
            }
            return Padding(
              padding: const EdgeInsets.only(right: MyPostsCarousel._cardSpacing),
              child: card,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaginationError(BuildContext context, double cardWidth) {
    final i18n = ref.watch(translationProvider).me;
    final colorScheme = MateoTheme.of(context).colorScheme;

    return SizedBox(
      width: cardWidth,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              $Illustrations.crying(key: const ValueKey('my_posts_pagination_error_illustration'), width: 124),
              const SizedBox(height: 32),
              Text(
                i18n.paginationError.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.text.primary),
              ),
              const SizedBox(height: 4),
              FractionallySizedBox(
                widthFactor: .8,
                child: Text(
                  i18n.paginationError.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.text.secondary),
                ),
              ),
              const SizedBox(height: 24),
              MateoButton(
                key: const ValueKey('my_posts_retry_next_page'),
                presentation: .label(
                  width: .fit,
                  size: .small,
                  leadingIcon: const MateoIcon(.arrowRotateClockwise),
                  variant: .secondary.neutral,
                  label: i18n.retryButtonTitle,
                ),
                onPressed: () => unawaited(ref.read(myPostsStateProvider.notifier).loadNextPage()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String message, {bool retry = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: MateoTheme.of(context).colorScheme.text.secondary),
          ),
          if (retry) ...[
            const SizedBox(height: 16),
            MateoButton(
              key: const ValueKey('my_posts_retry'),
              presentation: .label(
                width: .fit,
                variant: .secondary,
                label: ref.watch(translationProvider).me.retryButtonTitle,
              ),
              onPressed: () => ref.invalidate(myPostsStateProvider),
            ),
          ],
        ],
      ),
    );
  }
}
