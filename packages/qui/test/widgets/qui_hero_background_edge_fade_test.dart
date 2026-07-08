import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

import '../test_app.dart';

void main() {
  group('QuiHero.background edgeFade', () {
    testWidgets('when edgeFade is null, it should not render any QuiEdgeFade widgets', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: SizedBox(
            width: 300,
            height: 100,
            child: QuiHeroBackground(
              tag: 'test',
              decoration: BoxDecoration(color: Color(0xFFFF4A4B)),
              child: Text('No Fade'),
            ),
          ),
        ),
      );

      expect(find.byType(QuiEdgeFade), findsNothing);
    });

    testWidgets('when edgeFade has a top style, it should render one QuiEdgeFade at the top edge', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: SizedBox(
            width: 300,
            height: 100,
            child: QuiHeroBackground(
              tag: 'test-top',
              decoration: BoxDecoration(color: Color(0xFFFF4A4B)),
              edgeFade: QuiHeroEdgeFade(top: QuiEdgeFadeStyle()),
              child: Text('Top Fade'),
            ),
          ),
        ),
      );

      expect(find.byType(QuiEdgeFade), findsOneWidget);
    });

    testWidgets('when edgeFade has both sides, it should render two QuiEdgeFade widgets', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: SizedBox(
            width: 300,
            height: 100,
            child: QuiHeroBackground(
              tag: 'test-both',
              decoration: BoxDecoration(color: Color(0xFFFF4A4B)),
              edgeFade: QuiHeroEdgeFade.vertical,
              child: Text('Both Fades'),
            ),
          ),
        ),
      );

      expect(find.byType(QuiEdgeFade), findsNWidgets(2));
    });

    testWidgets('when edgeFade is set, the overlay should be wrapped in IgnorePointer', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: SizedBox(
            width: 300,
            height: 100,
            child: QuiHeroBackground(
              tag: 'test-pointer',
              decoration: BoxDecoration(color: Color(0xFFFF4A4B)),
              edgeFade: QuiHeroEdgeFade.vertical,
              child: Text('Ignore Pointer'),
            ),
          ),
        ),
      );

      // The hero overlay wraps fades in an IgnorePointer (on top of each
      // QuiEdgeFade's own IgnorePointer), so there should be IgnorePointers.
      expect(find.byType(IgnorePointer), findsWidgets);
    });

    testWidgets(
      'when popping from a destination with switchThreshold 0.1, it should use the destination fade early in the reverse flight',
      (tester) async {
        await tester.pumpWidget(const _EdgeFadeSwitchThresholdPopTestApp());
        await tester.tap(find.text(_EdgeFadeSwitchThresholdPopTestApp.sourceText));
        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.text(_EdgeFadeSwitchThresholdPopTestApp.destinationText));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(_EdgeFadeSwitchThresholdPopTestApp.topFadeHeights(tester), everyElement(equals(20.0)));
      },
    );

    testWidgets(
      'when popping from a destination with switchThreshold 0.9, it should keep the destination fade dominant early in the reverse flight',
      (tester) async {
        await tester.pumpWidget(const _EdgeFadeSwitchThresholdPopTestApp(destinationSwitchThreshold: 0.9));
        await tester.tap(find.text(_EdgeFadeSwitchThresholdPopTestApp.sourceText));
        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.text(_EdgeFadeSwitchThresholdPopTestApp.destinationText));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(_EdgeFadeSwitchThresholdPopTestApp.topFadeHeights(tester), everyElement(greaterThan(70.0)));
      },
    );
  });
}

class _EdgeFadeSwitchThresholdPopTestApp extends StatelessWidget {
  const _EdgeFadeSwitchThresholdPopTestApp({this.destinationSwitchThreshold = 0.1});

  static const sourceText = 'SOURCE';
  static const destinationText = 'DESTINATION';

  final double destinationSwitchThreshold;

  static List<double?> topFadeHeights(WidgetTester tester) {
    return tester
        .widgetList<QuiEdgeFade>(find.byType(QuiEdgeFade))
        .where((fade) => fade.position == QuiEdgeFadePosition.top)
        .map((fade) => fade.style.height)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push<void>(
                  context,
                  QuiHeroPage(
                    builder: (_) => _EdgeFadeSwitchThresholdPopDestination(switchThreshold: destinationSwitchThreshold),
                  ).createRoute(context),
                );
              },
              child: const SizedBox(
                width: 200,
                height: 100,
                child: QuiHeroBackground(
                  tag: 'edge-fade-threshold',
                  edgeFade: QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 20)),
                  child: Center(child: Text(sourceText)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EdgeFadeSwitchThresholdPopDestination extends StatelessWidget {
  const _EdgeFadeSwitchThresholdPopDestination({required this.switchThreshold});

  final double switchThreshold;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: SizedBox(
            width: 300,
            height: 200,
            child: QuiHeroBackground(
              tag: 'edge-fade-threshold',
              edgeFade: QuiHeroEdgeFade(top: QuiEdgeFadeStyle(height: 100), switchThreshold: switchThreshold),
              child: const Center(child: Text(_EdgeFadeSwitchThresholdPopTestApp.destinationText)),
            ),
          ),
        ),
      ),
    );
  }
}
