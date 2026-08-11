import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/job/job_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockJobRepository repository;

  setUp(() {
    repository = MockJobRepository();
    when(() => repository.getJob(jobId: any(named: 'jobId'))).thenAnswer((_) async => _envelope());
  });

  group('JobState', () {
    test('when the provider is first read, it should expose the job data', () async {
      final container = _container(repository: repository);

      final jobState = await container.read(jobStateProvider('dfa0eb67-7b9b-4df5-9112-b92e7a8a7502').future);

      expect(jobState.job.jobId, 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502');
    });

    test('when the provider is first read, it should pass the requested job id to the repository', () async {
      final container = _container(repository: repository);

      await container.read(jobStateProvider('custom-job-id').future);

      verify(() => repository.getJob(jobId: 'custom-job-id')).called(1);
    });

    test('when retry is called, it should fetch the job again', () async {
      final container = _container(repository: repository);
      await container.read(jobStateProvider('retry-test-id').future);
      final secondJob = JobDto.fixture().copyWith(jobId: 'second-fetch-job');
      when(() => repository.getJob(jobId: any(named: 'jobId'))).thenAnswer((_) async => _envelope(job: secondJob));

      await container.read(jobStateProvider('retry-test-id').notifier).retry();

      expect(container.read(jobStateProvider('retry-test-id')).value?.job.jobId, 'second-fetch-job');
    });

    test('when retry fails after a successful load, it should expose an AsyncError', () async {
      final container = _container(repository: repository);
      await container.read(jobStateProvider('retry-fail-id').future);
      when(() => repository.getJob(jobId: any(named: 'jobId'))).thenThrow(StateError('retry failed'));

      await container.read(jobStateProvider('retry-fail-id').notifier).retry();

      expect(container.read(jobStateProvider('retry-fail-id')).hasError, isTrue);
    });

    test('when the initial fetch fails, it should expose an AsyncError', () async {
      final failingRepository = MockJobRepository();
      when(() => failingRepository.getJob(jobId: any(named: 'jobId'))).thenThrow(StateError('initial fetch failed'));
      final container = _container(repository: failingRepository);

      await expectLater(container.read(jobStateProvider('fail-id').future), throwsA(isA<StateError>()));
    });
  });
}

ProviderContainer _container({required MockJobRepository repository}) {
  final container = ProviderContainer(overrides: [jobRepositoryProvider.overrideWithValue(repository)]);
  addTearDown(container.dispose);
  return container;
}

ApiEnvelopeDto<JobDto> _envelope({JobDto? job}) {
  return ApiEnvelopeDto<JobDto>(
    data: job ?? JobDto.fixture().copyWith(jobId: 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502'),
    requestId: '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
    timestamp: DateTime.parse('2026-06-06T00:37:46.623Z'),
    endpoint: '/v1/jobs/test-id',
  );
}
