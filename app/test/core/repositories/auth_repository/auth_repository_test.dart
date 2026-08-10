import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/repositories/auth_repository/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

void main() {
  late MockDio dio;
  late AuthRepository repository;

  setUp(() {
    dio = MockDio();
    repository = AuthRepository(dio: dio);
    _AuthRepositoryTestData.stubRegisteredAuthIntentRequest(dio: dio);
  });

  group('AuthRepository', () {
    group('registerAuthIntent', () {
      test('when registering a WhatsApp auth intent, it should post the supported backend channel', () async {
        await repository.registerAuthIntent(channel: AuthChannel.whatsapp);

        verify(
          () => dio.post<Map<String, Object?>>(
            '/auth/inbound-message/intents',
            data: <String, String>{'channel': 'WHATSAPP'},
          ),
        ).called(1);
      });

      test('when receiving a registered auth intent, it should map the intent token', () async {
        final envelope = await repository.registerAuthIntent(channel: AuthChannel.whatsapp);

        expect(envelope.data.intentToken, _AuthRepositoryTestData.intentToken);
      });

      test('when receiving a registered auth intent, it should map the authentication code', () async {
        final envelope = await repository.registerAuthIntent(channel: AuthChannel.whatsapp);

        expect(envelope.data.code, 'AUTH-K7F9Q2M8VD');
      });

      test('when receiving a registered auth intent, it should map the expiration timestamp', () async {
        final envelope = await repository.registerAuthIntent(channel: AuthChannel.whatsapp);

        expect(envelope.data.expiresAt, DateTime.parse('2026-08-10T15:15:00.000Z'));
      });

      test('when receiving a registered auth intent, it should preserve the request id', () async {
        final envelope = await repository.registerAuthIntent(channel: AuthChannel.whatsapp);

        expect(envelope.requestId, 'auth-intent-request-001');
      });

      test('when receiving a registered auth intent, it should preserve the response timestamp', () async {
        final envelope = await repository.registerAuthIntent(channel: AuthChannel.whatsapp);

        expect(envelope.timestamp, DateTime.parse('2026-08-10T15:00:00.000Z'));
      });

      test('when receiving a registered auth intent, it should preserve the endpoint', () async {
        final envelope = await repository.registerAuthIntent(channel: AuthChannel.whatsapp);

        expect(envelope.endpoint, '/v1/auth/inbound-message/intents');
      });
    });
  });

  group('authRepositoryProvider', () {
    test('when reading the provider, it should expose an auth repository', () {
      final container = ProviderContainer(overrides: [cataquiApiV1DioProvider.overrideWithValue(dio)]);
      addTearDown(container.dispose);

      final result = container.read(authRepositoryProvider);

      expect(result, isA<AuthRepository>());
    });
  });
}

class _AuthRepositoryTestData {
  const _AuthRepositoryTestData._();

  static const intentToken = 'kJ3YFf0SYkZp6gWlMTq3up5ELXWRw_zTuF8j0M5tJgI';

  static final responseJson = <String, Object?>{
    'data': <String, Object?>{
      'intentToken': intentToken,
      'code': 'AUTH-K7F9Q2M8VD',
      'expiresAt': '2026-08-10T15:15:00.000Z',
    },
    'requestId': 'auth-intent-request-001',
    'timestamp': '2026-08-10T15:00:00.000Z',
    'endpoint': '/v1/auth/inbound-message/intents',
  };

  static void stubRegisteredAuthIntentRequest({required MockDio dio}) {
    when(
      () => dio.post<Map<String, Object?>>(
        '/auth/inbound-message/intents',
        data: <String, String>{'channel': 'WHATSAPP'},
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: responseJson,
        requestOptions: RequestOptions(path: '/auth/inbound-message/intents'),
      ),
    );
  }
}
