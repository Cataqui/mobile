import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiLoadingText Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_loading_text_states',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'default',
            child: const TickerMode(
              enabled: false,
              child: MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: QuiLoadingText(text: 'Carregando oportunidades...'),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'custom indicator color',
            child: const TickerMode(
              enabled: false,
              child: MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: QuiLoadingText(
                  text: 'Buscando...',
                  progressIndicatorColor: Color(0xFF00A676),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'long text',
            child: const TickerMode(
              enabled: false,
              child: MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: QuiLoadingText(text: 'Verificando novas oportunidades perto de você...'),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
