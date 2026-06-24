part of 'feed_view.dart';

class _FeedBodyContent extends ConsumerWidget {
  const _FeedBodyContent({
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
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedStateProvider);

    return QuiWidgetTransition(
      builder: (context) => feedState.when(
        data: (data) => KeyedSubtree(key: const ValueKey('feed_data'), child: _buildFeedContent(context, ref, data)),
        error: (error, st) =>
            KeyedSubtree(key: const ValueKey('feed_error'), child: _buildInitialError(context, ref, error)),
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
            opacity: feedInCurve.animate(animation),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.30),
                end: Offset.zero,
              ).chain(feedInCurve).animate(animation),
              child: wrapped,
            ),
          ),
          orElse: () => FadeTransition(opacity: feedInCurve.animate(animation), child: wrapped),
        );
      },
    );
  }

  Widget _buildFeedContent(BuildContext context, WidgetRef ref, FeedData feedData) {
    if (feedData.isEmpty) return _buildEnd(context, ref);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 65, right: 12),
        child: QuiTikTokFeed<FeedJobDto>(
          controller: controller,
          items: (
            count: feedData.jobs.length,
            provider: (i) => feedData.jobs[i],
            keyBuilder: (job, index) => job.jobId,
          ),
          onNext: (feedJob, index) {},
          onLoadMore: () => ref.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true),
          loadingMoreBuilder: (context) => _buildLoadingMore(context, ref),
          loadMoreErrorBuilder: feedData.paginationError == null
              ? null
              : (context, retry) => _buildLoadMoreError(context, ref, retry),
          endBuilder: (context) => _buildEnd(context, ref),
          builder: (context, job, index) {
            final location = job.location;
            final mapConfig = location.mapConfig;

            return ClipRRect(
              borderRadius: cardBorderRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  QuiLocationRadiusMap(
                    maximumMapFps: 30,
                    tileUrlTemplate: mapConfig.authenticatedTileUrl,
                    location: (latitude: location.latitude, longitude: location.longitude),
                    radiusInMeters: location.areaRadius.toDouble(),
                    fontConfig: (fontStack: mapConfig.fontstack, glyphUrlTemplate: mapConfig.authenticatedGlyphUrl),
                    tileMinZoom: mapConfig.tileMinZoom.toInt(),
                    tileMaxZoom: mapConfig.tileMaxZoom.toInt(),
                    zoom: 12.8,
                    offset: const Offset(0, 15),
                    radiusStyle: RadiusStyle(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(9),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: FeedJobCard(feedJob: job, onTap: onOpenJobDetails),
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

  Widget _buildLoadingMore(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.qui.colors.background,
        borderRadius: cardBorderRadius,
        border: Border.all(color: context.qui.colors.borderOnBackground),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Spacer(),
            QuiOrbit(
              revolutionDuration: const Duration(milliseconds: 5000),
              radius: 70,
              items: [
                QuiOrbitItem(
                  child: Qui3d.brush.downsampledImage(context, color: context.qui.colors.ghost, logicalWidth: 50),
                  size: const Size(50, 50),
                ),
                QuiOrbitItem(
                  child: Qui3d.hammer.downsampledImage(context, color: context.qui.colors.ghost, logicalWidth: 50),
                  size: const Size(50, 50),
                ),
                QuiOrbitItem(
                  child: Qui3d.ladder.downsampledImage(context, color: context.qui.colors.ghost, logicalWidth: 50),
                  size: const Size(50, 50),
                ),
                QuiOrbitItem(
                  child: Qui3d.motorcycle.downsampledImage(context, color: context.qui.colors.ghost, logicalWidth: 50),
                  size: const Size(50, 50),
                ),
                QuiOrbitItem(
                  child: Qui3d.shoppingCart.downsampledImage(context, color: context.qui.colors.ghost, logicalWidth: 50),
                  size: const Size(50, 50),
                ),
                QuiOrbitItem(
                  child: Qui3d.smallTruck.downsampledImage(context, color: context.qui.colors.ghost, logicalWidth: 50),
                  size: const Size(50, 50),
                ),
                QuiOrbitItem(
                  child: Qui3d.toolBox.downsampledImage(context, color: context.qui.colors.ghost, logicalWidth: 43),
                  size: const Size(43, 43),
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: QuiLoadingText(text: i18n.feed.loadingMore.title),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreError(BuildContext context, WidgetRef ref, VoidCallback retry) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Qui3d.workItemsMess.downsampledImage(
            context,
            height: 150,
            width: 150,
          ),
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
    );
  }

  Widget _buildEnd(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Qui3d.emptyCitySaoPaulo.downsampledImage(
            context,
            height: 150,
            colorBlendMode: BlendMode.hue,
          ),
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
    );
  }

  Widget _buildInitialLoading(BuildContext context) {

    return Center(
      child: QuiOrbit(
        revolutionDuration: const Duration(milliseconds: 3000),
        radius: 100,
        items: [
          QuiOrbitItem(
            child: Qui3d.brush.downsampledImage(context, logicalWidth: 50),
            size: const Size(50, 50),
          ),
          QuiOrbitItem(
            child: Qui3d.hammer.downsampledImage(context, logicalWidth: 50),
            size: const Size(50, 50),
          ),
          QuiOrbitItem(
            child: Qui3d.ladder.downsampledImage(context, logicalWidth: 50),
            size: const Size(50, 50),
          ),
          QuiOrbitItem(
            child: Qui3d.motorcycle.downsampledImage(context, logicalWidth: 50),
            size: const Size(50, 50),
          ),
          QuiOrbitItem(
            child: Qui3d.shoppingCart.downsampledImage(context, logicalWidth: 50),
            size: const Size(50, 50),
          ),
          QuiOrbitItem(
            child: Qui3d.smallTruck.downsampledImage(context, logicalWidth: 50),
            size: const Size(50, 50),
          ),
          QuiOrbitItem(
            child: Qui3d.toolBox.downsampledImage(context, logicalWidth: 43),
            size: const Size(43, 43),
          ),
          QuiOrbitItem(
            child: Qui3d.box.downsampledImage(context, logicalWidth: 43),
            size: const Size(43, 43),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialError(BuildContext context, WidgetRef ref, Object error) {
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
