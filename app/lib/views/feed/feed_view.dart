import 'dart:async';
import 'dart:math' as math;

import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
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
  final SnapListController _feedController = SnapListController();
  late final ValueNotifier<bool> _isHintActiveNotifier;

  void _showLocationAvailabilitySheet() {
    final i18n = ref.read(translationProvider);
    final colorScheme = MateoTheme.of(context).colorScheme;

    unawaited(
      showMateoSheet<void>(
        context: context,
        view: MateoSheetView(
          reserveHeaderSpace: false,
          header: const MateoSheetViewHeader(presentation: .closeButton()),
          surface: MateoSheetViewSurface(
            key: const ValueKey('feed_location_sheet_surface'),
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
    _feedController.dispose();
    _isHintActiveNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = MateoTheme.of(context).colorScheme;
    final i18n = ref.watch(translationProvider);
    final hasJobs = ref.watch(feedStateProvider.select((s) => s.value?.jobs.isNotEmpty ?? false));

    return MateoView(
      avoidBottomInset: false,
      padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10, right: 20),
      header: MateoViewHeader(
        leading: MateoButton(
          presentation: .label(
            width: .fit,
            variant: .tertiary,
            size: .small,
            label: i18n.feed.locationAvailability.cityLabel,
            elevation: 0,
            leadingIcon: MateoIcon(.mapPin, color: MateoTheme.of(context).palette.accent[9]),
            trailingIcon: MateoIcon(.chevronDown, color: MateoTheme.of(context).colorScheme.text.primary),
          ),
          onPressed: _showLocationAvailabilitySheet,
        ),
      ),
      overlay: hasJobs
          ? IgnorePointer(
              child: _FeedSwipeUpHintOverlay(
                feedController: _feedController,
                isHintActiveNotifier: _isHintActiveNotifier,
              ),
            )
          : null,
      footer: .new(
        trailing: _buildJobCreationButton(i18n),
        leading: const CircleAvatar(radius: 28),
        padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(top: 0, bottom: 12),
      ),
      surface: MateoViewSurface(
        padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 20, top: 10),
        color: colorScheme.background,
        edgeEffect: .fade(),
        child: RepaintBoundary(
          child: _FeedViewBody(controller: _feedController, onAdjustAreaPressed: _showLocationAvailabilitySheet),
        ),
      ),
    );
  }

  Widget _buildJobCreationButton(Translations i18n) {
    return MateoButton(
      key: const ValueKey('feed_job_creation_button'),
      onPressed: () => unawaited(ref.read(appRouterProvider.notifier).push(context, const PostRoute())),
      presentation: .icon(
        variant: .primary.neutral,
        elevation: 1,
        semanticLabel: i18n.feed.jobCreationButtonSemanticLabel,
        icon: const MateoIcon(.plusSignal, key: ValueKey('feed_job_creation_plus_icon')),
      ),
    );
  }
}
