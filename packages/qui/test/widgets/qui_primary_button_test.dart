import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';
import '../test_app.dart';

void main() {
  group('QuiPrimaryButton', () {
    testWidgets('when tapped, it should call onPressed', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        TestApp(
          child: QuiPrimaryButton(label: 'Ver oportunidades', onPressed: () => tapCount += 1),
        ),
      );

      await tester.tap(find.text('Ver oportunidades'));
      await tester.pump(const Duration(milliseconds: 800));

      expect(tapCount, equals(1));
    });

    testWidgets('when pressed, it should show stronger opacity feedback', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiPrimaryButton(label: 'Ver oportunidades', onPressed: () {}),
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
      await tester.pumpWidget(const TestApp(child: QuiPrimaryButton(label: 'Indisponivel')));

      final semantics = tester.widget<Semantics>(
        find.descendant(of: find.byType(QuiPrimaryButton), matching: find.byType(Semantics)),
      );

      expect(semantics.properties.enabled, isFalse);
    });

    testWidgets('when leading icon spacing is customized, it should use the provided spacing', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiPrimaryButton(
            label: 'Buscar',
            leadingIconBuilder: (state) => const Icon(Icons.search),
            leadingIconSpacing: 10,
            onPressed: () {},
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.descendant(of: find.byType(Row), matching: find.byType(Padding)));

      expect(padding.padding, equals(const EdgeInsets.only(right: 10)));
    });

    testWidgets('when trailing icon spacing is customized, it should use the provided spacing', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiPrimaryButton(
            label: 'Continuar',
            trailingIconBuilder: (state) => const Icon(Icons.arrow_forward),
            trailingIconSpacing: 12,
            onPressed: () {},
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.descendant(of: find.byType(Row), matching: find.byType(Padding)));

      expect(padding.padding, equals(const EdgeInsets.only(left: 12)));
    });

    testWidgets('when enabled, it should pass the recommended icon color to leadingIconBuilder', (tester) async {
      Color? recommendedIconColor;

      await tester.pumpWidget(
        TestApp(
          child: QuiPrimaryButton(
            label: 'Buscar',
            foregroundColor: const Color(0xFFFF4A4B),
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
          child: QuiPrimaryButton(
            label: 'Indisponivel',
            leadingIconBuilder: (state) {
              isEnabled = state.isEnabled;
              return const Icon(Icons.lock);
            },
          ),
        ),
      );

      expect(isEnabled, isFalse);
    });

    testWidgets('when disabled, it should pass disabled foreground color to leadingIconBuilder', (tester) async {
      Color? recommendedIconColor;

      await tester.pumpWidget(
        TestApp(
          child: QuiPrimaryButton(
            label: 'Indisponivel',
            leadingIconBuilder: (state) {
              recommendedIconColor = state.recommendedIconColor;
              return const Icon(Icons.lock);
            },
          ),
        ),
      );

      expect(recommendedIconColor, equals(const Color(0xFF8E8E8E)));
    });

    testWidgets('when both icons are provided, it should render three children in the row', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiPrimaryButton(
            label: 'Filtrar',
            leadingIconBuilder: (state) => const Icon(Icons.tune),
            trailingIconBuilder: (state) => const Icon(Icons.arrow_drop_down),
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
          child: QuiPrimaryButton(
            label: 'Filtrar',
            leadingIconBuilder: (state) => const Icon(Icons.tune),
            trailingIconBuilder: (state) => const Icon(Icons.arrow_drop_down),
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('when both icons are provided, it should render the trailing icon', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiPrimaryButton(
            label: 'Filtrar',
            leadingIconBuilder: (state) => const Icon(Icons.tune),
            trailingIconBuilder: (state) => const Icon(Icons.arrow_drop_down),
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('when background is not customized, it should use the primary color', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiPrimaryButton(label: 'Ver oportunidades', onPressed: () {}),
        ),
      );

      expect(_containerColor(tester), equals(const Color(0xFFFF4A4B)));
    });

    testWidgets('when background is customized, it should use the provided color', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiPrimaryButton(
            label: 'Mapa',
            backgroundColor: const Color(0xFF00A676),
            onPressed: () {},
          ),
        ),
      );

      expect(_containerColor(tester), equals(const Color(0xFF00A676)));
    });

    testWidgets('when disabled, it should use the disabled background color', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: QuiPrimaryButton(label: 'Indisponivel'),
        ),
      );

      expect(_containerColor(tester), equals(const Color(0xFFE1E1E1)));
    });

    testWidgets('when disabled background is customized, it should use the provided color', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: QuiPrimaryButton(
            label: 'Fechado',
            disabledBackgroundColor: Color(0xFFDDDDDD),
          ),
        ),
      );

      expect(_containerColor(tester), equals(const Color(0xFFDDDDDD)));
    });

    testWidgets('when foreground is not customized, it should use white as the label color', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiPrimaryButton(label: 'Ver oportunidades', onPressed: () {}),
        ),
      );

      expect(_labelStyle(tester).color, equals(Colors.white));
    });

    testWidgets('when foreground is customized, it should use the provided color as the label color', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: QuiPrimaryButton(
            label: 'Salvar',
            foregroundColor: const Color(0xFF1A1A1A),
            onPressed: () {},
          ),
        ),
      );

      final style = tester.widget<Text>(find.text('Salvar')).style!;
      expect(style.color, equals(const Color(0xFF1A1A1A)));
    });

    testWidgets('when fit is expand, it should fill the available width', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: SizedBox(
            width: 300,
            child: QuiPrimaryButton(label: 'Expandir', fit: QuiPrimaryButtonFit.expand, onPressed: null),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(const Key('qui_primary_button_container'))).width, equals(300));
    });

    testWidgets('when fit is fit, it should size to content', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: QuiPrimaryButton(label: 'Encaixar', fit: QuiPrimaryButtonFit.fit, onPressed: null),
        ),
      );

      final buttonWidth = tester.getSize(find.byKey(const Key('qui_primary_button_container'))).width;
      final screenWidth = tester.getSize(find.byType(MaterialApp)).width;
      expect(buttonWidth, lessThan(screenWidth));
    });
  });
}

TextStyle _labelStyle(WidgetTester tester) {
  return tester.widget<Text>(find.text('Ver oportunidades')).style!;
}

Color? _containerColor(WidgetTester tester) {
  final container = tester.widget<Container>(find.byKey(const Key('qui_primary_button_container')));
  final decoration = container.decoration! as BoxDecoration;
  return decoration.color;
}
