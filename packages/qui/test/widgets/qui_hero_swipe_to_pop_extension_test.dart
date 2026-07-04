import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHeroSwipeToPopExtension', () {
    testWidgets('when dragging down from the top, it should move the route toward the source hero', (tester) async {
      await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp());
      await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
      await gesture.moveBy(const Offset(0, 160));
      await tester.pump();

      final route = QuiHeroPageRoute.maybeOf(tester.element(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey)));
      expect(route!.transitionValue, lessThan(1));
      await gesture.up();
    });

    testWidgets('when the scroll view is not at the top and the user drags downward, it should keep the route open', (
      tester,
    ) async {
      await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp());
      await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 160));
      await tester.pump();

      final route = QuiHeroPageRoute.maybeOf(tester.element(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey)));
      expect(route!.transitionValue, equals(1));
    });

    testWidgets('when dragging down past the commit threshold, it should pop back to the source hero', (tester) async {
      await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp());
      await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey), findsNothing);
    });

    testWidgets('when dragging down below the commit threshold, it should keep the destination open', (tester) async {
      await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp());
      await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pump(QuiHeroPage.defaultReverseTransitionDuration);
      await tester.pump();

      expect(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey), findsOneWidget);
    });

    testWidgets('when sensibility is high, it should move the route farther for the same drag distance', (
      tester,
    ) async {
      final slowTransitionValue = await _QuiHeroSwipeToPopTestApp.dragToTransitionValue(
        tester: tester,
        sensibility: 0,
        dragDistance: 80,
      );
      final fastTransitionValue = await _QuiHeroSwipeToPopTestApp.dragToTransitionValue(
        tester: tester,
        sensibility: 1,
        dragDistance: 80,
      );

      expect(fastTransitionValue, lessThan(slowTransitionValue));
    });

    testWidgets('when sensibility is high and the user drags a small distance, it should pop back to the source hero', (
      tester,
    ) async {
      await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp(sensibility: 1));
      await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();

      expect(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey), findsNothing);
    });

    testWidgets('when sensibility is low and the user drags a small distance, it should keep the destination open', (
      tester,
    ) async {
      await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp(sensibility: 0));
      await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pump(QuiHeroPage.defaultReverseTransitionDuration);
      await tester.pump();

      expect(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey), findsOneWidget);
    });

    testWidgets('when flinging down quickly below the commit threshold, it should pop back to the source hero', (
      tester,
    ) async {
      await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp());
      await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.fling(find.byType(CustomScrollView), const Offset(0, 30), 900);
      await tester.pumpAndSettle();

      expect(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey), findsNothing);
    });

    testWidgets('when flinging down slowly below the commit threshold, it should keep the destination open', (
      tester,
    ) async {
      await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp());
      await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.fling(find.byType(CustomScrollView), const Offset(0, 80), 400);
      await tester.pump(QuiHeroPage.defaultReverseTransitionDuration);
      await tester.pump();

      expect(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey), findsOneWidget);
    });

    testWidgets('when flinging upward quickly from the top, it should keep the destination open', (tester) async {
      await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp());
      await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.fling(find.byType(CustomScrollView), const Offset(0, -80), 900);
      await tester.pump();

      expect(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey), findsOneWidget);
    });

    testWidgets('when sensibility is below zero, it should reject the drag configuration', (tester) async {
      expect(() => QuiHeroSwipeToPopExtension(sensibility: -0.01), throwsAssertionError);
    });

    testWidgets('when sensibility is above one, it should reject the drag configuration', (tester) async {
      expect(() => QuiHeroSwipeToPopExtension(sensibility: 1.01), throwsAssertionError);
    });

    testWidgets('when dragging down from the top, it should notify that dragging started', (tester) async {
      final dragStateChanges = <QuiHeroSwipeToPopState>[];

      await tester.pumpWidget(_QuiHeroSwipeToPopTestApp(onSwipeStateChanged: dragStateChanges.add));
      await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();

      expect(dragStateChanges.last, equals(QuiHeroSwipeToPopState.dragging));
      await gesture.up();
    });

    testWidgets('when cancelling a drag below the commit threshold, it should notify that dragging ended', (
      tester,
    ) async {
      final dragStateChanges = <QuiHeroSwipeToPopState>[];

      await tester.pumpWidget(_QuiHeroSwipeToPopTestApp(onSwipeStateChanged: dragStateChanges.add));
      await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();

      expect(dragStateChanges.last, equals(QuiHeroSwipeToPopState.idle));
    });

    testWidgets(
      'when fast-scrolling upward from the bottom triggers an overscroll bounce and a tiny downward pointer move is performed mid-bounce, it should not trigger the swipe-to-pop',
      (tester) async {
        await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp(scrollPhysics: BouncingScrollPhysics()));
        await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
        await tester.pumpAndSettle();

        // Scroll to the bottom first.
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
        await tester.pumpAndSettle();

        // Use a fast timedDrag upward to create a strong ballistic simulation
        // with proper velocity.
        await tester.timedDrag(find.byType(CustomScrollView), const Offset(0, 1000), const Duration(milliseconds: 80));
        // Pump so the ballistic simulation reaches peak overshoot past the top.
        await tester.pump(const Duration(milliseconds: 50));

        // Perform a small downward move while the ballistic is near its peak.
        // The depth gate detects overshoot > 30px and blocks the pop.
        final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
        for (var i = 0; i < 3; i++) {
          await gesture.moveBy(const Offset(0, 5));
          await tester.pump();
        }

        final route = QuiHeroPageRoute.maybeOf(tester.element(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey)));
        expect(route!.transitionValue, equals(1));

        await gesture.up();
      },
    );

    testWidgets(
      'when dragging slowly downward through content with the finger and continuing past the top without lifting, it should trigger the swipe-to-pop',
      (tester) async {
        await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp(scrollPhysics: BouncingScrollPhysics()));
        await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
        await tester.pumpAndSettle();

        // One continuous gesture: scroll down then back up past the top.
        // Use small incremental moves so scrollDelta stays below the fast
        // threshold — a slow deliberate drag to top should still allow pop.
        final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
        // Scroll down through content (finger moves up).
        for (var i = 0; i < 80; i++) {
          await gesture.moveBy(const Offset(0, -5));
          await tester.pump();
        }
        // Scroll back up past the top (finger moves down).
        for (var i = 0; i < 160; i++) {
          await gesture.moveBy(const Offset(0, 5));
          await tester.pump();
        }

        final route = QuiHeroPageRoute.maybeOf(tester.element(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey)));
        expect(route!.transitionValue, lessThan(1));

        await gesture.up();
      },
    );

    testWidgets(
      'when dragging fast through content to the top with the finger and continuing past the top without lifting, it should keep the destination open',
      (tester) async {
        await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp(scrollPhysics: BouncingScrollPhysics()));
        await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
        await tester.pumpAndSettle();

        // One continuous gesture with fast moves — the high scrollDelta
        // triggers the cooldown, which extends while the finger stays on
        // screen near the top, blocking the pop.
        final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
        // Scroll down through content (finger moves up).
        for (var i = 0; i < 8; i++) {
          await gesture.moveBy(const Offset(0, -50));
          await tester.pump();
        }
        // Scroll back up past the top (finger moves down).
        for (var i = 0; i < 16; i++) {
          await gesture.moveBy(const Offset(0, 50));
          await tester.pump();
        }

        final route = QuiHeroPageRoute.maybeOf(tester.element(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey)));
        expect(route!.transitionValue, equals(1));

        await gesture.up();
      },
    );

    testWidgets(
      'when fast-scrolling upward triggers an overscroll bounce at the top and a sustained tiny downward drag is performed mid-bounce, it should not trigger the swipe-to-pop until the bounce settles',
      (tester) async {
        await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp(scrollPhysics: BouncingScrollPhysics()));
        await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
        await tester.pumpAndSettle();

        // Scroll to the bottom first.
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
        await tester.pumpAndSettle();

        // Use a fast timedDrag upward to create a strong ballistic simulation.
        await tester.timedDrag(find.byType(CustomScrollView), const Offset(0, 1000), const Duration(milliseconds: 80));
        await tester.pump(const Duration(milliseconds: 50));

        // Sustained tiny downward moves near peak overshoot — the depth gate
        // must block each since overshoot > 30px.
        final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
        for (var i = 0; i < 5; i++) {
          await gesture.moveBy(const Offset(0, 5));
          await tester.pump();
        }

        final routeAfterSustainedDrag = QuiHeroPageRoute.maybeOf(
          tester.element(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey)),
        );
        expect(routeAfterSustainedDrag!.transitionValue, equals(1));

        await gesture.up();
      },
    );

    testWidgets(
      'when fast-flinging upward with ClampingScrollPhysics reaches the top and the user drags down immediately, it should keep the destination open',
      (tester) async {
        await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp(
          scrollPhysics: ClampingScrollPhysics(),
        ));
        await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
        await tester.pumpAndSettle();

        // Scroll to bottom first so there's room to fling up.
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
        await tester.pumpAndSettle();

        // Fast fling upward.
        await tester.timedDrag(
          find.byType(CustomScrollView),
          const Offset(0, 1000),
          const Duration(milliseconds: 80),
        );
        // Let the ballistic run enough for position to reach the top.
        await tester.pump(const Duration(milliseconds: 50));

        // Try to swipe down immediately — should be blocked by the fling cooldown.
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        final route = QuiHeroPageRoute.maybeOf(
          tester.element(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey)),
        );
        expect(route!.transitionValue, equals(1));

        await gesture.up();
      },
    );

    testWidgets(
      'when waiting for the fling cooldown to expire after a fast fling and then swiping down, it should trigger the swipe-to-pop',
      (tester) async {
        await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp(
          scrollPhysics: ClampingScrollPhysics(),
        ));
        await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
        await tester.pumpAndSettle();

        // Scroll to bottom first.
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
        await tester.pumpAndSettle();

        // Fast fling upward.
        await tester.timedDrag(
          find.byType(CustomScrollView),
          const Offset(0, 1000),
          const Duration(milliseconds: 80),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // Wait for the cooldown to fully expire (250ms) plus margin.
        await tester.pump(const Duration(milliseconds: 300));

        // Now swipe down — cooldown has expired, pop should activate.
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 160));
        await tester.pump();

        final route = QuiHeroPageRoute.maybeOf(
          tester.element(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey)),
        );
        expect(route!.transitionValue, lessThan(1));

        await gesture.up();
      },
    );

    testWidgets(
      'when fast-swiping upward multiple times with BouncingScrollPhysics to reach the top and then swiping down immediately, it should keep the destination open',
      (tester) async {
        await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp(scrollPhysics: BouncingScrollPhysics()));
        await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
        await tester.pumpAndSettle();

        // Start deep in the content.
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
        await tester.pumpAndSettle();

        // Three rapid upward flings to reach the top — the user is trying to
        // get back to the top quickly, not to pop.
        for (var i = 0; i < 3; i++) {
          await tester.timedDrag(
            find.byType(CustomScrollView),
            const Offset(0, 500),
            const Duration(milliseconds: 50),
          );
          await tester.pump(const Duration(milliseconds: 30));
        }

        // Immediately try to pop — cooldown must block the gesture.
        final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
        await gesture.moveBy(const Offset(0, 160));
        await tester.pump();

        final route = QuiHeroPageRoute.maybeOf(
          tester.element(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey)),
        );
        expect(route!.transitionValue, equals(1));

        await gesture.up();
      },
    );

    testWidgets(
      'when fast-swiping upward multiple times with ClampingScrollPhysics to reach the top and then swiping down immediately, it should keep the destination open',
      (tester) async {
        await tester.pumpWidget(const _QuiHeroSwipeToPopTestApp(scrollPhysics: ClampingScrollPhysics()));
        await tester.tap(find.byKey(_QuiHeroSwipeToPopTestApp.openButtonKey));
        await tester.pumpAndSettle();

        // Start deep in the content.
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
        await tester.pumpAndSettle();

        // Three rapid upward flings to reach the top.
        for (var i = 0; i < 3; i++) {
          await tester.timedDrag(
            find.byType(CustomScrollView),
            const Offset(0, 500),
            const Duration(milliseconds: 50),
          );
          await tester.pump(const Duration(milliseconds: 30));
        }

        // Immediately try to pop — cooldown must block the gesture.
        final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
        await gesture.moveBy(const Offset(0, 160));
        await tester.pump();

        final route = QuiHeroPageRoute.maybeOf(
          tester.element(find.byKey(_QuiHeroSwipeToPopTestApp.destinationKey)),
        );
        expect(route!.transitionValue, equals(1));

        await gesture.up();
      },
    );

    testWidgets('when dragged outside a QuiHeroPageRoute, it should explain the route requirement', (tester) async {
      const dragTargetKey = Key('drag-target');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuiHero.background(
              tag: 'test-surface',
              extensions: const [QuiHeroSwipeToPopExtension()],
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

class _QuiHeroSwipeToPopTestApp extends StatefulWidget {
  const _QuiHeroSwipeToPopTestApp({
    this.sensibility = 0.5,
    this.onSwipeStateChanged,
    this.scrollPhysics = const AlwaysScrollableScrollPhysics(),
  });

  static const openButtonKey = Key('open-hero-page');
  static const destinationKey = Key('hero-destination');

  final double sensibility;
  final ValueChanged<QuiHeroSwipeToPopState>? onSwipeStateChanged;
  final ScrollPhysics scrollPhysics;

  static Future<double> dragToTransitionValue({
    required WidgetTester tester,
    required double sensibility,
    required double dragDistance,
    ScrollPhysics scrollPhysics = const AlwaysScrollableScrollPhysics(),
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(_QuiHeroSwipeToPopTestApp(sensibility: sensibility, scrollPhysics: scrollPhysics));
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
  State<_QuiHeroSwipeToPopTestApp> createState() => _QuiHeroSwipeToPopTestAppState();
}

class _QuiHeroSwipeToPopTestAppState extends State<_QuiHeroSwipeToPopTestApp> {
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
                  key: _QuiHeroSwipeToPopTestApp.openButtonKey,
                  onPressed: () {
                    unawaited(
                      Navigator.of(context).push<void>(
                        QuiHeroPage(
                          builder: (_) => _QuiHeroSwipeToPopTestDestination(
                            scrollController: _scrollController,
                            sensibility: widget.sensibility,
                            onSwipeStateChanged: widget.onSwipeStateChanged,
                            scrollPhysics: widget.scrollPhysics,
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

class _QuiHeroSwipeToPopTestDestination extends StatelessWidget {
  const _QuiHeroSwipeToPopTestDestination({
    required this.scrollController,
    required this.sensibility,
    this.onSwipeStateChanged,
    this.scrollPhysics = const AlwaysScrollableScrollPhysics(),
  });

  final ScrollController scrollController;
  final double sensibility;
  final ValueChanged<QuiHeroSwipeToPopState>? onSwipeStateChanged;
  final ScrollPhysics scrollPhysics;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QuiHero.background(
        tag: 'test-surface',
        decoration: const BoxDecoration(color: Colors.white),
        extensions: [
          QuiHeroSwipeToPopExtension(
            scrollController: scrollController,
            sensibility: sensibility,
            onSwipeStateChanged: onSwipeStateChanged,
          ),
        ],
        child: CustomScrollView(
          key: _QuiHeroSwipeToPopTestApp.destinationKey,
          controller: scrollController,
          physics: scrollPhysics,
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
