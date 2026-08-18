import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/onboarding/onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/test_app.dart';

abstract final class OnboardingViewTestHelpers {
  static Future<void> prepareGoldenCapture({required WidgetTester tester}) async {
    final context = tester.element(find.byType(OnboardingView));

    await tester.runAsync(() async {
      await Future.wait([
        precacheImage(const AssetImage('assets/illustrations/cooker_hat.webp'), context),
        precacheImage(const AssetImage('assets/illustrations/hammer.webp'), context),
        precacheImage(const AssetImage('assets/illustrations/ladder.webp'), context),
      ]);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  static Future<void> pumpView({
    required WidgetTester tester,
    double width = 390,
    double height = 844,
    EdgeInsets padding = EdgeInsets.zero,
    bool disableAnimations = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [translationProvider.overrideWithValue(AppLocale.ptBr.buildSync())],
        child: TestApp.screen(
          mediaQueryData: MediaQueryData(
            size: Size(width, height),
            padding: padding,
            disableAnimations: disableAnimations,
          ),
          child: const OnboardingView(),
        ),
      ),
    );
    if (!disableAnimations) {
      await tester.pump();
      return;
    }

    await tester.pumpAndSettle();
  }

  static Widget goldenScenario({double width = 390, double height = 844, EdgeInsets padding = EdgeInsets.zero}) {
    return ProviderScope(
      overrides: [translationProvider.overrideWithValue(AppLocale.ptBr.buildSync())],
      child: SizedBox(
        width: width,
        height: height,
        child: TestApp.screen(
          mediaQueryData: MediaQueryData(size: Size(width, height), padding: padding, disableAnimations: true),
          child: const OnboardingView(),
        ),
      ),
    );
  }
}
