import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHero.text', () {
    testWidgets('when building at rest, it should wrap the child in a Hero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuiHeroText('Hello', tag: 'test', style: TextStyle(fontSize: 16)),
          ),
        ),
      );

      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('when building at rest, it should not add a repaint boundary to the feed tree', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuiHeroText('Hello', tag: 'test', style: TextStyle(fontSize: 16)),
          ),
        ),
      );

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.child, isNot(isA<RepaintBoundary>()));
    });

    testWidgets('when inside a bounded width, it should reserve the full row width for the flight', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: QuiHeroText('Hello', tag: 'test', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(Hero)).width, equals(300));
    });

    testWidgets('when building with a custom style, it should display the text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuiHeroText(
              'Test Text',
              tag: 'test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );

      expect(find.text('Test Text'), findsOneWidget);
    });

    testWidgets('when pushing to a destination text hero, it should invoke only the source onStart callback', (
      tester,
    ) async {
      final events = <String>[];

      await tester.pumpWidget(_QuiHeroTextLifecycleTestApp(events: events));
      await tester.tap(find.text(_QuiHeroTextLifecycleTestApp.sourceText));
      await tester.pump();
      await tester.pump();

      expect(events, equals(['source-start']));
    });

    testWidgets(
      'when pushing to a destination text hero and settling, it should invoke only the source onEnd callback',
      (tester) async {
        final events = <String>[];

        await tester.pumpWidget(_QuiHeroTextLifecycleTestApp(events: events));
        await tester.tap(find.text(_QuiHeroTextLifecycleTestApp.sourceText));
        await tester.pumpAndSettle();

        expect(events, equals(['source-start', 'source-end']));
      },
    );

    testWidgets('when popping from a destination text hero, it should invoke only the destination onStart callback', (
      tester,
    ) async {
      final events = <String>[];

      await tester.pumpWidget(_QuiHeroTextLifecycleTestApp(events: events));
      await tester.tap(find.text(_QuiHeroTextLifecycleTestApp.sourceText));
      await tester.pumpAndSettle();
      events.clear();
      await tester.tap(find.text(_QuiHeroTextLifecycleTestApp.destinationText));
      await tester.pump();
      await tester.pump();

      expect(events, equals(['destination-start']));
    });

    testWidgets(
      'when popping from a destination text hero and settling, it should invoke only the destination onEnd callback',
      (tester) async {
        final events = <String>[];

        await tester.pumpWidget(_QuiHeroTextLifecycleTestApp(events: events));
        await tester.tap(find.text(_QuiHeroTextLifecycleTestApp.sourceText));
        await tester.pumpAndSettle();
        events.clear();
        await tester.tap(find.text(_QuiHeroTextLifecycleTestApp.destinationText));
        await tester.pumpAndSettle();

        expect(events, equals(['destination-start', 'destination-end']));
      },
    );

    testWidgets('when popping into a shorter text boundary, it should shorten the flight text without ellipsis', (
      tester,
    ) async {
      const destinationText =
          'Linha longa da oportunidade com muitos detalhes sobre horario, local, pagamento e combinados.';

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      QuiHeroPage(
                        builder: (_) => Scaffold(
                          body: Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const SizedBox(
                                width: 220,
                                child: QuiHeroText(
                                  destinationText,
                                  tag: 'test',
                                  switchThreshold: 0.99,
                                  style: TextStyle(fontSize: 18, height: 1.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ).createRoute(context),
                    );
                  },
                  child: const SizedBox(
                    width: 220,
                    height: 24,
                    child: QuiHeroText(
                      'Resumo curto',
                      tag: 'test',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Resumo curto'));
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.tap(find.text(destinationText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      final flightText = tester.widget<Text>(find.text(destinationText, skipOffstage: false).last);
      expect(((flightText.maxLines ?? 999) < 10, flightText.overflow), equals((true, null)));
    });

    testWidgets('when popping into a shorter text boundary and lines disappear, it should keep the first line fixed', (
      tester,
    ) async {
      const destinationText =
          'Linha longa da oportunidade com muitos detalhes sobre horario, local, pagamento, combinados, deslocamento, '
          'uniforme, entrada, saida, intervalo, responsaveis e instrucoes para o primeiro dia.';

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    top: 120,
                    left: 40,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          QuiHeroPage(
                            builder: (_) => Scaffold(
                              body: Stack(
                                children: [
                                  Positioned(
                                    top: 120,
                                    left: 40,
                                    child: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: const SizedBox(
                                        width: 220,
                                        child: QuiHeroText(
                                          destinationText,
                                          tag: 'test',
                                          switchThreshold: 0.99,
                                          style: TextStyle(fontSize: 18, height: 1.4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).createRoute(context),
                        );
                      },
                      child: const SizedBox(
                        width: 220,
                        height: 24,
                        child: QuiHeroText(
                          'Resumo curto',
                          tag: 'test',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Resumo curto'));
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.tap(find.text(destinationText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      final firstFrameFinder = find.text(destinationText, skipOffstage: false).last;
      final firstFrameTop = tester.getTopLeft(firstFrameFinder).dy;
      final firstFrameMaxLines = tester.widget<Text>(firstFrameFinder).maxLines ?? 999;

      await tester.pump(const Duration(milliseconds: 80));

      final secondFrameFinder = find.text(destinationText, skipOffstage: false).last;
      final secondFrameTop = tester.getTopLeft(secondFrameFinder).dy;
      final secondFrameText = tester.widget<Text>(secondFrameFinder);

      expect((
        secondFrameText.maxLines! < firstFrameMaxLines,
        (secondFrameTop - firstFrameTop).abs() < 0.5,
        secondFrameText.overflow,
      ), equals((true, true, null)));
    });
  });

  group('QuiHero.text switchThreshold', () {
    test('when creating with switchThreshold 0.5, it should not throw', () {
      expect(() => const QuiHeroText('Hello', tag: 'test', switchThreshold: 0.5), returnsNormally);
    });

    test('when creating with switchThreshold 0.8, it should not throw', () {
      expect(() => const QuiHeroText('Hello', tag: 'test', switchThreshold: 0.8), returnsNormally);
    });

    test('when creating with switchThreshold 0.2, it should not throw', () {
      expect(() => const QuiHeroText('Hello', tag: 'test', switchThreshold: 0.2), returnsNormally);
    });

    test('when creating with switchThreshold 0.0, it should not throw', () {
      expect(() => const QuiHeroText('Hello', tag: 'test', switchThreshold: 0), returnsNormally);
    });

    test('when creating with switchThreshold 1.0, it should not throw', () {
      expect(() => const QuiHeroText('Hello', tag: 'test', switchThreshold: 1), returnsNormally);
    });

    test('when creating with switchThreshold -0.1, it should throw an assertion error', () {
      expect(() => QuiHeroText('Hello', tag: 'test', switchThreshold: -0.1), throwsA(isA<AssertionError>()));
    });

    test('when creating with switchThreshold 1.5, it should throw an assertion error', () {
      expect(() => QuiHeroText('Hello', tag: 'test', switchThreshold: 1.5), throwsA(isA<AssertionError>()));
    });

    testWidgets('when building with switchThreshold 0.8, it should display the text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuiHeroText('Custom Threshold', tag: 'test', switchThreshold: 0.8, style: TextStyle(fontSize: 16)),
          ),
        ),
      );

      expect(find.text('Custom Threshold'), findsOneWidget);
    });
  });
}

class _QuiHeroTextLifecycleTestApp extends StatelessWidget {
  const _QuiHeroTextLifecycleTestApp({required this.events});

  static const sourceText = 'Source text hero';
  static const destinationText = 'Destination text hero';

  final List<String> events;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push<void>(
                    QuiHeroPage(builder: (_) => _QuiHeroTextLifecycleDestination(events: events)).createRoute(context),
                  );
                },
                child: QuiHeroText(
                  sourceText,
                  tag: 'text-lifecycle',
                  onStart: () => events.add('source-start'),
                  onEnd: () => events.add('source-end'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuiHeroTextLifecycleDestination extends StatelessWidget {
  const _QuiHeroTextLifecycleDestination({required this.events});

  final List<String> events;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: QuiHeroText(
            _QuiHeroTextLifecycleTestApp.destinationText,
            tag: 'text-lifecycle',
            onStart: () => events.add('destination-start'),
            onEnd: () => events.add('destination-end'),
          ),
        ),
      ),
    );
  }
}
