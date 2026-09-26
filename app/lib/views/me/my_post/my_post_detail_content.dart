import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/lotties.g.dart';
import 'package:cataqui_app/views/me/my_post/my_post_detail_chips.dart';
import 'package:cataqui_app/views/me/my_post/my_post_header_surface.dart';
import 'package:cataqui_app/views/me/my_post/my_post_morph_target.dart';
import 'package:cataqui_app/views/me/my_post/my_post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class MyPostDetailContent extends ConsumerWidget {
  const MyPostDetailContent({required this.jobId, required this.routeAnimation, required this.chipsWidth, super.key});

  static const fadeExtent = 16.0;
  static const shadowCoverage = 112.0;

  final String jobId;
  final Animation<double> routeAnimation;
  final double chipsWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = MateoTheme.of(context);
    final i18n = ref.watch(translationProvider);
    final detailState = ref.watch(myPostStateProvider(jobId));
    final data = detailState.asData?.value;
    final descriptionStyle = TextStyle(
      fontSize: 16,
      fontWeight: .w500,
      height: 1.25,
      color: theme.colorScheme.text.secondary,
    );
    final body = FadeTransition(
      opacity: MediaQuery.disableAnimationsOf(context)
          ? const AlwaysStoppedAnimation<double>(1)
          : routeAnimation.drive(CurveTween(curve: const Interval(.55, 1))),
      child: detailState.when(
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              mainAxisSize: .min,
              children: [
                $Lotties.doubleCross(
                  height: 62,
                  delay: const Duration(milliseconds: 150),
                  duration: const Duration(milliseconds: 750),
                  overrides: .new(
                    leftCrossBottomUpSlashColor: theme.colorScheme.text.tertiary,
                    rightCrossTopDownSlashColor: theme.colorScheme.text.tertiary,
                    leftCrossTopDownSlashColor: theme.colorScheme.text.tertiary,
                    rightCrossBottomUpSlashColor: theme.colorScheme.text.tertiary,
                  ),
                ),
                const SizedBox(height: 20),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Text(
                    i18n.me.myPost.error.title,
                    textAlign: .center,
                    style: TextStyle(fontSize: 16, fontWeight: .w500, color: theme.colorScheme.text.secondary),
                  ),
                ),
                const SizedBox(height: 24),
                MateoButton(
                  key: const ValueKey('my_post_retry_button'),
                  presentation: .label(
                    width: .fit,
                    size: .small,
                    variant: .secondary.neutral,
                    label: i18n.me.myPost.error.retryButtonTitle,
                  ),
                  onPressed: () => ref.read(myPostStateProvider(jobId).notifier).retry(),
                ),
              ],
            ),
          ),
        ),
        loading: () => Skeleton(
          semanticsLabel: i18n.me.myPost.loadingSemanticLabel,
          style: SkeletonStyle(
            color: theme.colorScheme.skeleton.bone,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          child: Text(
            'Ajudar com um serviço por algumas horas. Precisamos de alguém disponível na região para começar logo.',
            key: const ValueKey('my_post_description'),
            style: descriptionStyle,
          ),
        ),
        data: (data) =>
            Text(data.detail.description, key: const ValueKey('my_post_description'), style: descriptionStyle),
      ),
    );
    return MorphNode(
      target: ref.watch(myPostMorphTargetProvider(jobId)),
      zIndex: 1,
      transitionBuilder: (context, child, curvedAnimation, uncurvedAnimation) => FadeTransition(
        opacity: MediaQuery.disableAnimationsOf(context) ? const AlwaysStoppedAnimation<double>(1) : routeAnimation,
        child: child,
      ),
      child: Stack(
        clipBehavior: .none,
        children: [
          Positioned(
            top: MyPostHeaderSurface.detailBodyOverlap - MyPostHeaderSurface.detailRadius - fadeExtent,
            left: 0,
            right: 0,
            height: fadeExtent + MyPostHeaderSurface.detailRadius + shadowCoverage,
            child: IgnorePointer(
              child: OverflowBox(
                minWidth: chipsWidth,
                maxWidth: chipsWidth,
                child: DecoratedBox(
                  key: const ValueKey('my_post_card_fade'),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: .topCenter,
                      end: .bottomCenter,
                      stops: const [
                        0,
                        fadeExtent / (fadeExtent + MyPostHeaderSurface.detailRadius + shadowCoverage),
                        1,
                      ],
                      colors: [
                        theme.colorScheme.background.withValues(alpha: 0),
                        theme.colorScheme.background,
                        theme.colorScheme.background,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: .start,
            children: [
              if (!detailState.hasError) ...[
                SizedBox(
                  height: MyPostDetailChips.height,
                  child: OverflowBox(
                    alignment: .center,
                    minWidth: chipsWidth,
                    maxWidth: chipsWidth,
                    child: MyPostDetailChips(data: data),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (detailState.hasError) Expanded(child: body) else body,
            ],
          ),
        ],
      ),
    );
  }
}
