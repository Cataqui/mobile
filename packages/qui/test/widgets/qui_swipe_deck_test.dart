import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

typedef _ItemLog<T> = ({T item, int index});
typedef _ProgressLog = ({QuiSwipeDeckAction action, double percentage});

void main() {
  group('QuiSwipeDeck rendering', () {
    testWidgets('when items are provided, it should render the current item', (tester) async {
      await _pumpSwipeList(tester);

      expect(find.byKey(_cardKey('first')), findsOneWidget);
    });

    testWidgets('when multiple items are provided, it should render the next item underneath', (tester) async {
      await _pumpSwipeList(tester);

      expect(find.byKey(_cardKey('second')), findsOneWidget);
    });

    testWidgets('when one item is provided, it should not render a next item', (tester) async {
      await _pumpSwipeList(tester, items: const ['first']);

      expect(find.byKey(_cardKey('second')), findsNothing);
    });

    testWidgets('when no items are provided with endBuilder, it should render the end state', (tester) async {
      await _pumpSwipeList(tester, items: const []);

      expect(find.byKey(_endKey), findsOneWidget);
    });

    testWidgets('when no items are provided without endBuilder, it should render no card', (tester) async {
      await _pumpSwipeList(tester, items: const [], includeEndBuilder: false);

      expect(find.byType(_TestCard), findsNothing);
    });

    testWidgets('when using non-string item types, it should pass the typed item to the builder', (tester) async {
      final builtItems = <int>[];

      await _pumpTypedSwipeList<int>(
        tester,
        items: const [7],
        builder: (context, item, index) {
          builtItems.add(item);

          return _TestCard(label: '$item');
        },
      );

      expect(builtItems, contains(7));
    });

    testWidgets('when building an item, it should pass the correct item index', (tester) async {
      final builtIndexes = <int>[];

      await _pumpTypedSwipeList<String>(
        tester,
        items: const ['first'],
        builder: (context, item, index) {
          builtIndexes.add(index);

          return _TestCard(label: item);
        },
      );

      expect(builtIndexes, contains(0));
    });

    testWidgets('when itemProvider has far-away items, it should request only the current and next indexes', (
      tester,
    ) async {
      final requestedIndexes = <int>[];

      await _pumpTypedSwipeList<int>(
        tester,
        itemCount: 1000,
        itemProvider: (index) {
          requestedIndexes.add(index);

          return index;
        },
        builder: (context, item, index) => _TestCard(label: '$item'),
      );

      expect(requestedIndexes.toSet(), {0, 1});
    });
  });

  group('QuiSwipeDeck left dismiss', () {
    testWidgets('when dragging left below dismissThreshold, it should keep the same current item', (tester) async {
      await _pumpSwipeList(tester);

      await _dragCard(tester, 'first', const Offset(-120, 0));

      expect(find.byKey(_cardKey('first')), findsOneWidget);
    });

    testWidgets('when dragging left at dismissThreshold, it should advance to the next item', (tester) async {
      await _pumpSwipeList(tester);

      await _dragCard(tester, 'first', const Offset(-140, 0));

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when dragging left over dismissThreshold, it should advance to the next item', (tester) async {
      await _pumpSwipeList(tester);

      await _dragCard(tester, 'first', const Offset(-180, 0));

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when dismissing left, it should call onDismiss with the dismissed item', (tester) async {
      final dismissLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(tester, onDismiss: (item, index) => dismissLogs.add((item: item, index: index)));

      await _dragCard(tester, 'first', const Offset(-180, 0));

      expect(dismissLogs.single.item, 'first');
    });

    testWidgets('when dismissing left, it should call onDismiss with the dismissed index', (tester) async {
      final dismissLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(tester, onDismiss: (item, index) => dismissLogs.add((item: item, index: index)));

      await _dragCard(tester, 'first', const Offset(-180, 0));

      expect(dismissLogs.single.index, 0);
    });

    testWidgets('when dismissing multiple cards, it should advance in list order', (tester) async {
      await _pumpSwipeList(tester);

      await _dragCurrentCard(tester, const Offset(-180, 0));
      await _dragCurrentCard(tester, const Offset(-180, 0));

      expect(_currentCardLabel(tester), 'third');
    });

    testWidgets('when dismissing the final card, it should render the end state', (tester) async {
      await _pumpSwipeList(tester, items: const ['first']);

      await _dragCard(tester, 'first', const Offset(-180, 0));

      expect(find.byKey(_endKey), findsOneWidget);
    });

    testWidgets('when dismissing left, it should not call onAccept', (tester) async {
      final acceptLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(tester, onAccept: (item, index) => acceptLogs.add((item: item, index: index)));

      await _dragCard(tester, 'first', const Offset(-180, 0));

      expect(acceptLogs, isEmpty);
    });
  });

  group('QuiSwipeDeck right accept', () {
    testWidgets('when dragging right below acceptThreshold, it should not call onAccept', (tester) async {
      final acceptLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(tester, onAccept: (item, index) => acceptLogs.add((item: item, index: index)));

      await _dragCard(tester, 'first', const Offset(120, 0));

      expect(acceptLogs, isEmpty);
    });

    testWidgets('when dragging right at acceptThreshold, it should call onAccept', (tester) async {
      final acceptLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(tester, onAccept: (item, index) => acceptLogs.add((item: item, index: index)));

      await _dragCard(tester, 'first', const Offset(140, 0));

      expect(acceptLogs, hasLength(1));
    });

    testWidgets('when accepting right, it should keep the same current item', (tester) async {
      await _pumpSwipeList(tester);

      await _dragCard(tester, 'first', const Offset(180, 0));

      expect(_currentCardLabel(tester), 'first');
    });

    testWidgets('when accepting right, it should call onAccept with the accepted item', (tester) async {
      final acceptLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(tester, onAccept: (item, index) => acceptLogs.add((item: item, index: index)));

      await _dragCard(tester, 'first', const Offset(180, 0));

      expect(acceptLogs.single.item, 'first');
    });

    testWidgets('when accepting right, it should call onAccept with the accepted index', (tester) async {
      final acceptLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(tester, onAccept: (item, index) => acceptLogs.add((item: item, index: index)));

      await _dragCard(tester, 'first', const Offset(180, 0));

      expect(acceptLogs.single.index, 0);
    });

    testWidgets('when accepting right repeatedly, it should call onAccept each time for the same current item', (
      tester,
    ) async {
      final acceptLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(tester, onAccept: (item, index) => acceptLogs.add((item: item, index: index)));

      await _dragCard(tester, 'first', const Offset(180, 0));
      await _dragCard(tester, 'first', const Offset(180, 0));

      expect(acceptLogs.map((log) => log.item), ['first', 'first']);
    });

    testWidgets('when accepting right, it should not call onDismiss', (tester) async {
      final dismissLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(tester, onDismiss: (item, index) => dismissLogs.add((item: item, index: index)));

      await _dragCard(tester, 'first', const Offset(180, 0));

      expect(dismissLogs, isEmpty);
    });
  });

  group('QuiSwipeDeck controller', () {
    testWidgets('when controller.dismiss is called, it should advance to the next item', (tester) async {
      final controller = QuiSwipeDeckController();

      await _pumpSwipeList(tester, controller: controller);
      final dismissFuture = controller.dismiss();
      await tester.pumpAndSettle();
      await dismissFuture;

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when controller.dismiss is called, it should call onDismiss with the current item', (tester) async {
      final controller = QuiSwipeDeckController();
      final dismissLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(
        tester,
        controller: controller,
        onDismiss: (item, index) => dismissLogs.add((item: item, index: index)),
      );
      final dismissFuture = controller.dismiss();
      await tester.pumpAndSettle();
      await dismissFuture;

      expect(dismissLogs.single.item, 'first');
    });

    testWidgets('when controller.dismiss is called, it should call onDismiss with the current index', (tester) async {
      final controller = QuiSwipeDeckController();
      final dismissLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(
        tester,
        controller: controller,
        onDismiss: (item, index) => dismissLogs.add((item: item, index: index)),
      );
      final dismissFuture = controller.dismiss();
      await tester.pumpAndSettle();
      await dismissFuture;

      expect(dismissLogs.single.index, 0);
    });

    testWidgets('when controller.dismiss is called on the final item, it should render endBuilder', (tester) async {
      final controller = QuiSwipeDeckController();

      await _pumpSwipeList(tester, controller: controller, items: const ['first']);
      final dismissFuture = controller.dismiss();
      await tester.pumpAndSettle();
      await dismissFuture;

      expect(find.byKey(_endKey), findsOneWidget);
    });

    testWidgets('when controller.dismiss is called with no current item, it should return false', (tester) async {
      final controller = QuiSwipeDeckController();

      await _pumpSwipeList(tester, controller: controller, items: const []);
      final result = await controller.dismiss();

      expect(result, isFalse);
    });

    testWidgets('when controller.dismiss is called while detached, it should return false', (tester) async {
      final controller = QuiSwipeDeckController();

      final result = await controller.dismiss();

      expect(result, isFalse);
    });

    testWidgets('when controller.dismiss is called, it should report dismiss progress during animation', (
      tester,
    ) async {
      final controller = QuiSwipeDeckController();
      final progressLogs = <_ProgressLog>[];

      await _pumpSwipeList(
        tester,
        controller: controller,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );
      final dismissFuture = controller.dismiss();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 120));

      expect(progressLogs.map((log) => log.percentage), contains(predicate<double>((value) => value > 0.45)));

      await tester.pumpAndSettle();
      await dismissFuture;
    });

    testWidgets('when reduced motion is enabled, controller.dismiss should advance immediately', (tester) async {
      final controller = QuiSwipeDeckController();

      await _pumpSwipeList(tester, controller: controller, disableAnimations: true);
      await controller.dismiss();
      await tester.pump();

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when controller.accept is called, it should call onAccept', (tester) async {
      final controller = QuiSwipeDeckController();
      final acceptLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(
        tester,
        controller: controller,
        onAccept: (item, index) => acceptLogs.add((item: item, index: index)),
      );
      await controller.accept();

      expect(acceptLogs.single.item, 'first');
    });

    testWidgets('when controller.accept is called, it should keep the same current item', (tester) async {
      final controller = QuiSwipeDeckController();

      await _pumpSwipeList(tester, controller: controller);
      await controller.accept();
      await tester.pumpAndSettle();

      expect(_currentCardLabel(tester), 'first');
    });

    testWidgets('when controller.accept is called, it should return true', (tester) async {
      final controller = QuiSwipeDeckController();

      await _pumpSwipeList(tester, controller: controller);
      final result = await controller.accept();

      expect(result, isTrue);
    });

    testWidgets('when controller.accept is called with no current item, it should return false', (tester) async {
      final controller = QuiSwipeDeckController();

      await _pumpSwipeList(tester, controller: controller, items: const []);
      final result = await controller.accept();

      expect(result, isFalse);
    });

    testWidgets('when controller.accept is called while detached, it should return false', (tester) async {
      final controller = QuiSwipeDeckController();

      final result = await controller.accept();

      expect(result, isFalse);
    });

    testWidgets('when controller.accept is called, it should not call onDismiss', (tester) async {
      final controller = QuiSwipeDeckController();
      final dismissLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(
        tester,
        controller: controller,
        onDismiss: (item, index) => dismissLogs.add((item: item, index: index)),
      );
      await controller.accept();

      expect(dismissLogs, isEmpty);
    });

    testWidgets('when controller.accept is called, it should not emit swipe progress', (tester) async {
      final controller = QuiSwipeDeckController();
      final progressLogs = <_ProgressLog>[];

      await _pumpSwipeList(
        tester,
        controller: controller,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );
      await controller.accept();

      expect(progressLogs, isEmpty);
    });

    testWidgets('when a controller action is already running, it should return false for a second action', (
      tester,
    ) async {
      final controller = QuiSwipeDeckController();

      await _pumpSwipeList(tester, controller: controller);
      final dismissFuture = controller.dismiss();
      await tester.pump();
      final result = await controller.dismiss();

      expect(result, isFalse);

      await tester.pumpAndSettle();
      await dismissFuture;
    });

    testWidgets('when the widget swaps controllers, it should detach the old one and use the new one', (tester) async {
      final firstController = QuiSwipeDeckController();
      final secondController = QuiSwipeDeckController();

      await tester.pumpWidget(
        _ControllerSwapHost(firstController: firstController, secondController: secondController),
      );
      await tester.tap(find.byKey(_swapControllerButtonKey));
      await tester.pumpAndSettle();
      final oldResult = await firstController.accept();
      final newResultFuture = secondController.dismiss();
      await tester.pumpAndSettle();
      final newResult = await newResultFuture;

      expect(
        (oldResult: oldResult, newResult: newResult, label: _currentCardLabel(tester)),
        (oldResult: false, newResult: true, label: 'second'),
      );
    });
  });

  group('QuiSwipeDeck swipe progress', () {
    testWidgets('when dragging left, it should report QuiSwipeDeckAction.dismiss', (tester) async {
      final progressLogs = <_ProgressLog>[];

      await _pumpSwipeList(
        tester,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );

      await _dragCard(tester, 'first', const Offset(-80, 0));

      expect(progressLogs.first.action, QuiSwipeDeckAction.dismiss);
    });

    testWidgets('when dragging right, it should report QuiSwipeDeckAction.accept', (tester) async {
      final progressLogs = <_ProgressLog>[];

      await _pumpSwipeList(
        tester,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );

      await _dragCard(tester, 'first', const Offset(80, 0));

      expect(progressLogs.first.action, QuiSwipeDeckAction.accept);
    });

    testWidgets('when dragging halfway across the width, it should report percentage close to 0.5', (tester) async {
      final progressLogs = <_ProgressLog>[];

      await _pumpSwipeList(
        tester,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );

      await _dragCard(tester, 'first', const Offset(200, 0));

      expect(progressLogs.map((log) => log.percentage), contains(closeTo(0.5, 0.01)));
    });

    testWidgets('when dragging beyond the full width, it should clamp percentage to 1.0', (tester) async {
      final progressLogs = <_ProgressLog>[];

      await _pumpSwipeList(
        tester,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );

      await _dragCard(tester, 'first', const Offset(600, 0));

      expect(progressLogs.map((log) => log.percentage), contains(1));
    });

    testWidgets('when snapping back after an incomplete swipe, it should report a final percentage of 0.0', (
      tester,
    ) async {
      final progressLogs = <_ProgressLog>[];

      await _pumpSwipeList(
        tester,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );

      await _dragCard(tester, 'first', const Offset(80, 0));

      expect(progressLogs.last.percentage, 0);
    });

    testWidgets('when accepting right and snapping back, it should report a final percentage of 0.0', (tester) async {
      final progressLogs = <_ProgressLog>[];

      await _pumpSwipeList(
        tester,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );

      await _dragCard(tester, 'first', const Offset(180, 0));

      expect(progressLogs.last.percentage, 0);
    });

    testWidgets('when dismissing left with animation enabled, it should report progress during the exit animation', (
      tester,
    ) async {
      final progressLogs = <_ProgressLog>[];

      await _pumpSwipeList(
        tester,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );

      await tester.drag(find.byKey(_cardKey('first')), const Offset(-180, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 120));

      expect(progressLogs.map((log) => log.percentage), contains(predicate<double>((value) => value > 0.45)));
    });
  });

  group('QuiSwipeDeck threshold configuration', () {
    testWidgets('when dismissThreshold is custom, it should use that value for left dismissal', (tester) async {
      await _pumpSwipeList(tester, dismissThreshold: 0.6);

      await _dragCard(tester, 'first', const Offset(-200, 0));

      expect(_currentCardLabel(tester), 'first');
    });

    testWidgets('when acceptThreshold is custom, it should use that value for right acceptance', (tester) async {
      final acceptLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(
        tester,
        acceptThreshold: 0.6,
        onAccept: (item, index) => acceptLogs.add((item: item, index: index)),
      );

      await _dragCard(tester, 'first', const Offset(200, 0));

      expect(acceptLogs, isEmpty);
    });

    testWidgets('when dismissThreshold is invalid at 0, it should throw an assertion error', (tester) async {
      expect(
        () => QuiSwipeDeck<String>(
          itemCount: 0,
          itemProvider: (index) => 'item',
          dismissThreshold: 0,
          builder: _defaultCardBuilder,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('when dismissThreshold is invalid above 1, it should throw an assertion error', (tester) async {
      expect(
        () => QuiSwipeDeck<String>(
          itemCount: 0,
          itemProvider: (index) => 'item',
          dismissThreshold: 1.1,
          builder: _defaultCardBuilder,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('when acceptThreshold is invalid at 0, it should throw an assertion error', (tester) async {
      expect(
        () => QuiSwipeDeck<String>(
          itemCount: 0,
          itemProvider: (index) => 'item',
          acceptThreshold: 0,
          builder: _defaultCardBuilder,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('when acceptThreshold is invalid above 1, it should throw an assertion error', (tester) async {
      expect(
        () => QuiSwipeDeck<String>(
          itemCount: 0,
          itemProvider: (index) => 'item',
          acceptThreshold: 1.1,
          builder: _defaultCardBuilder,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('when maxRotation is negative, it should throw an assertion error', (tester) async {
      expect(
        () => QuiSwipeDeck<String>(
          itemCount: 0,
          itemProvider: (index) => 'item',
          maxRotation: -0.1,
          builder: _defaultCardBuilder,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('when itemCount is negative, it should throw an assertion error', (tester) async {
      expect(
        () => QuiSwipeDeck<String>(itemCount: -1, itemProvider: (index) => 'item', builder: _defaultCardBuilder),
        throwsAssertionError,
      );
    });

    testWidgets('when maxRotation is 0, it should still drag and complete callbacks', (tester) async {
      final acceptLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(
        tester,
        maxRotation: 0,
        onAccept: (item, index) => acceptLogs.add((item: item, index: index)),
      );

      await _dragCard(tester, 'first', const Offset(180, 0));

      expect(acceptLogs, hasLength(1));
    });
  });

  group('QuiSwipeDeck widget lifecycle and updates', () {
    testWidgets('when the parent rebuilds with the same items, it should preserve the current index', (tester) async {
      await tester.pumpWidget(const _MutableSwipeListHost());
      await _dragCard(tester, 'first', const Offset(-180, 0));

      await tester.tap(find.byKey(_rebuildButtonKey));
      await tester.pumpAndSettle();

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when the parent shrinks the items list below the current index, it should render the end state', (
      tester,
    ) async {
      await tester.pumpWidget(const _MutableSwipeListHost());
      await _dragCard(tester, 'first', const Offset(-180, 0));

      await tester.tap(find.byKey(_shrinkButtonKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_endKey), findsOneWidget);
    });

    testWidgets('when the parent replaces items before any swipe, it should render the replacement current item', (
      tester,
    ) async {
      await tester.pumpWidget(const _MutableSwipeListHost());

      await tester.tap(find.byKey(_replaceButtonKey));
      await tester.pumpAndSettle();

      expect(_currentCardLabel(tester), 'replacement');
    });

    testWidgets('when the widget is removed during an animation, it should dispose without throwing', (tester) async {
      await tester.pumpWidget(const _MutableSwipeListHost());

      await tester.drag(find.byKey(_cardKey('first')), const Offset(120, 0));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.byKey(_hideButtonKey));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'when a drag starts during snap-back animation, it should stop the old animation and follow the new drag',
      (tester) async {
        final acceptLogs = <_ItemLog<String>>[];

        await _pumpSwipeList(tester, onAccept: (item, index) => acceptLogs.add((item: item, index: index)));

        await tester.drag(find.byKey(_cardKey('first')), const Offset(120, 0));
        await tester.pump(const Duration(milliseconds: 40));
        await tester.drag(find.byKey(_cardKey('first')), const Offset(180, 0));
        await tester.pumpAndSettle();

        expect(acceptLogs, hasLength(1));
      },
    );
  });

  group('QuiSwipeDeck state preservation', () {
    testWidgets('when cards are stateful, dismissing should not leak old card state into the new current card', (
      tester,
    ) async {
      await _pumpStatefulSwipeList(tester);

      await tester.tap(find.byKey(_stateButtonKey('first')));
      await tester.pumpAndSettle();
      await _dragCard(tester, 'first', const Offset(-180, 0));

      expect(find.text('second:0'), findsOneWidget);
    });

    testWidgets(
      'when the same card is accepted, it should preserve that card state because the item does not advance',
      (tester) async {
        await _pumpStatefulSwipeList(tester);

        await tester.tap(find.byKey(_stateButtonKey('first')));
        await tester.pumpAndSettle();
        await _dragCard(tester, 'first', const Offset(180, 0));

        expect(find.text('first:1'), findsOneWidget);
      },
    );
  });

  group('QuiSwipeDeck reduced motion', () {
    testWidgets(
      'when MediaQuery.disableAnimations is true and a left dismiss completes, it should advance immediately',
      (tester) async {
        await _pumpSwipeList(tester, disableAnimations: true);

        await tester.drag(find.byKey(_cardKey('first')), const Offset(-180, 0));
        await tester.pump();

        expect(_currentCardLabel(tester), 'second');
      },
    );

    testWidgets(
      'when MediaQuery.disableAnimations is true and a right accept completes, it should snap back immediately',
      (tester) async {
        await _pumpSwipeList(tester, disableAnimations: true);

        await tester.drag(find.byKey(_cardKey('first')), const Offset(180, 0));
        await tester.pump();

        expect(tester.getCenter(find.byKey(_cardKey('first'))).dx, 400);
      },
    );

    testWidgets('when reduced motion is enabled, callbacks should still fire with the correct item', (tester) async {
      final dismissLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(
        tester,
        disableAnimations: true,
        onDismiss: (item, index) => dismissLogs.add((item: item, index: index)),
      );

      await tester.drag(find.byKey(_cardKey('first')), const Offset(-180, 0));
      await tester.pump();

      expect(dismissLogs.single.item, 'first');
    });

    testWidgets('when reduced motion is enabled, callbacks should still fire with the correct index', (tester) async {
      final dismissLogs = <_ItemLog<String>>[];

      await _pumpSwipeList(
        tester,
        disableAnimations: true,
        onDismiss: (item, index) => dismissLogs.add((item: item, index: index)),
      );

      await tester.drag(find.byKey(_cardKey('first')), const Offset(-180, 0));
      await tester.pump();

      expect(dismissLogs.single.index, 0);
    });
  });

  group('QuiSwipeDeck pagination', () {
    testWidgets('when loadMoreThreshold is 1.0, it should load only at the last loaded card', (tester) async {
      var loadMoreCount = 0;

      await _pumpSwipeList(tester, onLoadMore: () async => loadMoreCount += 1);
      await _dragCurrentCard(tester, const Offset(-180, 0));
      await _dragCurrentCard(tester, const Offset(-180, 0));
      await tester.pump();

      expect(loadMoreCount, 1);
    });

    testWidgets('when loadMoreThreshold is 0.8, it should load before the last loaded card', (tester) async {
      var loadMoreCount = 0;

      await _pumpSwipeList(
        tester,
        items: const ['first', 'second', 'third', 'fourth', 'fifth'],
        loadMoreThreshold: 0.8,
        onLoadMore: () async => loadMoreCount += 1,
      );
      await _dragCurrentCard(tester, const Offset(-180, 0));
      await _dragCurrentCard(tester, const Offset(-180, 0));
      await _dragCurrentCard(tester, const Offset(-180, 0));
      await tester.pump();

      expect(loadMoreCount, 1);
    });

    testWidgets('when loading is pending, it should skip duplicate load calls', (tester) async {
      final loadCompleter = Completer<void>();
      var loadMoreCount = 0;

      await _pumpSwipeList(
        tester,
        loadMoreThreshold: 0.8,
        loadingMoreBuilder: _loadingMoreBuilder,
        onLoadMore: () {
          loadMoreCount += 1;
          return loadCompleter.future;
        },
      );
      await _dragCurrentCard(tester, const Offset(-180, 0));
      await _dragCurrentCard(tester, const Offset(-180, 0));
      await tester.pump();
      await tester.pump();

      expect(loadMoreCount, 1);
    });

    testWidgets('when load completes without increased itemCount, it should stop further automatic calls', (
      tester,
    ) async {
      var loadMoreCount = 0;

      await _pumpSwipeList(tester, items: const ['first'], onLoadMore: () async => loadMoreCount += 1);
      await tester.pump();
      await _dragCard(tester, 'first', const Offset(180, 0));
      await tester.pump();

      expect(loadMoreCount, 1);
    });

    testWidgets('when itemCount increases after load completion, it should clear exhausted state', (tester) async {
      await tester.pumpWidget(const _PaginatedSwipeListHost());
      await tester.pump();
      await tester.tap(find.byKey(_appendButtonKey));
      await tester.pumpAndSettle();
      await _dragCard(tester, 'first', const Offset(-180, 0));

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when buildLoadMoreError is provided, it should render load-more error at the end', (tester) async {
      await _pumpSwipeList(tester, items: const ['first'], buildLoadMoreError: _buildLoadMoreError);
      await _dragCard(tester, 'first', const Offset(-180, 0));

      expect(find.byKey(_loadMoreErrorKey), findsOneWidget);
    });

    testWidgets('when buildLoadMoreError is provided, it should prevent automatic load-more calls', (tester) async {
      var loadMoreCount = 0;

      await _pumpSwipeList(
        tester,
        items: const ['first'],
        onLoadMore: () async => loadMoreCount += 1,
        buildLoadMoreError: _buildLoadMoreError,
      );
      await tester.pump();

      expect(loadMoreCount, 0);
    });

    testWidgets('when tapping retry in buildLoadMoreError, it should call onLoadMore', (tester) async {
      var loadMoreCount = 0;

      await _pumpSwipeList(
        tester,
        items: const ['first'],
        onLoadMore: () async => loadMoreCount += 1,
        buildLoadMoreError: _buildLoadMoreError,
      );
      await _dragCard(tester, 'first', const Offset(-180, 0));
      await tester.tap(find.byKey(_loadMoreRetryKey));
      await tester.pumpAndSettle();

      expect(loadMoreCount, 1);
    });

    testWidgets('when no next real card exists while loading, it should render loadingMoreBuilder', (tester) async {
      final loadCompleter = Completer<void>();

      await _pumpSwipeList(
        tester,
        items: const ['first'],
        onLoadMore: () => loadCompleter.future,
        loadingMoreBuilder: _loadingMoreBuilder,
      );
      await tester.pump();

      expect(find.byKey(_loadingKey), findsOneWidget);
    });

    testWidgets('when all loaded cards are dismissed and no new items arrived, it should render endBuilder', (
      tester,
    ) async {
      await _pumpSwipeList(tester, items: const ['first'], onLoadMore: () async {}, endBuilder: _endBuilder);
      await tester.pump();
      await _dragCard(tester, 'first', const Offset(-180, 0));

      expect(find.byKey(_endKey), findsOneWidget);
    });

    testWidgets('when loadMoreThreshold is below 0, it should throw an assertion error', (tester) async {
      expect(
        () => QuiSwipeDeck<String>(
          itemCount: 0,
          itemProvider: (index) => 'item',
          loadMoreThreshold: -0.1,
          builder: _defaultCardBuilder,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('when loadMoreThreshold is above 1, it should throw an assertion error', (tester) async {
      expect(
        () => QuiSwipeDeck<String>(
          itemCount: 0,
          itemProvider: (index) => 'item',
          loadMoreThreshold: 1.1,
          builder: _defaultCardBuilder,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('when pagination is enabled, it should still request only current and next real indexes', (
      tester,
    ) async {
      final requestedIndexes = <int>[];

      await _pumpTypedSwipeList<int>(
        tester,
        itemCount: 1000,
        itemProvider: (index) {
          requestedIndexes.add(index);

          return index;
        },
        onLoadMore: () async {},
        builder: (context, item, index) => _TestCard(label: '$item'),
      );

      expect(requestedIndexes.toSet(), {0, 1});
    });
  });
}

const _listSize = Size(400, 600);
const _rebuildButtonKey = Key('rebuild_button');
const _shrinkButtonKey = Key('shrink_button');
const _replaceButtonKey = Key('replace_button');
const _hideButtonKey = Key('hide_button');
const _appendButtonKey = Key('append_button');
const _swapControllerButtonKey = Key('swap_controller_button');
const _loadingKey = Key('qui_swipe_deck_loading');
const _loadMoreErrorKey = Key('qui_swipe_deck_load_more_error');
const _loadMoreRetryKey = Key('qui_swipe_deck_load_more_retry');
const _endKey = Key('qui_swipe_deck_end');

Key _cardKey(String item) => Key('card_$item');

Key _stateButtonKey(String item) => Key('state_button_$item');

Future<void> _pumpSwipeList(
  WidgetTester tester, {
  List<String> items = const ['first', 'second', 'third'],
  bool includeEndBuilder = true,
  bool disableAnimations = false,
  double dismissThreshold = 0.35,
  double acceptThreshold = 0.35,
  double loadMoreThreshold = 1,
  double maxRotation = 0.18,
  QuiSwipeDeckController? controller,
  void Function({required QuiSwipeDeckAction action, required double percentage})? onSwipeProgress,
  QuiSwipeDeckItemCallback<String>? onDismiss,
  QuiSwipeDeckItemCallback<String>? onAccept,
  QuiSwipeDeckLoadMoreCallback? onLoadMore,
  WidgetBuilder? loadingMoreBuilder,
  QuiSwipeDeckLoadMoreErrorBuilder? buildLoadMoreError,
  WidgetBuilder? endBuilder,
}) {
  return tester.pumpWidget(
    _HarnessApp(
      disableAnimations: disableAnimations,
      child: QuiSwipeDeck<String>(
        itemCount: items.length,
        itemProvider: (index) => items[index],
        dismissThreshold: dismissThreshold,
        acceptThreshold: acceptThreshold,
        loadMoreThreshold: loadMoreThreshold,
        maxRotation: maxRotation,
        controller: controller,
        onSwipeProgress: onSwipeProgress,
        onDismiss: onDismiss,
        onAccept: onAccept,
        onLoadMore: onLoadMore,
        loadingMoreBuilder: loadingMoreBuilder,
        buildLoadMoreError: buildLoadMoreError,
        endBuilder: includeEndBuilder ? endBuilder ?? _endBuilder : null,
        builder: _defaultCardBuilder,
      ),
    ),
  );
}

Future<void> _pumpTypedSwipeList<T>(
  WidgetTester tester, {
  required Widget Function(BuildContext context, T item, int index) builder,
  List<T>? items,
  int? itemCount,
  QuiSwipeDeckItemProvider<T>? itemProvider,
  QuiSwipeDeckLoadMoreCallback? onLoadMore,
}) {
  final providedItems = items;

  return tester.pumpWidget(
    _HarnessApp(
      child: QuiSwipeDeck<T>(
        itemCount: itemCount ?? providedItems!.length,
        itemProvider: itemProvider ?? (index) => providedItems![index],
        onLoadMore: onLoadMore,
        endBuilder: _endBuilder,
        builder: builder,
      ),
    ),
  );
}

Future<void> _pumpStatefulSwipeList(WidgetTester tester) {
  return tester.pumpWidget(
    _HarnessApp(
      child: QuiSwipeDeck<String>(
        itemCount: 2,
        itemProvider: (index) => const ['first', 'second'][index],
        endBuilder: _endBuilder,
        builder: (context, item, index) => _StatefulCard(label: item),
      ),
    ),
  );
}

Future<void> _dragCard(WidgetTester tester, String item, Offset offset) async {
  await tester.drag(find.byKey(_cardKey(item)), offset);
  await tester.pumpAndSettle();
}

Future<void> _dragCurrentCard(WidgetTester tester, Offset offset) async {
  final label = _currentCardLabel(tester);

  await _dragCard(tester, label, offset);
}

String _currentCardLabel(WidgetTester tester) {
  final activeGestureDetector = find.descendant(
    of: find.byType(QuiSwipeDeck<String>),
    matching: find.byType(GestureDetector),
  );
  final text = tester.widget<Text>(find.descendant(of: activeGestureDetector, matching: find.byType(Text)));

  return text.data ?? '';
}

Widget _defaultCardBuilder(BuildContext context, String item, int index) {
  return _TestCard(label: item);
}

Widget _loadingMoreBuilder(BuildContext context) {
  return const Center(child: Text('Loading more', key: _loadingKey));
}

Widget _buildLoadMoreError(BuildContext context, VoidCallback retry) {
  return Center(
    child: TextButton(
      key: _loadMoreErrorKey,
      onPressed: retry,
      child: const Text('Retry', key: _loadMoreRetryKey),
    ),
  );
}

Widget _endBuilder(BuildContext context) {
  return const Center(child: Text('End', key: _endKey));
}

class _HarnessApp extends StatelessWidget {
  const _HarnessApp({required this.child, this.disableAnimations = false});

  final Widget child;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(800, 800)).copyWith(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: SizedBox.fromSize(size: _listSize, child: child),
          ),
        ),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(key: _cardKey(label), alignment: Alignment.center, color: Colors.white, child: Text(label));
  }
}

class _ControllerSwapHost extends StatefulWidget {
  const _ControllerSwapHost({required this.firstController, required this.secondController});

  final QuiSwipeDeckController firstController;
  final QuiSwipeDeckController secondController;

  @override
  State<_ControllerSwapHost> createState() => _ControllerSwapHostState();
}

class _ControllerSwapHostState extends State<_ControllerSwapHost> {
  var _useSecondController = false;

  @override
  Widget build(BuildContext context) {
    return _HarnessApp(
      child: Column(
        children: [
          TextButton(
            key: _swapControllerButtonKey,
            onPressed: () => setState(() => _useSecondController = true),
            child: const Text('swap controller'),
          ),
          Expanded(
            child: QuiSwipeDeck<String>(
              controller: _useSecondController ? widget.secondController : widget.firstController,
              itemCount: 2,
              itemProvider: (index) => const ['first', 'second'][index],
              endBuilder: _endBuilder,
              builder: _defaultCardBuilder,
            ),
          ),
        ],
      ),
    );
  }
}

class _MutableSwipeListHost extends StatefulWidget {
  const _MutableSwipeListHost();

  @override
  State<_MutableSwipeListHost> createState() => _MutableSwipeListHostState();
}

class _MutableSwipeListHostState extends State<_MutableSwipeListHost> {
  var _items = const ['first', 'second', 'third'];
  var _isVisible = true;
  var _rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    return _HarnessApp(
      child: Column(
        children: [
          Wrap(
            children: [
              TextButton(
                key: _rebuildButtonKey,
                onPressed: () => setState(() => _rebuildCount += 1),
                child: Text('rebuild $_rebuildCount'),
              ),
              TextButton(
                key: _shrinkButtonKey,
                onPressed: () => setState(() => _items = const ['first']),
                child: const Text('shrink'),
              ),
              TextButton(
                key: _replaceButtonKey,
                onPressed: () => setState(() => _items = const ['replacement']),
                child: const Text('replace'),
              ),
              TextButton(
                key: _hideButtonKey,
                onPressed: () => setState(() => _isVisible = false),
                child: const Text('hide'),
              ),
            ],
          ),
          Expanded(
            child: _isVisible
                ? QuiSwipeDeck<String>(
                    itemCount: _items.length,
                    itemProvider: (index) => _items[index],
                    endBuilder: _endBuilder,
                    builder: _defaultCardBuilder,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PaginatedSwipeListHost extends StatefulWidget {
  const _PaginatedSwipeListHost();

  @override
  State<_PaginatedSwipeListHost> createState() => _PaginatedSwipeListHostState();
}

class _PaginatedSwipeListHostState extends State<_PaginatedSwipeListHost> {
  var _items = const ['first'];

  @override
  Widget build(BuildContext context) {
    return _HarnessApp(
      child: Column(
        children: [
          TextButton(
            key: _appendButtonKey,
            onPressed: () => setState(() => _items = const ['first', 'second']),
            child: const Text('append'),
          ),
          Expanded(
            child: QuiSwipeDeck<String>(
              itemCount: _items.length,
              itemProvider: (index) => _items[index],
              onLoadMore: () async {},
              endBuilder: _endBuilder,
              builder: _defaultCardBuilder,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatefulCard extends StatefulWidget {
  const _StatefulCard({required this.label});

  final String label;

  @override
  State<_StatefulCard> createState() => _StatefulCardState();
}

class _StatefulCardState extends State<_StatefulCard> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _cardKey(widget.label),
      alignment: Alignment.center,
      color: Colors.white,
      child: TextButton(
        key: _stateButtonKey(widget.label),
        onPressed: () => setState(() => _count += 1),
        child: Text('${widget.label}:$_count'),
      ),
    );
  }
}
