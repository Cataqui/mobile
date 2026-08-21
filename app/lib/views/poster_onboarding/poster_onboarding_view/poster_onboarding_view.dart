import 'dart:math' as math;

import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/memoji.g.dart';
import 'package:cataqui_app/gen/svg.g.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/whatsapp_login_button/whatsapp_login_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'poster_onboarding_job_card.dart';
part 'poster_onboarding_job_scene.dart';

class PosterOnboardingView extends ConsumerWidget {
  const PosterOnboardingView({super.key});

  static Future<void> precacheImages(BuildContext context) async {
    await Future.wait([
      $MemojiCache.precacheAlex(
        context,
        width: PosterOnboardingJobCard.avatarSize,
        height: PosterOnboardingJobCard.avatarSize,
      ),
      $MemojiCache.precacheChris(
        context,
        width: PosterOnboardingJobCard.avatarSize,
        height: PosterOnboardingJobCard.avatarSize,
      ),
      $MemojiCache.precacheAriana(
        context,
        width: PosterOnboardingJobCard.avatarSize,
        height: PosterOnboardingJobCard.avatarSize,
      ),
      $MemojiCache.precacheJustin(
        context,
        width: PosterOnboardingJobCard.avatarSize,
        height: PosterOnboardingJobCard.avatarSize,
      ),
      $MemojiCache.precacheAna(
        context,
        width: PosterOnboardingJobCard.avatarSize,
        height: PosterOnboardingJobCard.avatarSize,
      ),
      $MemojiCache.precacheEd(
        context,
        width: PosterOnboardingJobCard.avatarSize,
        height: PosterOnboardingJobCard.avatarSize,
      ),
      $MemojiCache.precacheSabrina(
        context,
        width: PosterOnboardingJobCard.avatarSize,
        height: PosterOnboardingJobCard.avatarSize,
      ),
      $MemojiCache.precacheRyan(
        context,
        width: PosterOnboardingJobCard.avatarSize,
        height: PosterOnboardingJobCard.avatarSize,
      ),
      $MemojiCache.precacheStephen(
        context,
        width: PosterOnboardingJobCard.avatarSize,
        height: PosterOnboardingJobCard.avatarSize,
      ),
    ]);
  }

  static const maximumContentWidth = 420.0;
  static const _compactAvailableHeight = 536.0;
  static const _regularAvailableHeight = 812.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);

    return MateoView(
      backgroundColor: context.mateo.colorScheme.background,
      edgeFade: null,
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(0, 20, 0, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sceneHeight = _layoutValue(
              availableHeight: constraints.maxHeight,
              compactValue: 210,
              regularValue: 420,
            );
            final headlineFontSize = _layoutValue(
              availableHeight: constraints.maxHeight,
              compactValue: 24,
              regularValue: 28,
            );
            final headlineHorizontalPadding = _layoutValue(
              availableHeight: constraints.maxHeight,
              compactValue: 12,
              regularValue: 24,
            );

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PosterOnboardingJobScene(i18n: i18n, viewportWidth: constraints.maxWidth, height: sceneHeight),
                _buildHeadline(
                  context: context,
                  i18n: i18n,
                  fontSize: headlineFontSize,
                  horizontalPadding: headlineHorizontalPadding,
                ),
                _buildActionsEntrance(context: context, i18n: i18n),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeadline({
    required BuildContext context,
    required Translations i18n,
    required double fontSize,
    required double horizontalPadding,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maximumContentWidth),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.2,
          child: TextMotion.list(
            key: const ValueKey('poster_onboarding_headline_motion'),
            stagger: const Duration(milliseconds: 40),
            effects: const [
              MoveMotionEffect(
                begin: Offset(0, 5),
                end: Offset.zero,
                duration: Duration(milliseconds: 180),
                delay: Duration(milliseconds: 600),
                curve: Curves.easeOut,
              ),
              FadeInMotionEffect(duration: Duration(milliseconds: 180), delay: Duration(milliseconds: 600)),
            ],
            child: Text(
              key: const ValueKey('poster_onboarding_headline'),
              i18n.posterOnboarding.headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.mateo.colorScheme.text.primary,
                fontSize: fontSize,
                height: 1.16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsEntrance({required BuildContext context, required Translations i18n}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maximumContentWidth),
      child: Motion(
        effect: const FadeInMotionEffect(delay: Duration(milliseconds: 780)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return MediaQuery.withClampedTextScaling(
                maxScaleFactor: constraints.maxWidth <= 280 ? 1 : 1.4,
                child: _buildActions(context: context, i18n: i18n),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActions({required BuildContext context, required Translations i18n}) {
    return Row(
      children: [
        MateoFloatingActionButton(
          key: const ValueKey('poster_onboarding_back_button'),
          semanticLabel: i18n.navigation.back,
          size: 60,
          onPressed: () => Navigator.of(context).maybePop(),
          iconBuilder: (state) =>
              MateoIcon.arrowLeft(width: state.iconSize, height: state.iconSize, color: state.foregroundColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: WhatsappLoginButton(key: const ValueKey('poster_onboarding_whatsapp_button'), onSuccess: (_) {}),
        ),
      ],
    );
  }

  double _layoutValue({required double availableHeight, required double compactValue, required double regularValue}) {
    final progress = ((availableHeight - _compactAvailableHeight) / (_regularAvailableHeight - _compactAvailableHeight))
        .clamp(0.0, 1.0);
    return compactValue + (regularValue - compactValue) * progress;
  }
}
