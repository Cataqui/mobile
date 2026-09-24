import 'package:cataqui_app/core/dtos/api_pagination_dto.dart';
import 'package:cataqui_app/core/dtos/job_location_dto.dart';
import 'package:cataqui_app/core/dtos/saved_contact_dto.dart';
import 'package:cataqui_app/core/dtos/user_job.dart';
import 'package:cataqui_app/core/dtos/user_profile_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/repositories/user_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockDio authenticatedDio;
  late UserRepository repository;

  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
  });

  setUp(() {
    authenticatedDio = MockDio();
    repository = UserRepository(authenticatedDio: authenticatedDio);
    _UserRepositoryTestHelpers.stubContactsRequest(dio: authenticatedDio);
    _UserRepositoryTestHelpers.stubProfileRequest(dio: authenticatedDio);
    _UserRepositoryTestHelpers.stubPostedJobsRequest(dio: authenticatedDio);
  });

  group('UserRepository', () {
    group('getMyPostedJobs', () {
      test('when requesting the first page, it should call my jobs endpoint without a cursor', () async {
        await repository.getMyPostedJobs();

        verify(
          () => authenticatedDio.get<Map<String, Object?>>('/users/me/jobs', queryParameters: <String, Object?>{}),
        ).called(1);
      });

      test('when requesting another page, it should forward the cursor unchanged', () async {
        await repository.getMyPostedJobs(cursor: 'next-posted-jobs-cursor');

        verify(
          () => authenticatedDio.get<Map<String, Object?>>(
            '/users/me/jobs',
            queryParameters: <String, Object?>{'cursor': 'next-posted-jobs-cursor'},
          ),
        ).called(1);
      });

      test('when receiving posted jobs, it should map all fields and both statuses', () async {
        final envelope = await repository.getMyPostedJobs();

        expect(envelope.data, <UserJob>[
          UserJob.fixture().copyWith(
            jobId: _UserRepositoryTestData.activeJobId,
            title: 'Descarregar caixas',
            descriptionSummary: 'Trabalho de um dia',
            payment: r'R$150',
            location: const JobLocationDto(latitude: -23.55, longitude: -46.63, areaRadius: 2000),
            status: JobStatus.active,
            createdAt: DateTime.parse('2026-09-23T12:00:00.000Z'),
            updatedAt: DateTime.parse('2026-09-23T13:00:00.000Z'),
          ),
          UserJob.fixture().copyWith(
            jobId: _UserRepositoryTestData.archivedJobId,
            title: 'Organizar estoque',
            descriptionSummary: 'Organização de caixas',
            payment: null,
            location: const JobLocationDto(latitude: -23.56, longitude: -46.64, areaRadius: 1500),
            status: JobStatus.archived,
            createdAt: DateTime.parse('2026-09-22T12:00:00.000Z'),
            updatedAt: DateTime.parse('2026-09-24T12:00:00.000Z'),
          ),
        ]);
      });

      test('when receiving posted jobs, it should map envelope pagination', () async {
        final envelope = await repository.getMyPostedJobs();

        expect(
          (requestId: envelope.requestId, endpoint: envelope.endpoint, pagination: envelope.pagination),
          (
            requestId: 'posted-jobs-request-001',
            endpoint: '/v1/users/me/jobs',
            pagination: const ApiPaginationDto(hasMore: true, nextCursor: 'next-posted-jobs-cursor'),
          ),
        );
      });

      test('when receiving an empty page, it should return no jobs and no next cursor', () async {
        _UserRepositoryTestHelpers.stubPostedJobsRequest(
          dio: authenticatedDio,
          responseJson: <String, Object?>{
            ..._UserRepositoryTestData.postedJobsEnvelopeJson,
            'data': <Object?>[],
            'pagination': <String, Object?>{'hasMore': false, 'nextCursor': null},
          },
        );

        final envelope = await repository.getMyPostedJobs();

        expect(envelope.data, isEmpty);
        expect(envelope.pagination, const ApiPaginationDto(hasMore: false));
      });

      test('when the request fails, it should propagate the Dio exception', () async {
        final exception = DioException(requestOptions: RequestOptions(path: '/users/me/jobs'));
        when(
          () => authenticatedDio.get<Map<String, Object?>>(
            '/users/me/jobs',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(exception);

        await expectLater(repository.getMyPostedJobs(), throwsA(same(exception)));
      });
    });

    group('getMyProfile', () {
      test('when requesting my profile, it should call the current user endpoint', () async {
        await repository.getMyProfile();

        verify(() => authenticatedDio.get<Map<String, Object?>>('/users/me')).called(1);
      });

      test('when receiving my profile, it should map the user fields', () async {
        final envelope = await repository.getMyProfile();

        expect(
          envelope.data,
          UserProfileDto.fixture().copyWith(
            userId: _UserRepositoryTestData.profileUserId,
            displayIdentifier: 'Maria Oliveira',
          ),
        );
      });

      test('when receiving my profile, it should map the envelope metadata', () async {
        final envelope = await repository.getMyProfile();

        expect(
          (requestId: envelope.requestId, endpoint: envelope.endpoint),
          (requestId: 'my-profile-request-001', endpoint: '/v1/users/me'),
        );
      });

      test('when the request fails, it should propagate the Dio exception', () async {
        final exception = DioException(requestOptions: RequestOptions(path: '/users/me'));
        when(() => authenticatedDio.get<Map<String, Object?>>('/users/me')).thenThrow(exception);

        await expectLater(repository.getMyProfile(), throwsA(same(exception)));
      });
    });

    group('getContacts', () {
      test('when requesting saved contacts, it should call the user contacts endpoint', () async {
        await repository.getContacts();

        verify(() => authenticatedDio.get<Map<String, Object?>>('/users/me/contacts')).called(1);
      });

      test('when receiving saved contacts, it should map every contact field', () async {
        final envelope = await repository.getContacts();

        expect(
          envelope.data.single,
          SavedContactDto.fixture().copyWith(
            contactId: _UserRepositoryTestData.contactId,
            contactMethod: JobContactMethod.whatsapp,
            identifier: '+5511888888888',
          ),
        );
      });

      test('when receiving no saved contacts, it should map an empty contact list', () async {
        _UserRepositoryTestHelpers.stubContactsRequest(
          dio: authenticatedDio,
          responseJson: <String, Object?>{..._UserRepositoryTestData.envelopeJson, 'data': <Object?>[]},
        );

        final envelope = await repository.getContacts();

        expect(envelope.data, isEmpty);
      });

      test('when receiving saved contacts, it should map the envelope metadata', () async {
        final envelope = await repository.getContacts();

        expect(
          (requestId: envelope.requestId, endpoint: envelope.endpoint),
          (requestId: 'saved-contacts-request-001', endpoint: '/v1/users/me/contacts'),
        );
      });
    });
  });

  group('userRepositoryProvider', () {
    test('when reading the provider, it should inject the authenticated dio', () {
      final container = ProviderContainer(
        overrides: [authenticatedCataquiApiV1DioProvider.overrideWithValue(authenticatedDio)],
      );
      addTearDown(container.dispose);

      final result = container.read(userRepositoryProvider);

      expect(result.authenticatedDio, same(authenticatedDio));
    });
  });
}

abstract final class _UserRepositoryTestData {
  static const contactId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  static const profileUserId = 'e3c24aa7-d27d-4ba3-9de1-e5f3e1658055';
  static const activeJobId = 'd27b86e5-c3e7-4426-9972-40c459486bb3';
  static const archivedJobId = '31ff79f9-6287-4a40-a573-0a81d6163d38';

  static final postedJobsEnvelopeJson = <String, Object?>{
    'data': <Object?>[
      <String, Object?>{
        'jobId': activeJobId,
        'title': 'Descarregar caixas',
        'descriptionSummary': 'Trabalho de um dia',
        'payment': r'R$150',
        'location': <String, Object?>{'latitude': -23.55, 'longitude': -46.63, 'areaRadius': 2000},
        'status': 'ACTIVE',
        'createdAt': '2026-09-23T12:00:00.000Z',
        'updatedAt': '2026-09-23T13:00:00.000Z',
      },
      <String, Object?>{
        'jobId': archivedJobId,
        'title': 'Organizar estoque',
        'descriptionSummary': 'Organização de caixas',
        'payment': null,
        'location': <String, Object?>{'latitude': -23.56, 'longitude': -46.64, 'areaRadius': 1500},
        'status': 'ARCHIVED',
        'createdAt': '2026-09-22T12:00:00.000Z',
        'updatedAt': '2026-09-24T12:00:00.000Z',
      },
    ],
    'requestId': 'posted-jobs-request-001',
    'timestamp': '2026-09-24T12:00:00.000Z',
    'endpoint': '/v1/users/me/jobs',
    'pagination': <String, Object?>{'hasMore': true, 'nextCursor': 'next-posted-jobs-cursor'},
  };

  static final profileEnvelopeJson = <String, Object?>{
    'data': <String, Object?>{'userId': profileUserId, 'displayIdentifier': 'Maria Oliveira'},
    'requestId': 'my-profile-request-001',
    'timestamp': '2026-09-24T12:00:00.000Z',
    'endpoint': '/v1/users/me',
  };

  static final envelopeJson = <String, Object?>{
    'data': <Object?>[
      <String, Object?>{'contactId': contactId, 'method': 'WHATSAPP', 'identifier': '+5511888888888'},
    ],
    'requestId': 'saved-contacts-request-001',
    'timestamp': '2026-09-04T12:00:00.000Z',
    'endpoint': '/v1/users/me/contacts',
  };
}

abstract final class _UserRepositoryTestHelpers {
  static void stubPostedJobsRequest({required MockDio dio, Map<String, Object?>? responseJson}) {
    when(
      () => dio.get<Map<String, Object?>>('/users/me/jobs', queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: responseJson ?? _UserRepositoryTestData.postedJobsEnvelopeJson,
        requestOptions: RequestOptions(path: '/users/me/jobs'),
      ),
    );
  }

  static void stubProfileRequest({required MockDio dio}) {
    when(() => dio.get<Map<String, Object?>>('/users/me')).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: _UserRepositoryTestData.profileEnvelopeJson,
        requestOptions: RequestOptions(path: '/users/me'),
      ),
    );
  }

  static void stubContactsRequest({required MockDio dio, Map<String, Object?>? responseJson}) {
    when(() => dio.get<Map<String, Object?>>('/users/me/contacts')).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: responseJson ?? _UserRepositoryTestData.envelopeJson,
        requestOptions: RequestOptions(path: '/users/me/contacts'),
      ),
    );
  }
}
