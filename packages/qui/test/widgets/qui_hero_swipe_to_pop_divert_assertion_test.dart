import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHeroSwipeToPopExtension divert assertion', () {
    testWidgets(
      'when dragging down past the commit threshold and releasing, '
      'it should not throw a hero-flight divert assertion',
      (tester) async {
        await tester.pumpWidget(const _DivertTestApp());
        await tester.tap(find.byKey(_DivertTestApp.openButtonKey));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'when flinging down quickly below the commit threshold and releasing, '
      'it should not throw a hero-flight divert assertion',
      (tester) async {
        await tester.pumpWidget(const _DivertTestApp());
        await tester.tap(find.byKey(_DivertTestApp.openButtonKey));
        await tester.pumpAndSettle();

        await tester.fling(find.byType(CustomScrollView), const Offset(0, 30), 900);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'when dragging down below the commit threshold and releasing, '
      'it should not throw a hero-flight divert assertion',
      (tester) async {
        await tester.pumpWidget(const _DivertTestApp());
        await tester.tap(find.byKey(_DivertTestApp.openButtonKey));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
        await tester.pump(QuiHeroPage.defaultReverseTransitionDuration);
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'when dragging down a minimal distance and releasing, '
      'it should not throw a hero-flight divert assertion',
      (tester) async {
        await tester.pumpWidget(const _DivertTestApp());
        await tester.tap(find.byKey(_DivertTestApp.openButtonKey));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(CustomScrollView), const Offset(0, 5));
        await tester.pump(QuiHeroPage.defaultReverseTransitionDuration);
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _DivertTestApp extends StatefulWidget {
  const _DivertTestApp();

  static const openButtonKey = Key('open-hero-page');

  @override
  State<_DivertTestApp> createState() => _DivertTestAppState();
}

class _DivertTestAppState extends State<_DivertTestApp> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: QuiHeroBackground(
                tag: 'test-surface',
                width: 220,
                height: 120,
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(24)),
                child: TextButton(
                  key: _DivertTestApp.openButtonKey,
                  onPressed: () {
                    unawaited(
                      Navigator.of(context).push<void>(
                        QuiHeroPage(
                          builder: (_) => const _DivertTestDestination(),
                        ).createRoute(context),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DivertTestDestination extends StatelessWidget {
  const _DivertTestDestination();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QuiHeroBackground(
        tag: 'test-surface',
        decoration: const BoxDecoration(color: Colors.white),
        extensions: [const QuiHeroSwipeToPopExtension()],
        child: const CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 1600,
                child: ColoredBox(
                  color: Colors.white,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Destination'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
