import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

import '../test_app.dart';

void main() {
  group('when constructing QuiSwipeUpHint', () {
    test('with default props, it should not throw', () {
      expect(() => const QuiSwipeUpHint(), returnsNormally);
    });

    test('with a custom height, it should not throw', () {
      expect(() => const QuiSwipeUpHint(height: 200), returnsNormally);
    });

    test('with a custom phoneColor, it should not throw', () {
      expect(() => const QuiSwipeUpHint(phoneColor: Color(0xFF1F1F1F)), returnsNormally);
    });

    test('with a custom accentColor, it should not throw', () {
      expect(() => const QuiSwipeUpHint(accentColor: Color(0xFFFF4A4B)), returnsNormally);
    });

    test('with height zero, it should not throw', () {
      expect(() => const QuiSwipeUpHint(height: 0), returnsNormally);
    });
  });

  group('when rendering QuiSwipeUpHint', () {
    testWidgets('with default props, it should paint via CustomPaint', (tester) async {
      await tester.pumpWidget(const TestApp(child: QuiSwipeUpHint()));
      expect(find.descendant(of: find.byType(QuiSwipeUpHint), matching: find.byType(CustomPaint)), findsOneWidget);
    });

    testWidgets('with default props, it should size itself from the height prop', (tester) async {
      await tester.pumpWidget(const TestApp(child: QuiSwipeUpHint()));

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(QuiSwipeUpHint), matching: find.byType(CustomPaint)),
      );

      expect(customPaint.size.height, closeTo(120, 0.1));
    });

    testWidgets('with a custom height, it should size itself accordingly', (tester) async {
      await tester.pumpWidget(const TestApp(child: QuiSwipeUpHint(height: 200)));

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(QuiSwipeUpHint), matching: find.byType(CustomPaint)),
      );

      expect(customPaint.size.height, closeTo(200, 0.1));
    });

    testWidgets('when animations are disabled, it should render without error', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: MediaQuery(data: MediaQueryData(disableAnimations: true), child: QuiSwipeUpHint()),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('when animations are disabled, it should still paint via CustomPaint', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: MediaQuery(data: MediaQueryData(disableAnimations: true), child: QuiSwipeUpHint()),
        ),
      );
      expect(find.descendant(of: find.byType(QuiSwipeUpHint), matching: find.byType(CustomPaint)), findsOneWidget);
    });

    testWidgets('with a custom phoneColor, it should render without error', (tester) async {
      await tester.pumpWidget(const TestApp(child: QuiSwipeUpHint(phoneColor: Color(0xFF1F1F1F))));
      expect(tester.takeException(), isNull);
    });

    testWidgets('with a custom accentColor, it should render without error', (tester) async {
      await tester.pumpWidget(const TestApp(child: QuiSwipeUpHint(accentColor: Color(0xFFFF4A4B))));
      expect(tester.takeException(), isNull);
    });
  });

  group('when animating QuiSwipeUpHint', () {
    testWidgets('after a partial cycle, it should still render without error', (tester) async {
      await tester.pumpWidget(const TestApp(child: QuiSwipeUpHint()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('after a full cycle, it should loop without error', (tester) async {
      await tester.pumpWidget(const TestApp(child: QuiSwipeUpHint()));
      await tester.pump(const Duration(milliseconds: 2200));

      expect(tester.takeException(), isNull);
    });
  });

  group('when reduced motion is enabled', () {
    testWidgets('it should render a static frame without error', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: MediaQuery(data: MediaQueryData(disableAnimations: true), child: QuiSwipeUpHint()),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.descendant(of: find.byType(QuiSwipeUpHint), matching: find.byType(CustomPaint)), findsOneWidget);
    });

    testWidgets('it should pass progress 0.3 to the generated animation widget', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: MediaQuery(data: MediaQueryData(disableAnimations: true), child: QuiSwipeUpHint()),
        ),
      );

      final swipeUpPhone = tester.widgetList<Widget>(
        find.descendant(
          of: find.byType(QuiSwipeUpHint),
          matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_SwipeUpPhoneAnimation'),
        ),
      ).first;

      final progress = (swipeUpPhone as dynamic).progress as double;

      expect(progress, 0.3);
    });
  });
}
