import 'dart:async';
import 'dart:math' as math;

import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/icons.g.dart';
import 'package:cataqui_app/gen/illustrations.g.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/post/post_route.dart';
import 'package:cataqui_app/views/welcome/welcome_view/enums/welcome_artwork_slot.dart';
import 'package:cataqui_app/views/welcome/welcome_view/enums/welcome_scene_phase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

part 'welcome_artwork_background_box_painter.dart';
part 'welcome_artwork_background_decoration.dart';
part 'welcome_job.dart';
part 'welcome_job_card.dart';
part 'welcome_job_scene.dart';
part 'welcome_jobs.dart';

class WelcomeView extends ConsumerStatefulWidget {
  const WelcomeView({super.key});

  static Future<void> precacheImages(BuildContext context) {
    return _WelcomeJobScene.precacheArtwork(
      context,
      artwork: _WelcomeJobs.forTranslations(
        ProviderScope.containerOf(context, listen: false).read(translationProvider),
      ).first.artwork,
    );
  }

  static const _titleRevealDelay = Duration(milliseconds: 600);
  static const _titleRevealDuration = Duration(milliseconds: 500);
  static const _titleMoveDuration = Duration(milliseconds: 500);
  static const _sceneEntranceDuration = Duration(milliseconds: 600);
  static const _artworkEntranceDelay = Duration(milliseconds: 1750);
  static const _controlsEntranceDelay = Duration(milliseconds: 1850);
  static const _controlsEntranceDuration = Duration(milliseconds: 500);
  static const _controlsEntranceOffset = Offset(0, 20);
  static const _minimumTopInset = 42.0;
  static final _titleMoveDelay = _titleRevealDelay + _titleRevealDuration;
  static final _sceneEntranceDelay = _titleMoveDelay + _titleMoveDuration;

  @override
  ConsumerState<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends ConsumerState<WelcomeView> {
  final ValueNotifier<bool> _sceneVisible = ValueNotifier(false);
  final ValueNotifier<bool> _termsVisible = ValueNotifier(false);
  final ValueNotifier<bool> _buttonVisible = ValueNotifier(false);

  void _showScene() {
    if (_sceneVisible.value || !mounted) return;
    _sceneVisible.value = true;
  }

  void _showTerms() {
    if (_termsVisible.value || !mounted) return;
    _termsVisible.value = true;
  }

  void _showButton() {
    if (_buttonVisible.value || !mounted) return;
    _buttonVisible.value = true;
  }

  @override
  void dispose() {
    _sceneVisible.dispose();
    _termsVisible.dispose();
    _buttonVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1,
      child: MateoView(
        padding: const EdgeInsets.only(bottom: 20, top: 20),
        footer: MateoViewFooter(
          principal: ValueListenableBuilder<bool>(
            valueListenable: _termsVisible,
            builder: (_, visible, child) => ExcludeSemantics(excluding: !visible, child: child),
            child: RepaintBoundary(
              child: Motion.list(
                key: const ValueKey('welcome_terms_entrance'),
                effects: [
                  const MoveMotionEffect(
                    begin: WelcomeView._controlsEntranceOffset,
                    end: Offset.zero,
                    delay: WelcomeView._controlsEntranceDelay,
                    duration: WelcomeView._controlsEntranceDuration,
                    curve: Curves.easeOutCubic,
                  ),
                  FadeInMotionEffect(
                    delay: WelcomeView._controlsEntranceDelay,
                    duration: WelcomeView._controlsEntranceDuration,
                    curve: Curves.easeOutCubic,
                    onEnd: _showTerms,
                  ),
                ],
                child: RepaintBoundary(
                  child: _buildTerms(context: context, i18n: i18n),
                ),
              ),
            ),
          ),
        ),
        surface: MateoViewSurface(
          color: MateoTheme.of(context).colorScheme.background,
          child: SafeArea(
            bottom: false,
            minimum: const EdgeInsets.only(top: WelcomeView._minimumTopInset),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _buildContent(context: context, i18n: i18n),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({required BuildContext context, required Translations i18n}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final fittedSceneSize = applyBoxFit(
                  BoxFit.scaleDown,
                  _WelcomeJobScene.sceneSize,
                  Size(constraints.maxWidth, constraints.maxHeight * 2 / 3),
                ).destination;

                return Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox.fromSize(
                        size: fittedSceneSize,
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: SizedBox.fromSize(
                            size: _WelcomeJobScene.sceneSize,
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _sceneVisible,
                              builder: (_, visible, child) => ExcludeSemantics(excluding: !visible, child: child),
                              child: Motion(
                                key: const ValueKey('welcome_scene_entrance'),
                                effect: FadeInMotionEffect(
                                  delay: WelcomeView._sceneEntranceDelay,
                                  duration: WelcomeView._sceneEntranceDuration,
                                  curve: Curves.easeOutCubic,
                                  onEnd: _showScene,
                                ),
                                child: _WelcomeJobScene(
                                  key: const ValueKey('welcome_scene_size'),
                                  jobs: _WelcomeJobs.forTranslations(i18n),
                                  accessibilityLabel: i18n.welcome.sceneAccessibilityLabel,
                                  floatingStartDelay: WelcomeView._sceneEntranceDelay,
                                  initialRevealDelay: WelcomeView._artworkEntranceDelay,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: fittedSceneSize.height,
                      right: 0,
                      bottom: 0,
                      left: 0,
                      child: Align(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: _WelcomeJobScene.sceneSize.width,
                            child: RepaintBoundary(
                              child: Motion.list(
                                key: const ValueKey('welcome_message_entrance'),
                                effects: [
                                  const ScaleInMotionEffect(
                                    scale: 1.12,
                                    delay: WelcomeView._titleRevealDelay,
                                    duration: WelcomeView._titleRevealDuration,
                                    curve: Curves.easeOutCubic,
                                  ),
                                  const FadeInMotionEffect(
                                    delay: WelcomeView._titleRevealDelay,
                                    duration: WelcomeView._titleRevealDuration,
                                    curve: Curves.easeOutCubic,
                                  ),
                                  MoveMotionEffect(
                                    begin: Offset(
                                      0,
                                      MediaQuery.sizeOf(context).height / 2 -
                                          math.max(MediaQuery.paddingOf(context).top, WelcomeView._minimumTopInset) -
                                          (fittedSceneSize.height + constraints.maxHeight) / 2,
                                    ),
                                    end: Offset.zero,
                                    delay: WelcomeView._titleMoveDelay,
                                    duration: WelcomeView._titleMoveDuration,
                                    curve: Curves.easeInOutCubic,
                                  ),
                                ],
                                child: RepaintBoundary(
                                  child: Column(
                                    key: const ValueKey('welcome_message'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Semantics(
                                        header: true,
                                        child: Text(
                                          i18n.welcome.headline,
                                          key: const ValueKey('welcome_headline'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: MateoTheme.of(context).colorScheme.text.primary,
                                            fontSize: 28,
                                            height: 1.12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      FractionallySizedBox(
                                        widthFactor: 0.6,
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(text: i18n.welcome.subtitle),
                                              const WidgetSpan(child: SizedBox(width: 5)),
                                              WidgetSpan(
                                                alignment: PlaceholderAlignment.middle,
                                                child: MateoIcon(
                                                  .buildings,
                                                  size: 18,
                                                  color: MateoTheme.of(context).colorScheme.text.tertiary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          key: const ValueKey('welcome_subtitle'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: MateoTheme.of(context).colorScheme.text.tertiary,
                                            fontSize: 17,
                                            height: 1.2,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
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
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ValueListenableBuilder<bool>(
              valueListenable: _buttonVisible,
              builder: (_, visible, child) => ExcludeSemantics(excluding: !visible, child: child),
              child: RepaintBoundary(
                child: Motion.list(
                  key: const ValueKey('welcome_button_entrance'),
                  effects: [
                    const MoveMotionEffect(
                      begin: WelcomeView._controlsEntranceOffset,
                      end: Offset.zero,
                      delay: WelcomeView._controlsEntranceDelay,
                      duration: WelcomeView._controlsEntranceDuration,
                      curve: Curves.easeOutCubic,
                    ),
                    FadeInMotionEffect(
                      delay: WelcomeView._controlsEntranceDelay,
                      duration: WelcomeView._controlsEntranceDuration,
                      curve: Curves.easeOutCubic,
                      onEnd: _showButton,
                    ),
                  ],
                  child: RepaintBoundary(
                    child: MateoMenuButton(
                      key: const ValueKey('welcome_start_button'),
                      animation: const .transform(),
                      buttonPresentation: .label(
                        label: i18n.welcome.startButton,
                        variant: .primary.neutral,
                        width: .fill,
                      ),
                      menuPresentation: .options(
                        density: .standard,
                        width: .fill,
                        items: [
                          .new(
                            principal: Text(
                              i18n.welcome.actions.post.title,
                              key: const ValueKey('welcome_post_action'),
                            ),
                            supporting: Text(i18n.welcome.actions.post.description),
                            leading: MateoIcon(
                              .boxPencil,
                              backgroundColor: MateoTheme.of(context).palette.green[9],
                              color: MateoTheme.of(context).palette.white,
                            ),
                          ),
                          .new(
                            principal: Text(
                              i18n.welcome.actions.browse.title,
                              key: const ValueKey('welcome_browse_action'),
                            ),
                            supporting: Text(i18n.welcome.actions.browse.description),
                            leading: MateoIcon(
                              .rectangleStack,
                              backgroundColor: MateoTheme.of(context).palette.blue[9],
                              color: MateoTheme.of(context).palette.white,
                            ),
                          ),
                        ],
                      ),
                      onItemPressed: (item) async {
                        if (item.principal?.key == const ValueKey('welcome_post_action')) {
                          await ref.read(appRouterProvider.notifier).go(context, const PostRoute());
                          return;
                        }
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

                        if (!context.mounted) return;
                        await ref.read(appRouterProvider.notifier).go(context, const FeedRoute());
                      },
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

  Widget _buildTerms({required BuildContext context, required Translations i18n}) {
    return MateoPress(
      key: const ValueKey('welcome_terms_button'),
      semanticLabel: '${i18n.welcome.terms.prefix} ${i18n.welcome.terms.link}',
      onPressed: (_) async => launchUrl(Uri.parse('https://cataqui.com/terms'), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${i18n.welcome.terms.prefix} '),
              TextSpan(
                text: i18n.welcome.terms.link,
                style: const TextStyle(decoration: TextDecoration.underline),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: MateoTheme.of(context).colorScheme.text.tertiary,
            decorationColor: MateoTheme.of(context).colorScheme.text.tertiary,
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
