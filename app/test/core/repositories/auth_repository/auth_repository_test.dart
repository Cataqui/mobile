import 'dart:async';

import 'package:cataqui_app/core/dtos/auth_intent_exchange_result_dto.dart';
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
    group('registerIntent', () {
      test('when registering a WhatsApp auth intent, it should post the supported backend channel', () async {
        await repository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp);

        verify(
          () => dio.post<Map<String, Object?>>(
            '/auth/inbound-message/intents',
            data: <String, String>{'channel': 'WHATSAPP'},
          ),
        ).called(1);
      });

      test('when receiving a registered auth intent, it should map the intent token', () async {
        final envelope = await repository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp);

        expect(envelope.data.intentToken, _AuthRepositoryTestData.intentToken);
      });

      test('when receiving a registered auth intent, it should map the authentication code', () async {
        final envelope = await repository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp);

        expect(envelope.data.code, 'AUTH-K7F9Q2M8VD');
      });

      test('when receiving a registered auth intent, it should map the code receiver', () async {
        final envelope = await repository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp);

        expect(envelope.data.codeReceiver, '5511988887777');
      });

      test('when receiving a registered auth intent, it should map the expiration timestamp', () async {
        final envelope = await repository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp);

        expect(envelope.data.expiresAt, DateTime.parse('2026-08-10T15:15:00.000Z'));
      });

      test('when receiving a registered auth intent, it should preserve the request id', () async {
        final envelope = await repository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp);

        expect(envelope.requestId, 'auth-intent-request-001');
      });

      test('when receiving a registered auth intent, it should preserve the response timestamp', () async {
        final envelope = await repository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp);

        expect(envelope.timestamp, DateTime.parse('2026-08-10T15:00:00.000Z'));
      });

      test('when receiving a registered auth intent, it should preserve the endpoint', () async {
        final envelope = await repository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp);

        expect(envelope.endpoint, '/v1/auth/inbound-message/intents');
      });
    });

    group('exchangeIntent', () {
      test('when exchanging an auth intent, it should post the intent token to the exchange endpoint', () async {
        _AuthRepositoryTestData.stubIssuedSessionExchangeRequest(dio: dio);

        await repository.exchangeInboundMessageAuthIntent(intentToken: _AuthRepositoryTestData.intentToken);

        verify(
          () => dio.post<Map<String, Object?>>(
            '/auth/inbound-message/intents/exchange',
            data: <String, String>{'intentToken': _AuthRepositoryTestData.intentToken},
          ),
        ).called(1);
      });

      test(
        'when the auth intent is pending before verification, it should poll and return the issued session',
        () async {
          var requestCount = 0;
          _AuthRepositoryTestData.stubPendingThenIssuedSessionExchangeRequest(
            dio: dio,
            onRequest: () => requestCount += 1,
          );

          final envelope = await repository.exchangeInboundMessageAuthIntent(
            intentToken: _AuthRepositoryTestData.intentToken,
          );

          expect(
            (session: envelope.data, requestCount: requestCount),
            (session: AuthIntentExchangeResultDto.issuedSessionFixture(), requestCount: 2),
          );
        },
      );

      test('when the auth intent stays pending past the exchange deadline, it should throw a timeout', () async {
        repository = AuthRepository(dio: dio, exchangeIntentTimeout: const Duration(milliseconds: 1));
        var requestCount = 0;
        _AuthRepositoryTestData.stubPendingExchangeRequest(dio: dio, onRequest: () => requestCount += 1);
        Object? thrownError;

        try {
          await repository.exchangeInboundMessageAuthIntent(intentToken: _AuthRepositoryTestData.intentToken);
        } on Object catch (error) {
          thrownError = error;
        }

        expect(
          (timedOut: thrownError is TimeoutException, requestCount: requestCount),
          (timedOut: true, requestCount: 1),
        );
      });

      test('when the exchange endpoint fails, it should propagate the error without polling again', () async {
        final terminalError = DioException(
          requestOptions: RequestOptions(path: '/auth/inbound-message/intents/exchange'),
          response: Response<void>(
            requestOptions: RequestOptions(path: '/auth/inbound-message/intents/exchange'),
            statusCode: 404,
          ),
        );
        var requestCount = 0;
        _AuthRepositoryTestData.stubFailingExchangeRequest(
          dio: dio,
          error: terminalError,
          onRequest: () => requestCount += 1,
        );
        Object? thrownError;

        try {
          await repository.exchangeInboundMessageAuthIntent(intentToken: _AuthRepositoryTestData.intentToken);
        } on Object catch (error) {
          thrownError = error;
        }

        expect((error: thrownError, requestCount: requestCount), (error: terminalError, requestCount: 1));
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
      'codeReceiver': '5511988887777',
      'expiresAt': '2026-08-10T15:15:00.000Z',
    },
    'requestId': 'auth-intent-request-001',
    'timestamp': '2026-08-10T15:00:00.000Z',
    'endpoint': '/v1/auth/inbound-message/intents',
  };

  static final issuedSessionResponseJson = <String, Object?>{
    'data': <String, Object?>{
      'accessToken': 'a' * 43,
      'tokenType': 'Bearer',
      'expiresAt': '2026-08-10T15:15:00.000Z',
      'refreshToken': 'refresh-token',
      'refreshExpiresAt': '2026-09-09T15:15:00.000Z',
      'userId': '4963fef0-b62a-4760-9f99-675fdc42a896',
    },
    'requestId': 'auth-exchange-request-002',
    'timestamp': '2026-08-10T15:00:01.000Z',
    'endpoint': '/v1/auth/inbound-message/intents/exchange',
  };

  static final pendingResponseJson = <String, Object?>{
    'data': <String, Object?>{'status': 'PENDING', 'retryAfterSeconds': 1},
    'requestId': 'auth-exchange-request-001',
    'timestamp': '2026-08-10T15:00:00.000Z',
    'endpoint': '/v1/auth/inbound-message/intents/exchange',
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

  static void stubIssuedSessionExchangeRequest({required MockDio dio}) {
    when(
      () => dio.post<Map<String, Object?>>(
        '/auth/inbound-message/intents/exchange',
        data: <String, String>{'intentToken': intentToken},
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: issuedSessionResponseJson,
        requestOptions: RequestOptions(path: '/auth/inbound-message/intents/exchange'),
      ),
    );
  }

  static void stubPendingThenIssuedSessionExchangeRequest({required MockDio dio, required void Function() onRequest}) {
    var isFirstRequest = true;
    when(
      () => dio.post<Map<String, Object?>>(
        '/auth/inbound-message/intents/exchange',
        data: <String, String>{'intentToken': intentToken},
      ),
    ).thenAnswer((_) async {
      onRequest();
      final responseData = isFirstRequest ? pendingResponseJson : issuedSessionResponseJson;
      isFirstRequest = false;

      return Response<Map<String, Object?>>(
        data: responseData,
        requestOptions: RequestOptions(path: '/auth/inbound-message/intents/exchange'),
      );
    });
  }

  static void stubPendingExchangeRequest({required MockDio dio, required void Function() onRequest}) {
    when(
      () => dio.post<Map<String, Object?>>(
        '/auth/inbound-message/intents/exchange',
        data: <String, String>{'intentToken': intentToken},
      ),
    ).thenAnswer((_) async {
      onRequest();

      return Response<Map<String, Object?>>(
        data: pendingResponseJson,
        requestOptions: RequestOptions(path: '/auth/inbound-message/intents/exchange'),
      );
    });
  }

  static void stubFailingExchangeRequest({
    required MockDio dio,
    required DioException error,
    required void Function() onRequest,
  }) {
    when(
      () => dio.post<Map<String, Object?>>(
        '/auth/inbound-message/intents/exchange',
        data: <String, String>{'intentToken': intentToken},
      ),
    ).thenAnswer((_) {
      onRequest();
      throw error;
    });
  }
}
