import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiButton Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_button_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(minWidth: 260),
        children: [
          GoldenTestScenario(
            name: 'resting label only',
            child: QuiButton(variant: QuiButtonVariant.primary, label: 'Ver oportunidades', onPressed: () {}),
          ),
          GoldenTestScenario(
            name: 'secondary resting label only',
            child: QuiButton(variant: QuiButtonVariant.secondary, label: 'Ver oportunidades', onPressed: () {}),
          ),
          GoldenTestScenario(
            name: 'leading icon',
            child: QuiButton(
              variant: QuiButtonVariant.primary,
              label: 'Buscar',
              leadingIconBuilder: (state) => Icon(Icons.search, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'trailing icon',
            child: QuiButton(
              variant: QuiButtonVariant.primary,
              label: 'Continuar',
              trailingIconBuilder: (state) => Icon(Icons.arrow_forward, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'both icons',
            child: QuiButton(
              variant: QuiButtonVariant.primary,
              label: 'Filtrar',
              leadingIconBuilder: (state) => Icon(Icons.tune, color: state.foregroundColor, size: 20),
              trailingIconBuilder: (state) => Icon(Icons.arrow_drop_down, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'custom color scheme background',
            child: QuiButton(
              variant: QuiButtonVariant.primary,
              label: 'Mapa',
              colorScheme: const QuiButtonColorScheme(
                background: Color(0xFF00A676),
                backgroundHover: Color(0xFF009966),
                backgroundDisabled: Color(0xFFDDDDDD),
                foreground: Color(0xFFFFFFFF),
                foregroundDisabled: Color(0xFF999999),
              ),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'custom color scheme foreground',
            child: QuiButton(
              variant: QuiButtonVariant.primary,
              label: 'Salvar',
              colorScheme: const QuiButtonColorScheme(
                background: Color(0xFFFFCD00),
                backgroundHover: Color(0xFFE6B900),
                backgroundDisabled: Color(0xFFDDDDDD),
                foreground: Color(0xFF1A1A1A),
                foregroundDisabled: Color(0xFF999999),
              ),
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: QuiButton(
              variant: QuiButtonVariant.primary,
              label: 'Indisponivel',
              leadingIconBuilder: (state) => Icon(Icons.lock, color: state.foregroundColor, size: 20),
            ),
          ),
          GoldenTestScenario(
            name: 'secondary disabled',
            child: QuiButton(
              variant: QuiButtonVariant.secondary,
              label: 'Indisponivel',
              leadingIconBuilder: (state) => Icon(Icons.lock, color: state.foregroundColor, size: 20),
            ),
          ),
          GoldenTestScenario(
            name: 'disabled custom color scheme',
            child: const QuiButton(
              variant: QuiButtonVariant.primary,
              label: 'Fechado',
              colorScheme: QuiButtonColorScheme(
                background: Color(0xFF00A676),
                backgroundHover: Color(0xFF009966),
                backgroundDisabled: Color(0xFFDDDDDD),
                foreground: Color(0xFFFFFFFF),
                foregroundDisabled: Color(0xFF999999),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'expand',
            child: const SizedBox(
              width: 300,
              child: QuiButton(
                variant: QuiButtonVariant.primary,
                label: 'Expandido',
                fit: QuiButtonFit.expand,
                onPressed: null,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'short label',
            child: QuiButton(variant: QuiButtonVariant.primary, label: 'OK', onPressed: () {}),
          ),
          GoldenTestScenario(
            name: 'long label',
            child: QuiButton(
              variant: QuiButtonVariant.primary,
              label: 'Enviar candidatura completa agora',
              onPressed: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'custom padding',
            child: const QuiButton(
              variant: QuiButtonVariant.primary,
              label: 'Compacto',
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: null,
            ),
          ),
          GoldenTestScenario(
            name: 'custom spacing',
            child: QuiButton(
              variant: QuiButtonVariant.primary,
              label: 'Espacado',
              leadingIconSpacing: 14,
              trailingIconSpacing: 18,
              leadingIconBuilder: (state) => Icon(Icons.tune, color: state.foregroundColor, size: 20),
              trailingIconBuilder: (state) => Icon(Icons.arrow_forward, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'when rendering alignment variants with expand, it should match the approved goldens',
      fileName: 'qui_button_alignment',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'left',
            child: SizedBox(
              width: 300,
              child: QuiButton(
                variant: QuiButtonVariant.primary,
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
              child: QuiButton(
                variant: QuiButtonVariant.primary,
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
              child: QuiButton(
                variant: QuiButtonVariant.primary,
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
      fileName: 'qui_button_pressed',
      whilePerforming: (tester) async {
        final gesture = await tester.startGesture(tester.getCenter(find.text('Ver oportunidades')));
        await tester.pump(const Duration(milliseconds: 120));
        addTearDown(gesture.removePointer);
        return null;
      },
      builder: () => SizedBox(
        width: 220,
        child: QuiButton(variant: QuiButtonVariant.primary, label: 'Ver oportunidades', onPressed: () {}),
      ),
    );

    goldenTest(
      'when rendering loading states with animations disabled, it should match the approved goldens',
      fileName: 'qui_button_loading',
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
              child: QuiButton(
                variant: QuiButtonVariant.primary,
                label: 'Fit loading',
                onPressed: () => Completer<void>().future,
              ),
            ),
            GoldenTestScenario(
              name: 'expand loading',
              child: SizedBox(
                width: 300,
                child: QuiButton(
                  variant: QuiButtonVariant.primary,
                  label: 'Expand loading',
                  fit: QuiButtonFit.expand,
                  onPressed: () => Completer<void>().future,
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'custom color scheme loading',
              child: QuiButton(
                variant: QuiButtonVariant.primary,
                label: 'Custom loading',
                colorScheme: const QuiButtonColorScheme(
                  background: Color(0xFFFFCD00),
                  backgroundHover: Color(0xFFE6B900),
                  backgroundDisabled: Color(0xFFDDDDDD),
                  foreground: Color(0xFF1A1A1A),
                  foregroundDisabled: Color(0xFF999999),
                ),
                onPressed: () => Completer<void>().future,
              ),
            ),
            GoldenTestScenario(
              name: 'loading with icon',
              child: QuiButton(
                variant: QuiButtonVariant.primary,
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
      fileName: 'qui_button_custom_dimensions',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          GoldenTestScenario(
            name: 'fit with icons',
            child: QuiButton(
              variant: QuiButtonVariant.primary,
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
              child: QuiButton(
                variant: QuiButtonVariant.primary,
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
              child: QuiButton(
                variant: QuiButtonVariant.primary,
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
      fileName: 'qui_button_stacked',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'stacked variants',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QuiButton(variant: QuiButtonVariant.primary, label: 'Ver oportunidades', onPressed: () {}),
                const SizedBox(height: 12),
                QuiButton(
                  variant: QuiButtonVariant.primary,
                  label: 'Buscar',
                  leadingIconBuilder: (state) => Icon(Icons.search, color: state.foregroundColor, size: 20),
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                QuiButton(
                  variant: QuiButtonVariant.primary,
                  label: 'Continuar',
                  trailingIconBuilder: (state) => Icon(Icons.arrow_forward, color: state.foregroundColor, size: 20),
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                QuiButton(
                  variant: QuiButtonVariant.primary,
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
