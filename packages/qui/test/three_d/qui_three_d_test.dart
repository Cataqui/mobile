import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiThreeD', () {
    testWidgets('when calling QuiThreeD.box, it should render an Image', (tester) async {
      await tester.pumpWidget(MaterialApp(home: QuiThreeD.box()));
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
    });

    test('when calling QuiThreeD.box with width and height, it should return a Widget', () {
      expect(QuiThreeD.box(width: 200, height: 200), isA<Widget>());
    });

    testWidgets('when calling QuiThreeD.precache, it should complete without error', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return const SizedBox();
        }),
      ));
      await tester.runAsync(() async {
        final context = tester.element(find.byType(SizedBox));
        await QuiThreeD.precache(context);
      });
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('when calling QuiThreeD.brush, it should render an Image', (tester) async {
      await tester.pumpWidget(MaterialApp(home: QuiThreeD.brush()));
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('when calling QuiThreeD.spilledCoffee, it should render an Image', (tester) async {
      await tester.pumpWidget(MaterialApp(home: QuiThreeD.spilledCoffee()));
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
