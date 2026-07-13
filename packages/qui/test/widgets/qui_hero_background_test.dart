import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHero.background', () {
    testWidgets('when building at rest, it should wrap the child in a Hero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: QuiHeroBackground(
                tag: 'test',
                decoration: BoxDecoration(color: Colors.white),
                child: SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Hero), findsNWidgets(2));
    });

    testWidgets('when building at rest, it should not add a repaint boundary to the feed tree', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: QuiHeroBackground(
                tag: 'test',
                decoration: BoxDecoration(color: Colors.white),
                child: SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      final hero = tester.widget<Hero>(find.byType(Hero).first);
      expect(hero.child, isNot(isA<RepaintBoundary>()));
    });

    testWidgets('when building with a decoration, it should render a DecoratedBox with that decoration', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: QuiHeroBackground(
                tag: 'test',
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(38)),
              ),
            ),
          ),
        ),
      );

      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final boxDecoration = decoratedBox.decoration as BoxDecoration;
      expect(boxDecoration.color, equals(Colors.white));
      expect(boxDecoration.borderRadius, equals(BorderRadius.circular(38)));
    });

    testWidgets('when building with a child, it should render the child inside the box', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: QuiHeroBackground(
                tag: 'test',
                decoration: BoxDecoration(color: Colors.white),
                child: Text('hello'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('when building with padding, it should wrap the child in a Padding widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: QuiHeroBackground(
                tag: 'test',
                decoration: BoxDecoration(color: Colors.white),
                padding: EdgeInsets.all(24),
                child: Text('hello'),
              ),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, equals(const EdgeInsets.all(24)));
    });

    testWidgets('when building with width, it should constrain the width via SizedBox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuiHeroBackground(
              tag: 'test',
              decoration: BoxDecoration(color: Colors.white),
              width: 300,
            ),
          ),
        ),
      );

      final sizedBoxes = find.byType(SizedBox).evaluate().map((e) => e.widget as SizedBox);
      final heroSizedBox = sizedBoxes.firstWhere((s) => s.width == 300);
      expect(heroSizedBox.width, equals(300));
    });

    testWidgets('when building with an extension, it should wrap the rendered box content', (tester) async {
      const extensionKey = Key('extension');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuiHeroBackground(
              tag: 'test',
              decoration: BoxDecoration(color: Colors.white),
              extensions: [_QuiHeroKeyedExtension(key: extensionKey)],
              child: Text('hello'),
            ),
          ),
        ),
      );

      expect(find.byKey(extensionKey), findsOneWidget);
    });

    testWidgets('when building with multiple extensions, it should apply the first extension as the outer wrapper', (
      tester,
    ) async {
      const outerExtensionKey = Key('outer-extension');
      const innerExtensionKey = Key('inner-extension');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuiHeroBackground(
              tag: 'test',
              decoration: BoxDecoration(color: Colors.white),
              extensions: [
                _QuiHeroKeyedExtension(key: outerExtensionKey),
                _QuiHeroKeyedExtension(key: innerExtensionKey),
              ],
              child: Text('hello'),
            ),
          ),
        ),
      );

      expect(find.ancestor(of: find.byKey(innerExtensionKey), matching: find.byKey(outerExtensionKey)), findsOneWidget);
    });

    testWidgets(
      'when pushing to a destination background hero and settling, it should invoke only the source callbacks',
      (tester) async {
        final events = <String>[];

        await tester.pumpWidget(_QuiHeroBackgroundLifecycleTestApp(events: events));
        await tester.tap(find.text(_QuiHeroBackgroundLifecycleTestApp.sourceText));
        await tester.pumpAndSettle();

        expect(events, equals(['source-start', 'source-end']));
      },
    );

    testWidgets(
      'when pushing to a destination background hero and settling, it should invoke the destination onReceived callback',
      (tester) async {
        final receivedEvents = <String>[];

        await tester.pumpWidget(
          _QuiHeroBackgroundLifecycleTestApp(events: [], receivedEvents: receivedEvents),
        );
        await tester.tap(find.text(_QuiHeroBackgroundLifecycleTestApp.sourceText));
        await tester.pumpAndSettle();

        expect(receivedEvents, equals(['destination-received']));
      },
    );

  });
}

class _QuiHeroKeyedExtension extends QuiHeroExtension {
  const _QuiHeroKeyedExtension({required this.key});

  final Key key;

  @override
  Widget wrap({required BuildContext context, required Widget child}) {
    return KeyedSubtree(key: key, child: child);
  }
}

class _QuiHeroBackgroundLifecycleTestApp extends StatelessWidget {
  const _QuiHeroBackgroundLifecycleTestApp({required this.events, this.receivedEvents});

  static const sourceText = 'Open background hero';
  static const destinationText = 'Close background hero';

  final List<String> events;
  final List<String>? receivedEvents;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: QuiTheme.light(),
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push<void>(
                    QuiHeroPage(
                      builder: (_) => _QuiHeroBackgroundLifecycleDestination(
                        events: events,
                        receivedEvents: receivedEvents,
                      ),
                    ).createRoute(context),
                  );
                },
                child: QuiHeroBackground(
                  tag: 'background-lifecycle',
                  width: 200,
                  height: 80,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  onStart: () => events.add('source-start'),
                  onEnd: () => events.add('source-end'),
                  onReceived:
                      receivedEvents != null ? () => receivedEvents!.add('source-received') : null,
                  child: const Center(child: Text(sourceText)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuiHeroBackgroundLifecycleDestination extends StatelessWidget {
  const _QuiHeroBackgroundLifecycleDestination({required this.events, this.receivedEvents});

  final List<String> events;
  final List<String>? receivedEvents;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: QuiHeroBackground(
          tag: 'background-lifecycle',
          width: 260,
          height: 120,
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(24)),
          onStart: () => events.add('destination-start'),
          onEnd: () => events.add('destination-end'),
          onReceived:
              receivedEvents != null ? () => receivedEvents!.add('destination-received') : null,
          child: const Center(child: Text(_QuiHeroBackgroundLifecycleTestApp.destinationText)),
        ),
      ),
    );
  }
}
