part of 'feed_view.dart';

class _FeedViewBody extends ConsumerStatefulWidget {
  const _FeedViewBody({
    required this.controller,
    required this.cardBorderRadius,
    required this.feedInCurve,
    required this.isHintActiveNotifier,
  });

  final QuiTikTokFeedController controller;
  final BorderRadius cardBorderRadius;
  final CurveTween feedInCurve;
  final ValueNotifier<bool> isHintActiveNotifier;

  @override
  ConsumerState<_FeedViewBody> createState() => _FeedBodyContentState();
}

class _FeedBodyContentState extends ConsumerState<_FeedViewBody> {
  final ValueNotifier<int> _mapMountLimitNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _mapMountLimitNotifier.dispose();
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

    final colorScheme = context.qui.colorScheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 65, right: 12),
        child: QuiTikTokFeed<FeedJobDto>(
          spacing: 10,
          controller: widget.controller,
          loadMoreThreshold: 0.7,
          items: (
            count: feedData.jobs.length,
            provider: (i) => feedData.jobs[i],
            keyBuilder: (job, index) => job.jobId,
          ),
          onNext: (feedJob, index) {
            final newCurrentIndex = index + 1;

            if (_mapMountLimitNotifier.value < newCurrentIndex) _mapMountLimitNotifier.value = newCurrentIndex;
          },
          onPrevious: (feedJob, index) {
            final newCurrentIndex = index - 1;

            if (_mapMountLimitNotifier.value < newCurrentIndex) _mapMountLimitNotifier.value = newCurrentIndex;
          },
          onLoadMore: () => ref.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true),
          loadMoreErrorBuilder: feedData.paginationError == null ? null : _buildLoadMoreError,
          endBuilder: _buildEnd,
          builder: (context, job, index) {
            final location = job.location;
            final mapConfig = location.mapConfig;

            return ClipRRect(
              borderRadius: widget.cardBorderRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ListenableBuilder(
                    listenable: Listenable.merge([_mapMountLimitNotifier, widget.isHintActiveNotifier]),
                    builder: (context, _) {
                      final effectiveLimit = widget.isHintActiveNotifier.value ? -1 : _mapMountLimitNotifier.value;
                      if (index > effectiveLimit) return ColoredBox(color: colorScheme.map.background);

                      const mapRadiusOffsetMultiplier = 1000;
                      const mapRadiusReferenceHeight = 100;
                      final mapRadiusOffset = Offset(
                        0,
                        mapRadiusOffsetMultiplier /
                            (math.pow(MediaQuery.sizeOf(context).height / mapRadiusReferenceHeight, 2)),
                      );

                      return QuiLocationRadiusMap(
                        maximumMapFps: 30,
                        tileUrlTemplate: mapConfig.authenticatedTileUrl,
                        location: (latitude: location.latitude, longitude: location.longitude),
                        radiusInMeters: location.areaRadius.toDouble(),
                        fontConfig: (fontStack: mapConfig.fontstack, glyphUrlTemplate: mapConfig.authenticatedGlyphUrl),
                        tileMinZoom: mapConfig.tileMinZoom.toInt(),
                        tileMaxZoom: mapConfig.tileMaxZoom.toInt(),
                        zoom: 12.8,
                        offset: mapRadiusOffset,
                        radiusStyle: (color: context.qui.colorScheme.map.locationRadius),
                        onMapLoad: () {
                          final next = index + 1;
                          if (_mapMountLimitNotifier.value < next) {
                            _mapMountLimitNotifier.value = next;
                          }
                        },
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(9),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: FeedJobCard(feedJob: job),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadMoreError(BuildContext context, VoidCallback retry) {
    final paginationError = ref.read(feedStateProvider).value?.paginationError;
    final i18n = ref.watch(translationProvider);

    if (paginationError.isOfflineConnectionDioException) {
      return QuiOfflineErrorState(
        title: i18n.feed.loadingMore.offline.title,
        description: i18n.feed.loadingMore.offline.description,
        retry: (label: i18n.feed.loadingMore.offline.retryButtonTitle, onRetry: retry),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: QuiSearchBarButton.searchBarHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QuiThreeD.workItemsMess(height: 150, width: 150),
            const SizedBox(height: 40),
            Text(
              i18n.feed.loadingMore.error.title,
              style: TextStyle(fontSize: 18, color: context.qui.colorScheme.text.primary, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            FractionallySizedBox(
              widthFactor: 0.7,
              child: Text(
                i18n.feed.loadingMore.error.description,
                style: TextStyle(
                  fontSize: 16,
                  color: context.qui.colorScheme.text.secondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            QuiButton(
              variant: QuiButtonVariant.primary,
              label: i18n.feed.loadingMore.error.retryButtonTitle,
              leadingIconBuilder: (state) => QuiIcon.arrowRotateClockwise(
                height: 15,
                width: 15,
                color: state.foregroundColor,
              ),
              leadingIconSpacing: 10,
              onPressed: () {
                retry();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnd(BuildContext context) {
    final i18n = ref.watch(translationProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: QuiSearchBarButton.searchBarHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QuiThreeD.emptyCitySaoPaulo(
              height: 150,
              colorBlendMode: BlendMode.hue,
            ),
            const SizedBox(height: 20),
            Text(
              i18n.feed.empty.title,
              style: TextStyle(fontSize: 18, color: context.qui.colorScheme.text.primary, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            FractionallySizedBox(
              widthFactor: 0.7,
              child: Text(
                i18n.feed.empty.description,
                style: TextStyle(
                  fontSize: 16,
                  color: context.qui.colorScheme.text.secondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            QuiButton(
              variant: QuiButtonVariant.secondary,
              label: i18n.feed.empty.adjustAreaButtonTitle,
              leadingIconBuilder: (state) => QuiIcon.wrench(
                height: 15,
                width: 15,
                color: state.foregroundColor,
              ),
              leadingIconSpacing: 10,
              onPressed: () {
                // TODO(RyanHolanda): Implement once we add the edit area screen
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialLoading(BuildContext context) {
    final colorScheme = context.qui.colorScheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 65, right: 12),
        child: SizedBox.expand(
          child: ClipRRect(
            borderRadius: widget.cardBorderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: colorScheme.map.background,
                  child: const Padding(padding: EdgeInsets.all(8), child: QuiDotMatrix(radius: 0, dotSize: 1)),
                ),
                Padding(
                  padding: const EdgeInsets.all(9),
                  child: Align(
                    alignment: Alignment.topCenter,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialError(BuildContext context, Object error) {
    final i18n = ref.watch(translationProvider);

    if (error.isOfflineConnectionDioException) {
      return QuiOfflineErrorState(
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
          QuiThreeD.locationPinRestingCracked(height: 140),
          const SizedBox(height: 20),
          Text(
            i18n.feed.error.title,
            style: TextStyle(fontSize: 18, color: context.qui.colorScheme.text.primary, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: 0.7,
            child: Text(
              i18n.feed.error.description,
              style: TextStyle(
                fontSize: 16,
                color: context.qui.colorScheme.text.secondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          QuiButton(
            variant: QuiButtonVariant.primary,
            label: i18n.feed.error.retryButtonTitle,
            leadingIconBuilder: (state) => QuiIcon.arrowRotateClockwise(
              height: 15,
              width: 15,
              color: state.foregroundColor,
            ),
            leadingIconSpacing: 10,
            onPressed: () => ref.read(feedStateProvider.notifier).getFeedJobs(),
          ),
        ],
      ),
    );
  }
}
