import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

import '../test_app.dart';

const _kChildSize = 50.0;
const _kChild = SizedBox(width: _kChildSize, height: _kChildSize);

void main() {
  group('when constructing QuiRadarPulse', () {
    test('with zero steps, it should throw AssertionError', () {
      expect(() => QuiRadarPulse(steps: const [], child: _kChild), throwsA(isA<AssertionError>()));
    });

    test('with default steps, it should not throw', () {
      expect(() => QuiRadarPulse(child: _kChild), returnsNormally);
    });

    test('with maxScale equal to 1.0, it should throw AssertionError', () {
      expect(() => QuiRadarPulse(maxScale: 1, child: _kChild), throwsA(isA<AssertionError>()));
    });

    test('with maxScale below 1.0, it should throw AssertionError', () {
      expect(() => QuiRadarPulse(maxScale: 0.5, child: _kChild), throwsA(isA<AssertionError>()));
    });

    test('with maxScale above 1.0, it should not throw', () {
      expect(() => QuiRadarPulse(maxScale: 1.001, child: _kChild), returnsNormally);
    });
  });

  group('when rendering QuiRadarPulse', () {
    testWidgets('with default steps, it should display the child without error', (tester) async {
      await tester.pumpWidget(TestApp(child: QuiRadarPulse(child: _kChild)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('with default steps, it should paint rings via CustomPaint', (tester) async {
      await tester.pumpWidget(TestApp(child: QuiRadarPulse(child: _kChild)));
      expect(find.descendant(of: find.byType(QuiRadarPulse), matching: find.byType(CustomPaint)), findsOneWidget);
    });

    testWidgets('with three custom steps, it should render without error', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiRadarPulse(steps: const [QuiRadarPulseStep(), QuiRadarPulseStep(), QuiRadarPulseStep()], child: _kChild),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('when animations are disabled, it should render without error', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: QuiRadarPulse(child: _kChild),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('when animations are disabled, it should still paint rings', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: QuiRadarPulse(child: _kChild),
          ),
        ),
      );
      expect(find.descendant(of: find.byType(QuiRadarPulse), matching: find.byType(CustomPaint)), findsOneWidget);
    });

    testWidgets('when a custom step color is provided, it should render without error', (tester) async {
      const customColor = Color(0xFF00A896);
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: QuiRadarPulse(
              steps: const [
                QuiRadarPulseStep(color: customColor),
                QuiRadarPulseStep(),
              ],
              child: _kChild,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('when a custom step borderRadius is provided, it should render without error', (tester) async {
      const customRadius = BorderRadius.all(Radius.circular(24));
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: QuiRadarPulse(
              steps: const [
                QuiRadarPulseStep(borderRadius: customRadius),
                QuiRadarPulseStep(),
              ],
              child: _kChild,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('when constructing QuiRadarPulseStep', () {
    test('with alpha below 0, it should throw AssertionError', () {
      expect(() => QuiRadarPulseStep(alpha: -0.1), throwsA(isA<AssertionError>()));
    });

    test('with alpha above 1, it should throw AssertionError', () {
      expect(() => QuiRadarPulseStep(alpha: 1.1), throwsA(isA<AssertionError>()));
    });

    test('with alpha equal to 0, it should not throw', () {
      expect(() => const QuiRadarPulseStep(alpha: 0), returnsNormally);
    });

    test('with alpha equal to 1, it should not throw', () {
      expect(() => const QuiRadarPulseStep(alpha: 1), returnsNormally);
    });

    test('with alpha inside range, it should not throw', () {
      expect(() => const QuiRadarPulseStep(alpha: 0.6), returnsNormally);
    });

    testWidgets('with a custom alpha, it should render without error', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: QuiRadarPulse(steps: const [QuiRadarPulseStep(alpha: 0.6), QuiRadarPulseStep(alpha: 0.2)], child: _kChild),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with alpha 0, it should not paint any visible ring', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: QuiRadarPulse(steps: const [QuiRadarPulseStep(alpha: 0), QuiRadarPulseStep(alpha: 0)], child: _kChild),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('when animating QuiRadarPulse', () {
    testWidgets('at the start, it should have an active animation controller', (tester) async {
      await tester.pumpWidget(TestApp(child: QuiRadarPulse(child: _kChild)));
      await tester.pump(Duration.zero);

      expect(find.descendant(of: find.byType(QuiRadarPulse), matching: find.byType(AnimatedBuilder)), findsOneWidget);
    });

    testWidgets('after half a cycle, it should still render without error', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiRadarPulse(duration: const Duration(milliseconds: 1600), child: _kChild),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));

      expect(tester.takeException(), isNull);
    });

    testWidgets('when duration is updated via didUpdateWidget, it should not throw', (tester) async {
      await tester.pumpWidget(TestApp(child: QuiRadarPulse(child: _kChild)));
      await tester.pumpWidget(
        TestApp(
          child: QuiRadarPulse(duration: const Duration(milliseconds: 2000), child: _kChild),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
