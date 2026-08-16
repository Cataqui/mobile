import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
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

  group('CreateJobState', () {
    test('when setting a non-empty description, it should preserve the raw text in create-job state', () {
      final container = _CreateJobStateTestHelpers.createContainer(jobRepository: jobRepository);

      container.read(createJobStateProvider.notifier).setDescription('  Preciso de ajuda  ');

      expect(container.read(createJobStateProvider).descriptionText, '  Preciso de ajuda  ');
    });

    test('when clearing the description, it should store null in create-job state', () {
      final container = _CreateJobStateTestHelpers.createContainer(jobRepository: jobRepository);
      container.read(createJobStateProvider.notifier).setDescription('Preciso de ajuda');

      container.read(createJobStateProvider.notifier).setDescription('');

      expect(container.read(createJobStateProvider).descriptionText, isNull);
    });

    test('when creating a draft, it should submit the preserved raw description through the repository', () async {
      final container = _CreateJobStateTestHelpers.createContainer(jobRepository: jobRepository);
      const description = '  Preciso de uma pessoa para descarregar caixas.  ';
      container.read(createJobStateProvider.notifier).setDescription(description);

      await container.read(createJobStateProvider.notifier).createDraft();

      verify(() => jobRepository.createDraft(description: description)).called(1);
    });

    test('when draft creation succeeds, it should return the created draft', () async {
      final expectedDraft = JobDraftDto.fixture().copyWith(jobId: 'created-draft-id');
      when(
        () => jobRepository.createDraft(description: any(named: 'description')),
      ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: expectedDraft));
      final container = _CreateJobStateTestHelpers.createContainer(jobRepository: jobRepository);
      container.read(createJobStateProvider.notifier).setDescription('Preciso de ajuda com algumas caixas.');

      final draft = await container.read(createJobStateProvider.notifier).createDraft();

      expect(draft, expectedDraft);
    });

    test('when draft creation succeeds, it should store the created job id', () async {
      final expectedDraft = JobDraftDto.fixture().copyWith(jobId: 'created-draft-id');
      when(
        () => jobRepository.createDraft(description: any(named: 'description')),
      ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: expectedDraft));
      final container = _CreateJobStateTestHelpers.createContainer(jobRepository: jobRepository);
      container.read(createJobStateProvider.notifier).setDescription('Preciso de ajuda com algumas caixas.');

      await container.read(createJobStateProvider.notifier).createDraft();

      expect(container.read(createJobStateProvider).jobId, expectedDraft.jobId);
    });

    test('when draft creation is pending, it should expose that the draft is being created', () async {
      final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
      when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
      final container = _CreateJobStateTestHelpers.createContainer(jobRepository: jobRepository);
      container.read(createJobStateProvider.notifier).setDescription('Preciso de ajuda com algumas caixas.');

      final result = container.read(createJobStateProvider.notifier).createDraft();

      expect(container.read(createJobStateProvider).isCreatingDraft, isTrue);
      response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
      await result;
    });

    test('when draft creation succeeds, it should stop exposing draft creation as pending', () async {
      final container = _CreateJobStateTestHelpers.createContainer(jobRepository: jobRepository);
      container.read(createJobStateProvider.notifier).setDescription('Preciso de ajuda com algumas caixas.');

      await container.read(createJobStateProvider.notifier).createDraft();

      expect(container.read(createJobStateProvider).isCreatingDraft, isFalse);
    });

    test('when draft creation fails, it should propagate the repository failure', () async {
      final failure = Exception('request failed');
      when(() => jobRepository.createDraft(description: any(named: 'description'))).thenThrow(failure);
      final container = _CreateJobStateTestHelpers.createContainer(jobRepository: jobRepository);
      container.read(createJobStateProvider.notifier).setDescription('Preciso de ajuda com algumas caixas.');

      final result = container.read(createJobStateProvider.notifier).createDraft();

      await expectLater(result, throwsA(same(failure)));
    });

    test('when changing the payment amount, it should preserve the entered text', () {
      final container = _CreateJobStateTestHelpers.createContainer(jobRepository: jobRepository);

      container.read(createJobStateProvider.notifier).setPaymentAmount('1250');

      expect(container.read(createJobStateProvider).paymentAmount, '1250');
    });
  });
}

abstract final class _CreateJobStateTestHelpers {
  static ProviderContainer createContainer({required JobRepository jobRepository}) {
    final container = ProviderContainer(overrides: [jobRepositoryProvider.overrideWithValue(jobRepository)])
      ..listen(createJobStateProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }
}
