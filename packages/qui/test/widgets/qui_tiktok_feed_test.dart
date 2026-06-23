import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

typedef _ItemLog<T> = ({T item, int index});
typedef _ProgressLog = ({QuiTikTokFeedAction action, double percentage});

void main() {
  group('QuiTikTokFeed rendering', () {
    testWidgets('when items are provided, it should render the current item', (tester) async {
      await _pumpFeed(tester);

      expect(find.byKey(_cardKey('first')), findsOneWidget);
    });

    testWidgets('when multiple items are provided, it should preload the next card', (tester) async {
      await _pumpFeed(tester);

      expect(find.byKey(_cardKey('second')), findsOneWidget);
    });

    testWidgets('when one item is provided, it should not render a next item', (tester) async {
      await _pumpFeed(tester, items: const ['first']);

      expect(find.byKey(_cardKey('second')), findsNothing);
    });

    testWidgets('when no items are provided with endBuilder, it should render the end state', (tester) async {
      await _pumpFeed(tester, items: const []);

      expect(find.byKey(_endKey), findsOneWidget);
    });

    testWidgets('when no items are provided without endBuilder, it should render no card', (tester) async {
      await _pumpFeed(tester, items: const [], includeEndBuilder: false);

      expect(find.byType(_TestCard), findsNothing);
    });

    testWidgets('when using non-string item types, it should pass the typed item to the builder', (tester) async {
      final builtItems = <int>[];

      await _pumpTypedFeed<int>(
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

      await _pumpTypedFeed<String>(
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

      await _pumpTypedFeed<int>(
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

  group('QuiTikTokFeed next (up swipe)', () {
    testWidgets('when dragging up below threshold, it should keep the same current item', (tester) async {
      await _pumpFeed(tester);

      await _dragCard(tester, 'first', const Offset(0, -80));

      expect(find.byKey(_cardKey('first')), findsOneWidget);
    });

    testWidgets('when dragging up at threshold, it should advance to the next item', (tester) async {
      await _pumpFeed(tester);

      await _dragCard(tester, 'first', const Offset(0, -160));

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when dragging up over threshold, it should advance to the next item', (tester) async {
      await _pumpFeed(tester);

      await _dragCard(tester, 'first', const Offset(0, -300));

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when advancing next, it should call onNext with the dismissed item', (tester) async {
      final nextLogs = <_ItemLog<String>>[];

      await _pumpFeed(tester, onNext: (item, index) => nextLogs.add((item: item, index: index)));

      await _dragCard(tester, 'first', const Offset(0, -300));

      expect(nextLogs.single.item, 'first');
    });

    testWidgets('when advancing next, it should call onNext with the dismissed index', (tester) async {
      final nextLogs = <_ItemLog<String>>[];

      await _pumpFeed(tester, onNext: (item, index) => nextLogs.add((item: item, index: index)));

      await _dragCard(tester, 'first', const Offset(0, -300));

      expect(nextLogs.single.index, 0);
    });

    testWidgets('when advancing multiple cards, it should advance in list order', (tester) async {
      await _pumpFeed(tester);

      await _dragCurrentCard(tester, const Offset(0, -300));
      await _dragCurrentCard(tester, const Offset(0, -300));

      expect(_currentCardLabel(tester), 'third');
    });

    testWidgets('when advancing the final card, it should render the end state', (tester) async {
      await _pumpFeed(tester, items: const ['first']);

      await _dragCard(tester, 'first', const Offset(0, -300));

      expect(find.byKey(_endKey), findsOneWidget);
    });

    testWidgets('when advancing next, it should not call onPrevious', (tester) async {
      final previousLogs = <_ItemLog<String>>[];

      await _pumpFeed(
        tester,
        onPrevious: (item, index) => previousLogs.add((item: item, index: index)),
      );

      await _dragCard(tester, 'first', const Offset(0, -300));

      expect(previousLogs, isEmpty);
    });
  });

  group('QuiTikTokFeed previous (down swipe)', () {
    testWidgets('when dragging down below threshold from index > 0, it should keep the same current item', (
      tester,
    ) async {
      await _pumpFeed(tester);

      await _dragCurrentCard(tester, const Offset(0, 80));
      await _dragCurrentCard(tester, const Offset(0, -300)); // advance to second

      await _dragCard(tester, 'second', const Offset(0, 80));

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when dragging down at threshold from index > 0, it should go back to the previous item', (
      tester,
    ) async {
      await _pumpFeed(tester);

      await _dragCurrentCard(tester, const Offset(0, -300)); // advance to second

      await _dragCard(tester, 'second', const Offset(0, 160));

      expect(_currentCardLabel(tester), 'first');
    });

    testWidgets('when dragging down over threshold from index > 0, it should go back to the previous item', (
      tester,
    ) async {
      await _pumpFeed(tester);

      await _dragCurrentCard(tester, const Offset(0, -300)); // advance to second

      await _dragCard(tester, 'second', const Offset(0, 300));

      expect(_currentCardLabel(tester), 'first');
    });

    testWidgets('when at index 0 and dragging down, it should keep the same current item', (tester) async {
      await _pumpFeed(tester);

      await _dragCard(tester, 'first', const Offset(0, 300));

      expect(_currentCardLabel(tester), 'first');
    });

    testWidgets('when going back, it should call onPrevious with the left-behind item', (tester) async {
      final previousLogs = <_ItemLog<String>>[];

      await _pumpFeed(
        tester,
        onPrevious: (item, index) => previousLogs.add((item: item, index: index)),
      );

      await _dragCurrentCard(tester, const Offset(0, -300)); // advance to second

      await _dragCard(tester, 'second', const Offset(0, 300));

      expect(previousLogs.single.item, 'second');
    });

    testWidgets('when going back, it should call onPrevious with the left-behind index', (tester) async {
      final previousLogs = <_ItemLog<String>>[];

      await _pumpFeed(
        tester,
        onPrevious: (item, index) => previousLogs.add((item: item, index: index)),
      );

      await _dragCurrentCard(tester, const Offset(0, -300)); // advance to second

      await _dragCard(tester, 'second', const Offset(0, 300));

      expect(previousLogs.single.index, 1);
    });

    testWidgets('when going back, it should not call onNext', (tester) async {
      final nextLogs = <_ItemLog<String>>[];

      await _pumpFeed(tester, onNext: (item, index) => nextLogs.add((item: item, index: index)));

      await _dragCurrentCard(tester, const Offset(0, -300)); // advance to second

      await _dragCard(tester, 'second', const Offset(0, 300));

      expect(nextLogs, hasLength(1)); // only the forward advance, not the back
    });
  });

  group('QuiTikTokFeed fling velocity', () {
    testWidgets('when flinging up with velocity above threshold, it should advance even below progress threshold', (
      tester,
    ) async {
      await _pumpFeed(tester);

      await tester.fling(find.byKey(_cardKey('first')), const Offset(0, -50), 900);

      await tester.pumpAndSettle();

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when flinging down with velocity above threshold from index > 0, it should go back', (
      tester,
    ) async {
      await _pumpFeed(tester);

      await _dragCurrentCard(tester, const Offset(0, -300)); // advance to second

      await tester.fling(find.byKey(_cardKey('second')), const Offset(0, 50), 900);

      await tester.pumpAndSettle();

      expect(_currentCardLabel(tester), 'first');
    });

    testWidgets('when flinging with low velocity below threshold, it should snap back', (tester) async {
      await _pumpFeed(tester);

      await tester.fling(find.byKey(_cardKey('first')), const Offset(0, -80), 400);

      await tester.pumpAndSettle();

      expect(_currentCardLabel(tester), 'first');
    });
  });

  group('QuiTikTokFeed controller', () {
    testWidgets('when controller.next is called, it should advance to the next item', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller);
      final nextFuture = controller.next();
      await tester.pumpAndSettle();
      await nextFuture;

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when controller.next is called, it should call onNext with the current item', (tester) async {
      final controller = QuiTikTokFeedController();
      final nextLogs = <_ItemLog<String>>[];

      await _pumpFeed(
        tester,
        controller: controller,
        onNext: (item, index) => nextLogs.add((item: item, index: index)),
      );
      final nextFuture = controller.next();
      await tester.pumpAndSettle();
      await nextFuture;

      expect(nextLogs.single.item, 'first');
    });

    testWidgets('when controller.next is called, it should call onNext with the current index', (tester) async {
      final controller = QuiTikTokFeedController();
      final nextLogs = <_ItemLog<String>>[];

      await _pumpFeed(
        tester,
        controller: controller,
        onNext: (item, index) => nextLogs.add((item: item, index: index)),
      );
      final nextFuture = controller.next();
      await tester.pumpAndSettle();
      await nextFuture;

      expect(nextLogs.single.index, 0);
    });

    testWidgets('when controller.next is called on the final item, it should render endBuilder', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['first']);
      final nextFuture = controller.next();
      await tester.pumpAndSettle();
      await nextFuture;

      expect(find.byKey(_endKey), findsOneWidget);
    });

    testWidgets('when controller.next is called with no current item, it should return false', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const []);
      final result = await controller.next();

      expect(result, isFalse);
    });

    testWidgets('when controller.next is called while detached, it should return false', (tester) async {
      final controller = QuiTikTokFeedController();

      final result = await controller.next();

      expect(result, isFalse);
    });

    testWidgets('when controller.next is called, it should report progress during animation', (tester) async {
      final controller = QuiTikTokFeedController();
      final progressLogs = <_ProgressLog>[];

      await _pumpFeed(
        tester,
        controller: controller,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );
      final nextFuture = controller.next();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 120));

      expect(progressLogs.map((log) => log.percentage), contains(predicate<double>((value) => value > 0.3)));

      await tester.pumpAndSettle();
      await nextFuture;
    });

    testWidgets('when reduced motion is enabled, controller.next should advance immediately', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, disableAnimations: true);
      await controller.next();
      await tester.pump();

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when controller.previous is called, it should go back to the previous item', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller);
      final nextFuture = controller.next();
      await tester.pumpAndSettle();
      await nextFuture;
      final previousFuture = controller.previous();
      await tester.pumpAndSettle();
      await previousFuture;

      expect(_currentCardLabel(tester), 'first');
    });

    testWidgets('when controller.previous is called, it should call onPrevious with the current item', (
      tester,
    ) async {
      final controller = QuiTikTokFeedController();
      final previousLogs = <_ItemLog<String>>[];

      await _pumpFeed(
        tester,
        controller: controller,
        onPrevious: (item, index) => previousLogs.add((item: item, index: index)),
      );
      final nextFuture = controller.next();
      await tester.pumpAndSettle();
      await nextFuture;
      final previousFuture = controller.previous();
      await tester.pumpAndSettle();
      await previousFuture;

      expect(previousLogs.single.item, 'second');
    });

    testWidgets('when controller.previous is called at index 0, it should return false', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['first']);
      final result = await controller.previous();

      expect(result, isFalse);
    });

    testWidgets('when controller.previous is called while detached, it should return false', (tester) async {
      final controller = QuiTikTokFeedController();

      final result = await controller.previous();

      expect(result, isFalse);
    });

    testWidgets('when controller.previous is called, it should not call onNext', (tester) async {
      final controller = QuiTikTokFeedController();
      final nextLogs = <_ItemLog<String>>[];

      await _pumpFeed(
        tester,
        controller: controller,
        onNext: (item, index) => nextLogs.add((item: item, index: index)),
      );
      final nextFuture = controller.next();
      await tester.pumpAndSettle();
      await nextFuture;
      final previousFuture = controller.previous();
      await tester.pumpAndSettle();
      await previousFuture;

      expect(nextLogs, hasLength(1)); // only the forward call
    });

    testWidgets('when a controller action is already running, it should return false for a second action',
      (tester) async {
        final controller = QuiTikTokFeedController();

        await _pumpFeed(tester, controller: controller);
        final nextFuture = controller.next();
        await tester.pump();
        final result = await controller.next();

        expect(result, isFalse);

        await tester.pumpAndSettle();
        await nextFuture;
      },
    );

    testWidgets('when the widget swaps controllers, it should detach the old one and use the new one', (
      tester,
    ) async {
      final firstController = QuiTikTokFeedController();
      final secondController = QuiTikTokFeedController();

      await tester.pumpWidget(
        _ControllerSwapHost(firstController: firstController, secondController: secondController),
      );
      await tester.tap(find.byKey(_swapControllerButtonKey));
      await tester.pumpAndSettle();
      final oldResult = await firstController.next();
      final newResultFuture = secondController.next();
      await tester.pumpAndSettle();
      final newResult = await newResultFuture;

      expect(
        (oldResult: oldResult, newResult: newResult, label: _currentCardLabel(tester)),
        (oldResult: false, newResult: true, label: 'second'),
      );
    });
  });

  group('QuiTikTokFeed swipe progress', () {
    testWidgets('when dragging up, it should report QuiTikTokFeedAction.next', (tester) async {
      final progressLogs = <_ProgressLog>[];

      await _pumpFeed(
        tester,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );

      await _dragCard(tester, 'first', const Offset(0, -200));

      expect(progressLogs.first.action, QuiTikTokFeedAction.next);
    });

    testWidgets('when dragging down, it should report QuiTikTokFeedAction.previous', (tester) async {
      final progressLogs = <_ProgressLog>[];

      await _pumpFeed(
        tester,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );

      await _dragCurrentCard(tester, const Offset(0, -300)); // advance to second

      await _dragCard(tester, 'second', const Offset(0, 200));

      expect(progressLogs.last.action, QuiTikTokFeedAction.previous);
    });

    testWidgets('when dragging halfway across the height, it should report percentage close to 0.5', (tester) async {
      final progressLogs = <_ProgressLog>[];

      await _pumpFeed(
        tester,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );

      await _dragCard(tester, 'first', const Offset(0, -300));

      expect(progressLogs.map((log) => log.percentage), contains(closeTo(0.5, 0.01)));
    });

    testWidgets('when dragging beyond the full height, it should clamp percentage to 1.0', (tester) async {
      final progressLogs = <_ProgressLog>[];

      await _pumpFeed(
        tester,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );

      await _dragCard(tester, 'first', const Offset(0, -700));

      expect(progressLogs.map((log) => log.percentage), contains(1));
    });

    testWidgets('when snapping back after an incomplete swipe, it should report a final percentage of 0.0', (
      tester,
    ) async {
      final progressLogs = <_ProgressLog>[];

      await _pumpFeed(
        tester,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );

      await _dragCard(tester, 'first', const Offset(0, -80));

      expect(progressLogs.last.percentage, 0);
    });

    testWidgets('when committing next with animation enabled, it should report progress during the exit animation', (
      tester,
    ) async {
      final progressLogs = <_ProgressLog>[];

      await _pumpFeed(
        tester,
        onSwipeProgress: ({required action, required percentage}) {
          progressLogs.add((action: action, percentage: percentage));
        },
      );

      await tester.drag(find.byKey(_cardKey('first')), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 120));

      expect(progressLogs.map((log) => log.percentage), contains(predicate<double>((value) => value > 0.45)));
    });
  });

  group('QuiTikTokFeed assertion validation', () {
    testWidgets('when items.count is negative, it should throw an assertion error', (tester) async {
      expect(
        () => QuiTikTokFeed<String>(
          items: (count: -1, provider: (i) => 'item'),
          builder: _defaultCardBuilder,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('when loadMoreThreshold is below 0, it should throw an assertion error', (tester) async {
      expect(
        () => QuiTikTokFeed<String>(
          items: (count: 0, provider: (i) => 'item'),
          loadMoreThreshold: -0.1,
          builder: _defaultCardBuilder,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('when loadMoreThreshold is above 1, it should throw an assertion error', (tester) async {
      expect(
        () => QuiTikTokFeed<String>(
          items: (count: 0, provider: (i) => 'item'),
          loadMoreThreshold: 1.1,
          builder: _defaultCardBuilder,
        ),
        throwsAssertionError,
      );
    });
  });

  group('QuiTikTokFeed widget lifecycle and updates', () {
    testWidgets('when the parent rebuilds with the same items, it should preserve the current index', (tester) async {
      await tester.pumpWidget(const _MutableFeedHost());
      await _dragCard(tester, 'first', const Offset(0, -300));

      await tester.tap(find.byKey(_rebuildButtonKey));
      await tester.pumpAndSettle();

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when the parent shrinks the items list below the current index, it should render the end state', (
      tester,
    ) async {
      await tester.pumpWidget(const _MutableFeedHost());
      await _dragCard(tester, 'first', const Offset(0, -300));

      await tester.tap(find.byKey(_shrinkButtonKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_endKey), findsOneWidget);
    });

    testWidgets('when the parent replaces items before any swipe, it should render the replacement current item', (
      tester,
    ) async {
      await tester.pumpWidget(const _MutableFeedHost());

      await tester.tap(find.byKey(_replaceButtonKey));
      await tester.pumpAndSettle();

      expect(_currentCardLabel(tester), 'replacement');
    });

    testWidgets('when the widget is removed during an animation, it should dispose without throwing', (tester) async {
      await tester.pumpWidget(const _MutableFeedHost());

      await tester.drag(find.byKey(_cardKey('first')), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.byKey(_hideButtonKey));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'when a drag starts during snap-back animation, it should stop the old animation and follow the new drag',
      (tester) async {
        final nextLogs = <_ItemLog<String>>[];

        await _pumpFeed(tester, onNext: (item, index) => nextLogs.add((item: item, index: index)));

        await tester.drag(find.byKey(_cardKey('first')), const Offset(0, -120));
        await tester.pump(const Duration(milliseconds: 40));
        await tester.drag(find.byKey(_cardKey('first')), const Offset(0, -180));
        await tester.pumpAndSettle();

        expect(nextLogs, hasLength(1));
      },
    );
  });

  group('QuiTikTokFeed state preservation', () {
    testWidgets('when cards are stateful, advancing should not leak old card state into the new current card', (
      tester,
    ) async {
      await _pumpStatefulFeed(tester);

      await tester.tap(find.byKey(_stateButtonKey('first')));
      await tester.pumpAndSettle();
      await _dragCard(tester, 'first', const Offset(0, -300));

      expect(find.text('second:0'), findsOneWidget);
    });

    testWidgets('when the next card becomes current after advancing, it should not recreate the card widget', (
      tester,
    ) async {
      final creations = <String>[];

      await _pumpTypedFeed<String>(
        tester,
        items: const ['first', 'second', 'third'],
        builder: (context, item, index) => _CreationTrackingCard(label: item, onCreate: creations.add),
      );
      creations.clear();

      await _dragCard(tester, 'first', const Offset(0, -300));

      expect(creations, isNot(contains('second')));
    });
  });

  group('QuiTikTokFeed reduced motion', () {
    testWidgets(
      'when MediaQuery.disableAnimations is true and an up swipe completes, it should advance immediately',
      (tester) async {
        await _pumpFeed(tester, disableAnimations: true);

        await tester.drag(find.byKey(_cardKey('first')), const Offset(0, -300));
        await tester.pump();

        expect(_currentCardLabel(tester), 'second');
      },
    );

    testWidgets(
      'when MediaQuery.disableAnimations is true and a down swipe completes, it should go back immediately',
      (tester) async {
        await _pumpFeed(tester, disableAnimations: true);

        await tester.drag(find.byKey(_cardKey('first')), const Offset(0, -300));
        await tester.pump();
        await tester.drag(find.byKey(_cardKey('second')), const Offset(0, 300));
        await tester.pump();

        expect(_currentCardLabel(tester), 'first');
      },
    );

    testWidgets('when reduced motion is enabled, callbacks should still fire with the correct item', (tester) async {
      final nextLogs = <_ItemLog<String>>[];

      await _pumpFeed(
        tester,
        disableAnimations: true,
        onNext: (item, index) => nextLogs.add((item: item, index: index)),
      );

      await tester.drag(find.byKey(_cardKey('first')), const Offset(0, -300));
      await tester.pump();

      expect(nextLogs.single.item, 'first');
    });

    testWidgets('when reduced motion is enabled, callbacks should still fire with the correct index', (tester) async {
      final nextLogs = <_ItemLog<String>>[];

      await _pumpFeed(
        tester,
        disableAnimations: true,
        onNext: (item, index) => nextLogs.add((item: item, index: index)),
      );

      await tester.drag(find.byKey(_cardKey('first')), const Offset(0, -300));
      await tester.pump();

      expect(nextLogs.single.index, 0);
    });
  });

  group('QuiTikTokFeed pagination', () {
    testWidgets('when loadMoreThreshold is 1.0, it should load only at the last loaded card', (tester) async {
      var loadMoreCount = 0;

      await _pumpFeed(tester, onLoadMore: () async => loadMoreCount += 1);
      await _dragCurrentCard(tester, const Offset(0, -300));
      await _dragCurrentCard(tester, const Offset(0, -300));
      await tester.pump();

      expect(loadMoreCount, 1);
    });

    testWidgets('when loadMoreThreshold is 0.8, it should load before the last loaded card', (tester) async {
      var loadMoreCount = 0;

      await _pumpFeed(
        tester,
        items: const ['first', 'second', 'third', 'fourth', 'fifth'],
        loadMoreThreshold: 0.8,
        onLoadMore: () async => loadMoreCount += 1,
      );
      await _dragCurrentCard(tester, const Offset(0, -300));
      await _dragCurrentCard(tester, const Offset(0, -300));
      await _dragCurrentCard(tester, const Offset(0, -300));
      await tester.pump();

      expect(loadMoreCount, 1);
    });

    testWidgets('when loading is pending, it should skip duplicate load calls', (tester) async {
      final loadCompleter = Completer<void>();
      var loadMoreCount = 0;

      await _pumpFeed(
        tester,
        loadMoreThreshold: 0.8,
        loadingMoreBuilder: _loadingMoreBuilder,
        onLoadMore: () {
          loadMoreCount += 1;

          return loadCompleter.future;
        },
      );
      await _dragCurrentCard(tester, const Offset(0, -300));
      await _dragCurrentCard(tester, const Offset(0, -300));
      await tester.pump();
      await tester.pump();

      expect(loadMoreCount, 1);
    });

    testWidgets('when load completes without increased itemCount, it should stop further automatic calls', (
      tester,
    ) async {
      var loadMoreCount = 0;

      await _pumpFeed(tester, items: const ['first'], onLoadMore: () async => loadMoreCount += 1);
      await tester.pump();
      await _dragCard(tester, 'first', const Offset(0, -300));
      await tester.pump();

      expect(loadMoreCount, 1);
    });

    testWidgets('when itemCount increases after load completion, it should clear exhausted state', (tester) async {
      await tester.pumpWidget(const _PaginatedFeedHost());
      await tester.pump();
      await tester.tap(find.byKey(_appendButtonKey));
      await tester.pumpAndSettle();
      await _dragCard(tester, 'first', const Offset(0, -300));

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when loadMoreErrorBuilder is provided, it should render load-more error at the end', (tester) async {
      await _pumpFeed(tester, items: const ['first'], loadMoreErrorBuilder: _loadMoreErrorBuilder);
      await _dragCard(tester, 'first', const Offset(0, -300));

      expect(find.byKey(_loadMoreErrorKey), findsOneWidget);
    });

    testWidgets('when loadMoreErrorBuilder is provided, it should prevent automatic load-more calls', (tester) async {
      var loadMoreCount = 0;

      await _pumpFeed(
        tester,
        items: const ['first'],
        onLoadMore: () async => loadMoreCount += 1,
        loadMoreErrorBuilder: _loadMoreErrorBuilder,
      );
      await tester.pump();

      expect(loadMoreCount, 0);
    });

    testWidgets('when tapping retry in loadMoreErrorBuilder, it should call onLoadMore', (tester) async {
      var loadMoreCount = 0;

      await _pumpFeed(
        tester,
        items: const ['first'],
        onLoadMore: () async => loadMoreCount += 1,
        loadMoreErrorBuilder: _loadMoreErrorBuilder,
      );
      await _dragCard(tester, 'first', const Offset(0, -300));
      await tester.tap(find.byKey(_loadMoreRetryKey));
      await tester.pumpAndSettle();

      expect(loadMoreCount, 1);
    });

    testWidgets('when no next real card exists while loading, it should render loadingMoreBuilder', (tester) async {
      final loadCompleter = Completer<void>();

      await _pumpFeed(
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
      await _pumpFeed(tester, items: const ['first'], onLoadMore: () async {}, endBuilder: _endBuilder);
      await tester.pump();
      await _dragCard(tester, 'first', const Offset(0, -300));

      expect(find.byKey(_endKey), findsOneWidget);
    });

    testWidgets(
      'when swiping the last card after pagination is exhausted, it should show the end card behind the outgoing card during the dismiss animation',
      (tester) async {
        await _pumpFeed(
          tester,
          items: const ['first'],
          onLoadMore: () async {},
          endBuilder: _endBuilder,
        );
        await tester.pump();
        await tester.pump();

        await tester.drag(find.byKey(_cardKey('first')), const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byKey(_endKey), findsOneWidget);
      },
    );

    testWidgets(
      'when the last card is dismissed while loading more, it should preserve the loading card state across the transition',
      (tester) async {
        var initStateCallCount = 0;

        await _pumpFeed(
          tester,
          items: const ['first'],
          onLoadMore: () => Completer<void>().future,
          loadingMoreBuilder: (context) => _InitTrackingWidget(onInit: () => initStateCallCount += 1),
        );
        await tester.pump();
        await tester.pump();

        expect(initStateCallCount, 1);

        await _dragCard(tester, 'first', const Offset(0, -300));

        expect(initStateCallCount, 1);
      },
    );

    testWidgets('when loadMoreThreshold is below 0, it should throw an assertion error', (tester) async {
      expect(
        () => QuiTikTokFeed<String>(
          items: (count: 0, provider: (i) => 'item'),
          loadMoreThreshold: -0.1,
          builder: _defaultCardBuilder,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('when loadMoreThreshold is above 1, it should throw an assertion error', (tester) async {
      expect(
        () => QuiTikTokFeed<String>(
          items: (count: 0, provider: (i) => 'item'),
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

      await _pumpTypedFeed<int>(
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

  group('QuiTikTokFeed haptic feedback', () {
    testWidgets('when committing next via gesture, it should emit a selectionClick haptic', (tester) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
        if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);

        return null;
      });

      await _pumpFeed(tester);

      await tester.drag(find.byType(GestureDetector), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(hapticCalls, isNotEmpty);
    });

    testWidgets('when committing next, it should use the selectionClick haptic type', (tester) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
        if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);

        return null;
      });

      await _pumpFeed(tester);

      await tester.drag(find.byType(GestureDetector), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(hapticCalls.first.arguments, 'HapticFeedbackType.selectionClick');
    });

    testWidgets('when enableHapticFeedback is false, committing next should not emit haptic', (tester) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
        if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);

        return null;
      });

      await _pumpFeed(tester, enableHapticFeedback: false);

      await tester.drag(find.byType(GestureDetector), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(hapticCalls, isEmpty);
    });

    testWidgets('when dragging without committing, it should emit only the start haptic', (tester) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
        if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);

        return null;
      });

      await _pumpFeed(tester);

      await tester.drag(find.byType(GestureDetector), const Offset(0, -80));
      await tester.pumpAndSettle();

      expect(hapticCalls, hasLength(1));
    });

    testWidgets('when swiping down, it should NOT emit a haptic', (tester) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
        if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);

        return null;
      });

      await _pumpFeed(tester);

      await _dragCurrentCard(tester, const Offset(0, -300)); // advance to second
      await tester.pumpAndSettle();
      hapticCalls.clear();

      await tester.drag(find.byType(GestureDetector), const Offset(0, 100));
      await tester.pumpAndSettle();

      expect(hapticCalls, isEmpty);
    });

    testWidgets('when a controller next is triggered, it should emit a settle haptic', (tester) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
        if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);

        return null;
      });

      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller);
      final nextFuture = controller.next();
      await tester.pumpAndSettle();
      await nextFuture;

      expect(hapticCalls, isNotEmpty);
    });
  });
}

const _feedSize = Size(400, 600);
const _rebuildButtonKey = Key('rebuild_button');
const _shrinkButtonKey = Key('shrink_button');
const _replaceButtonKey = Key('replace_button');
const _hideButtonKey = Key('hide_button');
const _appendButtonKey = Key('append_button');
const _swapControllerButtonKey = Key('swap_controller_button');
const _loadingKey = Key('qui_tiktok_feed_loading');
const _loadMoreErrorKey = Key('qui_tiktok_feed_load_more_error');
const _loadMoreRetryKey = Key('qui_tiktok_feed_load_more_retry');
const _endKey = Key('qui_tiktok_feed_end');

Key _cardKey(String item) => Key('card_$item');

Key _stateButtonKey(String item) => Key('state_button_$item');

Future<void> _pumpFeed(
  WidgetTester tester, {
  List<String> items = const ['first', 'second', 'third'],
  bool includeEndBuilder = true,
  bool disableAnimations = false,
  bool enableHapticFeedback = true,
  double loadMoreThreshold = 1,
  QuiTikTokFeedController? controller,
  void Function({required QuiTikTokFeedAction action, required double percentage})? onSwipeProgress,
  QuiTikTokFeedItemCallback<String>? onNext,
  QuiTikTokFeedItemCallback<String>? onPrevious,
  Future<void> Function()? onLoadMore,
  WidgetBuilder? loadingMoreBuilder,
  Widget Function(BuildContext, VoidCallback)? loadMoreErrorBuilder,
  WidgetBuilder? endBuilder,
}) {
  return tester.pumpWidget(
    _HarnessApp(
      disableAnimations: disableAnimations,
      child: QuiTikTokFeed<String>(
        items: (count: items.length, provider: (i) => items[i]),
        loadMoreThreshold: loadMoreThreshold,
        enableHapticFeedback: enableHapticFeedback,
        controller: controller,
        onSwipeProgress: onSwipeProgress,
        onNext: onNext,
        onPrevious: onPrevious,
        onLoadMore: onLoadMore,
        loadingMoreBuilder: loadingMoreBuilder,
        loadMoreErrorBuilder: loadMoreErrorBuilder,
        endBuilder: includeEndBuilder ? endBuilder ?? _endBuilder : null,
        builder: _defaultCardBuilder,
      ),
    ),
  );
}

Future<void> _pumpTypedFeed<T>(
  WidgetTester tester, {
  required Widget Function(BuildContext context, T item, int index) builder,
  List<T>? items,
  int? itemCount,
  T Function(int index)? itemProvider,
  Future<void> Function()? onLoadMore,
}) {
  final providedItems = items;

  return tester.pumpWidget(
    _HarnessApp(
      child: QuiTikTokFeed<T>(
        items: (
          count: itemCount ?? providedItems!.length,
          provider: itemProvider ?? (index) => providedItems![index],
        ),
        onLoadMore: onLoadMore,
        endBuilder: _endBuilder,
        builder: builder,
      ),
    ),
  );
}

Future<void> _pumpStatefulFeed(WidgetTester tester) {
  return tester.pumpWidget(
    _HarnessApp(
      child: QuiTikTokFeed<String>(
        items: (count: 2, provider: (i) => const ['first', 'second'][i]),
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
    of: find.byType(QuiTikTokFeed<String>),
    matching: find.byType(GestureDetector),
  );
  final texts = tester.widgetList<Text>(
    find.descendant(of: activeGestureDetector, matching: find.byType(Text)),
  );

  return texts.last.data ?? '';
}

Widget _defaultCardBuilder(BuildContext context, String item, int index) {
  return _TestCard(label: item);
}

Widget _loadingMoreBuilder(BuildContext context) {
  return const Center(child: Text('Loading more', key: _loadingKey));
}

Widget _loadMoreErrorBuilder(BuildContext context, VoidCallback retry) {
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
            child: SizedBox.fromSize(size: _feedSize, child: child),
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

  final QuiTikTokFeedController firstController;
  final QuiTikTokFeedController secondController;

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
            child: QuiTikTokFeed<String>(
              controller: _useSecondController ? widget.secondController : widget.firstController,
              items: (count: 2, provider: (i) => const ['first', 'second'][i]),
              endBuilder: _endBuilder,
              builder: _defaultCardBuilder,
            ),
          ),
        ],
      ),
    );
  }
}

class _MutableFeedHost extends StatefulWidget {
  const _MutableFeedHost();

  @override
  State<_MutableFeedHost> createState() => _MutableFeedHostState();
}

class _MutableFeedHostState extends State<_MutableFeedHost> {
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
                ? QuiTikTokFeed<String>(
                    items: (count: _items.length, provider: (i) => _items[i]),
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

class _PaginatedFeedHost extends StatefulWidget {
  const _PaginatedFeedHost();

  @override
  State<_PaginatedFeedHost> createState() => _PaginatedFeedHostState();
}

class _PaginatedFeedHostState extends State<_PaginatedFeedHost> {
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
            child: QuiTikTokFeed<String>(
              items: (count: _items.length, provider: (i) => _items[i]),
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

class _CreationTrackingCard extends StatefulWidget {
  const _CreationTrackingCard({required this.label, required this.onCreate});

  final String label;
  final void Function(String label) onCreate;

  @override
  State<_CreationTrackingCard> createState() => _CreationTrackingCardState();
}

class _CreationTrackingCardState extends State<_CreationTrackingCard> {
  @override
  void initState() {
    super.initState();
    widget.onCreate(widget.label);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _cardKey(widget.label),
      alignment: Alignment.center,
      color: Colors.white,
      child: Text(widget.label),
    );
  }
}

class _InitTrackingWidget extends StatefulWidget {
  const _InitTrackingWidget({required this.onInit});

  final VoidCallback onInit;

  @override
  State<_InitTrackingWidget> createState() => _InitTrackingWidgetState();
}

class _InitTrackingWidgetState extends State<_InitTrackingWidget> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Loading'));
  }
}
