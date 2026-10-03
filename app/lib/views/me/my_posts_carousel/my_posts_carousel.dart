import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/static_map/static_map_request.dart';
import 'package:cataqui_app/gen/illustrations.g.dart';
import 'package:cataqui_app/views/me/my_post_card/my_post_card.dart';
import 'package:cataqui_app/views/me/my_posts_data.dart';
import 'package:cataqui_app/views/me/my_posts_state.dart';
import 'package:cataqui_app/views/post/post_route.dart';
import 'package:cataqui_app/widgets/job_location_image/job_location_image_prefetcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'my_posts_drag.dart';
part 'my_posts_flick_physics.dart';
part 'my_posts_scroll_controller.dart';
part 'my_posts_scroll_position.dart';

class MyPostsCarousel extends ConsumerStatefulWidget {
  const MyPostsCarousel({required this.viewportWidth, required this.rightOverflow, super.key});

  static const _cardPeek = 30.0;
  static const _cardSpacing = 12.0;

  final double viewportWidth;
  final double rightOverflow;

  @override
  ConsumerState<MyPostsCarousel> createState() => _MyPostsWidgetState();
}

class _MyPostsWidgetState extends ConsumerState<MyPostsCarousel> {
  static const _decodedLookahead = 2;

  late final ScrollController _jobsScrollController = _MyPostsScrollController(
    onBallisticTargetChanged: _onBallisticTargetChanged,
  );
  double? _arrivalPixels;
  late final JobLocationImagePrefetcher _imagePrefetcher;
  bool _workScheduled = false;
  bool _scrollingForward = true;
  bool _canPrefetch = true;
  double _previousPixels = 0;

  double get _cardWidth => widget.viewportWidth - MyPostsCarousel._cardPeek;

  double get _cardExtent => _cardWidth + MyPostsCarousel._cardSpacing;

  void _onBallisticTargetChanged(double? pixels) {
    _arrivalPixels = pixels;
    _checkPaginationAfterLayout();
  }

  void _loadNextPage() {
    if (!_canPrefetch) return;
    final data = ref.read(myPostsStateProvider).value;
    if (!_jobsScrollController.hasClients) return;
    if (data == null || !data.hasMore || data.isLoadingMore || data.paginationError != null) return;

    final position = _jobsScrollController.position;
    final upcomingPosition = math.max(position.pixels, _arrivalPixels ?? position.pixels);
    if (upcomingPosition + position.viewportDimension < (data.jobs.length - 6) * _cardExtent) return;

    unawaited(ref.read(myPostsStateProvider.notifier).loadNextPage());
  }

  void _checkPaginationAfterLayout() {
    if (_jobsScrollController.hasClients && _jobsScrollController.position.hasContentDimensions) {
      final position = _jobsScrollController.position;
      final pixels = position.pixels.clamp(position.minScrollExtent, position.maxScrollExtent);
      if (pixels != _previousPixels) _scrollingForward = pixels > _previousPixels;
      _previousPixels = pixels;
    }
    if (_workScheduled) return;
    _workScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _workScheduled = false;
      if (!mounted) return;
      _loadNextPage();
      _prefetchImages();
    });
  }

  void _prefetchImages() {
    final data = ref.read(myPostsStateProvider).asData?.value;
    if (!_canPrefetch || !_jobsScrollController.hasClients || data == null || data.jobs.isEmpty) {
      _imagePrefetcher.update(requests: []);
      return;
    }
    final position = _jobsScrollController.position;
    final pixels = position.pixels.clamp(position.minScrollExtent, position.maxScrollExtent);
    final firstVisible = (pixels / _cardExtent).floor();
    final lastVisible = ((pixels + position.viewportDimension) / _cardExtent).ceil() - 1;
    final direction = _scrollingForward ? 1 : -1;
    final nextIndex = _scrollingForward ? lastVisible + 1 : firstVisible - 1;
    final upcomingIndices = [
      for (var offset = 0; offset < 3; offset++)
        if (nextIndex + offset * direction >= 0 && nextIndex + offset * direction < data.jobs.length)
          nextIndex + offset * direction,
    ];
    final arrivalPixels = _arrivalPixels;
    final decodedIndices = <int>[];
    if (arrivalPixels != null && (arrivalPixels - pixels).abs() > _cardExtent * _decodedLookahead) {
      final arrival = arrivalPixels.clamp(position.minScrollExtent, position.maxScrollExtent);
      final firstArrival = (arrival / _cardExtent).floor();
      final lastArrival = ((arrival + position.viewportDimension) / _cardExtent).ceil() - 1;
      final arrivalCenter = arrival + position.viewportDimension / 2;
      final arrivalIndices =
          [
            for (var index = firstArrival; index <= lastArrival; index++)
              if (index >= 0 && index < data.jobs.length) index,
          ]..sort(
            (first, second) => (first * _cardExtent + _cardWidth / 2 - arrivalCenter).abs().compareTo(
              (second * _cardExtent + _cardWidth / 2 - arrivalCenter).abs(),
            ),
          );
      decodedIndices.addAll({
        ...arrivalIndices.take(1),
        ...upcomingIndices.take(1),
        ...arrivalIndices.skip(1).take(_decodedLookahead - 1),
      });
    } else {
      decodedIndices.addAll(upcomingIndices.take(_decodedLookahead));
    }
    final requests = <int, StaticMapRequest>{
      for (final index in {...decodedIndices, ...upcomingIndices})
        index: StaticMapRequest(imageUrl: data.jobs[index].location.imageUrl, size: .pixels960x960),
    };
    _imagePrefetcher.update(
      requests: [for (final index in upcomingIndices) requests[index]!],
      decodedRequests: [for (final index in decodedIndices) requests[index]!],
    );
  }

  Future<void> _prepareImage(StaticMapRequest request) => precacheImage(
    CachedNetworkImageProvider(request.url, cacheKey: request.cacheKey, cacheManager: _imagePrefetcher.cacheManager),
    context,
    onError: (error, stackTrace) {},
  );

  @override
  void initState() {
    super.initState();
    _imagePrefetcher = JobLocationImagePrefetcher(
      cacheManager: ref.read(staticMapCacheManagerProvider),
      prepareImage: _prepareImage,
    );
    _jobsScrollController.addListener(_checkPaginationAfterLayout);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _canPrefetch = (ModalRoute.isCurrentOf(context) ?? true) && TickerMode.valuesOf(context).enabled;
    if (!_canPrefetch) _imagePrefetcher.update(requests: []);
    _checkPaginationAfterLayout();
  }

  @override
  void dispose() {
    _imagePrefetcher.dispose();
    _jobsScrollController
      ..removeListener(_checkPaginationAfterLayout)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(myPostsStateProvider);
    _checkPaginationAfterLayout();

    return jobsState.when(
      skipLoadingOnRefresh: false,
      data: (data) => _buildJobs(context, data),
      error: (_, _) => _buildInitialLoadError(context),
      loading: () => _buildCarousel(context),
    );
  }

  Widget _buildJobs(BuildContext context, MyPostsData? data) {
    if (data == null) return const SizedBox.shrink();
    if (data.jobs.isEmpty) return _buildCarousel(context, empty: true);
    return _buildCarousel(context, data: data);
  }

  Widget _buildEmptyOverlay(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final background = MateoTheme.of(context).colorScheme.background;

    return Stack(
      fit: .expand,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          right: -widget.rightOverflow,
          child: TweenAnimationBuilder<double>(
            key: const ValueKey('my_posts_empty_fade'),
            tween: Tween(begin: 0, end: 1),
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
            builder: (context, progress, _) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    background.withValues(alpha: progress * .1),
                    background.withValues(alpha: progress * .65),
                    background.withValues(alpha: progress),
                  ],
                  stops: const [0, .45, 1],
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEmptyReveal(
                  key: const ValueKey('my_posts_empty_text_motion'),
                  delay: const Duration(milliseconds: 300),
                  startOffset: 24,
                  child: Text(
                    i18n.me.myPosts.empty,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: MateoTheme.of(context).colorScheme.text.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildEmptyReveal(
                  key: const ValueKey('my_posts_empty_button_motion'),
                  interactive: true,
                  delay: const Duration(milliseconds: 500),
                  startOffset: 20,
                  child: Center(
                    child: MateoButton(
                      key: const ValueKey('my_posts_create_button'),
                      presentation: .icon(variant: .secondary.neutral, icon: const MateoIcon(.plusSignal)),
                      onPressed: () => unawaited(ref.read(appRouterProvider.notifier).push(context, const PostRoute())),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyReveal({
    required Key key,
    required Duration delay,
    required double startOffset,
    required Widget child,
    bool interactive = false,
  }) {
    const duration = Duration(milliseconds: 400);
    const curve = Curves.easeOutCubic;
    return Motion.list(
      key: key,
      interactive: interactive,
      effects: [
        MoveMotionEffect(
          begin: Offset(0, startOffset),
          end: Offset.zero,
          delay: delay,
          duration: duration,
          curve: curve,
        ),
        FadeInMotionEffect(delay: delay, duration: duration, curve: curve),
      ],
      child: child,
    );
  }

  Widget _buildCarousel(BuildContext context, {MyPostsData? data, bool empty = false}) {
    return SizedBox(
      height: _cardWidth / MyPostCard.aspectRatio,
      child: Stack(
        fit: .expand,
        clipBehavior: Clip.none,
        children: [
          Motion.list(
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
            child: ExcludeSemantics(
              excluding: empty,
              child: IgnorePointer(
                ignoring: empty,
                child: _buildPostsList(context, data: data),
              ),
            ),
          ),
          if (empty) _buildEmptyOverlay(context),
        ],
      ),
    );
  }

  Widget _buildPostsList(BuildContext context, {MyPostsData? data}) {
    final loading = data == null;
    final cardWidth = _cardWidth;
    return SizedBox(
      height: cardWidth / MyPostCard.aspectRatio,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: Listener(
          onPointerUp: (event) {
            if (_jobsScrollController.hasClients) {
              (_jobsScrollController.position as _MyPostsScrollPosition).pointerUpTime = event.timeStamp;
            }
          },
          child: ListView.builder(
            key: const ValueKey('me_posts_list'),
            scrollCacheExtent: const ScrollCacheExtent.pixels(0),
            controller: _jobsScrollController,
            physics: const _MyPostsFlickPhysics(),
            scrollDirection: .horizontal,
            clipBehavior: Clip.none,
            itemExtent: _cardExtent,
            itemCount: loading ? 2 : data.jobs.length + (data.hasMore || data.paginationError != null ? 1 : 0),
            itemBuilder: (context, index) {
              Widget card;
              if (!loading && index == data.jobs.length) {
                card = data.paginationError != null
                    ? _buildPaginationError(context, cardWidth)
                    : MyPostCard.skeleton(
                        skeletonSemanticsLabel: ref.watch(translationProvider).me.myPosts.loadingMoreSemanticLabel,
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
      ),
    );
  }

  Widget _buildPaginationError(BuildContext context, double cardWidth) {
    final i18n = ref.watch(translationProvider).me.myPosts;
    return _buildErrorPanel(
      context,
      width: cardWidth,
      illustrationKey: const ValueKey('my_posts_pagination_error_illustration'),
      retryButtonKey: const ValueKey('my_posts_retry_next_page'),
      title: i18n.paginationError.title,
      description: i18n.paginationError.description,
      retryButtonTitle: i18n.retryButtonTitle,
      onRetry: () => unawaited(ref.read(myPostsStateProvider.notifier).loadNextPage()),
    );
  }

  Widget _buildInitialLoadError(BuildContext context) {
    final i18n = ref.watch(translationProvider).me.myPosts;
    return _buildErrorPanel(
      context,
      illustrationKey: const ValueKey('my_posts_initial_error_illustration'),
      retryButtonKey: const ValueKey('my_posts_retry'),
      title: i18n.error.title,
      description: i18n.error.description,
      retryButtonTitle: i18n.retryButtonTitle,
      onRetry: () => ref.invalidate(myPostsStateProvider),
    );
  }

  Widget _buildErrorPanel(
    BuildContext context, {
    required Key illustrationKey,
    required Key retryButtonKey,
    required String title,
    required String description,
    required String retryButtonTitle,
    required VoidCallback onRetry,
    double? width,
  }) {
    final colorScheme = MateoTheme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: _cardWidth / MyPostCard.aspectRatio,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              $Illustrations.crying(key: illustrationKey, width: 124),
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.text.primary),
              ),
              const SizedBox(height: 4),
              FractionallySizedBox(
                widthFactor: .8,
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.text.secondary),
                ),
              ),
              const SizedBox(height: 24),
              MateoButton(
                key: retryButtonKey,
                presentation: .label(
                  width: .fit,
                  size: .small,
                  leadingIcon: const MateoIcon(.arrowRotateClockwise),
                  variant: .secondary.neutral,
                  label: retryButtonTitle,
                ),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
