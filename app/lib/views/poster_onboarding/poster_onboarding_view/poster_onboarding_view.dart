import 'dart:math' as math;

import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/assets.gen.dart';
import 'package:cataqui_app/gen/svg.g.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'poster_onboarding_job_card.dart';
part 'poster_onboarding_job_scene.dart';

class PosterOnboardingView extends ConsumerWidget {
  const PosterOnboardingView({super.key});

  static const maximumContentWidth = 420.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);

    return Scaffold(
      backgroundColor: context.mateo.colorScheme.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _buildScrollView(context: context, constraints: constraints, i18n: i18n);
              },
            ),
          ),
          Positioned(
            key: const ValueKey('poster_onboarding_top_edge_fade_layer'),
            top: 0,
            left: 0,
            right: 0,
            child: MateoEdgeFade(
              position: MateoEdgeFadePosition.top,
              style: MateoEdgeFadeStyle(color: context.mateo.colorScheme.background),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollView({
    required BuildContext context,
    required BoxConstraints constraints,
    required Translations i18n,
  }) {
    final safeAreaPadding = MediaQuery.paddingOf(context);

    return CustomScrollView(
      key: const ValueKey('poster_onboarding_scroll_view'),
      primary: false,
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight, maxWidth: maximumContentWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, safeAreaPadding.top + 20, 0, safeAreaPadding.bottom + 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PosterOnboardingJobScene(i18n: i18n, viewportWidth: constraints.maxWidth),
                    const SizedBox(height: 60),
                    _buildHeadline(context: context, i18n: i18n),
                    const SizedBox(height: 32),
                    _buildActionsEntrance(context: context, i18n: i18n),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeadline({required BuildContext context, required Translations i18n}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
            fontSize: 28,
            height: 1.16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionsEntrance({required BuildContext context, required Translations i18n}) {
    return Motion(
      effect: const FadeInMotionEffect(delay: Duration(milliseconds: 780)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return MediaQuery.withClampedTextScaling(
              maxScaleFactor: constraints.maxWidth <= 280 ? 1 : 1.4,
              child: _buildActions(context: context, i18n: i18n),
            );
          },
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
          child: _buildWhatsappButton(context: context, i18n: i18n),
        ),
      ],
    );
  }

  Widget _buildWhatsappButton({required BuildContext context, required Translations i18n}) {
    return MateoButton(
      key: const ValueKey('poster_onboarding_whatsapp_button'),
      variant: MateoButtonVariant.primary,
      fit: MateoButtonFit.expand,
      label: i18n.posterOnboarding.loginWithWhatsapp,
      colorScheme: context.mateo.colorScheme.buttons.whatsapp.tertiary,
      leadingIconSpacing: 6,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      onPressed: () {},
      leadingIconBuilder: (state) {
        return MateoIcon.whatsapp(width: 22, height: 22, color: state.foregroundColor);
      },
    );
  }
}
