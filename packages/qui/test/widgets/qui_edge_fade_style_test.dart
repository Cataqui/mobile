import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';
import '../test_app.dart';

void main() {
  group('QuiEdgeFadeStyle', () {
    testWidgets('when used in QuiEdgeFade without explicit style, it should default to theme background', (
      tester,
    ) async {
      await tester.pumpWidget(
        const TestApp(child: QuiEdgeFade(position: QuiEdgeFadePosition.top)),
      );

      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = box.decoration as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.colors.first, equals(Colors.white));
    });

    testWidgets('when style has explicit color, it should use that color for the gradient', (tester) async {
      const customColor = Color(0xFF00A676);

      await tester.pumpWidget(
        const TestApp(
          child: QuiEdgeFade(position: QuiEdgeFadePosition.top, style: QuiEdgeFadeStyle(color: customColor)),
        ),
      );

      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = box.decoration as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.colors.first, equals(customColor));
    });

    testWidgets('when style has explicit height, it should size the fade to that height', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: QuiEdgeFade(
            position: QuiEdgeFadePosition.top,
            style: QuiEdgeFadeStyle(height: 50),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.byWidgetPredicate((w) => w is SizedBox && w.height == 50),
      );
      expect(sizedBox.height, equals(50));
    });
  });
}
