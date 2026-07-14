import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';
import '../test_app.dart';

final _quiAppearFinder = find.byType(QuiAppear);

FadeTransition _fadeWithinQuiAppear(WidgetTester tester) => tester.widget<FadeTransition>(
  find.descendant(of: _quiAppearFinder, matching: find.byType(FadeTransition)),
);

void main() {
  group('QuiAppear', () {
    testWidgets('when appear is called after mounting, it should animate opacity from 0 to 1', (tester) async {
      final controller = QuiAppearController();

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(controller: controller, child: const Text('Hello')),
        ),
      );

      await tester.pump();

      final fade = _fadeWithinQuiAppear(tester);
      expect(fade.opacity.value, 0);

      controller.appear();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fade.opacity.value, 1);
    });

    testWidgets('when appear is called before mounting, it should appear once mounted', (tester) async {
      final controller = QuiAppearController();
      controller.appear();

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(controller: controller, child: const Text('Hello')),
        ),
      );

      await tester.pumpAndSettle();

      final fade = _fadeWithinQuiAppear(tester);
      expect(fade.opacity.value, 1);
    });

    testWidgets('when destroy is called, it should animate opacity from 1 to 0', (tester) async {
      final controller = QuiAppearController();

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(controller: controller, child: const Text('Hello')),
        ),
      );

      controller.appear();
      await tester.pumpAndSettle();

      final fade = _fadeWithinQuiAppear(tester);
      expect(fade.opacity.value, 1);

      controller.destroy();
      await tester.pumpAndSettle();

      expect(fade.opacity.value, 0);
    });

    testWidgets('when disableAnimations is true and appear is called, it should set opacity immediately to 1',
        (tester) async {
      final controller = QuiAppearController();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TestApp(
            child: QuiAppear(controller: controller, child: const Text('Hello')),
          ),
        ),
      );

      controller.appear();
      await tester.pump();

      final fade = _fadeWithinQuiAppear(tester);
      expect(fade.opacity.value, 1);
    });

    testWidgets('when disableAnimations is true and destroy is called, it should set opacity immediately to 0',
        (tester) async {
      final controller = QuiAppearController();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TestApp(
            child: QuiAppear(controller: controller, child: const Text('Hello')),
          ),
        ),
      );

      controller.appear();
      await tester.pump();
      controller.destroy();
      await tester.pump();

      final fade = _fadeWithinQuiAppear(tester);
      expect(fade.opacity.value, 0);
    });

    testWidgets('when the widget is disposed, the controller should not throw', (tester) async {
      final controller = QuiAppearController();

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(controller: controller, child: const Text('Hello')),
        ),
      );

      await tester.pumpWidget(const TestApp(child: SizedBox.shrink()));

      controller.appear();
      controller.destroy();
    });

    testWidgets('when fade animation is used, it should wrap child in FadeTransition', (tester) async {
      final controller = QuiAppearController();

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(
            controller: controller,
            animation: QuiAppearAnimationType.fade,
            child: const Text('Hello'),
          ),
        ),
      );

      await tester.pump();

      expect(
        find.descendant(of: _quiAppearFinder, matching: find.byType(FadeTransition)),
        findsOneWidget,
      );
    });

    testWidgets('when controller is swapped, the old controller should no longer trigger the widget', (tester) async {
      final oldController = QuiAppearController();
      final newController = QuiAppearController();

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(controller: oldController, child: const Text('Hello')),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(controller: newController, child: const Text('Hello')),
        ),
      );

      await tester.pump();

      oldController.appear();
      await tester.pump();

      final fade = _fadeWithinQuiAppear(tester);
      expect(fade.opacity.value, 0);
    });

    testWidgets('when unmount is true and destroy completes, it should remove the child from the tree', (tester) async {
      final controller = QuiAppearController();

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(controller: controller, unmount: true, child: const Text('Hello')),
        ),
      );

      controller.appear();
      await tester.pumpAndSettle();

      controller.destroy();
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsNothing);
    });

    testWidgets('when unmount is false and destroy completes, it should keep the child in the tree', (tester) async {
      final controller = QuiAppearController();

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(controller: controller, child: const Text('Hello')),
        ),
      );

      controller.appear();
      await tester.pumpAndSettle();

      controller.destroy();
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('when unmount is true and appear is called after destroy, it should re-mount the child and animate opacity to 1',
        (tester) async {
      final controller = QuiAppearController();

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(controller: controller, unmount: true, child: const Text('Hello')),
        ),
      );

      controller.appear();
      await tester.pumpAndSettle();

      controller.destroy();
      await tester.pumpAndSettle();

      controller.appear();
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      final fade = _fadeWithinQuiAppear(tester);
      expect(fade.opacity.value, 1);
    });

    testWidgets('when unmount is true and disableAnimations is true, destroy should remove the child immediately',
        (tester) async {
      final controller = QuiAppearController();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TestApp(
            child: QuiAppear(controller: controller, unmount: true, child: const Text('Hello')),
          ),
        ),
      );

      controller.appear();
      await tester.pump();

      controller.destroy();
      await tester.pump();

      expect(find.text('Hello'), findsNothing);
    });

    testWidgets('when unmount is true and the widget is disposed during destroy, it should not throw', (tester) async {
      final controller = QuiAppearController();

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(controller: controller, unmount: true, child: const Text('Hello')),
        ),
      );

      controller.appear();
      await tester.pumpAndSettle();

      controller.destroy();
      await tester.pumpWidget(const TestApp(child: SizedBox.shrink()));

      controller.appear();
      controller.destroy();
    });

    testWidgets('when onDestroy is provided and destroy is called, it should fire immediately', (tester) async {
      final controller = QuiAppearController();
      var onDestroyCalled = false;
      Future<void>? animationFuture;

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(
            controller: controller,
            onDestroy: (animation) {
              onDestroyCalled = true;
              animationFuture = animation;
            },
            child: const Text('Hello'),
          ),
        ),
      );

      controller.appear();
      await tester.pumpAndSettle();

      controller.destroy();

      expect(onDestroyCalled, isTrue);
      expect(animationFuture, isNotNull);
    });

    testWidgets('when onDestroy is provided and destroy is called, the animation future should complete when the animation finishes',
        (tester) async {
      final controller = QuiAppearController();
      Future<void>? animationFuture;

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(
            controller: controller,
            onDestroy: (animation) {
              animationFuture = animation;
            },
            child: const Text('Hello'),
          ),
        ),
      );

      controller.appear();
      await tester.pumpAndSettle();

      controller.destroy();
      await tester.pumpAndSettle();

      expect(animationFuture, isNotNull);
      expect(animationFuture, completes);
    });

    testWidgets('when onDestroy is provided and destroy is called while already at 0, it should fire immediately and the animation future should complete immediately',
        (tester) async {
      final controller = QuiAppearController();
      var onDestroyCalled = false;
      Future<void>? animationFuture;

      await tester.pumpWidget(
        TestApp(
          child: QuiAppear(
            controller: controller,
            onDestroy: (animation) {
              onDestroyCalled = true;
              animationFuture = animation;
            },
            child: const Text('Hello'),
          ),
        ),
      );

      await tester.pump();

      controller.destroy();

      expect(onDestroyCalled, isTrue);
      expect(animationFuture, isNotNull);
      expect(animationFuture, completes);
    });

    testWidgets('when onDestroy is provided and destroy is called with disableAnimations, it should fire immediately and the animation future should complete immediately',
        (tester) async {
      final controller = QuiAppearController();
      var onDestroyCalled = false;
      Future<void>? animationFuture;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TestApp(
            child: QuiAppear(
              controller: controller,
              onDestroy: (animation) {
                onDestroyCalled = true;
                animationFuture = animation;
              },
              child: const Text('Hello'),
            ),
          ),
        ),
      );

      controller.appear();
      await tester.pump();

      controller.destroy();

      expect(onDestroyCalled, isTrue);
      expect(animationFuture, isNotNull);
      expect(animationFuture, completes);
    });
  });
}
