import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiTextButton', () {
    testWidgets('when tapped, it should call onPressed', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        _TestApp(
          child: QuiTextButton(text: 'Ver oportunidades', onPressed: () => tapCount += 1),
        ),
      );

      await tester.tap(find.text('Ver oportunidades'));

      expect(tapCount, equals(1));
    });

    testWidgets('when pressed, it should show stronger opacity feedback', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiTextButton(text: 'Ver oportunidades', onPressed: () {}),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Ver oportunidades')));
      await tester.pump(const Duration(milliseconds: 45));

      final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));

      expect(opacity.opacity, equals(0.2));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('when disabled, it should expose disabled semantics', (tester) async {
      await tester.pumpWidget(const _TestApp(child: QuiTextButton(text: 'Indisponivel')));

      final semantics = tester.widget<Semantics>(
        find.descendant(of: find.byType(QuiTextButton), matching: find.byType(Semantics)),
      );

      expect(semantics.properties.enabled, isFalse);
    });

    testWidgets('when icon spacing is customized, it should use the provided spacing', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiTextButton(text: 'Buscar', icon: const Icon(Icons.search), iconSpacing: 10, onPressed: () {}),
        ),
      );

      final padding = tester.widget<Padding>(find.descendant(of: find.byType(Row), matching: find.byType(Padding)));

      expect(padding.padding, equals(const EdgeInsets.only(right: 10)));
    });

    testWidgets('when icon matching is enabled, it should provide the text color', (tester) async {
      Color? iconThemeColor;

      await tester.pumpWidget(
        _TestApp(
          child: QuiTextButton(
            text: 'Buscar',
            color: const Color(0xFFFF4A4B),
            icon: Builder(
              builder: (context) {
                iconThemeColor = IconTheme.of(context).color;
                return const Icon(Icons.search);
              },
            ),
            onPressed: () {},
          ),
        ),
      );

      expect(iconThemeColor, equals(const Color(0xFFFF4A4B)));
    });

    testWidgets('when icon matching is enabled, it should tint any widget icon', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiTextButton(
            text: 'Buscar',
            color: const Color(0xFFFF4A4B),
            icon: Container(width: 12, height: 12, color: Colors.blue),
            onPressed: () {},
          ),
        ),
      );

      final colorFiltered = tester.widget<ColorFiltered>(
        find.descendant(of: find.byType(QuiTextButton), matching: find.byType(ColorFiltered)),
      );

      expect(colorFiltered.colorFilter, equals(const ColorFilter.mode(Color(0xFFFF4A4B), BlendMode.srcIn)));
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
      home: Scaffold(body: Center(child: child)),
    );
  }
}
