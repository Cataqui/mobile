// These route method chaining patterns document intent more clearly as
// separate statements than as cascades.
// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHeroPageRoute', () {
    testWidgets('when calling maybeOf from inside a QuiHeroPageRoute, it should return the route safely', (
      tester,
    ) async {
      await tester.pumpWidget(const _RouteTestApp());
      await tester.tap(find.text('Push'));
      await tester.pump();
      // The route builder captures the context to test maybeOf
      final route = _RouteTestApp.capturedRoute;
      expect(route, isNotNull);
      expect(route, isA<QuiHeroPageRoute>());
    });

    testWidgets('when calling maybeOf from outside a QuiHeroPageRoute, it should return null', (tester) async {
      QuiHeroPageRoute? capturedRoute;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedRoute = QuiHeroPageRoute.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedRoute, isNull);
    });

    testWidgets('when calling startInteractivePop on the settled route, it should return true', (tester) async {
      await tester.pumpWidget(const _RouteTestApp());
      await tester.tap(find.text('Push'));
      await tester.pump();
      final route = _RouteTestApp.capturedRoute!;

      final result = route.startInteractivePop();

      expect(result, isTrue);
      expect(route.isInteractivePopActive, isTrue);
    });

    testWidgets('when calling startInteractivePop a second time, it should return false', (tester) async {
      await tester.pumpWidget(const _RouteTestApp());
      await tester.tap(find.text('Push'));
      await tester.pump();
      final route = _RouteTestApp.capturedRoute!;

      route.startInteractivePop();
      final secondResult = route.startInteractivePop();

      expect(secondResult, isFalse);
    });

    testWidgets('when calling updateInteractivePop with closingProgress 0.5, it should set transitionValue to 0.5', (
      tester,
    ) async {
      await tester.pumpWidget(const _RouteTestApp());
      await tester.tap(find.text('Push'));
      await tester.pump();
      final route = _RouteTestApp.capturedRoute!;

      route.startInteractivePop();
      route.updateInteractivePop(closingProgress: 0.5);

      expect(route.transitionValue, closeTo(0.5, 0.01));
    });

    testWidgets('when calling updateInteractivePop with closingProgress 0, it should keep transitionValue at 1', (
      tester,
    ) async {
      await tester.pumpWidget(const _RouteTestApp());
      await tester.tap(find.text('Push'));
      await tester.pump();
      final route = _RouteTestApp.capturedRoute!;

      route.startInteractivePop();
      route.updateInteractivePop(closingProgress: 0);

      expect(route.transitionValue, closeTo(1.0, 0.01));
    });

    testWidgets('when calling cancelInteractivePop, it should animate back to transitionValue 1.0', (tester) async {
      await tester.pumpWidget(const _RouteTestApp());
      await tester.tap(find.text('Push'));
      await tester.pump();
      final route = _RouteTestApp.capturedRoute!;

      route.startInteractivePop();
      route.updateInteractivePop(closingProgress: 0.5);
      await route.cancelInteractivePop();
      await tester.pumpAndSettle();

      expect(route.transitionValue, closeTo(1.0, 0.01));
      expect(route.isInteractivePopActive, isFalse);
    });

    testWidgets('when calling commitInteractivePop, it should pop the route', (tester) async {
      await tester.pumpWidget(const _RouteTestApp());
      await tester.tap(find.text('Push'));
      await tester.pump();
      expect(find.text('Destination'), findsOneWidget);
      final route = _RouteTestApp.capturedRoute!;

      route.startInteractivePop();
      route.commitInteractivePop();
      await tester.pumpAndSettle();

      expect(find.text('Destination'), findsNothing);
    });

    testWidgets('when the route is opaque, it should return false', (tester) async {
      await tester.pumpWidget(const _RouteTestApp());
      await tester.tap(find.text('Push'));
      await tester.pump();
      final route = _RouteTestApp.capturedRoute!;

      expect(route.opaque, isFalse);
    });

    testWidgets('when checking barrierDismissible, it should return false', (tester) async {
      await tester.pumpWidget(const _RouteTestApp());
      await tester.tap(find.text('Push'));
      await tester.pump();
      final route = _RouteTestApp.capturedRoute!;

      expect(route.barrierDismissible, isFalse);
    });

    testWidgets('when checking maintainState, it should return true', (tester) async {
      await tester.pumpWidget(const _RouteTestApp());
      await tester.tap(find.text('Push'));
      await tester.pump();
      final route = _RouteTestApp.capturedRoute!;

      expect(route.maintainState, isTrue);
    });
  });
}

class _RouteTestApp extends StatefulWidget {
  const _RouteTestApp();

  static QuiHeroPageRoute? capturedRoute;

  @override
  State<_RouteTestApp> createState() => _RouteTestAppState();
}

class _RouteTestAppState extends State<_RouteTestApp> {
  @override
  void initState() {
    super.initState();
    _RouteTestApp.capturedRoute = null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  unawaited(
                    Navigator.of(context).push<void>(
                      QuiHeroPageRoute(
                        builder: (routeContext) {
                          _RouteTestApp.capturedRoute = QuiHeroPageRoute.maybeOf(routeContext);
                          return const Text('Destination');
                        },
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    ),
                  );
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
