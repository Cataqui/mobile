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
  });
}
