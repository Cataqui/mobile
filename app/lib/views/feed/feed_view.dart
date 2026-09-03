import 'dart:async';
import 'dart:math' as math;

import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/illustrations.g.dart';
import 'package:cataqui_app/gen/lotties.g.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/post/post_route.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:cataqui_app/widgets/job_location_map/job_location_map.dart';
import 'package:cataqui_app/widgets/job_location_map/job_location_map_color_scheme.dart';
import 'package:cataqui_app/widgets/offline_error_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'feed_swipe_up_hint_overlay.dart';
part 'feed_view_body.dart';

class FeedView extends ConsumerStatefulWidget {
  const FeedView({super.key});

  static Future<void> precacheImages(BuildContext context) async {
    await Future.wait([
      $IllustrationsCache.precacheComingSoonPlatePortuguese(context, height: _comingSoonIllustrationHeight),
      $IllustrationsCache.precacheWorkItemsMess(
        context,
        width: _loadingMoreErrorIllustrationSize,
        height: _loadingMoreErrorIllustrationSize,
      ),
      $IllustrationsCache.precacheEmptyCitySaoPaulo(context, height: _emptyIllustrationHeight),
      $IllustrationsCache.precacheLocationPinRestingCracked(context, height: _errorIllustrationHeight),
      OfflineErrorState.precacheImages(context),
    ]);
  }

  static const _comingSoonIllustrationHeight = 130.0;
  static const _loadingMoreErrorIllustrationSize = 150.0;
  static const _emptyIllustrationHeight = 150.0;
  static const _errorIllustrationHeight = 140.0;

  @override
  ConsumerState<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends ConsumerState<FeedView> {
  final MateoYSnapListController _feedController = MateoYSnapListController();
  final _cardBorderRadius = BorderRadius.circular(48);
  final _feedInCurve = CurveTween(curve: Curves.easeOutCubic);
  late final ValueNotifier<bool> _isHintActiveNotifier;

  void _showLocationAvailabilitySheet() {
    final i18n = ref.read(translationProvider);
    final colorScheme = context.mateo.colorScheme;

    unawaited(
      MateoBottomSheet.show<void>(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            ExcludeSemantics(
              child: $Illustrations.comingSoonPlatePortuguese(
                fit: BoxFit.contain,
                height: FeedView._comingSoonIllustrationHeight,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Só em São Paulo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.text.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              i18n.feed.locationAvailability.message,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.text.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final hasSeenHint = ref.read(appStorageStateProvider.select((s) => s.value?.hasSeenSwipeFeedHint));
    _isHintActiveNotifier = ValueNotifier<bool>(!(hasSeenHint ?? false));
  }

  @override
  void dispose() {
    _isHintActiveNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.mateo.colorScheme;
    final i18n = ref.watch(translationProvider);
    final hasJobs = ref.watch(feedStateProvider.select((s) => s.value?.jobs.isNotEmpty ?? false));

    return MateoView(
      backgroundColor: colorScheme.background,
      extendBodyBehindFooter: true,
      edgeFade: (top: const MateoEdgeFadeStyle(), bottom: const MateoEdgeFadeStyle(mainAxisExtent: 160)),
      header: RepaintBoundary(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, end: 20, bottom: 10),
          child: Align(
            alignment: AlignmentGeometry.topStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: MateoTextButton(
                text: i18n.feed.locationAvailability.cityLabel,
                leadingIconBuilder: (state) {
                  return MateoIcon.mapPin(height: 17, width: 17, color: context.mateo.palette.accent[9]);
                },
                leadingIconSpacing: 10,
                trailingIconSpacing: 10,
                trailingIconBuilder: (state) {
                  return MateoIcon.chevronDown(height: 14, width: 14, color: state.recommendedIconColor);
                },
                onPressed: _showLocationAvailabilitySheet,
              ),
            ),
          ),
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Align(alignment: AlignmentGeometry.bottomRight, child: _buildJobCreationButton(i18n)),
      ),
      overlay: hasJobs
          ? IgnorePointer(
              child: _FeedSwipeUpHintOverlay(
                feedController: _feedController,
                isHintActiveNotifier: _isHintActiveNotifier,
              ),
            )
          : null,
      body: RepaintBoundary(
        child: _FeedViewBody(
          controller: _feedController,
          cardBorderRadius: _cardBorderRadius,
          feedInCurve: _feedInCurve,
          onAdjustAreaPressed: _showLocationAvailabilitySheet,
        ),
      ),
    );
  }

  Widget _buildJobCreationButton(Translations i18n) {
    return MateoFloatingActionButton(
      key: const ValueKey('feed_job_creation_button'),
      size: 62,
      backgroundColor: context.mateo.colorScheme.inverse.background,
      foregroundColor: context.mateo.colorScheme.inverse.onBackground,
      semanticLabel: i18n.feed.jobCreationButtonSemanticLabel,
      onPressed: () {
        unawaited(ref.read(appRouterProvider.notifier).push(context, const PostRoute()));
      },
      iconBuilder: (state) => MateoIcon.plusSignal(
        key: const ValueKey('feed_job_creation_plus_icon'),
        width: state.iconSize,
        height: state.iconSize,
        color: state.foregroundColor,
      ),
    );
  }
}
