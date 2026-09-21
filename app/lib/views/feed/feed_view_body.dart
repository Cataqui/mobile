part of 'feed_view.dart';

class _FeedViewBody extends ConsumerStatefulWidget {
  const _FeedViewBody({required this.controller, required this.onAdjustAreaPressed});

  final SnapListController controller;
  final VoidCallback onAdjustAreaPressed;

  @override
  ConsumerState<_FeedViewBody> createState() => _FeedBodyContentState();
}

class _FeedBodyContentState extends ConsumerState<_FeedViewBody> {
  static const MateoShape _mapSurfaceShape = .rounded(radius: 48);

  final ValueNotifier<int> _currentMapIndexNotifier = ValueNotifier<int>(0);

  void _loadNextPage() {
    final data = ref.read(feedStateProvider).value;
    final position = widget.controller.position;
    if (data == null || position == null || !data.hasMore || data.paginationError != null) return;
    if (position < data.jobs.length - 1.3) return;
    unawaited(ref.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true));
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_loadNextPage);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_loadNextPage);
    _currentMapIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedStateProvider);

    return feedState.when(
      data: (data) => KeyedSubtree(key: const ValueKey('feed_data'), child: _buildFeedContent(context, data)),
      error: (error, st) => KeyedSubtree(key: const ValueKey('feed_error'), child: _buildInitialError(context, error)),
      loading: () => KeyedSubtree(key: const ValueKey('feed_loading'), child: _buildInitialLoading(context)),
    );
  }

  Widget _buildFeedContent(BuildContext context, FeedData feedData) {
    if (feedData.isEmpty) return _buildEnd(context);

    final mapColorScheme = JobLocationMapColorScheme.fromBrightness(
      brightness: MateoTheme.of(context).brightness,
      palette: MateoTheme.of(context).palette,
    );

    return SnapList.builder(
      clipBehavior: Clip.none,
      spacing: 10,
      duration: const Duration(milliseconds: 230),
      cacheItemCount: 3,
      curve: Curves.easeOutCubic,
      controller: widget.controller,
      itemCount: feedData.jobs.length,
      outgoingTransitionBuilder: (_, animation, isReverse, child) {
        return FadeTransition(opacity: Tween<double>(begin: 1, end: 0).animate(animation), child: child);
      },
      incomingTransitionBuilder: (context, progress, isReverse, child) {
        return FadeTransition(opacity: progress, child: child);
      },
      onIndexChanged: (index) => _currentMapIndexNotifier.value = index,
      trailingBuilder: (context) {
        if (feedData.paginationError != null) {
          return _buildLoadMoreError(
            context,
            () => ref.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true),
          );
        }
        if (!feedData.hasMore) return _buildEnd(context, fillViewport: false);
        return _buildLoadingMore(context);
      },
      itemBuilder: (context, index) {
        final job = feedData.jobs[index];
        final location = job.location;

        return MateoSurface(
          key: ValueKey(job.jobId),
          shape: _mapSurfaceShape,
          color: mapColorScheme.background,
          width: const .fill(),
          height: const .fill(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ListenableBuilder(
                listenable: _currentMapIndexNotifier,
                builder: (context, _) {
                  if ((index - _currentMapIndexNotifier.value).abs() > 1) {
                    return const SizedBox.shrink();
                  }

                  const mapRadiusOffsetMultiplier = 4000;
                  const mapRadiusReferenceHeight = 100;
                  final mapRadiusOffset = Offset(
                    0,
                    mapRadiusOffsetMultiplier /
                        (math.pow(MediaQuery.sizeOf(context).height / mapRadiusReferenceHeight, 2)),
                  );

                  return JobLocationMap(
                    location: (latitude: location.latitude, longitude: location.longitude),
                    areaDiameterInMeters: location.areaRadius.toDouble(),
                    offset: mapRadiusOffset,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(9),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(child: FeedJobCard(feedJob: job)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrollableState({required Widget child, bool fillViewport = true}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          primary: false,
          clipBehavior: Clip.none,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: fillViewport ? constraints.maxHeight : 0),
            child: Padding(
              padding: EdgeInsets.only(top: 80 + (fillViewport ? 0 : 20), bottom: 40),
              child: Center(child: child),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingMore(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      child: Center(
        heightFactor: 1,
        child: MateoLoadingIndicator(presentation: .dots(color: MateoTheme.of(context).colorScheme.accent, height: 16)),
      ),
    );
  }

  Widget _buildLoadMoreError(BuildContext context, VoidCallback retry) {
    final paginationError = ref.read(feedStateProvider).value?.paginationError;
    final i18n = ref.watch(translationProvider);
    if (paginationError.isOfflineConnectionDioException) {
      return _buildScrollableState(
        fillViewport: false,
        child: OfflineErrorState(
          title: i18n.feed.loadingMore.offline.title,
          description: i18n.feed.loadingMore.offline.description,
          retry: (label: i18n.feed.loadingMore.offline.retryButtonTitle, onRetry: retry),
        ),
      );
    }

    return _buildScrollableState(
      fillViewport: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          $Illustrations.workItemsMess(
            height: FeedView._loadingMoreErrorIllustrationSize,
            width: FeedView._loadingMoreErrorIllustrationSize,
          ),
          const SizedBox(height: 30),
          Text(
            i18n.feed.loadingMore.error.title,
            style: TextStyle(
              fontSize: 18,
              color: MateoTheme.of(context).colorScheme.text.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: 0.7,
            child: Text(
              i18n.feed.loadingMore.error.description,
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
              label: i18n.feed.loadingMore.error.retryButtonTitle,
              leadingIcon: const MateoIcon(.arrowRotateClockwise),
            ),
            onPressed: () {
              retry();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnd(BuildContext context, {bool fillViewport = true}) {
    final i18n = ref.watch(translationProvider);

    return _buildScrollableState(
      fillViewport: fillViewport,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          $Illustrations.emptyCitySaoPaulo(height: FeedView._emptyIllustrationHeight, colorBlendMode: BlendMode.hue),
          const SizedBox(height: 20),
          Text(
            i18n.feed.empty.title,
            style: TextStyle(
              fontSize: 18,
              color: MateoTheme.of(context).colorScheme.text.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: 0.7,
            child: Text(
              i18n.feed.empty.description,
              style: TextStyle(
                fontSize: 16,
                color: MateoTheme.of(context).colorScheme.text.secondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          MateoButton(
            presentation: .label(
              width: .fit,
              variant: .secondary,
              label: i18n.feed.empty.adjustAreaButtonTitle,
              leadingIcon: const MateoIcon(.wrench, size: 15),
            ),
            key: const ValueKey('feed_empty_adjust_area_button'),
            onPressed: widget.onAdjustAreaPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildInitialLoading(BuildContext context) {
    final mapColorScheme = JobLocationMapColorScheme.fromBrightness(
      brightness: MateoTheme.of(context).brightness,
      palette: MateoTheme.of(context).palette,
    );

    return MateoSurface(
      shape: _mapSurfaceShape,
      color: mapColorScheme.background,
      width: const .fill(),
      height: const .fill(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(9),
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                child: FeedJobCard(
                  feedJob: FeedJobDto.fixture().copyWith(
                    title: 'Loading your next job',
                    createdAt: clock.now(),
                    descriptionSummary: 'Your next job is coming, wait a bit and it will appear...',
                    payment: JobPaymentDto.fixture().copyWith(minAmount: 1200, type: JobPaymentType.fixed),
                  ),
                  skeleton: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialError(BuildContext context, Object error) {
    final i18n = ref.watch(translationProvider);

    if (error.isOfflineConnectionDioException) {
      return OfflineErrorState(
        title: i18n.feed.offline.title,
        description: i18n.feed.offline.description,
        retry: (
          label: i18n.feed.offline.retryButtonTitle,
          onRetry: () => ref.read(feedStateProvider.notifier).getFeedJobs(),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          $Illustrations.locationPinRestingCracked(height: FeedView._errorIllustrationHeight),
          const SizedBox(height: 20),
          Text(
            i18n.feed.error.title,
            style: TextStyle(
              fontSize: 18,
              color: MateoTheme.of(context).colorScheme.text.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: 0.7,
            child: Text(
              i18n.feed.error.description,
              style: TextStyle(
                fontSize: 16,
                color: MateoTheme.of(context).colorScheme.text.secondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          MateoButton(
            presentation: .label(
              width: .fit,
              variant: .primary,
              label: i18n.feed.error.retryButtonTitle,
              leadingIcon: const MateoIcon(.arrowRotateClockwise, size: 15),
            ),
            onPressed: () => ref.read(feedStateProvider.notifier).getFeedJobs(),
          ),
        ],
      ),
    );
  }
}
