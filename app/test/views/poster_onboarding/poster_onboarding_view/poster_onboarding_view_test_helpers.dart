import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/assets.gen.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/poster_onboarding/poster_onboarding_view/poster_onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/test_app.dart';

abstract final class PosterOnboardingViewTestHelpers {
  static Future<void> prepareGoldenCapture({required WidgetTester tester}) async {
    final context = tester.element(find.byType(PosterOnboardingView));

    await _precacheMemoji(tester: tester, context: context);
    await tester.pumpAndSettle();
  }

  static Future<void> prepareJobSceneGoldenCapture({required WidgetTester tester}) async {
    final context = tester.element(find.byType(PosterOnboardingJobScene));

    await _precacheMemoji(tester: tester, context: context);
    await tester.pumpAndSettle();
  }

  static Future<void> prepareJobCardGoldenCapture({required WidgetTester tester}) async {
    final context = tester.element(find.byType(PosterOnboardingJobCard).first);

    await _precacheMemoji(tester: tester, context: context);
    await tester.pumpAndSettle();
  }

  static Future<void> pumpView({
    required WidgetTester tester,
    double width = 390,
    double height = 844,
    double textScaler = 1,
    bool disableAnimations = true,
  }) async {
    _configureView(tester: tester, width: width, height: height);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [translationProvider.overrideWithValue(AppLocale.ptBr.buildSync())],
        child: TestApp.screen(
          mediaQueryData: MediaQueryData(
            size: Size(width, height),
            textScaler: TextScaler.linear(textScaler),
            disableAnimations: disableAnimations,
          ),
          child: const PosterOnboardingView(),
        ),
      ),
    );
    await _settleInitialFrame(tester: tester, disableAnimations: disableAnimations);
  }

  static Future<void> pumpJobScene({
    required WidgetTester tester,
    double width = 390,
    bool disableAnimations = true,
  }) async {
    _configureView(tester: tester, width: width, height: 520);

    await tester.pumpWidget(jobSceneGoldenScenario(width: width, disableAnimations: disableAnimations));
    await _settleInitialFrame(tester: tester, disableAnimations: disableAnimations);
  }

  static Future<void> pumpJobCard({required WidgetTester tester, double textScaler = 1}) async {
    _configureView(tester: tester, width: 340, height: 460);

    await tester.pumpWidget(jobCardGoldenScenario(textScaler: textScaler));
    await tester.pumpAndSettle();
  }

  static Widget jobSceneGoldenScenario({double width = 390, bool disableAnimations = true}) {
    final i18n = AppLocale.ptBr.buildSync();

    return ProviderScope(
      overrides: [translationProvider.overrideWithValue(i18n)],
      child: SizedBox(
        width: width,
        height: 520,
        child: TestApp.screen(
          mediaQueryData: MediaQueryData(size: Size(width, 520), disableAnimations: disableAnimations),
          child: Scaffold(
            body: PosterOnboardingJobScene(i18n: i18n, viewportWidth: width),
          ),
        ),
      ),
    );
  }

  static Widget jobCardGoldenScenario({double textScaler = 1}) {
    final i18n = AppLocale.ptBr.buildSync();

    return ProviderScope(
      overrides: [translationProvider.overrideWithValue(i18n)],
      child: SizedBox(
        width: 340,
        height: 460,
        child: TestApp.screen(
          mediaQueryData: MediaQueryData(
            size: const Size(340, 460),
            textScaler: TextScaler.linear(textScaler),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: Center(child: PosterOnboardingJobCard.waiter(i18n: i18n, panelWidth: 278)),
          ),
        ),
      ),
    );
  }

  static Widget goldenScenario({double width = 390, double height = 844, double textScaler = 1}) {
    return ProviderScope(
      overrides: [translationProvider.overrideWithValue(AppLocale.ptBr.buildSync())],
      child: SizedBox(
        width: width,
        height: height,
        child: TestApp.screen(
          mediaQueryData: MediaQueryData(
            size: Size(width, height),
            textScaler: TextScaler.linear(textScaler),
            disableAnimations: true,
          ),
          child: const PosterOnboardingView(),
        ),
      ),
    );
  }

  static Future<void> _precacheMemoji({required WidgetTester tester, required BuildContext context}) async {
    await tester.runAsync(() async {
      await Future.wait(Assets.memoji.values.map((asset) => precacheImage(asset.provider(), context)));
    });
  }

  static void _configureView({required WidgetTester tester, required double width, required double height}) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
  }

  static Future<void> _settleInitialFrame({required WidgetTester tester, required bool disableAnimations}) async {
    if (disableAnimations) {
      await tester.pumpAndSettle();
      return;
    }

    await tester.pump();
  }
}
