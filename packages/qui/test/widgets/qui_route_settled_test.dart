import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';
import '../test_app.dart';

final _settledFinder = find.byType(QuiRouteSettled);

FadeTransition _fadeWithinSettled(WidgetTester tester) => tester.widget<FadeTransition>(
  find.descendant(of: _settledFinder, matching: find.byType(FadeTransition)),
);

void main() {
  group('QuiRouteSettled', () {
    testWidgets('when built inside a settled route, it should show the child', (tester) async {
      await tester.pumpWidget(TestApp(child: QuiRouteSettled(child: const Text('X'))));
      await tester.pumpAndSettle();

      final fade = _fadeWithinSettled(tester);
      expect(fade.opacity.value, 1);
    });

    testWidgets(
      'when mounted during a MaterialPageRoute push, it should stay hidden until the push settles',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        body: QuiRouteSettled(child: const Text('X')),
                      ),
                    ),
                  ),
                  child: const Text('Push'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.text('Push'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(find.byType(QuiRouteSettled), findsOneWidget);

        final fade = _fadeWithinSettled(tester);
        expect(fade.opacity.value, 0);

        await tester.pumpAndSettle();
        expect(fade.opacity.value, 1);
      },
    );

    testWidgets('when the route begins to pop, it should hide instantly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: Column(
                        children: [
                          QuiRouteSettled(child: const Text('X')),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: const Text('Pop'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                child: const Text('Push'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      final fade = _fadeWithinSettled(tester);
      expect(fade.opacity.value, 1);

      await tester.tap(find.text('Pop'));
      await tester.pump();

      expect(fade.opacity.value, 0);
    });

    testWidgets('when the user starts a navigation gesture, it should hide the child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: QuiRouteSettled(child: const Text('X')),
                    ),
                  ),
                ),
                child: const Text('Push'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      final fade = _fadeWithinSettled(tester);
      expect(fade.opacity.value, 1);

      final navigator = Navigator.of(tester.element(_settledFinder));
      navigator.didStartUserGesture();
      await tester.pump();

      expect(fade.opacity.value, 0);

      navigator.didStopUserGesture();
      await tester.pumpAndSettle();

      expect(fade.opacity.value, 1);
    });

    testWidgets('when disableAnimations is enabled, it should appear immediately', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TestApp(child: QuiRouteSettled(child: const Text('X'))),
        ),
      );
      await tester.pump();

      final fade = _fadeWithinSettled(tester);
      expect(fade.opacity.value, 1);
    });

    testWidgets('when custom appearDuration is provided, it should honor it', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiRouteSettled(
            appearDuration: const Duration(milliseconds: 100),
            child: const Text('X'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final fade = _fadeWithinSettled(tester);
      expect(fade.opacity.value, 1);
    });

    testWidgets('when the child changes between builds, it should keep the current visibility state',
        (tester) async {
      await tester.pumpWidget(
        TestApp(child: QuiRouteSettled(child: const Text('A'))),
      );
      await tester.pumpAndSettle();

      final fade = _fadeWithinSettled(tester);
      expect(fade.opacity.value, 1);

      await tester.pumpWidget(
        TestApp(child: QuiRouteSettled(child: const Text('B'))),
      );
      await tester.pump();

      expect(fade.opacity.value, 1);
    });
  });
}
