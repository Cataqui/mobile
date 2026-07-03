import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHero.background', () {
    testWidgets('when building at rest, it should wrap the child in a Hero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: QuiHero.background(
                tag: 'test',
                decoration: const BoxDecoration(color: Colors.white),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('when building at rest, it should not add a repaint boundary to the feed tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: QuiHero.background(
                tag: 'test',
                decoration: const BoxDecoration(color: Colors.white),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      final hero = tester.widget<Hero>(find.byType(Hero));
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
              child: QuiHero.background(
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
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: QuiHero.background(
                tag: 'test',
                decoration: const BoxDecoration(color: Colors.white),
                child: const Text('hello'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('when building with padding, it should wrap the child in a Padding widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: QuiHero.background(
                tag: 'test',
                decoration: const BoxDecoration(color: Colors.white),
                padding: const EdgeInsets.all(24),
                child: const Text('hello'),
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
        MaterialApp(
          home: Scaffold(
            body: QuiHero.background(
              tag: 'test',
              decoration: const BoxDecoration(color: Colors.white),
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
        MaterialApp(
          home: Scaffold(
            body: QuiHero.background(
              tag: 'test',
              decoration: const BoxDecoration(color: Colors.white),
              extensions: const [_QuiHeroKeyedExtension(key: extensionKey)],
              child: const Text('hello'),
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
        MaterialApp(
          home: Scaffold(
            body: QuiHero.background(
              tag: 'test',
              decoration: const BoxDecoration(color: Colors.white),
              extensions: const [
                _QuiHeroKeyedExtension(key: outerExtensionKey),
                _QuiHeroKeyedExtension(key: innerExtensionKey),
              ],
              child: const Text('hello'),
            ),
          ),
        ),
      );

      expect(find.ancestor(of: find.byKey(innerExtensionKey), matching: find.byKey(outerExtensionKey)), findsOneWidget);
    });
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
