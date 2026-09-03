import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/welcome/welcome_view/welcome_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../../utils/test_app.dart';

abstract final class WelcomeViewTestHelpers {
  static const artworkSlots = ['top', 'rightTopCorner', 'leftBottomCorner', 'bottom', 'rightBottomCorner'];

  static Future<void> pumpView({
    required WidgetTester tester,
    double width = 390,
    double height = 844,
    EdgeInsets padding = EdgeInsets.zero,
    TextScaler textScaler = TextScaler.noScaling,
    bool disableAnimations = true,
    bool tickerModeEnabled = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

    await repumpView(
      tester: tester,
      width: width,
      height: height,
      padding: padding,
      textScaler: textScaler,
      disableAnimations: disableAnimations,
      tickerModeEnabled: tickerModeEnabled,
    );
  }

  static Future<void> repumpView({
    required WidgetTester tester,
    double width = 390,
    double height = 844,
    EdgeInsets padding = EdgeInsets.zero,
    TextScaler textScaler = TextScaler.noScaling,
    bool disableAnimations = true,
    bool tickerModeEnabled = true,
  }) async {
    tester.view.physicalSize = Size(width, height);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [translationProvider.overrideWithValue(AppLocale.ptBr.buildSync())],
        child: TestApp.screen(
          mediaQueryData: MediaQueryData(
            size: Size(width, height),
            padding: padding,
            textScaler: textScaler,
            disableAnimations: disableAnimations,
          ),
          child: TickerMode(enabled: tickerModeEnabled, child: const WelcomeView()),
        ),
      ),
    );
    await tester.pump();
  }

  static Future<void> finishInitialReveal(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
  }

  static Future<void> beginNextReturn(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 2050));
  }

  static Future<void> finishNextReturn(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
  }

  static Future<void> finishNextReveal(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
  }

  static Future<void> advanceToNextAnimatedJob(WidgetTester tester) async {
    await beginNextReturn(tester);
    await finishNextReturn(tester);
    await finishNextReveal(tester);
  }

  static Future<void> advanceToNextReducedMotionJob(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
  }

  static Motion motion(WidgetTester tester, String key) {
    return tester.widget<Motion>(find.byKey(ValueKey(key)));
  }

  static ({double opacity, double scale, Offset translation}) motionState(WidgetTester tester, String key) {
    final renderObject = tester.renderObject<RenderObject>(
      find
          .descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_MotionTransition'),
          )
          .first,
    );

    return (
      opacity: _motionProperty<double>(renderObject: renderObject, name: 'opacity'),
      scale: _motionProperty<double>(renderObject: renderObject, name: 'scale'),
      translation: _motionProperty<Offset>(renderObject: renderObject, name: 'translation'),
    );
  }

  static Color artworkCircleColor(WidgetTester tester, String slot) {
    final decoration = tester.widget<DecoratedBox>(find.byKey(ValueKey('welcome_artwork_circle_$slot'))).decoration;
    final color = decoration.toDiagnosticsNode().getProperties().singleWhere((property) => property.name == 'color');
    return (color as ColorProperty).value!;
  }

  static Map<String, Element> mountedElements(WidgetTester tester, Iterable<String> keys) {
    return {for (final key in keys) key: find.byKey(ValueKey(key)).evaluate().single};
  }

  static bool elementsAreIdentical(WidgetTester tester, Map<String, Element> previousElements) {
    return previousElements.entries.every(
      (entry) => identical(entry.value, find.byKey(ValueKey(entry.key)).evaluate().single),
    );
  }

  static ({Object? exception, bool hasScrollable, bool contentFits}) layoutState(
    WidgetTester tester, {
    required double width,
    required double height,
  }) {
    final viewport = Rect.fromLTWH(0, 0, width, height);
    final contentFits =
        [
          'welcome_scene_size',
          'welcome_headline',
          'welcome_subtitle',
          'welcome_start_button',
          'welcome_terms_button',
        ].every((key) {
          final rect = tester.getRect(find.byKey(ValueKey(key)));
          return rect.left >= viewport.left - precisionErrorTolerance &&
              rect.top >= viewport.top - precisionErrorTolerance &&
              rect.right <= viewport.right + precisionErrorTolerance &&
              rect.bottom <= viewport.bottom + precisionErrorTolerance;
        });

    return (
      exception: tester.takeException(),
      hasScrollable: find.byType(Scrollable).evaluate().isNotEmpty,
      contentFits: contentFits,
    );
  }

  static Future<void> prepareGoldenCapture({required WidgetTester tester}) async {
    await tester.runAsync(() => WelcomeView.precacheImages(tester.element(find.byType(WelcomeView))));
    await tester.pump();
  }

  static Widget goldenScenario({double width = 390, double height = 844, EdgeInsets padding = EdgeInsets.zero}) {
    return ProviderScope(
      overrides: [translationProvider.overrideWithValue(AppLocale.ptBr.buildSync())],
      child: SizedBox(
        width: width,
        height: height,
        child: TestApp.screen(
          mediaQueryData: MediaQueryData(size: Size(width, height), padding: padding, disableAnimations: true),
          child: const WelcomeView(),
        ),
      ),
    );
  }

  static T _motionProperty<T>({required RenderObject renderObject, required String name}) {
    final property = renderObject.toDiagnosticsNode().getProperties().singleWhere((property) => property.name == name);
    final value = (property as DiagnosticsProperty<T>).value;
    if (value == null) throw StateError('Motion diagnostic $name is null.');
    return value;
  }
}
