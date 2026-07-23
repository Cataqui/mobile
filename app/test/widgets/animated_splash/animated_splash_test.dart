import 'package:cataqui_app/widgets/app_animated_splash/app_animated_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/test_app.dart';

abstract final class _AnimatedSplashTestHarness {
  static Widget build({bool disableAnimations = false}) {
    final mediaQueryData = const MediaQueryData(
      size: Size(390, 780),
      devicePixelRatio: 1,
    ).copyWith(disableAnimations: disableAnimations);

    return TestApp.screen(
      mediaQueryData: mediaQueryData,
      child: const AppAnimatedSplash(
        child: Scaffold(body: Center(child: Text('Cataquí'))),
      ),
    );
  }

  static double animatedScale(WidgetTester tester) {
    final transforms = tester.widgetList<Transform>(
      find.descendant(of: find.byType(AppAnimatedSplash), matching: find.byType(Transform)),
    );

    return transforms.map((transform) => transform.transform.storage.first).reduce((a, b) => a > b ? a : b);
  }

  static Finder splashOverlayPainter() {
    return find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter?.runtimeType.toString() == '_SplashOverlayPainter',
    );
  }

  static Finder splashLogoPainter() {
    return find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter?.runtimeType.toString() == '_SplashLogoPainter',
    );
  }

  static Future<void> settleStartupFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  static Future<void> startReveal(WidgetTester tester) async {
    await tester.pump(AppAnimatedSplash.anticipationDuration);
    await tester.pump();
  }

  static ({Offset center, double radius}) logoOpening(WidgetTester tester) {
    const assetScale = 160.25 / 641;
    final logoRenderBox = tester.renderObject<RenderBox>(splashLogoPainter());
    final openingCenter = logoRenderBox.localToGlobal(const Offset(294.649 * assetScale, 307.786 * assetScale));
    final openingEdge = logoRenderBox.localToGlobal(
      const Offset((294.649 + 49.575) * assetScale, 307.786 * assetScale),
    );

    return (center: openingCenter, radius: (openingEdge - openingCenter).distance);
  }
}

void main() {
  group('CataquiAnimatedSplash', () {
    testWidgets('when the matching Flutter frame first renders, it should keep the splash covering the app', (
      tester,
    ) async {
      await tester.pumpWidget(_AnimatedSplashTestHarness.build());

      expect(_AnimatedSplashTestHarness.splashOverlayPainter(), findsOneWidget);
    });

    testWidgets('when the splash waits before zooming, it should keep the centered logo at its native scale', (
      tester,
    ) async {
      await tester.pumpWidget(_AnimatedSplashTestHarness.build());
      await _AnimatedSplashTestHarness.settleStartupFrames(tester);
      await tester.pump(AppAnimatedSplash.anticipationDuration ~/ 2);

      expect(_AnimatedSplashTestHarness.animatedScale(tester), 1);

      await tester.pumpAndSettle();
    });

    testWidgets('when the logo zooms toward the app, it should reveal the app through the screen center', (
      tester,
    ) async {
      await tester.pumpWidget(_AnimatedSplashTestHarness.build());
      await _AnimatedSplashTestHarness.settleStartupFrames(tester);
      await _AnimatedSplashTestHarness.startReveal(tester);
      await tester.pump(const Duration(milliseconds: 360));

      final viewportSize = tester.getSize(find.byType(AppAnimatedSplash));
      final opening = _AnimatedSplashTestHarness.logoOpening(tester);
      final viewportCenter = viewportSize.center(Offset.zero);

      expect((viewportCenter - opening.center).distance <= opening.radius, isTrue);
    });

    testWidgets('when the logo begins zooming, it should align the reveal with the SVG circular opening', (
      tester,
    ) async {
      await tester.pumpWidget(_AnimatedSplashTestHarness.build());
      await _AnimatedSplashTestHarness.settleStartupFrames(tester);
      await _AnimatedSplashTestHarness.startReveal(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(_AnimatedSplashTestHarness.logoOpening(tester).radius, greaterThan(49.575 * 160.25 / 641));
    });

    testWidgets('when the logo begins zooming, it should move the opening toward the screen center', (tester) async {
      await tester.pumpWidget(_AnimatedSplashTestHarness.build());
      await _AnimatedSplashTestHarness.settleStartupFrames(tester);

      final viewportSize = tester.getSize(find.byType(AppAnimatedSplash));
      final viewportCenter = viewportSize.center(Offset.zero);
      final initialDistance = (_AnimatedSplashTestHarness.logoOpening(tester).center - viewportCenter).distance;

      await _AnimatedSplashTestHarness.startReveal(tester);
      await tester.pump(const Duration(milliseconds: 100));

      final revealDistance = (_AnimatedSplashTestHarness.logoOpening(tester).center - viewportCenter).distance;

      expect(revealDistance, lessThan(initialDistance));
    });

    testWidgets('when the app first appears through the logo opening, it should paint the brand-color reveal fade', (
      tester,
    ) async {
      await tester.pumpWidget(_AnimatedSplashTestHarness.build());
      await _AnimatedSplashTestHarness.settleStartupFrames(tester);
      await _AnimatedSplashTestHarness.startReveal(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(_AnimatedSplashTestHarness.splashOverlayPainter(), findsOneWidget);
    });

    testWidgets('when the reveal finishes, it should remove every splash overlay', (tester) async {
      await tester.pumpWidget(_AnimatedSplashTestHarness.build());
      await _AnimatedSplashTestHarness.settleStartupFrames(tester);
      await _AnimatedSplashTestHarness.startReveal(tester);
      await tester.pumpAndSettle();

      expect(_AnimatedSplashTestHarness.splashOverlayPainter(), findsNothing);
    });

    testWidgets('when the device disables animations, it should reveal the app without playing the zoom', (
      tester,
    ) async {
      await tester.pumpWidget(_AnimatedSplashTestHarness.build(disableAnimations: true));
      await tester.pumpAndSettle();

      expect(_AnimatedSplashTestHarness.splashOverlayPainter(), findsNothing);
    });
  });
}
