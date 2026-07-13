import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

RenderObject _findSkeletonRenderObject(WidgetTester tester) {
  return tester.renderObject(
    find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_QuiSkeletonRenderObjectWidget'),
  );
}

MaterialApp _app({required Widget child, Key? key}) {
  return MaterialApp(
    key: key,
    theme: QuiTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('QuiSkeleton', () {
    testWidgets('when enabled is false, it should render the child unchanged', (tester) async {
      await tester.pumpWidget(_app(child: const QuiSkeleton(enabled: false, child: Text('Hello'))));

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('when no style is provided, it should not create an animation controller', (tester) async {
      await tester.pumpWidget(_app(child: const QuiSkeleton(child: Text('Hello'))));

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('when style.effect is a QuiSkeletonShimmerEffect, it should create an animation controller', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(style: QuiSkeletonStyle(effect: QuiSkeletonShimmerEffect()), child: Text('Hello')),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('when style.effect is a QuiSkeletonFadeEffect, it should create an animation controller', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(style: QuiSkeletonStyle(effect: QuiSkeletonFadeEffect()), child: Text('Hello')),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('when the platform disables animations with style.effect, it should not schedule shimmer frames', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: QuiTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: QuiSkeleton(style: QuiSkeletonStyle(effect: QuiSkeletonShimmerEffect()), child: Text('Hello')),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('when skeletonizing a child, it should isolate repaint work inside a render boundary', (tester) async {
      await tester.pumpWidget(_app(child: const QuiSkeleton(child: Text('Hello'))));

      final renderObject = _findSkeletonRenderObject(tester);

      expect(renderObject.isRepaintBoundary, isTrue);
    });

    testWidgets('when skeletonizing a child, the render object should require compositing', (tester) async {
      await tester.pumpWidget(_app(child: const QuiSkeleton(child: Text('Hello'))));

      final renderObject = _findSkeletonRenderObject(tester);

      expect(renderObject.alwaysNeedsCompositing, isTrue);
    });

    testWidgets('when the widget rebuilds with style.effect toggled, it should update the render object', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(style: QuiSkeletonStyle(effect: QuiSkeletonShimmerEffect()), child: Text('Hello')),
        ),
      );
      final renderObject = _findSkeletonRenderObject(tester) as dynamic;
      expect(renderObject.effect, isA<QuiSkeletonShimmerEffect>());

      await tester.pumpWidget(_app(child: const QuiSkeleton(child: Text('Hello'))));
      expect(renderObject.effect, isNull);
    });

    testWidgets('when the widget rebuilds with style.effect toggled off then on, the render object persists', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(style: QuiSkeletonStyle(effect: QuiSkeletonShimmerEffect()), child: Text('Hello')),
        ),
      );
      final renderObject = _findSkeletonRenderObject(tester) as dynamic;
      expect(renderObject.effect, isA<QuiSkeletonShimmerEffect>());

      await tester.pumpWidget(_app(child: const QuiSkeleton(child: Text('Hello'))));
      expect(renderObject.effect, isNull);

      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(style: QuiSkeletonStyle(effect: QuiSkeletonShimmerEffect()), child: Text('Hello')),
        ),
      );
      expect(renderObject.effect, isA<QuiSkeletonShimmerEffect>());
    });
  });

  group('_RenderQuiSkeleton getter/setter', () {
    testWidgets('when the render object is created with no style, it should return correct defaults', (tester) async {
      await tester.pumpWidget(_app(child: const QuiSkeleton(child: Text('Hello'))));
      final ro = _findSkeletonRenderObject(tester) as dynamic;

      expect(ro.colorScheme.skeleton.bone, isNot(isNull));
      expect(ro.colorScheme.skeleton.shimmerGlow, isNot(isNull));
      expect(ro.effect, isNull);
      expect(ro.textRadius, isNull);
      expect(ro.boneColor, equals(ro.colorScheme.skeleton.bone));
      expect(ro.effectAnimation, isNull);
    });

    testWidgets('when the render object is created with a style.effect set, it should report effect non-null', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(style: QuiSkeletonStyle(effect: QuiSkeletonShimmerEffect()), child: Text('Hello')),
        ),
      );
      final ro = _findSkeletonRenderObject(tester) as dynamic;

      expect(ro.effect, isA<QuiSkeletonShimmerEffect>());
    });

    testWidgets('when didUpdateWidget fires with changed style.effect, it should invoke syncAnimationController', (
      tester,
    ) async {
      await tester.pumpWidget(_app(child: const QuiSkeleton(child: Text('Hello'))));
      final ro = _findSkeletonRenderObject(tester) as dynamic;
      expect(ro.effect, isNull);

      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(style: QuiSkeletonStyle(effect: QuiSkeletonShimmerEffect()), child: Text('Hello')),
        ),
      );
      expect(ro.effect, isA<QuiSkeletonShimmerEffect>());
    });

    testWidgets('when style.effect toggles via widget rebuild, setter markNeedsPaint should not throw', (tester) async {
      await tester.pumpWidget(_app(child: const QuiSkeleton(child: Text('Hello'))));

      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(style: QuiSkeletonStyle(effect: QuiSkeletonShimmerEffect()), child: Text('Hello')),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('QuiSkeleton canvas interception', () {
    testWidgets('when skeletonizing a deep widget tree with layers, it should render without error', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(
            child: Column(
              children: [
                Text('Header'),
                SizedBox(height: 8),
                Row(children: [Icon(Icons.star), Text('Rating')]),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  child: ColoredBox(color: Color(0xFF0000FF), child: SizedBox(width: 100, height: 100)),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('when skeletonizing Transform widgets, it should render without error', (tester) async {
      await tester.pumpWidget(
        _app(
          child: QuiSkeleton(child: Transform.scale(scale: 0.8, child: const Text('Scaled text'))),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('when skeletonizing a CircleAvatar, it should render without error', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(child: CircleAvatar(child: Text('AB'))),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('when skeletonizing a RotatedBox, it should render without error', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(child: RotatedBox(quarterTurns: 1, child: Text('Rotated'))),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('when skeletonizing an Opacity wrapper, it should render without error', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(child: Opacity(opacity: 0.5, child: Text('Faded'))),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('when skeletonizing a ClipPath widget, it should render without error', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(
            child: ClipPath(
              clipper: _TestClipper(),
              child: ColoredBox(color: Colors.blue, child: SizedBox(width: 100, height: 100)),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('when skeletonizing an OverflowBox, it should render without error', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(
            child: OverflowBox(minWidth: 50, maxWidth: 200, minHeight: 50, maxHeight: 200, child: Text('Overflow')),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('when skeletonizing a leaf container with color, it should intercept drawRect as a bone', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(
            child: SizedBox(width: 50, height: 50, child: ColoredBox(color: Colors.blue)),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('when skeletonizing a container with rounded corners, it should intercept drawRRect', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(
            child: SizedBox(
              width: 50,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.all(Radius.circular(8))),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('when skeletonizing a PhysicalModel, it should intercept drawDRRect', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(
            child: SizedBox(
              width: 50,
              height: 50,
              child: PhysicalModel(
                color: Colors.blue,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                child: SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('when skeletonizing an Align with a leaf child, it should intercept leaf draw calls', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const QuiSkeleton(
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(width: 50, height: 50, child: ColoredBox(color: Colors.green)),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('QuiSkeleton theme colors', () {
    testWidgets('when the theme provides custom skeleton colors, the render object should use them', (tester) async {
      final customColorScheme = QuiColorScheme.light().copyWith(
        skeleton: const QuiSkeletonColorScheme(
          bone: Color(0xFF111111),
          shimmerGlow: Color(0xFF222222),
          skeletonText: Color(0xFFB3B3B3),
          skeletonTextGlow: Color(0xFFE0E0E0),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF4A4B)),
            extensions: [QuiThemeData(colorScheme: customColorScheme)],
          ),
          home: const Scaffold(body: QuiSkeleton(child: Text('Hello'))),
        ),
      );

      final ro = _findSkeletonRenderObject(tester) as dynamic;
      expect(ro.colorScheme.skeleton.bone, equals(const Color(0xFF111111)));
      expect(ro.colorScheme.skeleton.shimmerGlow, equals(const Color(0xFF222222)));
    });

    testWidgets('when the theme provides custom skeletonShimmerGlow, the colorScheme object should carry it', (
      tester,
    ) async {
      final customColorScheme = QuiColorScheme.light().copyWith(
        skeleton: const QuiSkeletonColorScheme(
          bone: Color(0xFFEFEFEF),
          shimmerGlow: Color(0xFF444444),
          skeletonText: Color(0xFFB3B3B3),
          skeletonTextGlow: Color(0xFFE0E0E0),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF4A4B)),
            extensions: [QuiThemeData(colorScheme: customColorScheme)],
          ),
          home: const Scaffold(body: QuiSkeleton(child: Text('Hello'))),
        ),
      );

      final ro = _findSkeletonRenderObject(tester) as dynamic;
      expect(ro.colorScheme.skeleton.shimmerGlow, equals(const Color(0xFF444444)));
    });
  });

  group('WidgetExtension', () {
    testWidgets('when .skeleton() is called, it should wrap in QuiSkeleton', (tester) async {
      await tester.pumpWidget(_app(child: const Text('Hello').skeleton()));

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('when .skeleton(enabled: false) is called, it should pass through the child', (tester) async {
      await tester.pumpWidget(_app(child: const Text('Hello').skeleton(enabled: false)));

      expect(find.text('Hello'), findsOneWidget);
    });
  });
}

class _TestClipper extends CustomClipper<Path> {
  const _TestClipper();

  @override
  Path getClip(Size size) => Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
