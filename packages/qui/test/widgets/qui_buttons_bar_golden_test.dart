import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiButtonsBar Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_buttons_bar_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(width: 360, height: 140),
        children: [
          GoldenTestScenario(name: 'fit content', child: const _ButtonsBarScenario()),
          GoldenTestScenario(
            name: 'expanded width',
            child: const SizedBox(width: 260, child: _ButtonsBarScenario(widthFit: QuiButtonsBarFit.expand)),
          ),
          GoldenTestScenario(
            name: 'fixed width',
            child: const _ButtonsBarScenario(constraints: BoxConstraints.tightFor(width: 240)),
          ),
        ],
      ),
    );
  });
}

class _ButtonsBarScenario extends StatelessWidget {
  const _ButtonsBarScenario({this.constraints, this.widthFit = QuiButtonsBarFit.fitItems});

  final BoxConstraints? constraints;
  final QuiButtonsBarFit widthFit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFE8E2D7)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: QuiButtonsBar(
            constraints: constraints,
            widthFit: widthFit,
            items: [
              QuiIconButton(
                backgroundColor: const Color(0xFFE92D2F),
                iconBuilder: (state) => Icon(Icons.close, color: state.recommendedIconColor, size: state.iconSize),
                onPressed: () {},
              ),
              QuiIconButton(
                backgroundColor: const Color(0xFF2ED94F),
                iconBuilder: (state) => Icon(Icons.phone, color: state.recommendedIconColor, size: state.iconSize),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
