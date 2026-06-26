part of 'feed_view.dart';

class _FeedViewBody extends ConsumerStatefulWidget {
  const _FeedViewBody({
    required this.controller,
    required this.cardBorderRadius,
    required this.feedInCurve,
    required this.onOpenJobDetails,
  });

  final QuiTikTokFeedController controller;
  final BorderRadius cardBorderRadius;
  final CurveTween feedInCurve;
  final Future<void> Function() onOpenJobDetails;

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

    return QuiWidgetTransition(
      builder: (context) => feedState.when(
        data: (data) => KeyedSubtree(key: const ValueKey('feed_data'), child: _buildFeedContent(context, data)),
        error: (error, st) =>
            KeyedSubtree(key: const ValueKey('feed_error'), child: _buildInitialError(context, error)),
        loading: () => KeyedSubtree(key: const ValueKey('feed_loading'), child: _buildInitialLoading(context)),
      ),
      outDuration: const Duration(milliseconds: 600),
      outTransition: (child, animation) => FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(animation),
        child: RepaintBoundary(child: child),
      ),
      inDuration: const Duration(milliseconds: 600),
      inTransition: (child, animation) {
        final wrapped = RepaintBoundary(child: child);

        return feedState.maybeWhen(
          data: (_) => FadeTransition(
            opacity: widget.feedInCurve.animate(animation),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.30),
                end: Offset.zero,
              ).chain(widget.feedInCurve).animate(animation),
              child: wrapped,
            ),
          ),
          orElse: () => FadeTransition(opacity: widget.feedInCurve.animate(animation), child: wrapped),
        );
      },
    );
  }

  Widget _buildFeedContent(BuildContext context, FeedData feedData) {
    if (feedData.isEmpty) return _buildEnd(context);

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
                  ValueListenableBuilder<int>(
                    valueListenable: _mapMountLimitNotifier,
                    builder: (context, mapMountLimit, _) {
                      if (index > mapMountLimit) return ColoredBox(color: context.qui.colors.mapBackground);

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
                        radiusStyle: RadiusStyle(color: Colors.blue.withValues(alpha: 0.2)),
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
                      child: FeedJobCard(feedJob: job, onTap: widget.onOpenJobDetails),
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

    if (paginationError.isOmfOfflineConnectionDioException) {
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
            Qui3d.workItemsMess.downsampledImage(context, height: 150, width: 150),
            const SizedBox(height: 40),
            Text(
              i18n.feed.loadingMore.error.title,
              style: TextStyle(fontSize: 18, color: context.qui.colors.textPrimary, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            FractionallySizedBox(
              widthFactor: 0.7,
              child: Text(
                i18n.feed.loadingMore.error.description,
                style: TextStyle(fontSize: 16, color: context.qui.colors.textSecondary, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            QuiPrimaryButton(
              label: i18n.feed.loadingMore.error.retryButtonTitle,
              leadingIconBuilder: (state) => QuiIcons.arrowRotateClockwise.svg(
                height: 15,
                width: 15,
                colorFilter: ColorFilter.mode(state.recommendedIconColor, BlendMode.srcIn),
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
            Qui3d.emptyCitySaoPaulo.downsampledImage(context, height: 150, colorBlendMode: BlendMode.hue),
            const SizedBox(height: 20),
            Text(
              i18n.feed.empty.title,
              style: TextStyle(fontSize: 18, color: context.qui.colors.textPrimary, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            FractionallySizedBox(
              widthFactor: 0.7,
              child: Text(
                i18n.feed.empty.description,
                style: TextStyle(fontSize: 16, color: context.qui.colors.textSecondary, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            QuiSecondaryButton(
              label: i18n.feed.empty.adjustAreaButtonTitle,
              leadingIconBuilder: (state) => QuiIcons.wrench.svg(
                height: 15,
                width: 15,
                colorFilter: ColorFilter.mode(state.recommendedIconColor, BlendMode.srcIn),
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
    return Center(
      child: QuiOrbit(
        revolutionDuration: const Duration(milliseconds: 3000),
        radius: 100,
        items: [
          QuiOrbitItem(child: Qui3d.brush.downsampledImage(context, width: 50), size: const Size(50, 50)),
          QuiOrbitItem(child: Qui3d.hammer.downsampledImage(context, width: 50), size: const Size(50, 50)),
          QuiOrbitItem(child: Qui3d.ladder.downsampledImage(context, width: 50), size: const Size(50, 50)),
          QuiOrbitItem(child: Qui3d.motorcycle.downsampledImage(context, width: 50), size: const Size(50, 50)),
          QuiOrbitItem(child: Qui3d.shoppingCart.downsampledImage(context, width: 50), size: const Size(50, 50)),
          QuiOrbitItem(child: Qui3d.smallTruck.downsampledImage(context, width: 50), size: const Size(50, 50)),
          QuiOrbitItem(child: Qui3d.toolBox.downsampledImage(context, width: 43), size: const Size(43, 43)),
          QuiOrbitItem(child: Qui3d.box.downsampledImage(context, width: 43), size: const Size(43, 43)),
        ],
      ),
    );
  }

  Widget _buildInitialError(BuildContext context, Object error) {
    final i18n = ref.watch(translationProvider);

    if (error.isOmfOfflineConnectionDioException) {
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
          Qui3d.locationPinRestingCracked.downsampledImage(context, height: 140),
          const SizedBox(height: 20),
          Text(
            i18n.feed.error.title,
            style: TextStyle(fontSize: 18, color: context.qui.colors.textPrimary, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: 0.7,
            child: Text(
              i18n.feed.error.description,
              style: TextStyle(fontSize: 16, color: context.qui.colors.textSecondary, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          QuiPrimaryButton(
            label: i18n.feed.error.retryButtonTitle,
            leadingIconBuilder: (state) => QuiIcons.arrowRotateClockwise.svg(
              height: 15,
              width: 15,
              colorFilter: ColorFilter.mode(state.recommendedIconColor, BlendMode.srcIn),
            ),
            leadingIconSpacing: 10,
            onPressed: () => ref.read(feedStateProvider.notifier).getFeedJobs(),
          ),
        ],
      ),
    );
  }
}
