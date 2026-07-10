import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiSecondaryButton Golden Tests', () {
    autoUpdateGoldenFiles = true;
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_secondary_button_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(minWidth: 260),
        children: [
          GoldenTestScenario(
            name: 'resting label only',
            child: QuiSecondaryButton(label: 'Ver oportunidades', onPressed: () {}),
          ),
          GoldenTestScenario(
            name: 'leading icon',
            child: QuiSecondaryButton(
              label: 'Buscar',
              leadingIconBuilder: (state) => Icon(Icons.search, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'trailing icon',
            child: QuiSecondaryButton(
              label: 'Continuar',
              trailingIconBuilder: (state) => Icon(Icons.arrow_forward, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'both icons',
            child: QuiSecondaryButton(
              label: 'Filtrar',
              leadingIconBuilder: (state) => Icon(Icons.tune, color: state.foregroundColor, size: 20),
              trailingIconBuilder: (state) => Icon(Icons.arrow_drop_down, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: QuiSecondaryButton(
              label: 'Indisponivel',
              leadingIconBuilder: (state) => Icon(Icons.lock, color: state.foregroundColor, size: 20),
            ),
          ),
          GoldenTestScenario(
            name: 'expand',
            child: const SizedBox(
              width: 300,
              child: QuiSecondaryButton(label: 'Expandido', fit: QuiButtonFit.expand, onPressed: null),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'when rendering alignment variants with expand, it should match the approved goldens',
      fileName: 'qui_secondary_button_alignment',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'left',
            child: SizedBox(
              width: 300,
              child: QuiSecondaryButton(
                label: 'Esquerda',
                fit: QuiButtonFit.expand,
                alignment: QuiButtonAlignment.left,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'center',
            child: SizedBox(
              width: 300,
              child: QuiSecondaryButton(
                label: 'Centro',
                fit: QuiButtonFit.expand,
                alignment: QuiButtonAlignment.center,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'right',
            child: SizedBox(
              width: 300,
              child: QuiSecondaryButton(
                label: 'Direita',
                fit: QuiButtonFit.expand,
                alignment: QuiButtonAlignment.right,
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'when pressing the button, it should match the approved golden',
      fileName: 'qui_secondary_button_pressed',
      whilePerforming: (tester) async {
        final gesture = await tester.startGesture(tester.getCenter(find.text('Ver oportunidades')));
        await tester.pump(const Duration(milliseconds: 120));
        addTearDown(gesture.removePointer);
        return null;
      },
      builder: () => SizedBox(
        width: 220,
        child: QuiSecondaryButton(label: 'Ver oportunidades', onPressed: () {}),
      ),
    );
  });
}
