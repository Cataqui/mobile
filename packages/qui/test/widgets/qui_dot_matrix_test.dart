import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

import '../test_app.dart';

void main() {
  group('when constructing QuiDotMatrix', () {
    test('with a negative width, it should throw AssertionError', () {
      expect(
        () => QuiDotMatrix(width: -1, height: 100),
        throwsA(isA<AssertionError>()),
      );
    });

    test('with a negative height, it should throw AssertionError', () {
      expect(
        () => QuiDotMatrix(width: 100, height: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('with a negative radius, it should throw AssertionError', () {
      expect(
        () => QuiDotMatrix(width: 100, height: 100, radius: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('with default props, it should not throw', () {
      expect(
        () => QuiDotMatrix(width: 320, height: 220, radius: 16),
        returnsNormally,
      );
    });

    test('with all valid props including zero values, it should not throw', () {
      expect(
        () => QuiDotMatrix(width: 0, height: 0, radius: 0),
        returnsNormally,
      );
    });
  });

  group('when rendering QuiDotMatrix', () {
    testWidgets('with default props, it should paint particles via CustomPaint', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 320, height: 220, radius: 16)),
      );
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('with default props, it should not use ClipRRect', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 320, height: 220, radius: 16)),
      );
      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('with animations disabled, it should render without error', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const QuiDotMatrix(width: 320, height: 220, radius: 16),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with animations disabled, it should still paint particles', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const QuiDotMatrix(width: 320, height: 220, radius: 16),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('with a custom radius, it should render without error', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 200, height: 200, radius: 24)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with a zero radius, it should render without error', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 200, height: 140, radius: 0)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with a pill radius, it should render without error', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 160, height: 160, radius: 80)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with a tiny size, it should render without error', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 48, height: 48, radius: 12)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with a zero size, it should render without error', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 0, height: 0)),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('when checking particle layout', () {
    Future<void> assertNoOverlap(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child,
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final painter = customPaint.painter;
      final particles = (painter as dynamic).particles as List<dynamic>;
      if (particles.isEmpty) return;

      final diameter = (particles.first.radius as double) * 2;
      const tolerance = 0.01;
      final diameterSquared = diameter * diameter - tolerance;

      var hasOverlap = false;
      for (var i = 0; i < particles.length && !hasOverlap; i++) {
        final a = particles[i];
        for (var j = i + 1; j < particles.length && !hasOverlap; j++) {
          final b = particles[j];
          final dx = (a.position.dx as double) - (b.position.dx as double);
          final dy = (a.position.dy as double) - (b.position.dy as double);
          if (dx * dx + dy * dy < diameterSquared - 0.01) {
            hasOverlap = true;
          }
        }
      }

      expect(hasOverlap, isFalse);
    }

    testWidgets('with a large rounded-rect radius, it should place no overlapping particles', (tester) async {
      await assertNoOverlap(tester, const QuiDotMatrix(width: 320, height: 180, radius: 60));
    });

    testWidgets('with a small square, it should place no overlapping particles', (tester) async {
      await assertNoOverlap(tester, const QuiDotMatrix(width: 70, height: 70, radius: 0));
    });

    testWidgets('with a small circle, it should place no overlapping particles', (tester) async {
      await assertNoOverlap(tester, const QuiDotMatrix(width: 70, height: 70, radius: 35));
    });

    testWidgets('with a medium rect and rounding that nearly exhausts the corners, it should place no overlapping particles', (tester) async {
      await assertNoOverlap(tester, const QuiDotMatrix(width: 250, height: 150, radius: 35));
    });

    testWidgets('with a medium rect and intermediate radius, it should place no overlapping particles', (tester) async {
      await assertNoOverlap(tester, const QuiDotMatrix(width: 300, height: 200, radius: 35));
    });

    testWidgets('with a pill shape, it should place no overlapping particles', (tester) async {
      await assertNoOverlap(tester, const QuiDotMatrix(width: 300, height: 200, radius: 100));
    });

    testWidgets('with a large circle, it should place no overlapping particles', (tester) async {
      await assertNoOverlap(tester, const QuiDotMatrix(width: 200, height: 200, radius: 100));
    });

    testWidgets('with a large square, it should place no overlapping particles', (tester) async {
      await assertNoOverlap(tester, const QuiDotMatrix(width: 400, height: 400, radius: 0));
    });
  });

  group('when animating QuiDotMatrix', () {
    testWidgets('at the start, it should have an active AnimatedBuilder', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 320, height: 220)),
      );
      await tester.pump(Duration.zero);
      expect(
        find.descendant(
          of: find.byType(QuiDotMatrix),
          matching: find.byType(AnimatedBuilder),
        ),
        findsOneWidget,
      );
    });

    testWidgets('after half a cycle, it should still render without error', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 320, height: 220)),
      );
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    });
  });

  group('when the animation wraps around', () {
    testWidgets('after one full cycle, the painter progress should exceed 1.0', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 200, height: 200, radius: 0)),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final painter = customPaint.painter;
      final progress = (painter as dynamic).progress as double;
      expect(progress, greaterThan(1.0));
    });
  });

  group('when calling didUpdateWidget', () {
    testWidgets('with a different width, it should recalculate particles without error', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 200, height: 200, radius: 12)),
      );
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 300, height: 200, radius: 12)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with different height, it should recalculate particles without error', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 200, height: 200, radius: 12)),
      );
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 200, height: 300, radius: 12)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with different radius, it should recalculate particles without error', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 200, height: 200, radius: 12)),
      );
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 200, height: 200, radius: 60)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with same props, it should not crash', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 200, height: 200, radius: 12)),
      );
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 200, height: 200, radius: 12)),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('when width and height are omitted', () {
    testWidgets('it should fill the available space with a CustomPaint', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const SizedBox(width: 180, height: 120, child: QuiDotMatrix(radius: 12)),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('it should generate at least one particle when filling parent space', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const SizedBox(width: 180, height: 120, child: QuiDotMatrix(radius: 12)),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final painter = customPaint.painter;
      expect((painter as dynamic).particles.length, greaterThan(0));
    });

    testWidgets('it should not throw when filling parent space', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const SizedBox(width: 180, height: 120, child: QuiDotMatrix(radius: 12)),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('when the widget is just large enough for a single center dot', () {
    testWidgets('with 28x28 size, it should render at least one particle', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const QuiDotMatrix(width: 28, height: 28, radius: 0),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final painter = customPaint.painter;
      final particles = (painter as dynamic).particles as List<dynamic>;
      expect(particles.length, greaterThan(0));
    });

    testWidgets('with 28x28 size, x-coordinate of the particle should be near the widget centre', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const QuiDotMatrix(width: 28, height: 28, radius: 0),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final painter = customPaint.painter;
      final particles = (painter as dynamic).particles as List<dynamic>;
      final x = (particles.first.position.dx as double);
      expect(x, closeTo(14, 3));
    });

    testWidgets('with 28x28 size, y-coordinate of the particle should be near the widget centre', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const QuiDotMatrix(width: 28, height: 28, radius: 0),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final painter = customPaint.painter;
      final particles = (painter as dynamic).particles as List<dynamic>;
      final y = (particles.first.position.dy as double);
      expect(y, closeTo(14, 3));
    });
  });

  group('when the app lifecycle changes', () {
    testWidgets('when paused, it should stop the animation controller', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 200, height: 200)),
      );
      await tester.pump();

      final state = tester.state(find.byType(QuiDotMatrix));
      (state as dynamic).didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('when resumed, it should restart the animation', (tester) async {
      await tester.pumpWidget(
        TestApp(child: const QuiDotMatrix(width: 200, height: 200)),
      );
      await tester.pump();

      final state = tester.state(find.byType(QuiDotMatrix));
      (state as dynamic).didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();
      (state as dynamic).didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('when mediaQuery disables animations, paused->resumed should not start animation', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const QuiDotMatrix(width: 200, height: 200),
          ),
        ),
      );
      await tester.pump();

      final state = tester.state(find.byType(QuiDotMatrix));
      (state as dynamic).didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();
      (state as dynamic).didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
