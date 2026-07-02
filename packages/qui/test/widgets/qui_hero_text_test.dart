import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHero.text', () {
    testWidgets('when building at rest, it should wrap the child in a Hero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuiHero.text(tag: 'test', text: 'Hello', style: const TextStyle(fontSize: 16)),
          ),
        ),
      );

      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('when building at rest, it should not add a repaint boundary to the feed tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuiHero.text(tag: 'test', text: 'Hello', style: const TextStyle(fontSize: 16)),
          ),
        ),
      );

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.child, isNot(isA<RepaintBoundary>()));
    });

    testWidgets('when inside a bounded width, it should reserve the full row width for the flight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: QuiHero.text(tag: 'test', text: 'Hello', style: const TextStyle(fontSize: 16)),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(Hero)).width, equals(300));
    });

    testWidgets('when building with a custom style, it should display the text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuiHero.text(
              tag: 'test',
              text: 'Test Text',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );

      expect(find.text('Test Text'), findsOneWidget);
    });

    testWidgets('when popping into a shorter text boundary, it should shorten the flight text with ellipsis', (
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
                              child: SizedBox(
                                width: 220,
                                child: QuiHero.text(
                                  tag: 'test',
                                  text: destinationText,
                                  switchThreshold: 0.99,
                                  style: const TextStyle(fontSize: 18, height: 1.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ).createRoute(context),
                    );
                  },
                  child: SizedBox(
                    width: 220,
                    height: 24,
                    child: QuiHero.text(
                      tag: 'test',
                      text: 'Resumo curto',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16),
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
      expect(((flightText.maxLines ?? 999) < 10, flightText.overflow), equals((true, TextOverflow.ellipsis)));
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
                                      child: SizedBox(
                                        width: 220,
                                        child: QuiHero.text(
                                          tag: 'test',
                                          text: destinationText,
                                          switchThreshold: 0.99,
                                          style: const TextStyle(fontSize: 18, height: 1.4),
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
                      child: SizedBox(
                        width: 220,
                        height: 24,
                        child: QuiHero.text(
                          tag: 'test',
                          text: 'Resumo curto',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16),
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
        (secondFrameTop - firstFrameTop).abs() < 0.01,
        secondFrameText.overflow,
      ), equals((true, true, TextOverflow.ellipsis)));
    });
  });

  group('QuiHero.text switchThreshold', () {
    test('when creating with switchThreshold 0.5, it should not throw', () {
      expect(() => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: 0.5), returnsNormally);
    });

    test('when creating with switchThreshold 0.8, it should not throw', () {
      expect(() => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: 0.8), returnsNormally);
    });

    test('when creating with switchThreshold 0.2, it should not throw', () {
      expect(() => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: 0.2), returnsNormally);
    });

    test('when creating with switchThreshold 0.0, it should not throw', () {
      expect(() => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: 0), returnsNormally);
    });

    test('when creating with switchThreshold 1.0, it should not throw', () {
      expect(() => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: 1), returnsNormally);
    });

    test('when creating with switchThreshold -0.1, it should throw an assertion error', () {
      expect(() => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: -0.1), throwsA(isA<AssertionError>()));
    });

    test('when creating with switchThreshold 1.5, it should throw an assertion error', () {
      expect(() => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: 1.5), throwsA(isA<AssertionError>()));
    });

    testWidgets('when building with switchThreshold 0.8, it should display the text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuiHero.text(
              tag: 'test',
              text: 'Custom Threshold',
              switchThreshold: 0.8,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );

      expect(find.text('Custom Threshold'), findsOneWidget);
    });
  });
}
