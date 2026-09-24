import 'dart:async';
import 'dart:math' as math;

import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/illustrations.g.dart';
import 'package:cataqui_app/gen/lotties.g.dart';
import 'package:cataqui_app/gen/svg.g.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/me/me_route.dart';
import 'package:cataqui_app/views/me/user_avatar_morph_target.dart';
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
  const FeedView({super.key, this.toast});

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

  final MateoToast? toast;

  @override
  ConsumerState<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends ConsumerState<FeedView> {
  final SnapListController _feedController = SnapListController();
  late final ValueNotifier<bool> _isHintActiveNotifier;
  MateoToastController? _toastController;
  bool _shouldShowToast = false;
  bool _isRouteSettled = false;

  void _dismissToast() {
    _shouldShowToast = false;
    _toastController?.dismiss();
    _toastController = null;
  }

  void _showPendingToast() {
    if (!_isRouteSettled || !_shouldShowToast || widget.toast == null) return;
    _shouldShowToast = false;
    _toastController = showMateoToast(
      context: context,
      toast: widget.toast!,
      duration: .custom(duration: const Duration(seconds: 5)),
      delay: const Duration(milliseconds: 200),
    );
  }

  void _onRouteSettled() {
    _isRouteSettled = true;
    _showPendingToast();
  }

  void _onRouteUnsettled() {
    _isRouteSettled = false;
    _dismissToast();
  }

  void _onIndexChanged(int index) {
    if (index > 0) _dismissToast();
  }

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
    _shouldShowToast = widget.toast != null;
    final hasSeenHint = ref.read(appStorageStateProvider.select((s) => s.value?.hasSeenSwipeFeedHint));
    _isHintActiveNotifier = ValueNotifier<bool>(!(hasSeenHint ?? false));
  }

  @override
  void didUpdateWidget(covariant FeedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.toast, widget.toast)) return;
    _dismissToast();
    if (widget.toast == null) return;
    _shouldShowToast = true;
    if (_feedController.hasClients) _feedController.jumpTo(0);
    if (_isRouteSettled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showPendingToast();
      });
    }
  }

  @override
  void dispose() {
    _dismissToast();
    _feedController.dispose();
    _isHintActiveNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = MateoTheme.of(context).colorScheme;
    final i18n = ref.watch(translationProvider);
    final hasJobs = ref.watch(feedStateProvider.select((s) => s.value?.jobs.isNotEmpty ?? false));

    return RouteListener(
      onSettled: _onRouteSettled,
      onUnsettled: _onRouteUnsettled,
      child: MateoView(
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
        overlay: hasJobs && widget.toast == null
            ? IgnorePointer(
                child: _FeedSwipeUpHintOverlay(
                  feedController: _feedController,
                  isHintActiveNotifier: _isHintActiveNotifier,
                ),
              )
            : null,
        footer: .new(
          trailing: _buildJobCreationButton(i18n),
          leading: MateoPress(
            key: const ValueKey('feed_me_button'),
            semanticLabel: i18n.feed.meButtonSemanticLabel,
            onPressed: (animation) => unawaited(ref.read(appRouterProvider.notifier).push(context, const MeRoute())),
            child: Morph(
              targets: [ref.watch(userAvatarMorphTargetProvider)],
              child: MateoSurface(
                shape: const .capsule(),
                color: MateoTheme.of(context).palette.neutral[3],
                elevation: MateoElevation(level: 1),
                child: $Svg.defaultUserProfilePicture(height: 57, color1: MateoTheme.of(context).palette.neutral[3]),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(top: 0, bottom: 12),
        ),
        surface: MateoViewSurface(
          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 20, top: 10),
          color: colorScheme.background,
          edgeEffect: .fade(),
          child: RepaintBoundary(
            child: _FeedViewBody(
              controller: _feedController,
              onAdjustAreaPressed: _showLocationAvailabilitySheet,
              onIndexChanged: _onIndexChanged,
            ),
          ),
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
