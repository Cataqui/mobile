import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockDio unauthenticatedDio;
  late JobRepository repository;

  setUp(() {
    unauthenticatedDio = MockDio();
    repository = JobRepository(unauthenticatedDio: unauthenticatedDio);
    _JobRepositoryTestHelpers.stubJobRequest(dio: unauthenticatedDio);
    _JobRepositoryTestHelpers.stubJobContactRequest(dio: unauthenticatedDio);
  });

  group('JobRepository', () {
    group('getJob', () {
      test('when requesting a job, it should call the job detail endpoint with the job id', () async {
        await repository.getJob(jobId: _JobRepositoryTestData.jobId);

        verify(() => unauthenticatedDio.get<Map<String, Object?>>('/jobs/${_JobRepositoryTestData.jobId}')).called(1);
      });

      test('when receiving a job, it should map the job dto data', () async {
        final envelope = await repository.getJob(jobId: _JobRepositoryTestData.jobId);

        expect(envelope.data.jobId, JobDto.fixture().jobId);
      });

      test('when receiving a job, it should map the request id', () async {
        final envelope = await repository.getJob(jobId: _JobRepositoryTestData.jobId);

        expect(envelope.requestId, '5b591550-c650-4e27-a2ed-d6f02e1c0da2');
      });
    });

    group('getJobContact', () {
      test('when requesting a job contact, it should call the contact endpoint with the job and contact ids', () async {
        await repository.getJobContact(
          jobId: _JobRepositoryTestData.jobId,
          contactId: _JobRepositoryTestData.contactId,
        );

        verify(
          () => unauthenticatedDio.get<Map<String, Object?>>(
            '/jobs/${_JobRepositoryTestData.jobId}/contact/${_JobRepositoryTestData.contactId}',
          ),
        ).called(1);
      });

      test('when receiving a job contact, it should map the contact method from the dto', () async {
        final envelope = await repository.getJobContact(
          jobId: _JobRepositoryTestData.jobId,
          contactId: _JobRepositoryTestData.contactId,
        );

        expect(envelope.data.contactMethod, _JobRepositoryTestData.contact.contactMethod);
      });

      test('when receiving a job contact, it should map the identifier from the dto', () async {
        final envelope = await repository.getJobContact(
          jobId: _JobRepositoryTestData.jobId,
          contactId: _JobRepositoryTestData.contactId,
        );

        expect(envelope.data.identifier, _JobRepositoryTestData.contact.identifier);
      });

      test('when receiving a job contact, it should map the request id', () async {
        final envelope = await repository.getJobContact(
          jobId: _JobRepositoryTestData.jobId,
          contactId: _JobRepositoryTestData.contactId,
        );

        expect(envelope.requestId, 'contact-req-001');
      });
    });
  });

  group('jobRepositoryProvider', () {
    test('when reading the provider, it should inject the unauthenticated dio for public job endpoints', () {
      final container = _JobRepositoryTestHelpers.createProviderContainer(unauthenticatedDio: unauthenticatedDio);

      final result = container.read(jobRepositoryProvider);

      expect(result.unauthenticatedDio, same(unauthenticatedDio));
    });
  });
}

abstract final class _JobRepositoryTestData {
  static const jobId = 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502';
  static const contactId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

  static final contact = JobContactDto.fixture().copyWith(
    contactMethod: JobContactMethod.whatsapp,
    identifier: '+5511999999999',
  );

  static final jobEnvelopeJson = <String, Object?>{
    'data': JobDto.fixture().toJson(),
    'requestId': '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
    'timestamp': '2026-06-06T00:37:46.623Z',
    'endpoint': '/v1/jobs/$jobId',
  };

  static final contactEnvelopeJson = <String, Object?>{
    'data': contact.toJson(),
    'requestId': 'contact-req-001',
    'timestamp': '2026-06-06T00:37:46.623Z',
    'endpoint': '/v1/jobs/$jobId/contact/$contactId',
  };
}

abstract final class _JobRepositoryTestHelpers {
  static ProviderContainer createProviderContainer({required Dio unauthenticatedDio}) {
    final container = ProviderContainer(
      overrides: [unauthenticatedCataquiApiV1DioProvider.overrideWithValue(unauthenticatedDio)],
    );
    addTearDown(container.dispose);
    return container;
  }

  static void stubJobRequest({required MockDio dio}) {
    when(() => dio.get<Map<String, Object?>>(any())).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: _JobRepositoryTestData.jobEnvelopeJson,
        requestOptions: RequestOptions(path: '/jobs/${_JobRepositoryTestData.jobId}'),
      ),
    );
  }

  static void stubJobContactRequest({required MockDio dio}) {
    when(
      () => dio.get<Map<String, Object?>>(
        '/jobs/${_JobRepositoryTestData.jobId}/contact/${_JobRepositoryTestData.contactId}',
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: _JobRepositoryTestData.contactEnvelopeJson,
        requestOptions: RequestOptions(
          path: '/jobs/${_JobRepositoryTestData.jobId}/contact/${_JobRepositoryTestData.contactId}',
        ),
      ),
    );
  }
}
