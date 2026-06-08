import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiTextButton Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_text_button_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(minWidth: 180),
        children: [
          GoldenTestScenario(
            name: 'resting text only',
            child: QuiTextButton(text: 'Ver oportunidades', onPressed: () {}),
          ),
          GoldenTestScenario(
            name: 'leading icon',
            child: QuiTextButton(
              text: 'Buscar',
              iconBuilder: (state) => Icon(Icons.search, color: state.recommendedIconColor, size: 18),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'trailing icon',
            child: QuiTextButton(
              text: 'Continuar',
              iconBuilder: (state) => Icon(Icons.arrow_forward, color: state.recommendedIconColor, size: 18),
              iconPosition: QuiTextButtonIconPosition.trailing,
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'custom color',
            child: QuiTextButton(text: 'Destacar', color: const Color(0xFFFF4A4B), onPressed: () {}),
          ),
          GoldenTestScenario(
            name: 'independent icon color',
            child: QuiTextButton(
              text: 'Mapa',
              iconBuilder: (state) => const Icon(Icons.location_on, size: 18, color: Color(0xFF00A676)),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: QuiTextButton(
              text: 'Indisponivel',
              iconBuilder: (state) => Icon(Icons.lock, color: state.recommendedIconColor, size: 18),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'when pressing the button, it should match the approved golden',
      fileName: 'qui_text_button_pressed',
      whilePerforming: (tester) async {
        final gesture = await tester.startGesture(tester.getCenter(find.text('Ver oportunidades')));
        await tester.pump(const Duration(milliseconds: 120));
        addTearDown(gesture.removePointer);
        return null;
      },
      builder: () => SizedBox(
        width: 180,
        child: QuiTextButton(text: 'Ver oportunidades', onPressed: () {}),
      ),
    );
  });
}
