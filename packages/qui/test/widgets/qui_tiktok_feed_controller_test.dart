import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

typedef _ItemLog<T> = ({T item, int index});
typedef _ProgressLog = ({QuiTikTokFeedAction action, double percentage});

void main() {
  group('QuiTikTokFeedController lifecycle', () {
    testWidgets('when created without a feed, hasClients should be false', (tester) async {
      final controller = QuiTikTokFeedController();

      expect(controller.hasClients, isFalse);
    });

    testWidgets('when attached to a feed, hasClients should be true', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller);

      expect(controller.hasClients, isTrue);
    });

    testWidgets('when the feed is disposed, hasClients should become false', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller);
      await tester.pumpWidget(const SizedBox());

      expect(controller.hasClients, isFalse);
    });

    testWidgets('when the widget swaps controllers, the old controller should lose its client', (tester) async {
      final oldController = QuiTikTokFeedController();
      final newController = QuiTikTokFeedController();

      await tester.pumpWidget(
        _ControllerSwapHost(firstController: oldController, secondController: newController, useSecond: false),
      );
      await tester.pumpAndSettle();

      expect(oldController.hasClients, isTrue);
      expect(newController.hasClients, isFalse);

      await tester.pumpWidget(
        _ControllerSwapHost(firstController: oldController, secondController: newController, useSecond: true),
      );
      await tester.pumpAndSettle();

      expect(oldController.hasClients, isFalse);
      expect(newController.hasClients, isTrue);
    });

    testWidgets('when a detached controller is used, methods should return false', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller);
      await tester.pumpWidget(const SizedBox());

      expect(await controller.next(), isFalse);
      expect(await controller.previous(), isFalse);
    });

    testWidgets('when a controller is reattached after detach, it should work again', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['a', 'b']);
      await tester.pumpWidget(const SizedBox());

      await _pumpFeed(tester, controller: controller, items: const ['a', 'b']);
      await tester.pumpAndSettle();

      expect(controller.hasClients, isTrue);
      final nextFuture = controller.next();
      await tester.pumpAndSettle();
      await nextFuture;

      expect(_currentCardLabel(tester), 'b');
    });

    testWidgets('when one controller is attached to two feeds at the same time, it should throw FlutterError', (
      tester,
    ) async {
      final controller = QuiTikTokFeedController();

      await tester.pumpWidget(
        _HarnessApp(
          child: Column(
            children: [
              Expanded(
                child: QuiTikTokFeed<String>(
                  controller: controller,
                  items: (count: 1, provider: (int i) => const ['a'][i], keyBuilder: null),
                  endBuilder: _endBuilder,
                  builder: _defaultCardBuilder,
                ),
              ),
              Expanded(
                child: QuiTikTokFeed<String>(
                  controller: controller,
                  items: (count: 1, provider: (int i) => const ['b'][i], keyBuilder: null),
                  endBuilder: _endBuilder,
                  builder: _defaultCardBuilder,
                ),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isA<FlutterError>());
    });
  });

  group('QuiTikTokFeedController.next()', () {
    testWidgets('when called, it should advance to the next item', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller);
      final future = controller.next();
      await tester.pumpAndSettle();
      await future;

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when called, it should return true on success', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller);
      final future = controller.next();
      await tester.pumpAndSettle();
      final result = await future;

      expect(result, isTrue);
    });

    testWidgets('when called, it should fire onNext with the correct item', (tester) async {
      final controller = QuiTikTokFeedController();
      final logs = <_ItemLog<String>>[];

      await _pumpFeed(tester, controller: controller, onNext: (item, index) => logs.add((item: item, index: index)));
      final future = controller.next();
      await tester.pumpAndSettle();
      await future;

      expect(logs.single.item, 'first');
    });

    testWidgets('when called, it should fire onNext with the correct index', (tester) async {
      final controller = QuiTikTokFeedController();
      final logs = <_ItemLog<String>>[];

      await _pumpFeed(tester, controller: controller, onNext: (item, index) => logs.add((item: item, index: index)));
      final future = controller.next();
      await tester.pumpAndSettle();
      await future;

      expect(logs.single.index, 0);
    });

    testWidgets('when called on the last real card, it should advance to the terminal page', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['last']);
      final future = controller.next();
      await tester.pumpAndSettle();
      await future;

      expect(find.byKey(_endKey), findsOneWidget);
    });

    testWidgets('when called on the terminal page, it should return false', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['last']);
      final nextF = controller.next();
      await tester.pumpAndSettle();
      await nextF;
      final secondNext = controller.next();
      await tester.pumpAndSettle();
      final result = await secondNext;

      expect(result, isFalse);
    });

    testWidgets('when called with no items, it should return false', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const []);
      final result = await controller.next();

      expect(result, isFalse);
    });

    testWidgets('when called while detached, it should return false', (tester) async {
      final controller = QuiTikTokFeedController();

      final result = await controller.next();

      expect(result, isFalse);
    });

    testWidgets('when called repeatedly, it should advance through all items in order', (tester) async {
      final controller = QuiTikTokFeedController();
      final items = ['a', 'b', 'c'];

      await _pumpFeed(tester, controller: controller, items: items);

      for (var i = 1; i < items.length; i++) {
        final future = controller.next();
        await tester.pumpAndSettle();
        await future;
        expect(_currentCardLabel(tester), items[i]);
      }
    });

    testWidgets('when called, it should report swipe progress during animation', (tester) async {
      final controller = QuiTikTokFeedController();
      final logs = <_ProgressLog>[];

      await _pumpFeed(
        tester,
        controller: controller,
        onSwipeProgress: ({required action, required percentage}) {
          logs.add((action: action, percentage: percentage));
        },
      );
      final future = controller.next();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 120));

      expect(logs.map((l) => l.action), contains(QuiTikTokFeedAction.next));
      expect(logs.map((l) => l.percentage), contains(predicate<double>((v) => v > 0.3)));

      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('when reduce-motion is enabled, it should advance instantly', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, disableAnimations: true);
      await controller.next();
      await tester.pump();

      expect(_currentCardLabel(tester), 'second');
    });

    testWidgets('when reduce-motion is enabled, it should return true', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, disableAnimations: true);
      final result = await controller.next();

      expect(result, isTrue);
    });

    testWidgets('when called, it should emit a settle haptic', (tester) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
        if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);
        return null;
      });

      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller);
      final future = controller.next();
      await tester.pumpAndSettle();
      await future;

      expect(hapticCalls, isNotEmpty);
    });

    testWidgets('when called with enableHapticFeedback false, it should not emit haptic', (tester) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) {
        if (call.method.startsWith('HapticFeedback')) hapticCalls.add(call);
        return null;
      });

      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, enableHapticFeedback: false);
      final future = controller.next();
      await tester.pumpAndSettle();
      await future;

      expect(hapticCalls, isEmpty);
    });
  });

  group('QuiTikTokFeedController.previous()', () {
    testWidgets('when called from index > 0, it should go back to the previous item', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['a', 'b']);
      final nextF = controller.next();
      await tester.pumpAndSettle();
      await nextF;
      final prevF = controller.previous();
      await tester.pumpAndSettle();
      await prevF;

      expect(_currentCardLabel(tester), 'a');
    });

    testWidgets('when called from index > 0, it should return true', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['a', 'b']);
      final nextF = controller.next();
      await tester.pumpAndSettle();
      await nextF;
      final prevF = controller.previous();
      await tester.pumpAndSettle();
      final result = await prevF;

      expect(result, isTrue);
    });

    testWidgets('when called, it should fire onPrevious with the left-behind item', (tester) async {
      final controller = QuiTikTokFeedController();
      final logs = <_ItemLog<String>>[];

      await _pumpFeed(
        tester,
        controller: controller,
        items: const ['a', 'b'],
        onPrevious: (item, index) => logs.add((item: item, index: index)),
      );
      final nextF = controller.next();
      await tester.pumpAndSettle();
      await nextF;
      final prevF = controller.previous();
      await tester.pumpAndSettle();
      await prevF;

      expect(logs.single.item, 'b');
    });

    testWidgets('when called, it should fire onPrevious with the left-behind index', (tester) async {
      final controller = QuiTikTokFeedController();
      final logs = <_ItemLog<String>>[];

      await _pumpFeed(
        tester,
        controller: controller,
        items: const ['a', 'b'],
        onPrevious: (item, index) => logs.add((item: item, index: index)),
      );
      final nextF = controller.next();
      await tester.pumpAndSettle();
      await nextF;
      final prevF = controller.previous();
      await tester.pumpAndSettle();
      await prevF;

      expect(logs.single.index, 1);
    });

    testWidgets('when called from index 0, it should return false', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['a']);
      final result = await controller.previous();

      expect(result, isFalse);
    });

    testWidgets('when called from index 0, it should not change the current item', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['a']);
      await controller.previous();
      await tester.pump();

      expect(_currentCardLabel(tester), 'a');
    });

    testWidgets('when called while detached, it should return false', (tester) async {
      final controller = QuiTikTokFeedController();

      final result = await controller.previous();

      expect(result, isFalse);
    });

    testWidgets('when called, it should NOT fire onNext', (tester) async {
      final controller = QuiTikTokFeedController();
      final logs = <_ItemLog<String>>[];

      await _pumpFeed(
        tester,
        controller: controller,
        items: const ['a', 'b'],
        onNext: (item, index) => logs.add((item: item, index: index)),
      );
      final nextF = controller.next();
      await tester.pumpAndSettle();
      await nextF;
      final prevF = controller.previous();
      await tester.pumpAndSettle();
      await prevF;

      expect(logs, hasLength(1));
    });

    testWidgets('when called, it should emit swipe progress with action.previous', (tester) async {
      final controller = QuiTikTokFeedController();
      final logs = <_ProgressLog>[];

      await _pumpFeed(
        tester,
        controller: controller,
        items: const ['a', 'b'],
        onSwipeProgress: ({required action, required percentage}) => logs.add((action: action, percentage: percentage)),
      );
      final nextF = controller.next();
      await tester.pumpAndSettle();
      await nextF;
      logs.clear();
      final prevF = controller.previous();
      await tester.pumpAndSettle();
      await prevF;

      expect(logs.any((l) => l.action == QuiTikTokFeedAction.previous), isTrue);
    });

    testWidgets('when reduce-motion is enabled, it should go back instantly', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['a', 'b'], disableAnimations: true);
      await controller.next();
      await tester.pump();
      await controller.previous();
      await tester.pump();

      expect(_currentCardLabel(tester), 'a');
    });

    testWidgets('when reduce-motion is enabled, it should return true', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['a', 'b'], disableAnimations: true);
      await controller.next();
      await tester.pump();
      final result = await controller.previous();

      expect(result, isTrue);
    });

    testWidgets('when called from terminal page, it should go back to the last real card', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['last']);
      final nextF = controller.next();
      await tester.pumpAndSettle();
      await nextF;
      final prevF = controller.previous();
      await tester.pumpAndSettle();
      await prevF;

      expect(_currentCardLabel(tester), 'last');
    });

    testWidgets('when called from terminal page, it should NOT fire onPrevious', (tester) async {
      final controller = QuiTikTokFeedController();
      final logs = <_ItemLog<String>>[];

      await _pumpFeed(
        tester,
        controller: controller,
        items: const ['last'],
        onPrevious: (item, index) => logs.add((item: item, index: index)),
      );
      final nextFuture = controller.next();
      await tester.pumpAndSettle();
      await nextFuture;
      final prevFuture = controller.previous();
      await tester.pumpAndSettle();
      await prevFuture;

      expect(logs, isEmpty);
    });
  });

  group('QuiTikTokFeedController concurrency and edge cases', () {
    testWidgets('when next is already running, a second next should return false', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller);
      final firstFuture = controller.next();
      await tester.pump();
      final secondResult = await controller.next();

      expect(secondResult, isFalse);

      await tester.pumpAndSettle();
      await firstFuture;
    });

    testWidgets('when next is already running, previous should return false', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller);
      final nextFuture = controller.next();
      await tester.pump();
      final previousResult = await controller.previous();

      expect(previousResult, isFalse);

      await tester.pumpAndSettle();
      await nextFuture;
    });

    testWidgets('when previous is already running, next should return false', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['a', 'b']);
      final future = controller.next();
      await tester.pumpAndSettle();
      await future; // now at 'b'

      final prevFuture = controller.previous();
      await tester.pump();
      final nextResult = await controller.next();

      expect(nextResult, isFalse);

      await tester.pumpAndSettle();
      await prevFuture;
    });

    testWidgets('when the widget is removed mid-animation, controller should not crash', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller);
      final future = controller.next();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pumpWidget(const SizedBox());

      expect(controller.hasClients, isFalse);
      expect(future, completes);
    });

    testWidgets('when next is called after complete navigation cycle, it should still advance', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['a', 'b', 'c']);
      final firstNext = controller.next();
      await tester.pumpAndSettle();
      await firstNext;
      final secondNext = controller.next();
      await tester.pumpAndSettle();
      await secondNext;

      expect(_currentCardLabel(tester), 'c');
    });

    testWidgets('when next then previous is called sequentially, it should return to the start', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['a', 'b']);
      final nextF = controller.next();
      await tester.pumpAndSettle();
      await nextF;
      final prevF = controller.previous();
      await tester.pumpAndSettle();
      await prevF;

      expect(_currentCardLabel(tester), 'a');
    });

    testWidgets('when next is called multiple times after reaching terminal, it should keep returning false', (
      tester,
    ) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['last']);
      final future = controller.next();
      await tester.pumpAndSettle();
      await future;
      final result1 = await controller.next();
      final result2 = await controller.next();

      expect(result1, isFalse);
      expect(result2, isFalse);
    });

    testWidgets('when previous is called multiple times at index 0, it should keep returning false', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['a']);
      final result1 = await controller.previous();
      final result2 = await controller.previous();

      expect(result1, isFalse);
      expect(result2, isFalse);
    });

    testWidgets('when the widget re-uses the same controller after rebuild, state should persist', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(tester, controller: controller, items: const ['a', 'b', 'c']);
      final future = controller.next();
      await tester.pumpAndSettle();
      await future;

      await _pumpFeed(tester, controller: controller, items: const ['a', 'b', 'c']);
      await tester.pumpAndSettle();

      expect(_currentCardLabel(tester), 'b');
    });
  });

  group('QuiTikTokFeedController with pagination', () {
    testWidgets('when next is called on the last card with onLoadMore set, it should enter await mode', (tester) async {
      final controller = QuiTikTokFeedController();
      final loadCompleter = Completer<void>();

      await _pumpFeed(tester, controller: controller, items: const ['solo'], onLoadMore: () => loadCompleter.future);
      await tester.pump();
      await tester.pump();

      await controller.next();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(find.byKey(_cardKey('solo')), findsOneWidget);
    });

    testWidgets(
      'when next is called on the last card with onLoadMore set and load completes, it should auto-navigate',
      (tester) async {
        final controller = QuiTikTokFeedController();
        final loadCompleter = Completer<void>();

        await _pumpFeed(tester, controller: controller, items: const ['solo'], onLoadMore: () => loadCompleter.future);
        await tester.pump();
        await tester.pump();

        await controller.next();
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        loadCompleter.complete();
        await tester.pump();

        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        expect(find.byKey(_endKey), findsOneWidget);
      },
    );

    testWidgets('when next is called on the last exhausted card, it should show the end state', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(
        tester,
        controller: controller,
        items: const ['solo'],
        onLoadMore: () async {},
        endBuilder: _endBuilder,
      );
      await tester.pump();
      await tester.pump();

      final future = controller.next();
      await tester.pumpAndSettle();
      await future;

      expect(find.byKey(_endKey), findsOneWidget);
      expect(controller.hasClients, isTrue);
    });

    testWidgets('when next is called on a card with loadMoreError, it should show the error card', (tester) async {
      final controller = QuiTikTokFeedController();

      await _pumpFeed(
        tester,
        controller: controller,
        items: const ['solo'],
        loadMoreErrorBuilder: _loadMoreErrorBuilder,
      );
      await tester.pump();

      final future = controller.next();
      await tester.pumpAndSettle();
      await future;

      expect(find.byKey(_loadMoreErrorKey), findsOneWidget);
    });
  });
}

const _feedSize = Size(400, 600);
const _loadMoreErrorKey = Key('qui_tiktok_feed_controller_load_more_error');
const _loadMoreRetryKey = Key('qui_tiktok_feed_controller_retry');
const _endKey = Key('qui_tiktok_feed_controller_end');

Key _cardKey(String item) => Key('card_$item');

Future<void> _pumpFeed(
  WidgetTester tester, {
  List<String> items = const ['first', 'second', 'third'],
  bool disableAnimations = false,
  bool enableHapticFeedback = true,
  double loadMoreThreshold = 1,
  QuiTikTokFeedController? controller,
  void Function({required QuiTikTokFeedAction action, required double percentage})? onSwipeProgress,
  QuiTikTokFeedItemCallback<String>? onNext,
  QuiTikTokFeedItemCallback<String>? onPrevious,
  Future<void> Function()? onLoadMore,
  Widget Function(BuildContext, VoidCallback)? loadMoreErrorBuilder,
  WidgetBuilder? endBuilder,
}) {
  return tester.pumpWidget(
    _HarnessApp(
      disableAnimations: disableAnimations,
      child: QuiTikTokFeed<String>(
        items: (count: items.length, provider: (int i) => items[i], keyBuilder: null),
        loadMoreThreshold: loadMoreThreshold,
        enableHapticFeedback: enableHapticFeedback,
        controller: controller,
        onSwipeProgress: onSwipeProgress,
        onNext: onNext,
        onPrevious: onPrevious,
        onLoadMore: onLoadMore,
        loadMoreErrorBuilder: loadMoreErrorBuilder,
        endBuilder: endBuilder ?? _endBuilder,
        builder: _defaultCardBuilder,
      ),
    ),
  );
}

String _currentCardLabel(WidgetTester tester) {
  final gestureDetector = find.descendant(
    of: find.byType(QuiTikTokFeed<String>),
    matching: find.byType(GestureDetector),
  );
  final texts = tester.widgetList<Text>(find.descendant(of: gestureDetector, matching: find.byType(Text)));
  return texts.first.data ?? '';
}

Widget _defaultCardBuilder(BuildContext context, String item, int index) {
  return _TestCard(label: item);
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

class _ControllerSwapHost extends StatelessWidget {
  const _ControllerSwapHost({required this.firstController, required this.secondController, required this.useSecond});

  final QuiTikTokFeedController firstController;
  final QuiTikTokFeedController secondController;
  final bool useSecond;

  @override
  Widget build(BuildContext context) {
    return _HarnessApp(
      child: QuiTikTokFeed<String>(
        controller: useSecond ? secondController : firstController,
        items: (count: 2, provider: (int i) => const ['a', 'b'][i], keyBuilder: null),
        endBuilder: _endBuilder,
        builder: _defaultCardBuilder,
      ),
    );
  }
}
