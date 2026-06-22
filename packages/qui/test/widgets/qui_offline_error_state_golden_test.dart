import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiOfflineErrorState Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'qui_offline_error_state_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          GoldenTestScenario(
            name: 'full',
            child: QuiOfflineErrorState(
              title: 'Sem conexão',
              description: 'Verifique sua internet e tente novamente.',
              retry: (label: 'Tentar novamente', onRetry: () {}),
            ),
          ),
          GoldenTestScenario(
            name: 'no description',
            child: QuiOfflineErrorState(
              title: 'Sem conexão',
              retry: (label: 'Tentar novamente', onRetry: () {}),
            ),
          ),
          GoldenTestScenario(
            name: 'no retry',
            child: const QuiOfflineErrorState(
              title: 'Sem conexão',
              description: 'Verifique sua internet e tente novamente.',
            ),
          ),
          GoldenTestScenario(
            name: 'title only',
            child: const QuiOfflineErrorState(
              title: 'Sem conexão',
            ),
          ),
        ],
      ),
    );
  });
}
