import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';
import '../test_app.dart';

void main() {
  group('QuiSearchBarButton', () {
    test('when accessing searchBarHeight, it should equal 60', () {
      expect(QuiSearchBarButton.searchBarHeight, equals(60));
    });

    testWidgets('when rendering, the SizedBox height should be 60', (tester) async {
      await tester.pumpWidget(
        const TestApp(child: QuiSearchBarButton(placeholder: 'Search...')),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.byWidgetPredicate((w) => w is SizedBox && w.height == 60),
      );

      expect(sizedBox.height, equals(60));
    });
  });
}
