import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiTapAnimation', () {
    testWidgets('when tapped, it should call onPressed', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        _TestApp(
          child: QuiTapAnimation(onPressed: (animation) async { tapCount += 1; }, child: const Text('Tap')),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pump(const Duration(milliseconds: 800));

      expect(tapCount, equals(1));
    });

    testWidgets('when pressed, it should apply pressed opacity', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiTapAnimation(onPressed: (animation) async {}, child: const Text('Tap')),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));
      await tester.pump(const Duration(milliseconds: 45));

      final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));

      expect(opacity.opacity, equals(0.2));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('when pressed, it should apply pressed scale', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiTapAnimation(onPressed: (animation) async {}, child: const Text('Tap')),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));
      await tester.pump(const Duration(milliseconds: 45));

      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));

      expect(scale.scale, equals(0.94));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('when disableAnimations is enabled, it should skip pressed visual state', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _TestApp(
            child: QuiTapAnimation(onPressed: (animation) async {}, child: const Text('Tap')),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));
      await tester.pump(const Duration(milliseconds: 45));

      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));

      expect(scale.scale, equals(1.0));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('when disabled and tapped, it should not call onPressed', (tester) async {
      const tapCount = 0;

      await tester.pumpWidget(const _TestApp(child: QuiTapAnimation(child: Text('Tap'))));

      await tester.tap(find.text('Tap'));

      expect(tapCount, equals(0));
    });

    testWidgets('when tapped down, it should call HapticFeedback.lightImpact', (tester) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) {
          if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);
          return null;
        },
      );

      await tester.pumpWidget(
        _TestApp(
          child: QuiTapAnimation(onPressed: (animation) async {}, child: const Text('Tap')),
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
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) {
          if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);
          return null;
        },
      );

      await tester.pumpWidget(const _TestApp(child: QuiTapAnimation(child: Text('Tap'))));

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));
      await tester.pump();

      expect(hapticCalls, isEmpty);

      addTearDown(gesture.up);
    });

    testWidgets('when scale animation type is used, it should render AnimatedScale without AnimatedOpacity', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiTapAnimation(
            animation: QuiTapAnimationType.scale,
            onPressed: (animation) async {},
            child: const Text('Tap'),
          ),
        ),
      );

      expect(find.byType(AnimatedScale), findsOneWidget);
      expect(find.byType(AnimatedOpacity), findsNothing);
    });

    testWidgets('when scale animation type is used and pressed, it should apply pressed scale', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiTapAnimation(
            animation: QuiTapAnimationType.scale,
            onPressed: (animation) async {},
            child: const Text('Tap'),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap')));
      await tester.pump(const Duration(milliseconds: 45));

      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));

      expect(scale.scale, equals(0.94));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('when animation future is awaited, it should complete after release duration', (tester) async {
      var animationCompleted = false;

      await tester.pumpWidget(
        _TestApp(
          child: QuiTapAnimation(
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

      await tester.pump(const Duration(milliseconds: 800));

      expect(animationCompleted, isTrue);
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
      home: Scaffold(body: Center(child: child)),
    );
  }
}
