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
}
