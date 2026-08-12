import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_data.dart';
import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockJobRepository jobRepository;

  setUp(() {
    jobRepository = MockJobRepository();
    when(
      () => jobRepository.createDraft(description: any(named: 'description')),
    ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
  });

  group('JobCreationFlowState', () {
    test('when setting a non-empty description, it should preserve the raw text in the shared flow data', () {
      final container = _JobCreationFlowStateTestHelpers.createContainer(jobRepository: jobRepository);

      container.read(jobCreationFlowStateProvider.notifier).setDescription('  Preciso de ajuda  ');

      expect(container.read(jobCreationFlowStateProvider).descriptionText, '  Preciso de ajuda  ');
    });

    test('when clearing the description, it should store null in the shared flow data', () {
      final container = _JobCreationFlowStateTestHelpers.createContainer(jobRepository: jobRepository);
      container.read(jobCreationFlowStateProvider.notifier).setDescription('Preciso de ajuda');

      container.read(jobCreationFlowStateProvider.notifier).setDescription('');

      expect(container.read(jobCreationFlowStateProvider).descriptionText, isNull);
    });

    test('when creating a draft, it should submit the preserved raw description through the repository', () async {
      final container = _JobCreationFlowStateTestHelpers.createContainer(jobRepository: jobRepository);
      const description = '  Preciso de uma pessoa para descarregar caixas.  ';
      container.read(jobCreationFlowStateProvider.notifier).setDescription(description);

      await container.read(jobCreationFlowStateProvider.notifier).createDraft();

      verify(() => jobRepository.createDraft(description: description)).called(1);
    });

    test('when draft creation succeeds, it should return the created draft', () async {
      final expectedDraft = JobDraftDto.fixture().copyWith(jobId: 'created-draft-id');
      when(
        () => jobRepository.createDraft(description: any(named: 'description')),
      ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: expectedDraft));
      final container = _JobCreationFlowStateTestHelpers.createContainer(jobRepository: jobRepository);
      container.read(jobCreationFlowStateProvider.notifier).setDescription('Preciso de ajuda com algumas caixas.');

      final draft = await container.read(jobCreationFlowStateProvider.notifier).createDraft();

      expect(draft, expectedDraft);
    });

    test('when draft creation succeeds, it should leave the shared flow data unchanged', () async {
      final container = _JobCreationFlowStateTestHelpers.createContainer(jobRepository: jobRepository);
      const expectedData = JobCreationFlowData(descriptionText: 'Preciso de ajuda com algumas caixas.');
      container.read(jobCreationFlowStateProvider.notifier).setDescription(expectedData.descriptionText!);

      await container.read(jobCreationFlowStateProvider.notifier).createDraft();

      expect(container.read(jobCreationFlowStateProvider), expectedData);
    });

    test('when draft creation fails, it should propagate the repository failure', () async {
      final failure = Exception('request failed');
      when(() => jobRepository.createDraft(description: any(named: 'description'))).thenThrow(failure);
      final container = _JobCreationFlowStateTestHelpers.createContainer(jobRepository: jobRepository);
      container.read(jobCreationFlowStateProvider.notifier).setDescription('Preciso de ajuda com algumas caixas.');

      final result = container.read(jobCreationFlowStateProvider.notifier).createDraft();

      await expectLater(result, throwsA(same(failure)));
    });
  });
}

abstract final class _JobCreationFlowStateTestHelpers {
  static ProviderContainer createContainer({required JobRepository jobRepository}) {
    final container = ProviderContainer(overrides: [jobRepositoryProvider.overrideWithValue(jobRepository)])
      ..listen(jobCreationFlowStateProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }
}
