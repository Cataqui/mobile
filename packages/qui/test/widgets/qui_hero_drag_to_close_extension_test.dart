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
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 260));
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
  const _QuiHeroDragToCloseTestApp({this.onDragStateChanged});

  static const openButtonKey = Key('open-hero-page');
  static const destinationKey = Key('hero-destination');

  final ValueChanged<QuiHeroDragToCloseState>? onDragStateChanged;

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
  const _QuiHeroDragToCloseTestDestination({required this.scrollController, this.onDragStateChanged});

  final ScrollController scrollController;
  final ValueChanged<QuiHeroDragToCloseState>? onDragStateChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QuiHero.background(
        tag: 'test-surface',
        decoration: const BoxDecoration(color: Colors.white),
        extensions: [
          QuiHeroDragToCloseExtension(scrollController: scrollController, onDragStateChanged: onDragStateChanged),
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
