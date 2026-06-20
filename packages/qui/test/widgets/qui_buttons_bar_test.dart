import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';
import '../test_app.dart';

void main() {
  group('QuiButtonsBar', () {
    testWidgets('when rendered, it should use theme background color', (tester) async {
      await tester.pumpWidget(const TestApp(child: _TestButtonsBar()));

      expect(_barDecoration(tester).color, equals(const Color(0xFFFFFFFF)));
    });

    testWidgets('when rendered, it should apply item padding', (tester) async {
      await tester.pumpWidget(const TestApp(child: _TestButtonsBar()));

      expect(_barContainer(tester).padding, equals(const EdgeInsets.all(12)));
    });

    testWidgets('when multiple items are provided, it should space them by forty pixels', (tester) async {
      await tester.pumpWidget(const TestApp(child: _TestButtonsBar()));

      expect(_itemGap(tester), equals(40));
    });

    testWidgets('when widthFit is fitItems, it should size to content width', (tester) async {
      await tester.pumpWidget(const TestApp(child: _TestButtonsBar()));

      expect(tester.getSize(find.byKey(const Key('qui_buttons_bar_container'))).width, equals(104));
    });

    testWidgets('when widthFit is expand, it should fill finite available width', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: SizedBox(width: 260, child: _TestButtonsBar(widthFit: QuiButtonsBarFit.expand)),
        ),
      );

      expect(tester.getSize(find.byKey(const Key('qui_buttons_bar_container'))).width, equals(260));
    });

    testWidgets('when height is not constrained, it should size height to content', (tester) async {
      await tester.pumpWidget(const TestApp(child: _TestButtonsBar()));

      expect(tester.getSize(find.byKey(const Key('qui_buttons_bar_container'))).height, equals(44));
    });

    testWidgets('when constraints specify fixed height, it should use that height', (tester) async {
      await tester.pumpWidget(
        const TestApp(child: _TestButtonsBar(constraints: BoxConstraints.tightFor(height: 100))),
      );

      expect(tester.getSize(find.byKey(const Key('qui_buttons_bar_container'))).height, equals(100));
    });

    testWidgets('when constraints specify fixed width, it should use that width', (tester) async {
      await tester.pumpWidget(const TestApp(child: _TestButtonsBar(constraints: BoxConstraints.tightFor(width: 220))));

      expect(tester.getSize(find.byKey(const Key('qui_buttons_bar_container'))).width, equals(220));
    });

    testWidgets('when items are empty, it should fail the constructor assert', (tester) async {
      expect(() => QuiButtonsBar(items: const []), throwsAssertionError);
    });
  });
}

BoxDecoration _barDecoration(WidgetTester tester) {
  return _barContainer(tester).decoration! as BoxDecoration;
}

Container _barContainer(WidgetTester tester) {
  return tester.widget<Container>(find.byKey(const Key('qui_buttons_bar_container')));
}

double _itemGap(WidgetTester tester) {
  final firstItem = find.byKey(const Key('qui_buttons_bar_test_first_item'));
  final secondItem = find.byKey(const Key('qui_buttons_bar_test_second_item'));

  return tester.getTopLeft(secondItem).dx - tester.getTopRight(firstItem).dx;
}

class _TestButtonsBar extends StatelessWidget {
  const _TestButtonsBar({this.constraints, this.widthFit = QuiButtonsBarFit.fitItems});

  final BoxConstraints? constraints;
  final QuiButtonsBarFit widthFit;

  @override
  Widget build(BuildContext context) {
    return QuiButtonsBar(
      constraints: constraints,
      widthFit: widthFit,
      items: const [
        SizedBox.square(key: Key('qui_buttons_bar_test_first_item'), dimension: 20),
        SizedBox.square(key: Key('qui_buttons_bar_test_second_item'), dimension: 20),
      ],
    );
  }
}
