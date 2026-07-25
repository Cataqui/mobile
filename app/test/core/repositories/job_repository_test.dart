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

const _testJobId = 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502';
const _testContactId = 'contact-001';

final _jobEnvelopeJson = <String, Object?>{
  'data': JobDto.fixture().toJson(),
  'request_id': '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
  'timestamp': '2026-06-06T00:37:46.623Z',
  'endpoint': '/job/$_testJobId',
};

final _contact = JobContactDto.fixture().copyWith(
  contactMethod: JobContactMethod.whatsapp,
  identifier: '+5511999999999',
);

final _contactEnvelopeJson = <String, Object?>{
  'data': _contact.toJson(),
  'request_id': 'contact-req-001',
  'timestamp': '2026-06-06T00:37:46.623Z',
  'endpoint': '/job/$_testJobId/contact/$_testContactId',
};

void main() {
  late MockDio dio;
  late JobRepository repository;

  setUp(() {
    dio = MockDio();
    repository = JobRepository(dio: dio);
    _stubJobRequest(dio: dio);
    _stubJobContactRequest(dio: dio);
  });

  group('JobRepository', () {
    group('getJob', () {
      test('when requesting a job, it should call the job detail endpoint with the job id', () async {
        await repository.getJob(jobId: _testJobId);

        verify(() => dio.get<Map<String, Object?>>('/job/$_testJobId')).called(1);
      });

      test('when receiving a job, it should map the job dto data', () async {
        final envelope = await repository.getJob(jobId: _testJobId);

        expect(envelope.data.jobId, JobDto.fixture().jobId);
      });

      test('when receiving a job, it should map the request id', () async {
        final envelope = await repository.getJob(jobId: _testJobId);

        expect(envelope.requestId, '5b591550-c650-4e27-a2ed-d6f02e1c0da2');
      });
    });

    group('getJobContact', () {
      test('when requesting a job contact, it should call the contact endpoint with the job and contact ids', () async {
        await repository.getJobContact(jobId: _testJobId, contactId: _testContactId);

        verify(() => dio.get<Map<String, Object?>>('/job/$_testJobId/contact/$_testContactId')).called(1);
      });

      test('when receiving a job contact, it should map the contact method from the dto', () async {
        final envelope = await repository.getJobContact(jobId: _testJobId, contactId: _testContactId);

        expect(envelope.data.contactMethod, _contact.contactMethod);
      });

      test('when receiving a job contact, it should map the identifier from the dto', () async {
        final envelope = await repository.getJobContact(jobId: _testJobId, contactId: _testContactId);

        expect(envelope.data.identifier, _contact.identifier);
      });

      test('when receiving a job contact, it should map the request id', () async {
        final envelope = await repository.getJobContact(jobId: _testJobId, contactId: _testContactId);

        expect(envelope.requestId, 'contact-req-001');
      });
    });
  });

  group('jobRepositoryProvider', () {
    test('when reading the provider, it should expose a job repository', () {
      final container = ProviderContainer(overrides: [cataquiApiV1DioProvider.overrideWithValue(MockDio())]);
      addTearDown(container.dispose);

      final result = container.read(jobRepositoryProvider);

      expect(result, isA<JobRepository>());
    });
  });
}

void _stubJobRequest({required MockDio dio, Map<String, Object?>? responseJson}) {
  when(() => dio.get<Map<String, Object?>>(any())).thenAnswer(
    (_) async => Response<Map<String, Object?>>(
      data: responseJson ?? _jobEnvelopeJson,
      requestOptions: RequestOptions(path: '/job/$_testJobId'),
    ),
  );
}

void _stubJobContactRequest({required MockDio dio, Map<String, Object?>? responseJson}) {
  when(() => dio.get<Map<String, Object?>>('/job/$_testJobId/contact/$_testContactId')).thenAnswer(
    (_) async => Response<Map<String, Object?>>(
      data: responseJson ?? _contactEnvelopeJson,
      requestOptions: RequestOptions(path: '/job/$_testJobId/contact/$_testContactId'),
    ),
  );
}
