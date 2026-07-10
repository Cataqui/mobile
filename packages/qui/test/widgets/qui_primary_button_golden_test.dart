import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiPrimaryButton Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_primary_button_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(minWidth: 260),
        children: [
          GoldenTestScenario(
            name: 'resting label only',
            child: QuiPrimaryButton(label: 'Ver oportunidades', onPressed: () {}),
          ),
          GoldenTestScenario(
            name: 'leading icon',
            child: QuiPrimaryButton(
              label: 'Buscar',
              leadingIconBuilder: (state) => Icon(Icons.search, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'trailing icon',
            child: QuiPrimaryButton(
              label: 'Continuar',
              trailingIconBuilder: (state) => Icon(Icons.arrow_forward, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'both icons',
            child: QuiPrimaryButton(
              label: 'Filtrar',
              leadingIconBuilder: (state) => Icon(Icons.tune, color: state.foregroundColor, size: 20),
              trailingIconBuilder: (state) => Icon(Icons.arrow_drop_down, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'custom background',
            child: QuiPrimaryButton(
              label: 'Mapa',
              backgroundColor: const Color(0xFF00A676),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'custom foreground',
            child: QuiPrimaryButton(
              label: 'Salvar',
              foregroundColor: const Color(0xFF1A1A1A),
              backgroundColor: const Color(0xFFFFCD00),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: QuiPrimaryButton(
              label: 'Indisponivel',
              leadingIconBuilder: (state) => Icon(Icons.lock, color: state.foregroundColor, size: 20),
            ),
          ),
          GoldenTestScenario(
            name: 'disabled custom background',
            child: const QuiPrimaryButton(
              label: 'Fechado',
              disabledBackgroundColor: Color(0xFFDDDDDD),
            ),
          ),
          GoldenTestScenario(
            name: 'expand',
            child: const SizedBox(
              width: 300,
              child: QuiPrimaryButton(label: 'Expandido', fit: QuiPrimaryButtonFit.expand, onPressed: null),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'when rendering alignment variants with expand, it should match the approved goldens',
      fileName: 'qui_primary_button_alignment',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'left',
            child: SizedBox(
              width: 300,
              child: QuiPrimaryButton(
                label: 'Esquerda',
                fit: QuiPrimaryButtonFit.expand,
                alignment: QuiPrimaryButtonAlignment.left,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'center',
            child: SizedBox(
              width: 300,
              child: QuiPrimaryButton(
                label: 'Centro',
                fit: QuiPrimaryButtonFit.expand,
                alignment: QuiPrimaryButtonAlignment.center,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'right',
            child: SizedBox(
              width: 300,
              child: QuiPrimaryButton(
                label: 'Direita',
                fit: QuiPrimaryButtonFit.expand,
                alignment: QuiPrimaryButtonAlignment.right,
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'when pressing the button, it should match the approved golden',
      fileName: 'qui_primary_button_pressed',
      whilePerforming: (tester) async {
        final gesture = await tester.startGesture(tester.getCenter(find.text('Ver oportunidades')));
        await tester.pump(const Duration(milliseconds: 120));
        addTearDown(gesture.removePointer);
        return null;
      },
      builder: () => SizedBox(
        width: 220,
        child: QuiPrimaryButton(label: 'Ver oportunidades', onPressed: () {}),
      ),
    );
  });
}
