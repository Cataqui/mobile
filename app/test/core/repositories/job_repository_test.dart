import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

final _jobEnvelopeJson = <String, Object?>{
  'data': JobDto.fixture().toJson(),
  'request_id': '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
  'timestamp': '2026-06-06T00:37:46.623Z',
  'endpoint': '/job/dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
};

void main() {
  late MockDio dio;
  late JobRepository repository;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = MockDio();
    repository = JobRepository(dio: dio);
    _stubJobRequest(dio: dio);
  });

  group('JobRepository', () {
    test('when requesting a job, it should call the job detail endpoint with the job id', () async {
      await repository.getJob(jobId: 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502', locale: AppLocale.ptBr);

      verify(
        () => dio.get<Map<String, Object?>>(
          '/job/dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('when requesting a job, it should send the accept-language header from the current locale', () async {
      await repository.getJob(jobId: 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502', locale: AppLocale.ptBr);

      verify(
        () => dio.get<Map<String, Object?>>(
          any(),
          options: any(
            named: 'options',
            that: predicate<Options>((o) => o.headers?['accept-language'] == 'pt-BR'),
          ),
        ),
      ).called(1);
    });

    test('when receiving a job, it should map the job dto data', () async {
      final envelope = await repository.getJob(jobId: 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502', locale: AppLocale.ptBr);

      expect(envelope.data.jobId, JobDto.fixture().jobId);
    });

    test('when receiving a job, it should map the request id', () async {
      final envelope = await repository.getJob(jobId: 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502', locale: AppLocale.ptBr);

      expect(envelope.requestId, '5b591550-c650-4e27-a2ed-d6f02e1c0da2');
    });
  });

  group('jobRepositoryProvider', () {
    test('when reading the provider, it should expose a job repository', () {
      final container = ProviderContainer(overrides: [cataquiDioProvider.overrideWithValue(MockDio())]);
      addTearDown(container.dispose);

      final result = container.read(jobRepositoryProvider);

      expect(result, isA<JobRepository>());
    });
  });
}

void _stubJobRequest({required MockDio dio, Map<String, Object?>? responseJson}) {
  when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenAnswer(
    (_) async => Response<Map<String, Object?>>(
      data: responseJson ?? _jobEnvelopeJson,
      requestOptions: RequestOptions(path: '/job/dfa0eb67-7b9b-4df5-9112-b92e7a8a7502'),
    ),
  );
}
