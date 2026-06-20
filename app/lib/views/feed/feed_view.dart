import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/widgets/feed_job_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qui/qui.dart';

class FeedView extends ConsumerStatefulWidget {
  const FeedView({super.key});

  @override
  ConsumerState<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends ConsumerState<FeedView> {
  final QuiSwipeDeckController _swipeDeckController = QuiSwipeDeckController();
  final cardBorderRadius = BorderRadius.circular(44);

  Future<void> _openJobDetails() async {}

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final feedState = ref.watch(feedStateProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 24),
            Align(
              alignment: AlignmentGeometry.centerStart,
              child: Padding(
                padding: const EdgeInsets.only(left: 34),
                child: QuiTextButton(
                  text: 'São Paulo',
                  leadingIconBuilder: (state) => QuiIcons.mapPin.svg(
                    colorFilter: ColorFilter.mode(context.qui.colors.primary, BlendMode.srcIn),
                    height: 14,
                    width: 14,
                  ),
                  leadingIconSpacing: 10,
                  trailingIconSpacing: 10,
                  trailingIconBuilder: (state) => QuiIcons.chevronDown.svg(
                    colorFilter: ColorFilter.mode(state.recommendedIconColor, BlendMode.srcIn),
                    height: 8,
                    // width: 16,
                  ),
                  onPressed: () {},
                ),
              ),
            ),

            const SizedBox(height: 30),
            Expanded(
              child: feedState.when(
                data: (feedData) => _buildFeedContent(context, feedData),
                error: (error, stackTrace) => _buildInitialError(context, error),
                loading: () => _buildInitialLoading(context),
              ),
            ),
            const SizedBox(height: 30),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: QuiSearchBarButton(placeholder: i18n.feed.searchPlaceholder),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedContent(BuildContext context, FeedData feedData) {
    if (feedData.isEmpty) return _buildEnd(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: QuiSwipeDeck<FeedJobDto>(
        controller: _swipeDeckController,
        itemCount: feedData.jobs.length,
        itemProvider: (index) => feedData.jobs[index],
        onAccept: (feedJob, index) {},
        onLoadMore: () => ref.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true),
        loadingMoreBuilder: _buildLoadingMore,
        buildLoadMoreError: feedData.paginationError == null ? null : _buildLoadMoreError,
        endBuilder: _buildEnd,
        builder: (context, job, index) {
          final location = job.location;
          final mapConfig = location.mapConfig;

          return ClipRRect(
            borderRadius: cardBorderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                QuiLocationRadiusMap(
                  tileUrlTemplate: mapConfig.authenticatedTileUrl,
                  location: (latitude: location.latitude, longitude: location.longitude),
                  radiusInMeters: location.areaRadius.toDouble(),
                  fontConfig: (fontStack: mapConfig.fontstack, glyphUrlTemplate: mapConfig.authenticatedGlyphUrl),
                  tileMinZoom: mapConfig.tileMinZoom.toInt(),
                  tileMaxZoom: mapConfig.tileMaxZoom.toInt(),
                  zoom: 13.5,
                ),
                Padding(
                  padding: const EdgeInsets.all(9),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FeedJobCard(feedJob: job, onTap: _openJobDetails),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: QuiIconButton(
                      onPressed: _swipeDeckController.dismiss,
                      buttonSize: 65,
                      iconSize: 22,
                      iconBuilder: (state) {
                        return QuiIcons.cross.svg(
                          colorFilter: ColorFilter.mode(state.recommendedIconColor, BlendMode.srcIn),
                          height: state.iconSize,
                          width: state.iconSize,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingMore(BuildContext context) {
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
                QuiOrbitItem(child: Qui3d.brush.image(), size: const Size(50, 50)),
                QuiOrbitItem(child: Qui3d.hammer.image(), size: const Size(50, 50)),
                QuiOrbitItem(child: Qui3d.ladder.image(), size: const Size(50, 50)),
                QuiOrbitItem(child: Qui3d.motorcycle.image(), size: const Size(50, 50)),
                QuiOrbitItem(child: Qui3d.shoppingCart.image(), size: const Size(50, 50)),
                QuiOrbitItem(child: Qui3d.smallTruck.image(), size: const Size(50, 50)),
                QuiOrbitItem(child: Qui3d.toolBox.image(), size: const Size(43, 43)),
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

  Widget _buildLoadMoreError(BuildContext context, VoidCallback retry) {
    final i18n = ref.watch(translationProvider);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Qui3d.workItemsMess.image(height: 150, width: 150),
          const SizedBox(height: 40),
          Text(
            i18n.feed.loadingMore.error.title,
            style: TextStyle(fontSize: 18, color: context.qui.colors.textPrimary, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.7,
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

  Widget _buildEnd(BuildContext context) {
    final i18n = ref.watch(translationProvider);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Qui3d.emptyCitySaoPaulo.image(height: 150, colorBlendMode: BlendMode.hue),
          const SizedBox(height: 20),
          Text(
            i18n.feed.empty.title,
            style: TextStyle(fontSize: 18, color: context.qui.colors.textPrimary, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.7,
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
              // TODO: Implement once we add the edit area screen
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
          QuiOrbitItem(child: Qui3d.brush.image(), size: const Size(50, 50)),
          QuiOrbitItem(child: Qui3d.hammer.image(), size: const Size(50, 50)),
          QuiOrbitItem(child: Qui3d.ladder.image(), size: const Size(50, 50)),
          QuiOrbitItem(child: Qui3d.motorcycle.image(), size: const Size(50, 50)),
          QuiOrbitItem(child: Qui3d.shoppingCart.image(), size: const Size(50, 50)),
          QuiOrbitItem(child: Qui3d.smallTruck.image(), size: const Size(50, 50)),
          QuiOrbitItem(child: Qui3d.toolBox.image(), size: const Size(43, 43)),
          QuiOrbitItem(child: Qui3d.box.image(), size: const Size(43, 43)),
        ],
      ),
    );
  }

  Widget _buildInitialError(BuildContext context, Object error) {
    final i18n = ref.watch(translationProvider);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Qui3d.locationPinRestingCracked.image(height: 140),
          const SizedBox(height: 20),
          Text(
            i18n.feed.error.title,
            style: TextStyle(fontSize: 18, color: context.qui.colors.textPrimary, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.7,
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
