import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

import '../test_app.dart';

final _tapFinder = find.byType(QuiTap);

Finder _scaleWithinTap() => find.descendant(of: _tapFinder, matching: find.byType(ScaleTransition));
Finder _fadeWithinTap() => find.descendant(of: _tapFinder, matching: find.byType(FadeTransition));

void main() {
  group('QuiTap', () {
    testWidgets('when tapped, it should call onPressed', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        TestApp(
          child: QuiTap(
            onPressed: (animation) async {
              tapCount += 1;
            },
            child: const Text('Tap'),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pump(const Duration(milliseconds: 800));

      expect(tapCount, equals(1));
    });

    testWidgets('when pressed, it should apply pressed opacity', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiTap(onPressed: (animation) async {}, child: const Text('Tap')),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));

      await tester.pumpAndSettle();

      final fade = tester.widget<FadeTransition>(_fadeWithinTap());

      expect(fade.opacity.value, closeTo(0.4, 0.001));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('when pressed, it should apply pressed scale', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiTap(onPressed: (animation) async {}, child: const Text('Tap')),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));

      await tester.pumpAndSettle();

      final scale = tester.widget<ScaleTransition>(_scaleWithinTap());

      expect(scale.scale.value, closeTo(0.96, 0.001));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('when disableAnimations is enabled, it should skip pressed visual state', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TestApp(
            child: QuiTap(onPressed: (animation) async {}, child: const Text('Tap')),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));
      await tester.pump(const Duration(milliseconds: 45));

      final scale = tester.widget<ScaleTransition>(_scaleWithinTap());

      expect(scale.scale.value, equals(1.0));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('when disabled and tapped, it should not call onPressed', (tester) async {
      const tapCount = 0;

      await tester.pumpWidget(const TestApp(child: QuiTap(child: Text('Tap'))));

      await tester.tap(find.text('Tap'));

      expect(tapCount, equals(0));
    });

    testWidgets('when tapped down, it should call HapticFeedback.lightImpact', (tester) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
        if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);
        return null;
      });

      await tester.pumpWidget(
        TestApp(
          child: QuiTap(onPressed: (animation) async {}, child: const Text('Tap')),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));
      await tester.pump();

      expect(hapticCalls, hasLength(1));
      expect(hapticCalls[0].method, equals('HapticFeedback.vibrate'));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('when disabled and tapped down, it should not call HapticFeedback', (tester) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
        if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);
        return null;
      });

      await tester.pumpWidget(const TestApp(child: QuiTap(child: Text('Tap'))));

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));
      await tester.pump();

      expect(hapticCalls, isEmpty);

      addTearDown(gesture.up);
    });

    testWidgets('when fireHapticFeedback is true, it should fire haptic feedback', (tester) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
        if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);
        return null;
      });

      await tester.pumpWidget(
        TestApp(
          child: QuiTap(fireHapticFeedback: true, onPressed: (animation) async {}, child: const Text('Tap')),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));
      await tester.pump();

      expect(hapticCalls, hasLength(1));
      expect(hapticCalls[0].method, equals('HapticFeedback.vibrate'));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('when fireHapticFeedback is false, it should not fire haptic feedback', (tester) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
        if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);
        return null;
      });

      await tester.pumpWidget(
        TestApp(
          child: QuiTap(fireHapticFeedback: false, onPressed: (animation) async {}, child: const Text('Tap')),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));
      await tester.pump();

      expect(hapticCalls, isEmpty);

      addTearDown(gesture.up);
    });

    testWidgets('when scale animation type is used, it should render ScaleTransition without FadeTransition', (
      tester,
    ) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiTap(
            animation: QuiTapAnimationType.scale,
            onPressed: (animation) async {},
            child: const Text('Tap'),
          ),
        ),
      );

      expect(_scaleWithinTap(), findsOneWidget);
      expect(_fadeWithinTap(), findsNothing);
    });

    testWidgets('when scale animation type is used and pressed, it should apply pressed scale', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiTap(
            animation: QuiTapAnimationType.scale,
            onPressed: (animation) async {},
            child: const Text('Tap'),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));

      await tester.pumpAndSettle();

      final scale = tester.widget<ScaleTransition>(_scaleWithinTap());

      expect(scale.scale.value, closeTo(0.96, 0.001));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('when animation future is awaited, it should complete after release duration', (tester) async {
      var animationCompleted = false;

      await tester.pumpWidget(
        TestApp(
          child: QuiTap(
            onPressed: (animation) async {
              await animation;
              animationCompleted = true;
            },
            child: const Text('Tap'),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));

      expect(animationCompleted, isFalse);

      await tester.pumpAndSettle();

      expect(animationCompleted, isTrue);
    });

    testWidgets('when tapped very fast, it should still reach the full pressed scale before releasing', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiTap(onPressed: (animation) async {}, child: const Text('Tap')),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();

      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      final scale = tester.widget<ScaleTransition>(_scaleWithinTap());
      expect(scale.scale.value, closeTo(0.96, 0.001));

      await tester.pumpAndSettle();
      expect(scale.scale.value, closeTo(1.0, 0.001));
    });

    testWidgets('when none animation type is used, it should not render ScaleTransition or FadeTransition', (
      tester,
    ) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiTap(
            animation: QuiTapAnimationType.none,
            onPressed: (animation) async {},
            child: const Text('Tap'),
          ),
        ),
      );

      expect(find.descendant(of: _tapFinder, matching: find.byType(ScaleTransition)), findsNothing);
      expect(find.descendant(of: _tapFinder, matching: find.byType(FadeTransition)), findsNothing);
    });

    testWidgets('when none animation type and tapped, it should call onPressed immediately', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        TestApp(
          child: QuiTap(
            animation: QuiTapAnimationType.none,
            onPressed: (animation) async {
              tapCount += 1;
            },
            child: const Text('Tap'),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(tapCount, equals(1));
    });

    testWidgets('when none animation type and disabled, it should not call onPressed', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiTap(
            animation: QuiTapAnimationType.none,
            child: const Text('Tap'),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));
      await tester.pump();

      expect(find.descendant(of: _tapFinder, matching: find.byType(ScaleTransition)), findsNothing);
      expect(find.descendant(of: _tapFinder, matching: find.byType(FadeTransition)), findsNothing);

      await gesture.up();
      await tester.pump();
    });
  });
}
