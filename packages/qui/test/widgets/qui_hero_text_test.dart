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

  });

  group('QuiHero.text switchThreshold', () {
    test('when creating with switchThreshold 0.5, it should not throw', () {
      expect(
        () => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: 0.5),
        returnsNormally,
      );
    });

    test('when creating with switchThreshold 0.8, it should not throw', () {
      expect(
        () => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: 0.8),
        returnsNormally,
      );
    });

    test('when creating with switchThreshold 0.2, it should not throw', () {
      expect(
        () => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: 0.2),
        returnsNormally,
      );
    });

    test('when creating with switchThreshold 0.0, it should not throw', () {
      expect(
        () => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: 0.0),
        returnsNormally,
      );
    });

    test('when creating with switchThreshold 1.0, it should not throw', () {
      expect(
        () => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: 1.0),
        returnsNormally,
      );
    });

    test('when creating with switchThreshold -0.1, it should throw an assertion error', () {
      expect(
        () => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: -0.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('when creating with switchThreshold 1.5, it should throw an assertion error', () {
      expect(
        () => QuiHero.text(tag: 'test', text: 'Hello', switchThreshold: 1.5),
        throwsA(isA<AssertionError>()),
      );
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
