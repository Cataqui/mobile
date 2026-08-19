import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/payment/widgets/flexible_payment_values_wheel/flexible_payment_values_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../../../../utils/test_app.dart';
import '../../../create_job_test_state.dart';

void main() {
  late Translations i18n;

  setUpAll(() {
    i18n = AppLocale.ptBr.buildSync();
  });

  testWidgets('when the wheel uses BRL, it should show a locale-formatted Brazilian amount', (tester) async {
    await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'BRL');

    expect(
      find.text(i18n.createJob.payment.flexibleCarousel.amount(currencySymbol: r'R$', value: 350)),
      findsOneWidget,
    );
  });

  testWidgets('when the wheel is rendered, it should own its viewport and use compact amount spacing', (tester) async {
    await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'BRL');
    final amountSpacing =
        _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 1).dy -
        _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;

    expect(
      (
        tester.getSize(find.byKey(_FlexiblePaymentValuesWheelTestHost.wheelKey)),
        _FlexiblePaymentValuesWheelTestHost.amountFontSize(tester: tester, relativeIndex: 0),
        amountSpacing,
      ),
      (const Size(390, 200), 46, 50),
    );
  });

  testWidgets('when BRL amounts are resting, it should emphasize the centered amount with the stronger orange', (
    tester,
  ) async {
    await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'BRL');
    final context = tester.element(find.byKey(_FlexiblePaymentValuesWheelTestHost.wheelKey));

    expect(
      (
        _FlexiblePaymentValuesWheelTestHost.amountColor(tester: tester, relativeIndex: -1),
        _FlexiblePaymentValuesWheelTestHost.amountColor(tester: tester, relativeIndex: 0),
        _FlexiblePaymentValuesWheelTestHost.amountColor(tester: tester, relativeIndex: 1),
      ),
      (context.mateo.palette.orange[3], context.mateo.palette.orange[5], context.mateo.palette.orange[3]),
    );
  });

  testWidgets('when BRL amounts are resting, it should make adjacent values smaller than the centered value', (
    tester,
  ) async {
    await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'BRL');

    expect(
      (
        _FlexiblePaymentValuesWheelTestHost.amountScale(tester: tester, relativeIndex: 0),
        _FlexiblePaymentValuesWheelTestHost.amountScale(tester: tester, relativeIndex: 1),
      ),
      (1, 0.6),
    );
  });

  testWidgets('when BRL amounts leave their resting sizes, it should ease away from both scale boundaries', (
    tester,
  ) async {
    await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'BRL', disableAnimations: false);
    await tester.pump(const Duration(milliseconds: 100));
    final centeredAmountScale = _FlexiblePaymentValuesWheelTestHost.amountScale(tester: tester, relativeIndex: 0);
    final adjacentAmountScale = _FlexiblePaymentValuesWheelTestHost.amountScale(tester: tester, relativeIndex: 1);

    expect((centeredAmountScale > 0.998, adjacentAmountScale < 0.602), (true, true));
  });

  testWidgets('when BRL amounts begin moving, it should add the fourth value only for the transition', (tester) async {
    await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'BRL', disableAnimations: false);
    final restingFourthValueCount = find
        .byKey(const ValueKey<Object>(('flexible_payment_values_wheel_amount', 2)))
        .evaluate()
        .length;

    await tester.pump(const Duration(milliseconds: 1750));
    final movingFourthValueCount = find
        .byKey(const ValueKey<Object>(('flexible_payment_values_wheel_amount', 2)))
        .evaluate()
        .length;

    expect((restingFourthValueCount, movingFourthValueCount), (0, 1));
  });

  testWidgets('when BRL amounts are resting, it should keep one two-sided alpha mask without an overlay gradient', (
    tester,
  ) async {
    await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'BRL');
    final edgeMask = tester.widget<ShaderMask>(find.byKey(_FlexiblePaymentValuesWheelTestHost.edgeMaskKey));

    expect(
      (edgeMask.blendMode, find.byType(ShaderMask).evaluate().length, find.byType(MateoEdgeFade).evaluate().length),
      (BlendMode.dstIn, 1, 0),
    );
  });

  testWidgets('when BRL amounts are halfway through a transition, it should blend both central oranges equally', (
    tester,
  ) async {
    await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'BRL', disableAnimations: false);
    await tester.pump(const Duration(milliseconds: 1000));
    final context = tester.element(find.byKey(_FlexiblePaymentValuesWheelTestHost.wheelKey));
    final halfwayColor = Color.lerp(context.mateo.palette.orange[3], context.mateo.palette.orange[5], 0.5);

    expect(
      (
        _FlexiblePaymentValuesWheelTestHost.amountColor(tester: tester, relativeIndex: 0),
        _FlexiblePaymentValuesWheelTestHost.amountColor(tester: tester, relativeIndex: 1),
      ),
      (halfwayColor, halfwayColor),
    );
  });

  for (final currencyCode in ['ARS', 'USD']) {
    testWidgets('when the wheel uses unsupported $currencyCode, it should hide every amount', (tester) async {
      await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: currencyCode);
      await tester.pumpAndSettle();

      expect(find.byKey(_FlexiblePaymentValuesWheelTestHost.wheelKey), findsNothing);
    });
  }

  testWidgets('when the wheel receives an unsupported currency, it should emit one debug log for that currency', (
    tester,
  ) async {
    final originalDebugPrint = debugPrint;
    final debugMessages = <String>[];
    debugPrint = (message, {wrapWidth}) {
      if (message != null) debugMessages.add(message);
    };
    try {
      await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'ARS');
    } finally {
      debugPrint = originalDebugPrint;
    }

    expect(debugMessages, ['FlexiblePaymentValuesWheel does not have amount values for currency code "ARS".']);
  });

  testWidgets(
    'when currency changes from BRL to unsupported and back, it should hide then restart from the first amount',
    (tester) async {
      await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'BRL', disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 2400));

      _FlexiblePaymentValuesWheelTestHost.setCurrencyCode(tester: tester, currencyCode: 'ARS');
      await tester.pump();
      await tester.pumpAndSettle();
      final unsupportedWheelCount = find.byKey(_FlexiblePaymentValuesWheelTestHost.wheelKey).evaluate().length;

      _FlexiblePaymentValuesWheelTestHost.setCurrencyCode(tester: tester, currencyCode: 'BRL');
      await tester.pump();
      final restoredWheelCount = find.byKey(_FlexiblePaymentValuesWheelTestHost.wheelKey).evaluate().length;
      final restoredCenterAmount = _FlexiblePaymentValuesWheelTestHost.centerAmount(tester);

      expect(
        (unsupportedWheelCount, restoredWheelCount, restoredCenterAmount),
        (0, 1, i18n.createJob.payment.flexibleCarousel.amount(currencySymbol: r'R$', value: 350)),
      );
    },
  );

  testWidgets('when the BRL wheel completes eight steps, it should show eight amounts before wrapping to the first', (
    tester,
  ) async {
    await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'BRL', disableAnimations: false);
    final firstAmount = _FlexiblePaymentValuesWheelTestHost.centerAmount(tester);
    final amounts = <String>{firstAmount};

    for (var step = 1; step < 8; step += 1) {
      await tester.pump(const Duration(milliseconds: 2001));
      amounts.add(_FlexiblePaymentValuesWheelTestHost.centerAmount(tester));
    }

    await tester.pump(const Duration(milliseconds: 2001));
    final wrappedAmount = _FlexiblePaymentValuesWheelTestHost.centerAmount(tester);

    expect((amounts.length, wrappedAmount), (8, firstAmount));
  });

  testWidgets('when the BRL wheel enters its transition, it should move the centered amount upward', (tester) async {
    await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'BRL', disableAnimations: false);
    final restingCenter = _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;

    await tester.pump(const Duration(milliseconds: 1750));
    final movingCenter = _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;

    expect(movingCenter, lessThan(restingCenter));
  });

  testWidgets('when reduced motion is enabled, it should keep the centered BRL amount stationary', (tester) async {
    await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'BRL');
    final initialCenter = _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;

    await tester.pump(const Duration(seconds: 2));
    final laterCenter = _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;

    expect(laterCenter, initialCenter);
  });

  testWidgets('when the wheel first enters with a page transition, it should start moving only after settling', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await _FlexiblePaymentValuesWheelTestHost.pumpNavigationHost(tester: tester, navigatorKey: navigatorKey);
    unawaited(navigatorKey.currentState!.push(_FlexiblePaymentValuesWheelTestHost.wheelRoute()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    final initialCenter = _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;

    await tester.pump(const Duration(milliseconds: 149));
    final transitioningCenter = _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    final settledCenter = _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    final movingCenter = _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;

    expect((transitioningCenter, settledCenter, movingCenter < settledCenter), (initialCenter, initialCenter, true));
  });

  testWidgets('when returning to the wheel through a page transition, it should resume from its preserved position', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await _FlexiblePaymentValuesWheelTestHost.pumpNavigationHost(tester: tester, navigatorKey: navigatorKey);
    unawaited(navigatorKey.currentState!.push(_FlexiblePaymentValuesWheelTestHost.wheelRoute()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final centerBeforeCover = _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;

    unawaited(navigatorKey.currentState!.push(_FlexiblePaymentValuesWheelTestHost.coverRoute()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final centerDuringCover = _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;
    await tester.pump(const Duration(milliseconds: 150));
    navigatorKey.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final centerDuringReturn = _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    final centerAfterReturn = _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    final movingCenter = _FlexiblePaymentValuesWheelTestHost.amountCenter(tester: tester, relativeIndex: 0).dy;

    expect(
      (centerDuringCover, centerDuringReturn, centerAfterReturn, movingCenter < centerAfterReturn),
      (centerBeforeCover, centerBeforeCover, centerBeforeCover, true),
    );
  });

  testWidgets('when assistive technology reads the BRL wheel, it should expose one stable localized description', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _FlexiblePaymentValuesWheelTestHost.pump(tester: tester, currencyCode: 'BRL');
    final semanticDescriptionCount = find
        .bySemanticsLabel(i18n.createJob.payment.flexibleCarousel.semanticLabel)
        .evaluate()
        .length;
    semantics.dispose();

    expect(semanticDescriptionCount, 1);
  });
}

abstract final class _FlexiblePaymentValuesWheelTestHost {
  static const wheelKey = ValueKey('flexible_payment_values_wheel');
  static const centerAmountKey = ValueKey<Object>(('flexible_payment_values_wheel_amount', 0));
  static const edgeMaskKey = ValueKey('flexible_payment_values_wheel_edge_mask');

  static PageRoute<void> wheelRoute() {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const Center(child: SizedBox(width: 390, child: FlexiblePaymentValuesWheel())),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }

  static PageRoute<void> coverRoute() {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.expand(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }

  static Finder amountTextFinder({required int relativeIndex}) {
    return find.descendant(
      of: find.byKey(ValueKey<Object>(('flexible_payment_values_wheel_amount', relativeIndex))),
      matching: find.byType(Text),
    );
  }

  static Offset amountCenter({required WidgetTester tester, required int relativeIndex}) {
    return tester.getCenter(find.byKey(ValueKey<Object>(('flexible_payment_values_wheel_amount', relativeIndex))));
  }

  static Color? amountColor({required WidgetTester tester, required int relativeIndex}) {
    final amountTextFinder = _FlexiblePaymentValuesWheelTestHost.amountTextFinder(relativeIndex: relativeIndex);
    final amountText = tester.widget<Text>(amountTextFinder);

    return DefaultTextStyle.of(tester.element(amountTextFinder)).style.merge(amountText.style).color;
  }

  static double amountScale({required WidgetTester tester, required int relativeIndex}) {
    final transforms = tester.widgetList<Transform>(
      find.ancestor(
        of: find.byKey(ValueKey<Object>(('flexible_payment_values_wheel_amount', relativeIndex))),
        matching: find.byType(Transform),
      ),
    );

    return transforms
        .map((transform) => transform.transform.storage.first)
        .reduce((smallest, scale) => scale < smallest ? scale : smallest);
  }

  static double amountFontSize({required WidgetTester tester, required int relativeIndex}) {
    return tester.widget<Text>(amountTextFinder(relativeIndex: relativeIndex)).style!.fontSize!;
  }

  static String centerAmount(WidgetTester tester) {
    return tester.widget<Text>(find.descendant(of: find.byKey(centerAmountKey), matching: find.byType(Text))).data!;
  }

  static void setCurrencyCode({required WidgetTester tester, required String currencyCode}) {
    ProviderScope.containerOf(
      tester.element(find.byType(FlexiblePaymentValuesWheel)),
    ).read(createJobStateProvider.notifier).setCurrencyCode(currencyCode);
  }

  static Future<void> pump({
    required WidgetTester tester,
    required String currencyCode,
    bool disableAnimations = true,
  }) async {
    await tester.pumpWidget(
      TestApp.screen(
        mediaQueryData: MediaQueryData(
          size: const Size(390, 844),
          devicePixelRatio: 1,
          textScaler: TextScaler.noScaling,
          disableAnimations: disableAnimations,
        ),
        providerOverrides: [
          translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
          createJobStateProvider.overrideWith(
            () => CreateJobTestState(initialData: CreateJobData(currencyCode: currencyCode)),
          ),
        ],
        child: const Center(child: SizedBox(width: 390, child: FlexiblePaymentValuesWheel())),
      ),
    );
    await tester.pump();
  }

  static Future<void> pumpNavigationHost({
    required WidgetTester tester,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    await tester.pumpWidget(
      TestApp.screen(
        navigatorKey: navigatorKey,
        mediaQueryData: const MediaQueryData(
          size: Size(390, 844),
          devicePixelRatio: 1,
          textScaler: TextScaler.noScaling,
        ),
        providerOverrides: [
          translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
          createJobStateProvider.overrideWith(
            () => CreateJobTestState(initialData: const CreateJobData(currencyCode: 'BRL')),
          ),
        ],
        child: const SizedBox.expand(),
      ),
    );
    await tester.pump();
  }
}
