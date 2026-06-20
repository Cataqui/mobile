import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';
import '../test_app.dart';

void main() {
  group('QuiTextButton', () {
    testWidgets('when tapped, it should call onPressed', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        TestApp(
          child: QuiTextButton(text: 'Ver oportunidades', onPressed: () => tapCount += 1),
        ),
      );

      await tester.tap(find.text('Ver oportunidades'));
      await tester.pump(const Duration(milliseconds: 800));

      expect(tapCount, equals(1));
    });

    testWidgets('when pressed, it should show stronger opacity feedback', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiTextButton(text: 'Ver oportunidades', onPressed: () {}),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Ver oportunidades')));
      await tester.pump(const Duration(milliseconds: 45));

      final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));

      expect(opacity.opacity, equals(0.2));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('when disabled, it should expose disabled semantics', (tester) async {
      await tester.pumpWidget(const TestApp(child: QuiTextButton(text: 'Indisponivel')));

      final semantics = tester.widget<Semantics>(
        find.descendant(of: find.byType(QuiTextButton), matching: find.byType(Semantics)),
      );

      expect(semantics.properties.enabled, isFalse);
    });

    testWidgets('when leading icon spacing is customized, it should use the provided spacing', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiTextButton(
            text: 'Buscar',
            leadingIconBuilder: (state) => const Icon(Icons.search),
            leadingIconSpacing: 10,
            onPressed: () {},
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.descendant(of: find.byType(Row), matching: find.byType(Padding)));

      expect(padding.padding, equals(const EdgeInsets.only(right: 10)));
    });

    testWidgets('when enabled, it should pass the recommended icon color to leadingIconBuilder', (tester) async {
      Color? recommendedIconColor;

      await tester.pumpWidget(
        TestApp(
          child: QuiTextButton(
            text: 'Buscar',
            color: const Color(0xFFFF4A4B),
            leadingIconBuilder: (state) {
              recommendedIconColor = state.recommendedIconColor;
              return const Icon(Icons.search);
            },
            onPressed: () {},
          ),
        ),
      );

      expect(recommendedIconColor, equals(const Color(0xFFFF4A4B)));
    });

    testWidgets('when disabled, it should pass disabled state to leadingIconBuilder', (tester) async {
      bool? isEnabled;

      await tester.pumpWidget(
        TestApp(
          child: QuiTextButton(
            text: 'Indisponivel',
            leadingIconBuilder: (state) {
              isEnabled = state.isEnabled;
              return const Icon(Icons.lock);
            },
          ),
        ),
      );

      expect(isEnabled, isFalse);
    });

    testWidgets('when disabled, it should pass placeholder color to leadingIconBuilder', (tester) async {
      Color? recommendedIconColor;

      await tester.pumpWidget(
        TestApp(
          child: QuiTextButton(
            text: 'Indisponivel',
            leadingIconBuilder: (state) {
              recommendedIconColor = state.recommendedIconColor;
              return const Icon(Icons.lock);
            },
          ),
        ),
      );

      expect(recommendedIconColor, equals(const Color(0xFF9E9E9E)));
    });

    testWidgets('when trailing icon spacing is customized, it should use the provided spacing', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiTextButton(
            text: 'Continuar',
            trailingIconBuilder: (state) => const Icon(Icons.arrow_forward),
            trailingIconSpacing: 12,
            onPressed: () {},
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.descendant(of: find.byType(Row), matching: find.byType(Padding)));

      expect(padding.padding, equals(const EdgeInsets.only(left: 12)));
    });

    testWidgets('when both icons are provided, it should render three children in the row', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiTextButton(
            text: 'Distância',
            leadingIconBuilder: (state) => const Icon(Icons.near_me),
            trailingIconBuilder: (state) => const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children.length, equals(3));
    });

    testWidgets('when both icons are provided, it should render the leading icon', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiTextButton(
            text: 'Distância',
            leadingIconBuilder: (state) => const Icon(Icons.near_me),
            trailingIconBuilder: (state) => const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.near_me), findsOneWidget);
    });

    testWidgets('when both icons are provided, it should render the trailing icon', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiTextButton(
            text: 'Distância',
            leadingIconBuilder: (state) => const Icon(Icons.near_me),
            trailingIconBuilder: (state) => const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
