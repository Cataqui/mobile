import 'dart:async';

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
            child: QuiPrimaryButton(label: 'Mapa', backgroundColor: const Color(0xFF00A676), onPressed: () {}),
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
            child: const QuiPrimaryButton(label: 'Fechado', disabledBackgroundColor: Color(0xFFDDDDDD)),
          ),
          GoldenTestScenario(
            name: 'expand',
            child: const SizedBox(
              width: 300,
              child: QuiPrimaryButton(label: 'Expandido', fit: QuiButtonFit.expand, onPressed: null),
            ),
          ),
          GoldenTestScenario(
            name: 'short label',
            child: QuiPrimaryButton(label: 'OK', onPressed: () {}),
          ),
          GoldenTestScenario(
            name: 'long label',
            child: QuiPrimaryButton(label: 'Enviar candidatura completa agora', onPressed: () {}),
          ),
          GoldenTestScenario(
            name: 'custom padding',
            child: const QuiPrimaryButton(
              label: 'Compacto',
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: null,
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
              child: QuiPrimaryButton(
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
              child: QuiPrimaryButton(
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

    goldenTest(
      'when rendering loading states with animations disabled, it should match the approved goldens',
      fileName: 'qui_primary_button_loading',
      whilePerforming: (tester) async {
        await tester.tap(find.text('Fit loading'));
        await tester.tap(find.text('Expand loading'));
        await tester.tap(find.text('Custom loading'));
        await tester.pump(const Duration(milliseconds: 101));
        await tester.pump();
        return null;
      },
      builder: () => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(minWidth: 300),
          children: [
            GoldenTestScenario(
              name: 'fit loading',
              child: QuiPrimaryButton(label: 'Fit loading', onPressed: () => Completer<void>().future),
            ),
            GoldenTestScenario(
              name: 'expand loading',
              child: SizedBox(
                width: 300,
                child: QuiPrimaryButton(
                  label: 'Expand loading',
                  fit: QuiButtonFit.expand,
                  onPressed: () => Completer<void>().future,
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'custom foreground loading',
              child: QuiPrimaryButton(
                label: 'Custom loading',
                foregroundColor: const Color(0xFF1A1A1A),
                backgroundColor: const Color(0xFFFFCD00),
                onPressed: () => Completer<void>().future,
              ),
            ),
            GoldenTestScenario(
              name: 'loading with icon',
              child: QuiPrimaryButton(
                label: 'Icon loading',
                leadingIconBuilder: (state) => Icon(Icons.search, color: state.foregroundColor, size: 20),
                onPressed: () => Completer<void>().future,
              ),
            ),
          ],
        ),
      ),
    );

    goldenTest(
      'when rendering with custom dimensions, it should match the approved goldens',
      fileName: 'qui_primary_button_custom_dimensions',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          GoldenTestScenario(
            name: 'fit with icons',
            child: QuiPrimaryButton(
              label: 'Filtrar resultados',
              leadingIconBuilder: (state) => Icon(Icons.tune, color: state.foregroundColor, size: 20),
              trailingIconBuilder: (state) => Icon(Icons.arrow_drop_down, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'expand with trailing icon',
            child: SizedBox(
              width: 300,
              child: QuiPrimaryButton(
                label: 'Continuar',
                trailingIconBuilder: (state) => Icon(Icons.arrow_forward, color: state.foregroundColor, size: 20),
                fit: QuiButtonFit.expand,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'expand disabled',
            child: SizedBox(
              width: 300,
              child: QuiPrimaryButton(
                label: 'Indisponivel',
                fit: QuiButtonFit.expand,
                leadingIconBuilder: (state) => Icon(Icons.lock, color: state.foregroundColor, size: 20),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'when multiple buttons are stacked, it should match the approved goldens',
      fileName: 'qui_primary_button_stacked',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'stacked variants',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QuiPrimaryButton(label: 'Ver oportunidades', onPressed: () {}),
                const SizedBox(height: 12),
                QuiPrimaryButton(
                  label: 'Buscar',
                  leadingIconBuilder: (state) => Icon(Icons.search, color: state.foregroundColor, size: 20),
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                QuiPrimaryButton(
                  label: 'Continuar',
                  trailingIconBuilder: (state) => Icon(Icons.arrow_forward, color: state.foregroundColor, size: 20),
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                QuiPrimaryButton(
                  label: 'Indisponivel',
                  leadingIconBuilder: (state) => Icon(Icons.lock, color: state.foregroundColor, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });
}
