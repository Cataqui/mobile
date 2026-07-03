import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHeroDragToCloseExtension', () {
    testWidgets('when dragging down from the top, it should move the route toward the source hero', (tester) async {
      await tester.pumpWidget(const _QuiHeroDragToCloseTestApp());
      await tester.tap(find.byKey(_QuiHeroDragToCloseTestApp.openButtonKey));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
      await gesture.moveBy(const Offset(0, 160));
      await tester.pump();

      final route = QuiHeroPageRoute.maybeOf(tester.element(find.byKey(_QuiHeroDragToCloseTestApp.destinationKey)));
      expect(route!.transitionValue, lessThan(1));
      await gesture.up();
    });

    testWidgets('when the scroll view is not at the top and the user drags downward, it should keep the route open', (
      tester,
    ) async {
      await tester.pumpWidget(const _QuiHeroDragToCloseTestApp());
      await tester.tap(find.byKey(_QuiHeroDragToCloseTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 160));
      await tester.pump();

      final route = QuiHeroPageRoute.maybeOf(tester.element(find.byKey(_QuiHeroDragToCloseTestApp.destinationKey)));
      expect(route!.transitionValue, equals(1));
    });

    testWidgets('when dragging down past the commit threshold, it should pop back to the source hero', (tester) async {
      await tester.pumpWidget(const _QuiHeroDragToCloseTestApp());
      await tester.tap(find.byKey(_QuiHeroDragToCloseTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.byKey(_QuiHeroDragToCloseTestApp.destinationKey), findsNothing);
    });

    testWidgets('when dragging down below the commit threshold, it should keep the destination open', (tester) async {
      await tester.pumpWidget(const _QuiHeroDragToCloseTestApp());
      await tester.tap(find.byKey(_QuiHeroDragToCloseTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pump(QuiHeroPage.defaultReverseTransitionDuration);
      await tester.pump();

      expect(find.byKey(_QuiHeroDragToCloseTestApp.destinationKey), findsOneWidget);
    });

    testWidgets('when sensibility is high, it should move the route farther for the same drag distance', (
      tester,
    ) async {
      final slowTransitionValue = await _QuiHeroDragToCloseTestApp.dragToTransitionValue(
        tester: tester,
        sensibility: 0,
        dragDistance: 80,
      );
      final fastTransitionValue = await _QuiHeroDragToCloseTestApp.dragToTransitionValue(
        tester: tester,
        sensibility: 1,
        dragDistance: 80,
      );

      expect(fastTransitionValue, lessThan(slowTransitionValue));
    });

    testWidgets('when sensibility is high and the user drags a small distance, it should pop back to the source hero', (
      tester,
    ) async {
      await tester.pumpWidget(const _QuiHeroDragToCloseTestApp(sensibility: 1));
      await tester.tap(find.byKey(_QuiHeroDragToCloseTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();

      expect(find.byKey(_QuiHeroDragToCloseTestApp.destinationKey), findsNothing);
    });

    testWidgets('when sensibility is low and the user drags a small distance, it should keep the destination open', (
      tester,
    ) async {
      await tester.pumpWidget(const _QuiHeroDragToCloseTestApp(sensibility: 0));
      await tester.tap(find.byKey(_QuiHeroDragToCloseTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pump(QuiHeroPage.defaultReverseTransitionDuration);
      await tester.pump();

      expect(find.byKey(_QuiHeroDragToCloseTestApp.destinationKey), findsOneWidget);
    });

    testWidgets('when flinging down quickly below the commit threshold, it should pop back to the source hero', (
      tester,
    ) async {
      await tester.pumpWidget(const _QuiHeroDragToCloseTestApp());
      await tester.tap(find.byKey(_QuiHeroDragToCloseTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.fling(find.byType(CustomScrollView), const Offset(0, 30), 900);
      await tester.pumpAndSettle();

      expect(find.byKey(_QuiHeroDragToCloseTestApp.destinationKey), findsNothing);
    });

    testWidgets('when flinging down slowly below the commit threshold, it should keep the destination open', (
      tester,
    ) async {
      await tester.pumpWidget(const _QuiHeroDragToCloseTestApp());
      await tester.tap(find.byKey(_QuiHeroDragToCloseTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.fling(find.byType(CustomScrollView), const Offset(0, 80), 400);
      await tester.pump(QuiHeroPage.defaultReverseTransitionDuration);
      await tester.pump();

      expect(find.byKey(_QuiHeroDragToCloseTestApp.destinationKey), findsOneWidget);
    });

    testWidgets('when flinging upward quickly from the top, it should keep the destination open', (tester) async {
      await tester.pumpWidget(const _QuiHeroDragToCloseTestApp());
      await tester.tap(find.byKey(_QuiHeroDragToCloseTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.fling(find.byType(CustomScrollView), const Offset(0, -80), 900);
      await tester.pump();

      expect(find.byKey(_QuiHeroDragToCloseTestApp.destinationKey), findsOneWidget);
    });

    testWidgets('when sensibility is below zero, it should reject the drag configuration', (tester) async {
      expect(() => QuiHeroDragToCloseExtension(sensibility: -0.01), throwsAssertionError);
    });

    testWidgets('when sensibility is above one, it should reject the drag configuration', (tester) async {
      expect(() => QuiHeroDragToCloseExtension(sensibility: 1.01), throwsAssertionError);
    });

    testWidgets('when dragging down from the top, it should notify that dragging started', (tester) async {
      final dragStateChanges = <QuiHeroDragToCloseState>[];

      await tester.pumpWidget(_QuiHeroDragToCloseTestApp(onDragStateChanged: dragStateChanges.add));
      await tester.tap(find.byKey(_QuiHeroDragToCloseTestApp.openButtonKey));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();

      expect(dragStateChanges.last, equals(QuiHeroDragToCloseState.dragging));
      await gesture.up();
    });

    testWidgets('when cancelling a drag below the commit threshold, it should notify that dragging ended', (
      tester,
    ) async {
      final dragStateChanges = <QuiHeroDragToCloseState>[];

      await tester.pumpWidget(_QuiHeroDragToCloseTestApp(onDragStateChanged: dragStateChanges.add));
      await tester.tap(find.byKey(_QuiHeroDragToCloseTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();

      expect(dragStateChanges.last, equals(QuiHeroDragToCloseState.idle));
    });

    testWidgets('when dragged outside a QuiHeroPageRoute, it should explain the route requirement', (tester) async {
      const dragTargetKey = Key('drag-target');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuiHero.background(
              tag: 'test-surface',
              extensions: const [QuiHeroDragToCloseExtension()],
              child: const SizedBox(key: dragTargetKey, width: 200, height: 200),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(dragTargetKey)));
      await gesture.moveBy(const Offset(0, 160));

      expect(tester.takeException(), isA<FlutterError>());
    });
  });
}

class _QuiHeroDragToCloseTestApp extends StatefulWidget {
  const _QuiHeroDragToCloseTestApp({this.sensibility = 0.5, this.onDragStateChanged});

  static const openButtonKey = Key('open-hero-page');
  static const destinationKey = Key('hero-destination');

  final double sensibility;
  final ValueChanged<QuiHeroDragToCloseState>? onDragStateChanged;

  static Future<double> dragToTransitionValue({
    required WidgetTester tester,
    required double sensibility,
    required double dragDistance,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(_QuiHeroDragToCloseTestApp(sensibility: sensibility));
    await tester.tap(find.byKey(openButtonKey));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    await gesture.moveBy(Offset(0, dragDistance));
    await tester.pump();

    final route = QuiHeroPageRoute.maybeOf(tester.element(find.byKey(destinationKey)));
    final transitionValue = route!.transitionValue;
    await gesture.up();
    await tester.pumpAndSettle();
    return transitionValue;
  }

  @override
  State<_QuiHeroDragToCloseTestApp> createState() => _QuiHeroDragToCloseTestAppState();
}

class _QuiHeroDragToCloseTestAppState extends State<_QuiHeroDragToCloseTestApp> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: QuiHero.background(
                tag: 'test-surface',
                width: 220,
                height: 120,
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(24)),
                child: TextButton(
                  key: _QuiHeroDragToCloseTestApp.openButtonKey,
                  onPressed: () {
                    unawaited(
                      Navigator.of(context).push<void>(
                        QuiHeroPage(
                          builder: (_) => _QuiHeroDragToCloseTestDestination(
                            scrollController: _scrollController,
                            sensibility: widget.sensibility,
                            onDragStateChanged: widget.onDragStateChanged,
                          ),
                        ).createRoute(context),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuiHeroDragToCloseTestDestination extends StatelessWidget {
  const _QuiHeroDragToCloseTestDestination({
    required this.scrollController,
    required this.sensibility,
    this.onDragStateChanged,
  });

  final ScrollController scrollController;
  final double sensibility;
  final ValueChanged<QuiHeroDragToCloseState>? onDragStateChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QuiHero.background(
        tag: 'test-surface',
        decoration: const BoxDecoration(color: Colors.white),
        extensions: [
          QuiHeroDragToCloseExtension(
            scrollController: scrollController,
            sensibility: sensibility,
            onDragStateChanged: onDragStateChanged,
          ),
        ],
        child: CustomScrollView(
          key: _QuiHeroDragToCloseTestApp.destinationKey,
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 1600,
                child: ColoredBox(
                  color: Colors.white,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Destination', style: Theme.of(context).textTheme.headlineMedium),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
