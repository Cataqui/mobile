import 'package:cataqui_app/core/dtos/saved_contact_dto.dart';
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

  setUp(() {
    authenticatedDio = MockDio();
    repository = UserRepository(authenticatedDio: authenticatedDio);
    _UserRepositoryTestHelpers.stubContactsRequest(dio: authenticatedDio);
  });

  group('UserRepository', () {
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
  static void stubContactsRequest({required MockDio dio, Map<String, Object?>? responseJson}) {
    when(() => dio.get<Map<String, Object?>>('/users/me/contacts')).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: responseJson ?? _UserRepositoryTestData.envelopeJson,
        requestOptions: RequestOptions(path: '/users/me/contacts'),
      ),
    );
  }
}
