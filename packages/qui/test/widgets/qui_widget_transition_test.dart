import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

typedef _Builder = Widget Function(BuildContext);

void main() {
  group('QuiWidgetTransition rendering', () {
    testWidgets('when building, it should render the initial child', (
      tester,
    ) async {
      await _pumpTransition(tester, builder: (_) => const Text('hello', key: ValueKey('a')));

      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('when the builder returns a different key, it should transition', (
      tester,
    ) async {
      var builder = _constBuilder('A');

      await _pumpTransition(tester, builder: builder);
      expect(find.text('A'), findsOneWidget);

      builder = _constBuilder('B');
      await _pumpTransition(tester, builder: builder);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('when the builder returns a different type, it should transition', (
      tester,
    ) async {
      var isText = true;

      await _pumpTransition(
        tester,
        builder: (_) => isText
            ? const Text('hello', key: ValueKey('w'))
            : const SizedBox(key: ValueKey('w')),
      );
      expect(find.text('hello'), findsOneWidget);

      isText = false;
      await _pumpTransition(tester, builder: (_) => const SizedBox(key: ValueKey('w')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets(
      'when the builder returns the same type and key, it should NOT transition',
      (tester) async {
        var builder = _constBuilder('A');

        await _pumpTransition(tester, builder: builder);
        expect(find.text('A'), findsOneWidget);

        builder = _constBuilder('A updated');
        await _pumpTransition(tester, builder: builder);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('A updated'), findsOneWidget);
      },
    );
  });

  group('QuiWidgetTransition reduced motion', () {
    testWidgets(
      'when disableAnimations is true and widget changes, it should swap instantly',
      (tester) async {
        var builder = _constBuilder('A');

        await _pumpTransition(tester, builder: builder, disableAnimations: true);
        expect(find.text('A'), findsOneWidget);

        builder = _constBuilder('B');
        await _pumpTransition(tester, builder: builder, disableAnimations: true);
        await tester.pump();

        expect(find.text('B'), findsOneWidget);
      },
    );
  });

  group('QuiWidgetTransition element reuse', () {
    testWidgets(
      'when transitioning from A to B, it should NOT reinitialize A',
      (tester) async {
        final initCounts = <String, int>{};
        var trackKey = 'A';

        // Set up a transition where outTransition and inTransition
        // produce DIFFERENT wrapper structures — the exact pattern
        // that caused A to be recreated on every A→B transition.
        Widget build({required bool disableAnimations}) => _HarnessApp(
              disableAnimations: disableAnimations,
              child: QuiWidgetTransition(
                builder: (_) => _TrackedWidget(
                  label: trackKey,
                  initCounts: initCounts,
                  key: ValueKey(trackKey),
                ),
                outDuration: const Duration(milliseconds: 100),
                outTransition: (child, animation) => FadeTransition(
                  opacity: Tween<double>(begin: 1, end: 0).animate(animation),
                  child: RepaintBoundary(child: child),
                ),
                inDuration: const Duration(milliseconds: 200),
                inTransition: (child, animation) {
                  final curved = CurveTween(curve: Curves.easeOutCubic);
                  return FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(curved.animate(animation)),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.03),
                        end: Offset.zero,
                      ).animate(curved.animate(animation)),
                      child: RepaintBoundary(child: child),
                    ),
                  );
                },
              ),
            );

        // Show A — initState called once
        trackKey = 'A';
        await tester.pumpWidget(build(disableAnimations: true));
        await tester.pump();
        expect(initCounts['A'], 1, reason: 'A should init exactly once on first show');

        // Transition to B — A's element is preserved (same wrapper through all phases)
        trackKey = 'B';
        await tester.pumpWidget(build(disableAnimations: false));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(initCounts['A'], 1,
            reason: 'A should NOT reinit during A→B exit phase');

        // Complete the transition
        await tester.pumpAndSettle();
        expect(find.text('B'), findsOneWidget);
        expect(initCounts['B'], 1, reason: 'B should init once');
        expect(initCounts['A'], 1,
            reason: 'A should NOT have reinit after A→B completes');
      },
    );

    testWidgets(
      'when transitioning back to A (A→B→A), it should reinitialize A with fresh state',
      (tester) async {
        final initCounts = <String, int>{};
        var trackKey = 'A';

        Widget build({required bool disableAnimations}) => _HarnessApp(
              disableAnimations: disableAnimations,
              child: QuiWidgetTransition(
                builder: (_) => _TrackedWidget(
                  label: trackKey,
                  initCounts: initCounts,
                  key: ValueKey(trackKey),
                ),
                outDuration: const Duration(milliseconds: 100),
                outTransition: (child, animation) => FadeTransition(
                  opacity: Tween<double>(begin: 1, end: 0).animate(animation),
                  child: RepaintBoundary(child: child),
                ),
                inDuration: const Duration(milliseconds: 200),
                inTransition: (child, animation) {
                  final curved = CurveTween(curve: Curves.easeOutCubic);
                  return FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(curved.animate(animation)),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.03),
                        end: Offset.zero,
                      ).animate(curved.animate(animation)),
                      child: RepaintBoundary(child: child),
                    ),
                  );
                },
              ),
            );

        // A→B — A is disposed after transition completes
        trackKey = 'A';
        await tester.pumpWidget(build(disableAnimations: true));
        await tester.pump();
        trackKey = 'B';
        await tester.pumpWidget(build(disableAnimations: false));
        await tester.pumpAndSettle();

        expect(initCounts['A'], 1, reason: 'A should init once after A→B');

        // B→A — A should be REINITIALIZED (previous A was disposed after A→B)
        trackKey = 'A';
        await tester.pumpWidget(build(disableAnimations: false));
        await tester.pumpAndSettle();

        expect(initCounts['A'], 2,
            reason: 'A should reinit when transitioning back (previous A was disposed)');
        expect(find.text('A'), findsOneWidget);
      },
    );
  });

  group('QuiWidgetTransition lifecycle', () {
    testWidgets(
      'when the widget is removed during a transition, it should not throw',
      (tester) async {
        var builder = _constBuilder('A');

        await _pumpTransition(tester, builder: builder);
        builder = _constBuilder('B');
        await _pumpTransition(tester, builder: builder);
        await tester.pump(const Duration(milliseconds: 50));

        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('QuiWidgetTransition mid-transition control', () {
    testWidgets(
      'when disableAnimations becomes true mid-transition, it should skip to idle',
      (tester) async {
        var builder = _constBuilder('A');

        Widget build({required bool disableAnimations}) => _HarnessApp(
              disableAnimations: disableAnimations,
              child: QuiWidgetTransition(
                builder: builder,
                outDuration: const Duration(milliseconds: 5000),
                outTransition: (child, controller) => FadeTransition(
                  opacity: Tween<double>(begin: 1, end: 0).animate(controller),
                  child: child,
                ),
                inDuration: const Duration(milliseconds: 5000),
                inTransition: (child, controller) {
                  final curved = CurveTween(curve: Curves.easeOutCubic);
                  return FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(curved.animate(controller)),
                    child: child,
                  );
                },
              ),
            );

        await tester.pumpWidget(build(disableAnimations: false));
        await tester.pump();
        expect(find.text('A'), findsOneWidget);

        // Start A→B transition (long duration, animations enabled)
        builder = _constBuilder('B');
        await tester.pumpWidget(build(disableAnimations: false));
        await tester.pump();
        expect(find.text('A'), findsOneWidget);

        // Switch to disableAnimations = true mid-transition
        await tester.pumpWidget(build(disableAnimations: true));
        await tester.pump();

        // Should skip to idle: A disposed, B fully visible
        expect(find.text('B'), findsOneWidget);
        expect(find.text('A'), findsNothing);
      },
    );
  });

  group('QuiWidgetTransition null transitions', () {
    testWidgets(
      'when outTransition is null, it should animate in the new widget without exit',
      (tester) async {
        var builder = _constBuilder('A');
        await tester.pumpWidget(
          _HarnessApp(
            child: QuiWidgetTransition(
              builder: builder,
              outDuration: const Duration(milliseconds: 300),
              outTransition: null,
              inDuration: const Duration(milliseconds: 500),
              inTransition: (child, controller) {
                final curved = CurveTween(curve: Curves.easeOutCubic);
                return FadeTransition(
                  opacity: Tween<double>(begin: 0, end: 1).animate(curved.animate(controller)),
                  child: child,
                );
              },
            ),
          ),
        );
        await tester.pump();
        expect(find.text('A'), findsOneWidget);

        builder = _constBuilder('B');
        await tester.pumpWidget(
          _HarnessApp(
            child: QuiWidgetTransition(
              builder: builder,
              outDuration: const Duration(milliseconds: 300),
              outTransition: null,
              inDuration: const Duration(milliseconds: 500),
              inTransition: (child, controller) {
                final curved = CurveTween(curve: Curves.easeOutCubic);
                return FadeTransition(
                  opacity: Tween<double>(begin: 0, end: 1).animate(curved.animate(controller)),
                  child: child,
                );
              },
            ),
          ),
        );
        await tester.pump();

        // A should be gone (no exit animation), B is animating in
        expect(find.text('A'), findsNothing);

        await tester.pumpAndSettle();
        expect(find.text('B'), findsOneWidget);
      },
    );

    testWidgets(
      'when outTransition is null and inTransition is null, it should swap instantly',
      (tester) async {
        var builder = _constBuilder('A');
        await tester.pumpWidget(
          _HarnessApp(
            child: QuiWidgetTransition(
              builder: builder,
              outDuration: const Duration(milliseconds: 300),
              outTransition: null,
              inDuration: const Duration(milliseconds: 500),
              inTransition: null,
            ),
          ),
        );
        await tester.pump();
        expect(find.text('A'), findsOneWidget);

        builder = _constBuilder('B');
        await tester.pumpWidget(
          _HarnessApp(
            child: QuiWidgetTransition(
              builder: builder,
              outDuration: const Duration(milliseconds: 300),
              outTransition: null,
              inDuration: const Duration(milliseconds: 500),
              inTransition: null,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('B'), findsOneWidget);
        expect(find.text('A'), findsNothing);
      },
    );
  });

  group('QuiWidgetTransition rapid key changes', () {
    testWidgets(
      'when the builder returns a different key during exit phase, it should still animate the pending transition then show the new widget',
      (tester) async {
        var builder = _constBuilder('A');

        await _pumpTransition(tester, builder: builder);
        expect(find.text('A'), findsOneWidget);

        // Start A→B transition
        builder = _constBuilder('B');
        await _pumpTransition(tester, builder: builder);
        await tester.pump();

        // During exit, builder returns C (different key from B)
        builder = _constBuilder('C');
        await _pumpTransition(tester, builder: builder);

        // The transition continues with B, but C is enqueued.
        // After both transitions settle, C is shown.
        await tester.pumpAndSettle();
        expect(find.text('C'), findsOneWidget);
      },
    );
  });

  group('QuiWidgetTransition app lifecycle', () {
    testWidgets(
      'when the app is paused during exit phase and resumed, it should complete the transition',
      (tester) async {
        final lifecycleKey = GlobalKey<_LifecycleObserverState>();
        var builder = _constBuilder('A');

        Widget build({required bool disableAnimations}) => _HarnessApp(
              disableAnimations: disableAnimations,
              child: _LifecycleObserver(
                key: lifecycleKey,
                child: QuiWidgetTransition(
                  builder: builder,
                  outDuration: const Duration(milliseconds: 100),
                  outTransition: (child, controller) => FadeTransition(
                    opacity: Tween<double>(begin: 1, end: 0).animate(controller),
                    child: child,
                  ),
                  inDuration: const Duration(milliseconds: 200),
                  inTransition: (child, controller) {
                    final curved = CurveTween(curve: Curves.easeOutCubic);
                    return FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(curved.animate(controller)),
                      child: child,
                    );
                  },
                ),
              ),
            );

        await tester.pumpWidget(build(disableAnimations: false));
        await tester.pump();
        expect(find.text('A'), findsOneWidget);

        // Start A→B transition
        builder = _constBuilder('B');
        await tester.pumpWidget(build(disableAnimations: false));
        await tester.pump();

        // Simulate app pause
        lifecycleKey.currentState?.dispatchLifecycle(AppLifecycleState.paused);
        await tester.pump();

        // Simulate app resume
        lifecycleKey.currentState?.dispatchLifecycle(AppLifecycleState.resumed);
        await tester.pump();

        // Transition should continue to completion
        await tester.pumpAndSettle();
        expect(find.text('B'), findsOneWidget);
      },
    );

    testWidgets(
      'when the app is paused during enter phase and resumed, it should complete the transition',
      (tester) async {
        final lifecycleKey = GlobalKey<_LifecycleObserverState>();
        var builder = _constBuilder('A');

        Widget build({required bool disableAnimations}) => _HarnessApp(
              disableAnimations: disableAnimations,
              child: _LifecycleObserver(
                key: lifecycleKey,
                child: QuiWidgetTransition(
                  builder: builder,
                  outDuration: const Duration(milliseconds: 100),
                  outTransition: (child, controller) => FadeTransition(
                    opacity: Tween<double>(begin: 1, end: 0).animate(controller),
                    child: child,
                  ),
                  inDuration: const Duration(milliseconds: 200),
                  inTransition: (child, controller) {
                    final curved = CurveTween(curve: Curves.easeOutCubic);
                    return FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(curved.animate(controller)),
                      child: child,
                    );
                  },
                ),
              ),
            );

        await tester.pumpWidget(build(disableAnimations: false));
        await tester.pump();
        expect(find.text('A'), findsOneWidget);

        // Start A→B transition and let it reach enter phase
        builder = _constBuilder('B');
        await tester.pumpWidget(build(disableAnimations: false));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120)); // Past exit (100ms), into enter (200ms)

        // Simulate app pause
        lifecycleKey.currentState?.dispatchLifecycle(AppLifecycleState.paused);
        await tester.pump();

        // Simulate app resume
        lifecycleKey.currentState?.dispatchLifecycle(AppLifecycleState.resumed);
        await tester.pump();

        // Transition should continue to completion
        await tester.pumpAndSettle();
        expect(find.text('B'), findsOneWidget);
      },
    );
  });

  group('QuiWidgetTransition incoming-mount timing', () {
    testWidgets(
      'when transitioning A to B, it should NOT mount the incoming widget during the exit phase',
      (tester) async {
        final initCounts = <String, int>{};
        var trackKey = 'A';

        Widget build() => _HarnessApp(
              child: QuiWidgetTransition(
                builder: (_) => _TrackedWidget(
                  label: trackKey,
                  initCounts: initCounts,
                  key: ValueKey(trackKey),
                ),
                outDuration: const Duration(milliseconds: 5000),
                outTransition: (child, animation) => FadeTransition(
                  opacity: Tween<double>(begin: 1, end: 0).animate(animation),
                  child: RepaintBoundary(child: child),
                ),
                inDuration: const Duration(milliseconds: 200),
                inTransition: (child, animation) {
                  final curved = CurveTween(curve: Curves.easeOutCubic);
                  return FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(curved.animate(animation)),
                    child: RepaintBoundary(child: child),
                  );
                },
              ),
            );

        trackKey = 'A';
        await tester.pumpWidget(build());
        await tester.pump();

        trackKey = 'B';
        await tester.pumpWidget(build());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(initCounts['B'], isNull);
      },
    );
  });
}

_Builder _constBuilder(String label) {
  return (_) => Text(label, key: ValueKey(label));
}

Future<void> _pumpTransition(
  WidgetTester tester, {
  required _Builder builder,
  bool disableAnimations = false,
}) {
  return tester.pumpWidget(
    _HarnessApp(
      disableAnimations: disableAnimations,
      child: QuiWidgetTransition(
        builder: builder,
        outDuration: const Duration(milliseconds: 300),
        outTransition: (child, controller) => FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(controller),
          child: child,
        ),
        inDuration: const Duration(milliseconds: 500),
        inTransition: (child, controller) {
          final curved = CurveTween(curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(curved.animate(controller)),
            child: child,
          );
        },
      ),
    ),
  );
}

class _TrackedWidget extends StatefulWidget {
  const _TrackedWidget({required this.label, required this.initCounts, required super.key});

  final String label;
  final Map<String, int> initCounts;

  @override
  State<_TrackedWidget> createState() => _TrackedWidgetState();
}

class _TrackedWidgetState extends State<_TrackedWidget> {
  @override
  void initState() {
    super.initState();
    widget.initCounts[widget.label] = (widget.initCounts[widget.label] ?? 0) + 1;
  }

  @override
  Widget build(BuildContext context) => Text(widget.label, key: ValueKey(widget.label));
}

class _LifecycleObserver extends StatefulWidget {
  const _LifecycleObserver({required this.child, super.key});

  final Widget child;

  @override
  State<_LifecycleObserver> createState() => _LifecycleObserverState();
}

class _LifecycleObserverState extends State<_LifecycleObserver> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void dispatchLifecycle(AppLifecycleState state) {
    didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _HarnessApp extends StatelessWidget {
  const _HarnessApp({required this.child, this.disableAnimations = false});

  final Widget child;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: QuiTheme.light(),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(400, 600)).copyWith(
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }
}
