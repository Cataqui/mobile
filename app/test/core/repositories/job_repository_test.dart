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
  late MockDio authenticatedDio;
  late MockDio unauthenticatedDio;
  late JobRepository repository;

  setUp(() {
    authenticatedDio = MockDio();
    unauthenticatedDio = MockDio();
    repository = JobRepository(authenticatedDio: authenticatedDio, unauthenticatedDio: unauthenticatedDio);
    _JobRepositoryTestHelpers.stubJobRequest(dio: unauthenticatedDio);
    _JobRepositoryTestHelpers.stubJobContactRequest(dio: unauthenticatedDio);
    _JobRepositoryTestHelpers.stubCreateJobRequest(dio: authenticatedDio);
  });

  group('JobRepository', () {
    group('createJob', () {
      test('sends the complete post and idempotency key through authenticated dio', () async {
        await repository.createJob(
          description: _JobRepositoryTestData.description,
          latitude: -23.556391,
          longitude: -46.844076,
          contactMethod: .phoneCall,
          contactIdentifier: '+5511999999999',
          idempotencyKey: _JobRepositoryTestData.idempotencyKey,
        );

        final request = verify(
          () => authenticatedDio.post<Map<String, Object?>>(
            '/jobs',
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          ),
        ).captured;
        expect(request[0], {
          'description': _JobRepositoryTestData.description,
          'location': {'latitude': -23.556391, 'longitude': -46.844076},
          'contact': {'method': 'PHONE_CALL', 'identifier': '+5511999999999'},
        });
        expect((request[1] as Options).headers, {'Idempotency-Key': _JobRepositoryTestData.idempotencyKey});
        verifyNever(() => unauthenticatedDio.post<Map<String, Object?>>(any()));
      });

      test('maps the created job and response envelope', () async {
        final envelope = await repository.createJob(
          description: _JobRepositoryTestData.description,
          latitude: -23.556391,
          longitude: -46.844076,
          contactMethod: .whatsapp,
          contactIdentifier: '+5511999999999',
          idempotencyKey: _JobRepositoryTestData.idempotencyKey,
        );

        expect(envelope.data.jobId, _JobRepositoryTestData.jobId);
        expect(envelope.data.payment, r'R$120');
        expect(envelope.requestId, 'create-req-001');
      });

      test('propagates a failed posting request', () async {
        final error = DioException(requestOptions: RequestOptions(path: '/jobs'));
        when(
          () => authenticatedDio.post<Map<String, Object?>>(
            '/jobs',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(error);

        expect(
          repository.createJob(
            description: _JobRepositoryTestData.description,
            latitude: -23.556391,
            longitude: -46.844076,
            contactMethod: .whatsapp,
            contactIdentifier: '+5511999999999',
            idempotencyKey: _JobRepositoryTestData.idempotencyKey,
          ),
          throwsA(same(error)),
        );
      });
    });

    group('getJob', () {
      test('when requesting a job, it should call the job detail endpoint with the job id', () async {
        await repository.getJob(jobId: _JobRepositoryTestData.jobId);

        verify(() => unauthenticatedDio.get<Map<String, Object?>>('/jobs/${_JobRepositoryTestData.jobId}')).called(1);
      });

      test('when receiving a job, it should map the job dto data', () async {
        final envelope = await repository.getJob(jobId: _JobRepositoryTestData.jobId);

        expect(envelope.data.jobId, JobDto.fixture().jobId);
      });

      test('when receiving payment text, it should preserve the backend text', () async {
        _JobRepositoryTestHelpers.stubJobRequest(
          dio: unauthenticatedDio,
          responseJson: {
            ..._JobRepositoryTestData.jobEnvelopeJson,
            'data': JobDto.fixture().copyWith(payment: r'R$150 ou R$140').toJson(),
          },
        );

        final envelope = await repository.getJob(jobId: _JobRepositoryTestData.jobId);

        expect(envelope.data.payment, r'R$150 ou R$140');
      });

      test('when receiving null payment, it should preserve null', () async {
        _JobRepositoryTestHelpers.stubJobRequest(
          dio: unauthenticatedDio,
          responseJson: {
            ..._JobRepositoryTestData.jobEnvelopeJson,
            'data': JobDto.fixture().copyWith(payment: null).toJson(),
          },
        );

        final envelope = await repository.getJob(jobId: _JobRepositoryTestData.jobId);

        expect(envelope.data.payment, isNull);
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
    test('injects authenticated dio for posting and unauthenticated dio for public reads', () {
      final container = _JobRepositoryTestHelpers.createProviderContainer(
        authenticatedDio: authenticatedDio,
        unauthenticatedDio: unauthenticatedDio,
      );

      final result = container.read(jobRepositoryProvider);

      expect(result.authenticatedDio, same(authenticatedDio));
      expect(result.unauthenticatedDio, same(unauthenticatedDio));
    });
  });
}

abstract final class _JobRepositoryTestData {
  static const jobId = 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502';
  static const contactId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  static const idempotencyKey = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
  static const description = 'Preciso de ajuda para descarregar caixas.';

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

  static final createdJobEnvelopeJson = <String, Object?>{
    'data': JobDto.fixture().toJson(),
    'requestId': 'create-req-001',
    'timestamp': '2026-06-06T00:37:46.623Z',
    'endpoint': '/v1/jobs',
  };
}

abstract final class _JobRepositoryTestHelpers {
  static ProviderContainer createProviderContainer({required Dio authenticatedDio, required Dio unauthenticatedDio}) {
    final container = ProviderContainer(
      overrides: [
        authenticatedCataquiApiV1DioProvider.overrideWithValue(authenticatedDio),
        unauthenticatedCataquiApiV1DioProvider.overrideWithValue(unauthenticatedDio),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  static void stubCreateJobRequest({required MockDio dio}) {
    when(
      () => dio.post<Map<String, Object?>>(
        '/jobs',
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: _JobRepositoryTestData.createdJobEnvelopeJson,
        requestOptions: RequestOptions(path: '/jobs'),
      ),
    );
  }

  static void stubJobRequest({required MockDio dio, Map<String, Object?>? responseJson}) {
    when(() => dio.get<Map<String, Object?>>(any())).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: responseJson ?? _JobRepositoryTestData.jobEnvelopeJson,
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
