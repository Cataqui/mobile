import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHeroPage', () {
    test('defaultTransitionDuration should be 560ms', () {
      expect(QuiHeroPage.defaultTransitionDuration, equals(const Duration(milliseconds: 560)));
    });

    test('defaultReverseTransitionDuration should be 430ms', () {
      expect(QuiHeroPage.defaultReverseTransitionDuration, equals(const Duration(milliseconds: 430)));
    });

    testWidgets('when creating a route from QuiHeroPage, it should return a QuiHeroPageRoute', (tester) async {
      QuiHeroPageRoute? capturedRoute;

      await tester.pumpWidget(
        _PageTestApp(
          onRouteCreated: (route) {
            capturedRoute = route;
          },
        ),
      );

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      expect(capturedRoute, isA<QuiHeroPageRoute>());
    });

    testWidgets('when custom transition duration is set, it should use the custom value', (tester) async {
      const customDuration = Duration(milliseconds: 300);
      QuiHeroPageRoute? capturedRoute;

      await tester.pumpWidget(
        _PageTestApp(
          customTransitionDuration: customDuration,
          onRouteCreated: (route) {
            capturedRoute = route;
          },
        ),
      );

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      expect(capturedRoute!.transitionDuration, equals(customDuration));
    });

    testWidgets('when custom reverse transition duration is set, it should use the custom value', (tester) async {
      const customDuration = Duration(milliseconds: 200);
      QuiHeroPageRoute? capturedRoute;

      await tester.pumpWidget(
        _PageTestApp(
          customReverseTransitionDuration: customDuration,
          onRouteCreated: (route) {
            capturedRoute = route;
          },
        ),
      );

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      expect(capturedRoute!.reverseTransitionDuration, equals(customDuration));
    });
  });
}

class _PageTestApp extends StatelessWidget {
  const _PageTestApp({
    this.customTransitionDuration,
    this.customReverseTransitionDuration,
    this.onRouteCreated,
  });

  final Duration? customTransitionDuration;
  final Duration? customReverseTransitionDuration;
  final void Function(QuiHeroPageRoute route)? onRouteCreated;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  final page = QuiHeroPage(
                    builder: (_) => const SizedBox(),
                    transitionDuration: customTransitionDuration ?? QuiHeroPage.defaultTransitionDuration,
                    reverseTransitionDuration: customReverseTransitionDuration ?? QuiHeroPage.defaultReverseTransitionDuration,
                  );
                  final createdRoute = page.createRoute(context) as QuiHeroPageRoute;
                  onRouteCreated?.call(createdRoute);
                  unawaited(Navigator.of(context).push(createdRoute));
                },
                child: const Text('Push'),
              ),
            ),
          );
        },
      ),
    );
  }
}
