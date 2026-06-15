import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiIconButton', () {
    testWidgets('when tapped, it should call onPressed', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            iconBuilder: (state) => Icon(Icons.search, size: state.iconSize),
            onPressed: () => tapCount += 1,
          ),
        ),
      );

      await tester.tap(find.byType(QuiIconButton));
      await tester.pump(const Duration(milliseconds: 800));

      expect(tapCount, equals(1));
    });

    testWidgets('when disabled, it should expose disabled semantics', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(iconBuilder: (state) => Icon(Icons.lock, size: state.iconSize)),
        ),
      );

      final semantics = tester.widget<Semantics>(find.byKey(const Key('qui_icon_button_semantics')));

      expect(semantics.properties.enabled, isFalse);
    });

    testWidgets('when label is not provided, it should not render label text', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            iconBuilder: (state) => Icon(Icons.search, size: state.iconSize),
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Buscar'), findsNothing);
    });

    testWidgets('when label style is not provided, it should use text primary as label color', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            label: 'Buscar',
            iconBuilder: (state) => Icon(Icons.search, size: state.iconSize),
            onPressed: () {},
          ),
        ),
      );

      expect(_labelStyle(tester).color, equals(const Color(0xFF1A1A1A)));
    });

    testWidgets('when label style is not provided, it should use label medium size', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            label: 'Buscar',
            iconBuilder: (state) => Icon(Icons.search, size: state.iconSize),
            onPressed: () {},
          ),
        ),
      );

      expect(_labelStyle(tester).fontSize, equals(12));
    });

    testWidgets('when label style is not provided, it should use semi-bold weight', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            label: 'Buscar',
            iconBuilder: (state) => Icon(Icons.search, size: state.iconSize),
            onPressed: () {},
          ),
        ),
      );

      expect(_labelStyle(tester).fontWeight, equals(FontWeight.w600));
    });

    testWidgets('when label style sets color, it should use the provided label color', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            label: 'Buscar',
            labelStyle: const TextStyle(color: Color(0xFF00A676)),
            iconBuilder: (state) => Icon(Icons.search, size: state.iconSize),
            onPressed: () {},
          ),
        ),
      );

      expect(_labelStyle(tester).color, equals(const Color(0xFF00A676)));
    });

    testWidgets('when label style omits color, it should keep the default label color', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            label: 'Buscar',
            labelStyle: const TextStyle(fontSize: 16),
            iconBuilder: (state) => Icon(Icons.search, size: state.iconSize),
            onPressed: () {},
          ),
        ),
      );

      expect(_labelStyle(tester).color, equals(const Color(0xFF1A1A1A)));
    });

    testWidgets('when disabled, it should use the disabled background color', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(iconBuilder: (state) => Icon(Icons.lock, size: state.iconSize)),
        ),
      );

      expect(_circleColor(tester), equals(const Color(0xFFE1E1E1)));
    });

    testWidgets('when disabled background color is customized, it should use the provided color', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            disabledBackgroundColor: const Color(0xFFDDDDDD),
            iconBuilder: (state) => Icon(Icons.lock, size: state.iconSize),
          ),
        ),
      );

      expect(_circleColor(tester), equals(const Color(0xFFDDDDDD)));
    });

    testWidgets('when button size is not customized, it should use the default size', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            iconBuilder: (state) => Icon(Icons.search, size: state.iconSize),
            onPressed: () {},
          ),
        ),
      );

      expect(_circleSize(tester), equals(const Size(55, 55)));
    });

    testWidgets('when button size is customized, it should use the provided size', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            buttonSize: 64,
            iconBuilder: (state) => Icon(Icons.search, size: state.iconSize),
            onPressed: () {},
          ),
        ),
      );

      expect(_circleSize(tester), equals(const Size(64, 64)));
    });

    testWidgets('when icon size is not customized, it should pass the default size to iconBuilder', (tester) async {
      double? resolvedIconSize;

      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            iconBuilder: (state) {
              resolvedIconSize = state.iconSize;
              return Icon(Icons.search, size: state.iconSize);
            },
            onPressed: () {},
          ),
        ),
      );

      expect(resolvedIconSize, equals(27));
    });

    testWidgets('when icon size is customized, it should pass the size to iconBuilder', (tester) async {
      double? resolvedIconSize;

      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            iconSize: 30,
            iconBuilder: (state) {
              resolvedIconSize = state.iconSize;
              return Icon(Icons.search, size: state.iconSize);
            },
            onPressed: () {},
          ),
        ),
      );

      expect(resolvedIconSize, equals(30));
    });

    testWidgets('when icon size is customized, it should size the icon slot', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            iconSize: 30,
            iconBuilder: (state) => Container(width: 10, height: 20, color: Colors.white),
            onPressed: () {},
          ),
        ),
      );

      expect(tester.getSize(find.byKey(const Key('qui_icon_button_icon_box'))), equals(const Size(30, 30)));
    });

    testWidgets('when icon does not use recommended color, it should keep the icon color unset', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            iconBuilder: (state) => Icon(Icons.search, size: state.iconSize),
            onPressed: () {},
          ),
        ),
      );

      expect(tester.widget<Icon>(find.byIcon(Icons.search)).color, isNull);
    });

    testWidgets('when disabled, it should pass a darker disabled background color to iconBuilder', (tester) async {
      Color? resolvedForegroundColor;

      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            iconBuilder: (state) {
              resolvedForegroundColor = state.recommendedIconColor;
              return Icon(Icons.lock, size: state.iconSize);
            },
          ),
        ),
      );

      expect(resolvedForegroundColor, equals(Color.lerp(const Color(0xFFE1E1E1), Colors.black, 0.28)));
    });

    testWidgets('when disabled background is customized, it should pass a darker custom color to iconBuilder', (
      tester,
    ) async {
      Color? resolvedForegroundColor;

      await tester.pumpWidget(
        _TestApp(
          child: QuiIconButton(
            disabledBackgroundColor: const Color(0xFFDDDDDD),
            iconBuilder: (state) {
              resolvedForegroundColor = state.recommendedIconColor;
              return Icon(Icons.lock, size: state.iconSize);
            },
          ),
        ),
      );

      expect(resolvedForegroundColor, equals(Color.lerp(const Color(0xFFDDDDDD), Colors.black, 0.28)));
    });
  });
}

TextStyle _labelStyle(WidgetTester tester) {
  return tester.widget<Text>(find.text('Buscar')).style!;
}

Size _circleSize(WidgetTester tester) {
  final container = tester.widget<Container>(find.byKey(const Key('qui_icon_button_circle')));
  return Size(container.constraints!.maxWidth, container.constraints!.maxHeight);
}

Color? _circleColor(WidgetTester tester) {
  final container = tester.widget<Container>(find.byKey(const Key('qui_icon_button_circle')));
  final decoration = container.decoration! as BoxDecoration;
  return decoration.color;
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
