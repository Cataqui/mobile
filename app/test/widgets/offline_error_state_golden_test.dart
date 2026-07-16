import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/widgets/offline_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfflineErrorState Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'offline_error_state_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          GoldenTestScenario(
            name: 'full',
            child: OfflineErrorState(
              title: 'Sem conexão',
              description: 'Verifique sua internet e tente novamente.',
              retry: (label: 'Tentar novamente', onRetry: () {}),
            ),
          ),
          GoldenTestScenario(
            name: 'no description',
            child: OfflineErrorState(title: 'Sem conexão', retry: (label: 'Tentar novamente', onRetry: () {})),
          ),
          GoldenTestScenario(
            name: 'no retry',
            child: const OfflineErrorState(
              title: 'Sem conexão',
              description: 'Verifique sua internet e tente novamente.',
            ),
          ),
          GoldenTestScenario(
            name: 'title only',
            child: const OfflineErrorState(title: 'Sem conexão'),
          ),
        ],
      ),
    );
  });
}
