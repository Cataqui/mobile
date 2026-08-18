import 'dart:async';
import 'dart:math' as math;

import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/illustrations.g.dart';
import 'package:cataqui_app/gen/lotties.g.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/poster_onboarding/poster_onboarding_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  static const _headlineRevealDelay = Duration(milliseconds: 600);
  static const _headlineMoveDelay = Duration(milliseconds: 1600);
  static const _sceneRevealDelay = Duration(milliseconds: 2048);
  static const _buttonRevealDelay = Duration(milliseconds: 2624);
  static const _entranceDuration = Duration(milliseconds: 576);
  static const _introCompleteDelay = Duration(milliseconds: 2624 + 576);

  static const _compactAvailableHeight = 616.0;
  static const _regularAvailableHeight = 820.0;
  static const _headlineLineHeight = 1.16;

  bool _actionsAvailable = false;
  bool _isOpeningFeed = false;

  void _triggerHaptic(Future<void> Function() feedback) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    unawaited(feedback());
  }

  void _enableInteractions() {
    if (_actionsAvailable) return;
    setState(() => _actionsAvailable = true);
  }

  Future<void> _openFeed() async {
    if (_isOpeningFeed) return;
    _isOpeningFeed = true;

    try {
      await ref.read(appStorageStateProvider.notifier).completeOnboarding();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'cataqui_app',
          context: ErrorDescription('while saving onboarding completion'),
        ),
      );
    }

    if (!mounted) return;
    const FeedRoute().go(context);
  }

  double _sceneHeight(BoxConstraints constraints) {
    final heightBasedSceneHeight =
        constraints.maxHeight *
        _layoutValue(availableHeight: constraints.maxHeight, compactValue: 0.43, regularValue: 0.5);
    final widthBasedSceneHeight = constraints.maxWidth * 1.18;
    return math.min(heightBasedSceneHeight, widthBasedSceneHeight).clamp(0.0, 460.0);
  }

  double _layoutValue({required double availableHeight, required double compactValue, required double regularValue}) {
    final progress = ((availableHeight - _compactAvailableHeight) / (_regularAvailableHeight - _compactAvailableHeight))
        .clamp(0.0, 1.0);
    return compactValue + (regularValue - compactValue) * progress;
  }

  double _initialHeadlineOffset({
    required double viewportHeight,
    required double sceneHeight,
    required double contentTopSpacing,
    required double headlineTopPadding,
    required double headlineBottomPadding,
    required double headlineFontSize,
  }) {
    final headlineTextHeight = headlineFontSize * _headlineLineHeight * 3;
    final headlineHeight = headlineTopPadding + headlineTextHeight + headlineBottomPadding;
    final headlineFinalCenter = contentTopSpacing + sceneHeight + headlineHeight / 2;
    return viewportHeight / 2 - headlineFinalCenter;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);

    return Scaffold(
      backgroundColor: context.mateo.colorScheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            bottom: false,
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sceneHeight = _sceneHeight(constraints);
                  final contentTopSpacing = _layoutValue(
                    availableHeight: constraints.maxHeight,
                    compactValue: 14,
                    regularValue: 36,
                  );
                  final headlineTopPadding = _layoutValue(
                    availableHeight: constraints.maxHeight,
                    compactValue: 12,
                    regularValue: 28,
                  );
                  final headlineBottomPadding = _layoutValue(
                    availableHeight: constraints.maxHeight,
                    compactValue: 10,
                    regularValue: 24,
                  );
                  final headlineFontSize = _layoutValue(
                    availableHeight: constraints.maxHeight,
                    compactValue: 24,
                    regularValue: 30,
                  );
                  final initialHeadlineOffset = _initialHeadlineOffset(
                    viewportHeight: constraints.maxHeight,
                    sceneHeight: sceneHeight,
                    contentTopSpacing: contentTopSpacing,
                    headlineTopPadding: headlineTopPadding,
                    headlineBottomPadding: headlineBottomPadding,
                    headlineFontSize: headlineFontSize,
                  );

                  return OverflowBox(
                    alignment: Alignment.topCenter,
                    minWidth: 0,
                    maxWidth: constraints.maxWidth,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: contentTopSpacing),
                          _buildScene(i18n: i18n, height: sceneHeight),
                          _buildHeadline(
                            i18n: i18n,
                            initialOffset: initialHeadlineOffset,
                            topPadding: headlineTopPadding,
                            bottomPadding: headlineBottomPadding,
                            fontSize: headlineFontSize,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ExcludeSemantics(
                    key: const ValueKey('onboarding_actions_semantics_gate'),
                    excluding: !_actionsAvailable,
                    child: Motion.list(
                      key: const ValueKey('onboarding_intro_button_panel'),
                      interactive: false,
                      effects: [
                        const FadeInMotionEffect(
                          delay: _buttonRevealDelay,
                          duration: _entranceDuration,
                          curve: Curves.easeOutCubic,
                        ),
                        MoveMotionEffect(
                          begin: const Offset(0, 28),
                          end: Offset.zero,
                          delay: _buttonRevealDelay,
                          duration: _entranceDuration,
                          curve: Curves.easeOutCubic,
                          onStart: () => _triggerHaptic(HapticFeedback.heavyImpact),
                          onEnd: _enableInteractions,
                        ),
                      ],
                      child: RepaintBoundary(
                        child: MateoButtonPanel(
                          buttons: [
                            MateoButton(
                              key: const ValueKey('onboarding_view_jobs_button'),
                              label: i18n.onboarding.actions.viewJobs,
                              variant: MateoButtonVariant.primary,
                              fit: MateoButtonFit.expand,
                              trailingIconBuilder: (state) {
                                return MateoIcon.arrowDown(color: state.foregroundColor);
                              },
                              onPressed: _openFeed,
                            ),
                            MateoButton(
                              key: const ValueKey('onboarding_post_job_button'),
                              label: i18n.onboarding.actions.postJob,
                              variant: MateoButtonVariant.secondary,
                              fit: MateoButtonFit.expand,
                              colorScheme: context.mateo.colorScheme.buttons.tertiary,
                              leadingIconBuilder: (state) {
                                return MateoIcon.boxPen(color: state.foregroundColor);
                              },
                              onPressed: () => unawaited(const PosterOnboardingRoute().push<void>(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScene({required Translations i18n, required double height}) {
    return Motion.list(
      key: const ValueKey('onboarding_intro_scene'),
      effects: [
        FadeInMotionEffect(
          delay: _sceneRevealDelay,
          duration: const Duration(milliseconds: 704),
          curve: Curves.easeOutCubic,
          onStart: () => _triggerHaptic(HapticFeedback.mediumImpact),
        ),
      ],
      child: RepaintBoundary(
        child: SizedBox(
          key: const ValueKey('onboarding_job_scene_size'),
          height: height,
          child: PauseAnimations.temporarily(
            duration: _sceneRevealDelay,
            child: AspectRatio(
              aspectRatio: 458 / 540,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: width * 0.18,
                        top: width * 0.05,
                        child: _buildFloatingAsset(
                          key: const ValueKey('onboarding_cooker_hat'),
                          child: ExcludeSemantics(child: $Illustrations.cookerHat(width: width * 0.14)),
                        ),
                      ),
                      Positioned(
                        right: width * -0.04,
                        top: width * 0.50,
                        child: _buildFloatingAsset(
                          key: const ValueKey('onboarding_hammer'),
                          child: ExcludeSemantics(child: $Illustrations.hammer(width: width * 0.16)),
                        ),
                      ),
                      Positioned(
                        left: width * -0.04,
                        bottom: width * 0.12,
                        child: _buildFloatingAsset(
                          key: const ValueKey('onboarding_ladder'),
                          child: ExcludeSemantics(child: $Illustrations.ladder(width: width * 0.16)),
                        ),
                      ),
                      Positioned.fill(
                        child: Semantics(
                          image: true,
                          label: i18n.onboarding.sceneAccessibilityLabel,
                          child: ExcludeSemantics(
                            child: Center(
                              child: $Lotties.jobCardsCarousel(
                                key: const ValueKey('onboarding_job_cards_carousel'),
                                clip: false,
                                overrides: JobCardsCarouselOverrides(
                                  jobCard01TextPostedTimeText: i18n.onboarding.jobCards.postedTime,
                                  jobCard01TextJobTitleText: i18n.onboarding.jobCards.card1.title,
                                  jobCard01TextPayText: i18n.onboarding.jobCards.card1.amount,
                                  jobCard01TextDescriptionText: i18n.onboarding.jobCards.card1.description,
                                  jobCard02TextPostedTimeText: i18n.onboarding.jobCards.postedTime,
                                  jobCard02TextJobTitleText: i18n.onboarding.jobCards.card2.title,
                                  jobCard02TextPayText: i18n.onboarding.jobCards.card2.amount,
                                  jobCard02TextDescriptionText: i18n.onboarding.jobCards.card2.description,
                                  jobCard03TextPostedTimeText: i18n.onboarding.jobCards.postedTime,
                                  jobCard03TextJobTitleText: i18n.onboarding.jobCards.card3.title,
                                  jobCard03TextPayText: i18n.onboarding.jobCards.card3.amount,
                                  jobCard03TextDescriptionText: i18n.onboarding.jobCards.card3.description,
                                  jobCard04TextPostedTimeText: i18n.onboarding.jobCards.postedTime,
                                  jobCard04TextJobTitleText: i18n.onboarding.jobCards.card4.title,
                                  jobCard04TextPayText: i18n.onboarding.jobCards.card4.amount,
                                  jobCard04TextDescriptionText: i18n.onboarding.jobCards.card4.description,
                                  jobCard05TextPostedTimeText: i18n.onboarding.jobCards.postedTime,
                                  jobCard05TextJobTitleText: i18n.onboarding.jobCards.card5.title,
                                  jobCard05TextPayText: i18n.onboarding.jobCards.card5.amount,
                                  jobCard05TextDescriptionText: i18n.onboarding.jobCards.card5.description,
                                  jobCard06TextPostedTimeText: i18n.onboarding.jobCards.postedTime,
                                  jobCard06TextJobTitleText: i18n.onboarding.jobCards.card6.title,
                                  jobCard06TextPayText: i18n.onboarding.jobCards.card6.amount,
                                  jobCard06TextDescriptionText: i18n.onboarding.jobCards.card6.description,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadline({
    required Translations i18n,
    required double initialOffset,
    required double topPadding,
    required double bottomPadding,
    required double fontSize,
  }) {
    return Motion.list(
      key: const ValueKey('onboarding_intro_headline_motion'),
      effects: [
        FadeInMotionEffect(
          duration: const Duration(milliseconds: 448),
          curve: Curves.easeOutCubic,
          delay: _headlineRevealDelay,
          onStart: () => _triggerHaptic(HapticFeedback.selectionClick),
        ),
        const ScaleInMotionEffect(
          scale: 0.7,
          duration: _entranceDuration,
          curve: Curves.easeOutBack,
          delay: _headlineRevealDelay,
        ),
        MoveMotionEffect(
          begin: Offset(0, initialOffset),
          end: Offset.zero,
          delay: _headlineMoveDelay,
          duration: _entranceDuration,
          curve: Curves.easeInOutCubic,
          onStart: () => _triggerHaptic(HapticFeedback.lightImpact),
        ),
      ],
      child: Padding(
        key: const ValueKey('onboarding_intro_headline'),
        padding: EdgeInsets.fromLTRB(24, topPadding, 24, bottomPadding),
        child: Text(
          i18n.onboarding.headline,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.mateo.palette.neutral[11],
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: _headlineLineHeight,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingAsset({required Key key, required Widget child}) {
    return Motion(
      key: key,
      effect: const FloatingMotionEffect(
        distance: 6,
        delay: _introCompleteDelay,
        duration: Duration(milliseconds: 2600),
      ),
      child: RepaintBoundary(child: child),
    );
  }
}
