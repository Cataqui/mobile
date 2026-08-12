import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobCreationFlowState', () {
    test('when setting a non-empty description, it should preserve the raw text in the shared flow data', () {
      final container = _JobCreationFlowStateTestHelpers.createContainer();

      container.read(jobCreationFlowStateProvider.notifier).setDescription('  Preciso de ajuda  ');

      expect(container.read(jobCreationFlowStateProvider).descriptionText, '  Preciso de ajuda  ');
    });

    test('when clearing the description, it should store null in the shared flow data', () {
      final container = _JobCreationFlowStateTestHelpers.createContainer();
      container.read(jobCreationFlowStateProvider.notifier).setDescription('Preciso de ajuda');

      container.read(jobCreationFlowStateProvider.notifier).setDescription('');

      expect(container.read(jobCreationFlowStateProvider).descriptionText, isNull);
    });
  });
}

abstract final class _JobCreationFlowStateTestHelpers {
  static ProviderContainer createContainer() {
    final container = ProviderContainer()..listen(jobCreationFlowStateProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }
}
