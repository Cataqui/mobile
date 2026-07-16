import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiSwipeToPopSurface', () {
    testWidgets(
      'when dragging down on a wrapped route, it should translate the surface downward',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopSurfaceTestApp());
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          greaterThan(0),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging diagonally down on a wrapped route, it should move the surface horizontally',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(sensibility: 0.5),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(42, 80));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationHorizontalOffset(tester),
          equals(42),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging sideways first and then downward without releasing, it should keep the preview closed',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopSurfaceTestApp());
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          equals(0),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging horizontally more than downward at the start, it should keep the preview closed',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopSurfaceTestApp());
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(40, 20));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          equals(0),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging right with right swipes disabled, it should keep the preview closed',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopSurfaceTestApp());
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationHorizontalOffset(tester),
          equals(0),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging right with right swipes enabled, it should move the surface horizontally',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(swipeRight: true),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationHorizontalOffset(tester),
          greaterThan(0),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging right past the threshold with right swipes enabled, it should pop the current route',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(swipeRight: true),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(140, 0));
        await tester.pumpAndSettle();

        expect(
          find.byKey(_SwipeToPopSurfaceTestApp.destinationKey),
          findsNothing,
        );
      },
    );

    testWidgets(
      'when dragging down with down swipes disabled, it should keep the preview closed',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(swipeDown: false),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          equals(0),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when moving slightly downward below the activation distance, it should keep the preview closed',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopSurfaceTestApp());
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 9));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          equals(0),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when moving downward past the activation distance, it should apply the full drag immediately',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopSurfaceTestApp());
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 12));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          greaterThan(6),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging down with zero sensibility, it should move the surface much less than the finger',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(sensibility: 0),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          lessThan(20),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging far downward on a wrapped route, it should strongly resist movement past the preview distance',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopSurfaceTestApp());
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 600));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          allOf(greaterThan(150), lessThan(190)),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging down from the top with scrollable content, it should keep the scroll position pinned at the top',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(
            scrollPhysics: BouncingScrollPhysics(),
          ),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        for (var i = 0; i < 16; i++) {
          await gesture.moveBy(const Offset(0, 5));
          await tester.pump();
        }

        expect(_SwipeToPopSurfaceTestApp.destinationScrollOffset(tester), 0);
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging down on a wrapped route, it should scale the surface below full size',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopSurfaceTestApp());
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        expect(_SwipeToPopSurfaceTestApp.destinationScale(tester), lessThan(1));
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging down with higher sensibility, it should scale the surface further',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(sensibility: 1),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationScale(tester),
          lessThan(0.94),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging down with a border radius, it should animate the preview corners toward the configured radius',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(
            borderRadius: BorderRadius.all(Radius.circular(40)),
          ),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 10));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationBorderRadius(tester).topLeft.x,
          allOf(greaterThan(0), lessThan(40)),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging down with a border radius, it should expose the preview scale and border radius together',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(
            borderRadius: BorderRadius.all(Radius.circular(40)),
          ),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump();

        expect(
          QuiSwipeToPopSurface.maybeHandoffStateOf(
            tester.element(find.byType(CustomScrollView)),
          ),
          isA<QuiSwipeToPopHandoffState>()
              .having((state) => state.scale, 'scale', lessThan(1))
              .having((state) => state.borderRadius, 'borderRadius', isNotNull),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging down to the commit threshold with a border radius, it should use the full configured radius',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(
            borderRadius: BorderRadius.all(Radius.circular(40)),
          ),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 90));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationBorderRadius(tester),
          equals(const BorderRadius.all(Radius.circular(40))),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging down on a wrapped QuiHeroPage, it should keep the route transition fully open',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(useQuiHeroPage: true),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        final route = QuiHeroPageRoute.maybeOf(
          tester.element(find.byKey(_SwipeToPopSurfaceTestApp.destinationKey)),
        );
        expect(route!.transitionValue, equals(1));
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging down past the threshold and releasing, it should pop the current route',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopSurfaceTestApp());
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 90));
        await tester.pumpAndSettle();

        expect(
          find.byKey(_SwipeToPopSurfaceTestApp.destinationKey),
          findsNothing,
        );
      },
    );

    testWidgets(
      'when releasing past the threshold but the route blocks the pop, it should restore the surface',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(popAllowed: false),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 90));
        await tester.pumpAndSettle();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          equals(0),
        );
      },
    );

    testWidgets(
      'when dragging down below the threshold and releasing, it should keep the current route open',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopSurfaceTestApp());
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 30));
        await tester.pumpAndSettle();

        expect(
          find.byKey(_SwipeToPopSurfaceTestApp.destinationKey),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'when flinging downward quickly below the threshold, it should pop the current route',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopSurfaceTestApp());
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, 30),
          900,
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(_SwipeToPopSurfaceTestApp.destinationKey),
          findsNothing,
        );
      },
    );

    testWidgets(
      'when flinging upward quickly from the top, it should keep the current route open',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopSurfaceTestApp());
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, -80),
          900,
        );
        await tester.pump();

        expect(
          find.byKey(_SwipeToPopSurfaceTestApp.destinationKey),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'when reduced motion is enabled and a short downward drag is released, it should keep the current route open',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(disableAnimations: true),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 30));
        await tester.pump();

        expect(
          find.byKey(_SwipeToPopSurfaceTestApp.destinationKey),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'when the scroll view is away from the top and the user drags downward, it should keep the preview closed',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopSurfaceTestApp());
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pump();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          equals(0),
        );
      },
    );

    testWidgets(
      'when dragging slowly through content to the top and continuing downward, it should move the preview',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(
            scrollPhysics: BouncingScrollPhysics(),
          ),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        for (var i = 0; i < 80; i++) {
          await gesture.moveBy(const Offset(0, -5));
          await tester.pump();
        }
        for (var i = 0; i < 160; i++) {
          await gesture.moveBy(const Offset(0, 5));
          await tester.pump();
        }

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          greaterThan(0),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging fast through content to the top and continuing downward, it should keep the preview closed',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(
            scrollPhysics: BouncingScrollPhysics(),
          ),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        for (var i = 0; i < 8; i++) {
          await gesture.moveBy(const Offset(0, -50));
          await tester.pump();
        }
        for (var i = 0; i < 16; i++) {
          await gesture.moveBy(const Offset(0, 50));
          await tester.pump();
        }

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          equals(0),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when waiting for the fling cooldown to expire and then dragging downward, it should move the preview',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(
            scrollPhysics: ClampingScrollPhysics(),
          ),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -1000),
        );
        await tester.pumpAndSettle();
        await tester.timedDrag(
          find.byType(CustomScrollView),
          const Offset(0, 1000),
          const Duration(milliseconds: 80),
        );
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 100));
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          greaterThan(0),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when fast flinging to the top and immediately dragging downward, it should keep the preview closed',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(
            scrollPhysics: ClampingScrollPhysics(),
          ),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -1000),
        );
        await tester.pumpAndSettle();
        await tester.timedDrag(
          find.byType(CustomScrollView),
          const Offset(0, 1000),
          const Duration(milliseconds: 80),
        );
        await tester.pump(const Duration(milliseconds: 50));
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          equals(0),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when scroll content fits the screen and the user drags downward, it should move the preview',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(contentHeight: 50),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          greaterThan(0),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when scroll content fits the screen and the user drags upward, it should keep the preview closed',
      (tester) async {
        await tester.pumpWidget(
          const _SwipeToPopSurfaceTestApp(contentHeight: 50),
        );
        await tester.tap(find.byKey(_SwipeToPopSurfaceTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesture.moveBy(const Offset(0, -80));
        await tester.pump();

        expect(
          _SwipeToPopSurfaceTestApp.destinationVerticalOffset(tester),
          equals(0),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when dragging a wrapped hero route, it should not start the hero pop flight',
      (tester) async {
        final events = <String>[];

        await tester.pumpWidget(_SwipeToPopHeroStartTestApp(events: events));
        await tester.tap(find.byKey(_SwipeToPopHeroStartTestApp.openButtonKey));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_SwipeToPopHeroStartTestApp.dragKey)),
        );
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();

        expect(events, isEmpty);
        await gesture.up();
      },
    );

    testWidgets(
      'when releasing a wrapped hero route to pop, it should not compound the preview scale',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopHeroHandoffTestApp());
        await tester.tap(
          find.byKey(_SwipeToPopHeroHandoffTestApp.openButtonKey),
        );
        await tester.pumpAndSettle();
        await tester.drag(
          find.byKey(_SwipeToPopHeroHandoffTestApp.dragKey),
          const Offset(0, 90),
        );
        await tester.pump();

        expect(
          _SwipeToPopHeroHandoffTestApp.smallestActiveScale(tester),
          allOf(greaterThan(0.86), lessThan(1)),
        );
      },
    );

    testWidgets(
      'when releasing a rounded wrapped background hero route to pop, it should start the background flight from the preview radius',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopBackgroundHeroRadiusTestApp());
        await tester.tap(
          find.byKey(_SwipeToPopBackgroundHeroRadiusTestApp.openButtonKey),
        );
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(
            find.byKey(_SwipeToPopBackgroundHeroRadiusTestApp.dragKey),
          ),
        );
        await gesture.moveBy(const Offset(0, 90));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        expect(
          _SwipeToPopBackgroundHeroRadiusTestApp.largestBackgroundRadius(
            tester,
          ),
          greaterThan(35),
        );
      },
    );

    testWidgets(
      'when dragging a rounded wrapped background hero before the opening flight settles, it should apply the preview radius to the background flight',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopBackgroundHeroRadiusTestApp());
        await tester.tap(
          find.byKey(_SwipeToPopBackgroundHeroRadiusTestApp.openButtonKey),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        final gesture = await tester.startGesture(
          tester.getCenter(
            find.byKey(_SwipeToPopBackgroundHeroRadiusTestApp.dragKey),
          ),
        );
        await gesture.moveBy(const Offset(0, 90));
        await tester.pump();

        expect(
          _SwipeToPopBackgroundHeroRadiusTestApp.largestBackgroundRadius(
            tester,
          ),
          greaterThan(8),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when releasing a rounded wrapped background hero route to pop, it should start the edge fade flight from the preview radius',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopBackgroundHeroRadiusTestApp());
        await tester.tap(
          find.byKey(_SwipeToPopBackgroundHeroRadiusTestApp.openButtonKey),
        );
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(
          tester.getCenter(
            find.byKey(_SwipeToPopBackgroundHeroRadiusTestApp.dragKey),
          ),
        );
        await gesture.moveBy(const Offset(0, 90));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        expect(
          _SwipeToPopBackgroundHeroRadiusTestApp.largestEdgeFadeClipRadius(
            tester,
          ),
          greaterThan(35),
        );
      },
    );

    testWidgets(
      'when dragging a rounded wrapped background hero before the opening flight settles, it should apply the preview radius to the edge fade flight',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopBackgroundHeroRadiusTestApp());
        await tester.tap(
          find.byKey(_SwipeToPopBackgroundHeroRadiusTestApp.openButtonKey),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        final gesture = await tester.startGesture(
          tester.getCenter(
            find.byKey(_SwipeToPopBackgroundHeroRadiusTestApp.dragKey),
          ),
        );
        await gesture.moveBy(const Offset(0, 90));
        await tester.pump();

        expect(
          _SwipeToPopBackgroundHeroRadiusTestApp.largestEdgeFadeClipRadius(
            tester,
          ),
          greaterThan(8),
        );
        await gesture.up();
      },
    );

    testWidgets(
      'when fast swiping a wrapped grouped hero route to pop, it should keep grouped text gaps compact',
      (tester) async {
        await tester.pumpWidget(const _SwipeToPopGroupedHeroHandoffTestApp());
        await tester.tap(
          find.byKey(_SwipeToPopGroupedHeroHandoffTestApp.openButtonKey),
        );
        await tester.pumpAndSettle();

        final destinationGap =
            _SwipeToPopGroupedHeroHandoffTestApp.paymentToDescriptionGap(
              tester,
            );

        await tester.fling(
          find.byKey(_SwipeToPopGroupedHeroHandoffTestApp.dragKey),
          const Offset(0, 30),
          900,
        );
        await tester.pump();

        final flightGap =
            _SwipeToPopGroupedHeroHandoffTestApp.paymentToDescriptionGap(
              tester,
            );

        expect(
          flightGap <= destinationGap + 1,
          isTrue,
          reason: 'destinationGap=$destinationGap flightGap=$flightGap',
        );
      },
    );
  });
}

class _SwipeToPopSurfaceTestApp extends StatelessWidget {
  const _SwipeToPopSurfaceTestApp({
    this.scrollPhysics = const AlwaysScrollableScrollPhysics(),
    this.contentHeight = 1600,
    this.disableAnimations = false,
    this.useQuiHeroPage = false,
    this.borderRadius = BorderRadius.zero,
    this.sensibility = 0.3,
    this.swipeDown = true,
    this.swipeRight = false,
    this.popAllowed = true,
  });

  static const openButtonKey = Key('open-swipe-page');
  static const destinationKey = Key('swipe-destination');

  final ScrollPhysics scrollPhysics;
  final double contentHeight;
  final bool disableAnimations;
  final bool useQuiHeroPage;
  final BorderRadiusGeometry borderRadius;
  final double sensibility;
  final bool swipeDown;
  final bool swipeRight;
  final bool popAllowed;

  static double destinationHorizontalOffset(WidgetTester tester) {
    return _destinationTranslationTransform(tester).transform.entry(0, 3);
  }

  static double destinationVerticalOffset(WidgetTester tester) {
    return _destinationTranslationTransform(tester).transform.entry(1, 3);
  }

  static double destinationScale(WidgetTester tester) {
    return _destinationScaleTransform(tester).transform.entry(0, 0);
  }

  static double destinationScrollOffset(WidgetTester tester) {
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(destinationKey),
        matching: find.byType(Scrollable),
      ),
    );

    return scrollable.position.pixels;
  }

  static BorderRadius destinationBorderRadius(WidgetTester tester) {
    final clip = tester
        .widgetList<ClipRRect>(
          find.ancestor(
            of: find.byKey(destinationKey),
            matching: find.byType(ClipRRect),
          ),
        )
        .last;

    return clip.borderRadius.resolve(TextDirection.ltr);
  }

  static Transform _destinationScaleTransform(WidgetTester tester) {
    return _destinationTransforms(tester).firstWhere(
      (transform) => transform.transform.entry(0, 0) < 1,
      orElse: () => Transform(transform: Matrix4.identity()),
    );
  }

  static Transform _destinationTranslationTransform(WidgetTester tester) {
    return _destinationTransforms(tester).firstWhere(
      (transform) =>
          transform.transform.entry(0, 3) != 0 ||
          transform.transform.entry(1, 3) != 0,
      orElse: () => Transform(transform: Matrix4.identity()),
    );
  }

  static Iterable<Transform> _destinationTransforms(WidgetTester tester) {
    return tester.widgetList<Transform>(
      find.ancestor(
        of: find.byKey(destinationKey),
        matching: find.byType(Transform),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(disableAnimations: disableAnimations),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: TextButton(
                key: openButtonKey,
                onPressed: () {
                  final destination = _SwipeToPopSurfaceTestDestination(
                    scrollPhysics: scrollPhysics,
                    contentHeight: contentHeight,
                    borderRadius: borderRadius,
                    sensibility: sensibility,
                    swipeDown: swipeDown,
                    swipeRight: swipeRight,
                    popAllowed: popAllowed,
                  );
                  if (useQuiHeroPage) {
                    unawaited(
                      Navigator.of(context).push<void>(
                        QuiHeroPage(
                          builder: (_) => destination,
                        ).createRoute(context),
                      ),
                    );
                    return;
                  }

                  unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(builder: (_) => destination),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SwipeToPopSurfaceTestDestination extends StatelessWidget {
  const _SwipeToPopSurfaceTestDestination({
    required this.scrollPhysics,
    required this.contentHeight,
    required this.borderRadius,
    required this.sensibility,
    required this.swipeDown,
    required this.swipeRight,
    required this.popAllowed,
  });

  final ScrollPhysics scrollPhysics;
  final double contentHeight;
  final BorderRadiusGeometry borderRadius;
  final double sensibility;
  final bool swipeDown;
  final bool swipeRight;
  final bool popAllowed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: popAllowed,
      child: QuiSwipeToPopSurface(
        borderRadius: borderRadius,
        sensibility: sensibility,
        swipeDown: swipeDown,
        swipeRight: swipeRight,
        child: Scaffold(
          body: CustomScrollView(
            key: _SwipeToPopSurfaceTestApp.destinationKey,
            physics: scrollPhysics,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: contentHeight,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Destination',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeToPopHeroStartTestApp extends StatelessWidget {
  const _SwipeToPopHeroStartTestApp({required this.events});

  static const openButtonKey = Key('open-hero-start-page');
  static const dragKey = Key('hero-start-drag-target');

  final List<String> events;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: QuiHeroBackground(
                tag: 'hero-start-surface',
                width: 120,
                height: 120,
                child: TextButton(
                  key: openButtonKey,
                  onPressed: () {
                    unawaited(
                      Navigator.of(context).push<void>(
                        QuiHeroPage(
                          builder: (_) =>
                              _SwipeToPopHeroStartDestination(events: events),
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

class _SwipeToPopHeroStartDestination extends StatelessWidget {
  const _SwipeToPopHeroStartDestination({required this.events});

  final List<String> events;

  @override
  Widget build(BuildContext context) {
    return QuiSwipeToPopSurface(
      child: Scaffold(
        body: QuiHeroBackground(
          tag: 'hero-start-surface',
          onStart: () => events.add('destination-start'),
          child: const SizedBox.expand(
            child: Center(
              child: SizedBox(
                key: _SwipeToPopHeroStartTestApp.dragKey,
                width: 240,
                height: 240,
                child: Text('Destination'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeToPopHeroHandoffTestApp extends StatelessWidget {
  const _SwipeToPopHeroHandoffTestApp();

  static const openButtonKey = Key('open-hero-handoff-page');
  static const dragKey = Key('hero-handoff-drag-target');

  static double smallestActiveScale(WidgetTester tester) {
    return tester
        .widgetList<Transform>(find.byType(Transform))
        .where(
          (transform) =>
              transform.transform.entry(0, 1).abs() < 0.0001 &&
              transform.transform.entry(1, 0).abs() < 0.0001,
        )
        .map((transform) => transform.transform.entry(0, 0))
        .where((scale) => scale > 0)
        .reduce(math.min);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: QuiHeroText(
                'Source title',
                tag: 'hero-handoff-title',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            floatingActionButton: Builder(
              builder: (buttonContext) {
                return TextButton(
                  key: openButtonKey,
                  onPressed: () {
                    unawaited(
                      Navigator.of(buttonContext).push<void>(
                        QuiHeroPage(
                          builder: (_) =>
                              const _SwipeToPopHeroHandoffDestination(),
                        ).createRoute(buttonContext),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SwipeToPopHeroHandoffDestination extends StatelessWidget {
  const _SwipeToPopHeroHandoffDestination();

  @override
  Widget build(BuildContext context) {
    return QuiSwipeToPopSurface(
      child: Scaffold(
        body: Center(
          child: SizedBox(
            key: _SwipeToPopHeroHandoffTestApp.dragKey,
            width: 280,
            height: 280,
            child: const Center(
              child: QuiHeroText(
                'Destination title',
                tag: 'hero-handoff-title',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeToPopBackgroundHeroRadiusTestApp extends StatelessWidget {
  const _SwipeToPopBackgroundHeroRadiusTestApp();

  static const openButtonKey = Key('open-background-hero-radius-page');
  static const dragKey = Key('background-hero-radius-drag-target');

  static double largestBackgroundRadius(WidgetTester tester) {
    return tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .map((decoration) {
          final borderRadius = decoration.borderRadius;
          if (borderRadius == null) return 0.0;

          return borderRadius.resolve(TextDirection.ltr).topLeft.x;
        })
        .fold(0.0, math.max);
  }

  static double largestEdgeFadeClipRadius(WidgetTester tester) {
    return tester
        .widgetList<ClipRRect>(
          find.ancestor(
            of: find.byType(QuiEdgeFade, skipOffstage: false),
            matching: find.byType(ClipRRect),
          ),
        )
        .map((clip) => clip.borderRadius.resolve(TextDirection.ltr).topLeft.x)
        .fold(0.0, math.max);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: TextButton(
                key: openButtonKey,
                onPressed: () {
                  unawaited(
                    Navigator.of(context).push<void>(
                      QuiHeroPage(
                        builder: (_) =>
                            const _SwipeToPopBackgroundHeroRadiusDestination(),
                      ).createRoute(context),
                    ),
                  );
                },
                child: const QuiHeroBackground(
                  tag: 'background-hero-radius',
                  width: 160,
                  height: 120,
                  edgeFade: QuiHeroEdgeFade.vertical,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Center(child: Text('Open')),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SwipeToPopBackgroundHeroRadiusDestination extends StatelessWidget {
  const _SwipeToPopBackgroundHeroRadiusDestination();

  @override
  Widget build(BuildContext context) {
    return QuiSwipeToPopSurface(
      borderRadius: const BorderRadius.all(Radius.circular(40)),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            key: _SwipeToPopBackgroundHeroRadiusTestApp.dragKey,
            width: 260,
            height: 220,
            child: const QuiHeroBackground(
              tag: 'background-hero-radius',
              width: 260,
              height: 220,
              edgeFade: QuiHeroEdgeFade.vertical,
              decoration: BoxDecoration(color: Colors.red),
              child: Center(child: Text('Close')),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeToPopGroupedHeroHandoffTestApp extends StatelessWidget {
  const _SwipeToPopGroupedHeroHandoffTestApp();

  static const openButtonKey = Key('open-grouped-hero-handoff-page');
  static const dragKey = Key('grouped-hero-handoff-drag-target');
  static const title = 'Motorista de Caminhao Truck';
  static const payment = r'R$2.863/mes';
  static const description =
      'Motorista de caminhao de segunda a sexta das 6h as 15h e sabados das 6h as 10h.';

  static double paymentToDescriptionGap(WidgetTester tester) {
    final paymentRect = tester.getRect(
      find.text(payment, skipOffstage: false).last,
    );
    final descriptionRect = tester.getRect(
      find.text(description, skipOffstage: false).last,
    );

    return descriptionRect.top - paymentRect.bottom;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: GestureDetector(
                onTap: () {
                  unawaited(
                    Navigator.of(context).push<void>(
                      QuiHeroPage(
                        builder: (_) =>
                            const _SwipeToPopGroupedHeroHandoffDestination(),
                      ).createRoute(context),
                    ),
                  );
                },
                child: const SizedBox(
                  width: 260,
                  child: _SwipeToPopGroupedHeroHandoffGroup(
                    isDestination: false,
                  ),
                ),
              ),
            ),
            floatingActionButton: TextButton(
              key: openButtonKey,
              onPressed: () {
                unawaited(
                  Navigator.of(context).push<void>(
                    QuiHeroPage(
                      builder: (_) =>
                          const _SwipeToPopGroupedHeroHandoffDestination(),
                    ).createRoute(context),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          );
        },
      ),
    );
  }
}

class _SwipeToPopGroupedHeroHandoffDestination extends StatelessWidget {
  const _SwipeToPopGroupedHeroHandoffDestination();

  @override
  Widget build(BuildContext context) {
    return QuiSwipeToPopSurface(
      child: Scaffold(
        body: Center(
          child: SizedBox(
            key: _SwipeToPopGroupedHeroHandoffTestApp.dragKey,
            width: 340,
            child: const _SwipeToPopGroupedHeroHandoffGroup(
              isDestination: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeToPopGroupedHeroHandoffGroup extends StatelessWidget {
  const _SwipeToPopGroupedHeroHandoffGroup({required this.isDestination});

  final bool isDestination;

  @override
  Widget build(BuildContext context) {
    final scale = isDestination ? 1.0 : 0.58;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        QuiHeroGroup(
          tag: 'grouped-hero-handoff',
          heroes: [
            QuiHeroText(
              '18 dias atras',
              style: TextStyle(fontSize: 14 * scale),
            ),
            QuiHeroText(
              _SwipeToPopGroupedHeroHandoffTestApp.title,
              style: TextStyle(
                fontSize: 40 * scale,
                fontWeight: FontWeight.w700,
              ),
              maxLines: isDestination ? null : 1,
            ),
            QuiHeroText(
              _SwipeToPopGroupedHeroHandoffTestApp.payment,
              style: TextStyle(
                fontSize: 34 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
            QuiHeroText(
              _SwipeToPopGroupedHeroHandoffTestApp.description,
              style: TextStyle(fontSize: 24 * scale, height: 1.25),
              maxLines: isDestination ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
