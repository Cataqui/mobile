import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
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
    _JobRepositoryTestHelpers.stubUpdateDraftRequest(dio: authenticatedDio);
  });

  group('JobRepository', () {
    group('createDraft', () {
      test('when creating a local draft, it should not call the authenticated API', () async {
        await repository.createDraft(description: _JobRepositoryTestData.draftDescription);

        verifyNever(
          () => authenticatedDio.post<Map<String, Object?>>(any(), data: any<Map<String, String>>(named: 'data')),
        );
      });

      test('when creating a draft, it should not use the unauthenticated client', () async {
        await repository.createDraft(description: _JobRepositoryTestData.draftDescription);

        verifyNever(
          () => unauthenticatedDio.post<Map<String, Object?>>(any(), data: any<Map<String, String>>(named: 'data')),
        );
      });

      test('when creating a local draft, it should return the draft status', () async {
        final envelope = await repository.createDraft(description: _JobRepositoryTestData.draftDescription);

        expect(envelope.data.status, JobStatus.draft);
      });
    });

    group('updateDraft', () {
      test('when updating every draft field, it should patch the serialized values to the draft endpoint', () async {
        await repository.updateDraft(
          jobId: _JobRepositoryTestData.jobId,
          description: _JobRepositoryTestData.updatedDraftDescription,
          contact: _JobRepositoryTestData.contactInput,
          location: _JobRepositoryTestData.locationInput,
          type: JobType.contractor,
          payment: _JobRepositoryTestData.paymentInput,
        );

        verify(
          () => authenticatedDio.patch<Map<String, Object?>>(
            '/jobs/drafts/${_JobRepositoryTestData.jobId}',
            data: <String, Object?>{
              'description': _JobRepositoryTestData.updatedDraftDescription,
              'contact': <String, Object?>{'contactMethod': 'WHATSAPP', 'identifier': '+5511999999999'},
              'location': <String, Object?>{
                'street': 'Rua das Flores, 100',
                'neighborhood': 'Centro',
                'city': 'São Paulo',
                'state': 'SP',
                'country': 'BR',
                'latitude': -23.55052,
                'longitude': -46.633308,
              },
              'type': 'CONTRACTOR',
              'payment': <String, Object?>{
                'type': 'RANGE',
                'minAmount': 120,
                'maxAmount': 200,
                'amountPeriod': 'SINGLE',
                'currency': 'BRL',
              },
            },
          ),
        ).called(1);
      });

      test('when updating no draft fields, it should patch an empty object so every field remains unchanged', () async {
        await repository.updateDraft(jobId: _JobRepositoryTestData.jobId);

        verify(
          () => authenticatedDio.patch<Map<String, Object?>>(
            '/jobs/drafts/${_JobRepositoryTestData.jobId}',
            data: <String, Object?>{},
          ),
        ).called(1);
      });

      test(
        'when saving a payment range with its maximum below its minimum, it should invert the persisted amounts',
        () async {
          await repository.updateDraft(
            jobId: _JobRepositoryTestData.jobId,
            payment: (
              type: JobPaymentType.range,
              minAmount: 200,
              maxAmount: 120,
              note: null,
              amountPeriod: JobPaymentAmountPeriod.single,
              currency: 'BRL',
            ),
          );

          verify(
            () => authenticatedDio.patch<Map<String, Object?>>(
              '/jobs/drafts/${_JobRepositoryTestData.jobId}',
              data: <String, Object?>{
                'payment': <String, Object?>{
                  'type': 'RANGE',
                  'minAmount': 120,
                  'maxAmount': 200,
                  'amountPeriod': 'SINGLE',
                  'currency': 'BRL',
                },
              },
            ),
          ).called(1);
        },
      );

      test('when updating a draft, it should not use the unauthenticated client', () async {
        await repository.updateDraft(
          jobId: _JobRepositoryTestData.jobId,
          description: _JobRepositoryTestData.updatedDraftDescription,
        );

        verifyNever(
          () => unauthenticatedDio.patch<Map<String, Object?>>(any(), data: any<Map<String, Object?>>(named: 'data')),
        );
      });

      test('when receiving an updated draft with incomplete fields, it should map the nullable response', () async {
        final envelope = await repository.updateDraft(jobId: _JobRepositoryTestData.jobId);

        expect(
          envelope.data,
          JobDraftDto(
            jobId: _JobRepositoryTestData.jobId,
            description: _JobRepositoryTestData.draftDescription,
            status: JobStatus.draft,
            createdAt: DateTime.parse('2026-08-12T12:00:00.000Z'),
            updatedAt: DateTime.parse('2026-08-12T12:00:00.000Z'),
          ),
        );
      });

      test('when receiving an updated draft, it should map the request id', () async {
        final envelope = await repository.updateDraft(jobId: _JobRepositoryTestData.jobId);

        expect(envelope.requestId, 'draft-update-req-001');
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
    test('when reading the provider, it should inject the authenticated dio for draft creation', () {
      final container = _JobRepositoryTestHelpers.createProviderContainer(
        authenticatedDio: authenticatedDio,
        unauthenticatedDio: unauthenticatedDio,
      );

      final result = container.read(jobRepositoryProvider);

      expect(result.authenticatedDio, same(authenticatedDio));
    });

    test('when reading the provider, it should inject the unauthenticated dio for public job endpoints', () {
      final container = _JobRepositoryTestHelpers.createProviderContainer(
        authenticatedDio: authenticatedDio,
        unauthenticatedDio: unauthenticatedDio,
      );

      final result = container.read(jobRepositoryProvider);

      expect(result.unauthenticatedDio, same(unauthenticatedDio));
    });
  });
}

abstract final class _JobRepositoryTestData {
  static const jobId = 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502';
  static const contactId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  static const draftDescription = 'Preciso de uma pessoa para descarregar caixas.';
  static const updatedDraftDescription = 'Preciso de ajuda para descarregar um caminhão amanhã.';

  static final contact = JobContactDto.fixture().copyWith(
    contactMethod: JobContactMethod.whatsapp,
    identifier: '+5511999999999',
  );

  static const contactInput = (contactMethod: JobContactMethod.whatsapp, identifier: '+5511999999999');

  static const locationInput = (
    street: 'Rua das Flores, 100',
    neighborhood: 'Centro',
    city: 'São Paulo',
    state: 'SP',
    country: 'BR',
    latitude: -23.55052,
    longitude: -46.633308,
  );

  static const paymentInput = (
    type: JobPaymentType.range,
    minAmount: 120,
    maxAmount: 200,
    note: null as String?,
    amountPeriod: JobPaymentAmountPeriod.single,
    currency: 'BRL',
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

  static final draftEnvelopeJson = <String, Object?>{
    'data': <String, Object?>{
      'jobId': jobId,
      'title': null,
      'description': draftDescription,
      'descriptionSummary': null,
      'contactReference': null,
      'location': null,
      'payment': null,
      'status': 'DRAFT',
      'type': null,
      'createdAt': '2026-08-12T12:00:00.000Z',
      'updatedAt': '2026-08-12T12:00:00.000Z',
    },
    'requestId': 'draft-req-001',
    'timestamp': '2026-08-12T12:00:01.000Z',
    'endpoint': '/v1/jobs/drafts',
  };

  static final updatedDraftEnvelopeJson = <String, Object?>{
    ...draftEnvelopeJson,
    'requestId': 'draft-update-req-001',
    'endpoint': '/v1/jobs/drafts/$jobId',
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

  static void stubUpdateDraftRequest({required MockDio dio}) {
    when(
      () => dio.patch<Map<String, Object?>>(
        '/jobs/drafts/${_JobRepositoryTestData.jobId}',
        data: any<Map<String, Object?>>(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: _JobRepositoryTestData.updatedDraftEnvelopeJson,
        requestOptions: RequestOptions(path: '/jobs/drafts/${_JobRepositoryTestData.jobId}'),
      ),
    );
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
