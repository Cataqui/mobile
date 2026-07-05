import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHero.text switchThreshold direction', () {
    testWidgets('when popping, it should respect the destination switchThreshold', (tester) async {
      // Setup: origin threshold=0.5, destination threshold=0.99
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
                              child: const QuiHeroText(
                                'DEST',
                                tag: 'test',
                                switchThreshold: 0.99,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ).createRoute(context),
                    );
                  },
                  child: const QuiHeroText('ORIGIN', tag: 'test', switchThreshold: 0.5, style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Push to destination
      await tester.tap(find.text('ORIGIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 560));
      await tester.pumpAndSettle();
      expect(find.text('DEST'), findsOneWidget);

      // Now pop back
      await tester.tap(find.text('DEST'));
      await tester.pump();

      // Pump enough frames for the buggy code to have switched (origin
      // threshold 0.5 switches at ~79% of the pop) but BEFORE the fixed
      // code switches (destination threshold 0.99 switches at ~99%).
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // At this mid-pop point (roughly 70-80% through):
      // With the bug (origin threshold 0.5 controls pop, begin swapped):
      //   - the origin threshold has already caused the switch to ORIGIN
      // With the fix (destination threshold 0.99 controls pop):
      //   - DEST is still shown (threshold 0.99 delays the switch)
      expect(find.text('DEST'), findsOneWidget);
    });
  });
}
