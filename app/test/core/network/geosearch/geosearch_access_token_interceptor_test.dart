import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/microservice_access_token_dto.dart';
import 'package:cataqui_app/core/enums/microservice_access_token_type.dart';
import 'package:cataqui_app/core/network/auth_interceptor/authentication_dismissed_dio_exception.dart';
import 'package:cataqui_app/core/network/geosearch/geosearch_access_token_interceptor.dart';
import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/v1/addresses/search'));
  });

  group('GeosearchAccessTokenInterceptor', () {
    late Dio geosearchDio;
    late MockHttpClientAdapter geosearchAdapter;
    late MockAuthRepository authRepository;
    late String? authenticatedUserId;
    late int accessTokenRequestCount;
    late Future<AuthSessionDto?> Function() getOrAuthenticateSession;
    late Future<MicroserviceAccessTokenDto> Function() createAccessToken;

    setUp(() {
      geosearchDio = Dio();
      geosearchAdapter = MockHttpClientAdapter();
      authRepository = MockAuthRepository();
      geosearchDio.httpClientAdapter = geosearchAdapter;
      authenticatedUserId = 'user-1';
      accessTokenRequestCount = 0;
      getOrAuthenticateSession = () async {
        final userId = authenticatedUserId;
        if (userId == null) return null;

        return AuthSessionDto.fixture().copyWith(userId: userId);
      };
      createAccessToken = () async {
        accessTokenRequestCount += 1;
        return _GeosearchAccessTokenInterceptorTestData.accessToken(
          accessToken: 'access-token-$accessTokenRequestCount',
        );
      };
      when(
        () => authRepository.createGeosearchAccessToken(),
      ).thenAnswer((_) async => ApiEnvelopeDto<MicroserviceAccessTokenDto>.fixture(data: await createAccessToken()));
      geosearchDio.interceptors.add(
        GeosearchAccessTokenInterceptor(
          geosearchDio: geosearchDio,
          authRepository: authRepository,
          readAuthenticatedUserId: () => authenticatedUserId,
          getOrAuthenticateSession: () => getOrAuthenticateSession(),
        ),
      );
    });

    tearDown(() {
      geosearchDio.close(force: true);
    });

    test('when no geosearch token is cached, it should issue and attach one', () async {
      String? authorization;
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
        authorization = (invocation.positionalArguments.first as RequestOptions).headers['Authorization'] as String?;
        return ResponseBody.fromString('{}', 200, headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders);
      });

      await withClock(
        Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
        () => geosearchDio.get<void>('/v1/addresses/search'),
      );

      expect(
        (authorization: authorization, accessTokenRequestCount: accessTokenRequestCount),
        (authorization: 'Bearer access-token-1', accessTokenRequestCount: 1),
      );
    });

    test('when geosearch is the first authenticated request, it should authenticate before issuing a token', () async {
      authenticatedUserId = null;
      getOrAuthenticateSession = () async {
        authenticatedUserId = 'user-1';
        return AuthSessionDto.fixture().copyWith(userId: 'user-1');
      };
      String? authorization;
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
        authorization = (invocation.positionalArguments.first as RequestOptions).headers['Authorization'] as String?;
        return ResponseBody.fromString('{}', 200, headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders);
      });

      await withClock(
        Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
        () => geosearchDio.get<void>('/v1/addresses/search'),
      );

      expect(
        (authorization: authorization, accessTokenRequestCount: accessTokenRequestCount),
        (authorization: 'Bearer access-token-1', accessTokenRequestCount: 1),
      );
    });

    test('when the cached geosearch token remains valid, it should reuse it', () async {
      final authorizations = <String?>[];
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
        authorizations.add(
          (invocation.positionalArguments.first as RequestOptions).headers['Authorization'] as String?,
        );
        return ResponseBody.fromString('{}', 200, headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders);
      });

      await withClock(Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime), () async {
        await geosearchDio.get<void>('/v1/addresses/search');
        await geosearchDio.get<void>('/v1/addresses/search');
      });

      expect(
        (authorizations: authorizations.join(','), accessTokenRequestCount: accessTokenRequestCount),
        (authorizations: 'Bearer access-token-1,Bearer access-token-1', accessTokenRequestCount: 1),
      );
    });

    test('when thirty seconds remain, it should replace the token before the request', () async {
      final authorizations = <String?>[];
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
        authorizations.add(
          (invocation.positionalArguments.first as RequestOptions).headers['Authorization'] as String?,
        );
        return ResponseBody.fromString('{}', 200, headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders);
      });

      await withClock(
        Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
        () => geosearchDio.get<void>('/v1/addresses/search'),
      );
      await withClock(
        Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime.add(const Duration(minutes: 9, seconds: 30))),
        () => geosearchDio.get<void>('/v1/addresses/search'),
      );

      expect(
        (authorizations: authorizations.join(','), accessTokenRequestCount: accessTokenRequestCount),
        (authorizations: 'Bearer access-token-1,Bearer access-token-2', accessTokenRequestCount: 2),
      );
    });

    test('when concurrent requests miss the token, it should coalesce issuance', () async {
      final accessTokenCompleter = Completer<MicroserviceAccessTokenDto>();
      createAccessToken = () {
        accessTokenRequestCount += 1;
        return accessTokenCompleter.future;
      };
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString('{}', 200, headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders),
      );

      final requests = withClock(Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime), () {
        return Future.wait<void>([
          geosearchDio.get<void>('/v1/addresses/search'),
          geosearchDio.get<void>('/v1/addresses/search'),
        ]);
      });
      await Future<void>.delayed(Duration.zero);
      accessTokenCompleter.complete(
        _GeosearchAccessTokenInterceptorTestData.accessToken(accessToken: 'coalesced-access-token'),
      );
      await requests;

      expect(accessTokenRequestCount, 1);
    });

    test('when token issuance fails, it should reject without calling the worker', () async {
      final issuanceError = StateError('Geosearch access is unavailable.');
      createAccessToken = () async {
        accessTokenRequestCount += 1;
        throw issuanceError;
      };
      var workerRequestCount = 0;
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
        workerRequestCount += 1;
        return ResponseBody.fromString('{}', 200, headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders);
      });
      DioException? thrownError;

      try {
        await withClock(
          Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
          () => geosearchDio.get<void>('/v1/addresses/search'),
        );
      } on DioException catch (error) {
        thrownError = error;
      }

      expect(
        (
          cause: thrownError?.error,
          accessTokenRequestCount: accessTokenRequestCount,
          workerRequestCount: workerRequestCount,
        ),
        (cause: issuanceError, accessTokenRequestCount: 1, workerRequestCount: 0),
      );
    });

    test('when the authenticated user changes, it should replace the cached token', () async {
      final authorizations = <String?>[];
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
        authorizations.add(
          (invocation.positionalArguments.first as RequestOptions).headers['Authorization'] as String?,
        );
        return ResponseBody.fromString('{}', 200, headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders);
      });

      await withClock(
        Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
        () => geosearchDio.get<void>('/v1/addresses/search'),
      );
      authenticatedUserId = 'user-2';
      await withClock(
        Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
        () => geosearchDio.get<void>('/v1/addresses/search'),
      );

      expect(
        (authorizations: authorizations.join(','), accessTokenRequestCount: accessTokenRequestCount),
        (authorizations: 'Bearer access-token-1,Bearer access-token-2', accessTokenRequestCount: 2),
      );
    });

    test('when the authenticated user disappears and login is dismissed, it should discard the cached token', () async {
      var workerRequestCount = 0;
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
        workerRequestCount += 1;
        return ResponseBody.fromString('{}', 200, headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders);
      });

      await withClock(
        Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
        () => geosearchDio.get<void>('/v1/addresses/search'),
      );
      authenticatedUserId = null;
      DioException? thrownError;
      try {
        await withClock(
          Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
          () => geosearchDio.get<void>('/v1/addresses/search'),
        );
      } on DioException catch (error) {
        thrownError = error;
      }

      expect(
        (
          errorType: thrownError.runtimeType,
          accessTokenRequestCount: accessTokenRequestCount,
          workerRequestCount: workerRequestCount,
        ),
        (errorType: AuthenticationDismissedDioException, accessTokenRequestCount: 1, workerRequestCount: 1),
      );
    });

    test('when the authenticated user changes during issuance, it should reject the issued token', () async {
      final accessTokenCompleter = Completer<MicroserviceAccessTokenDto>();
      final issuanceStartedCompleter = Completer<void>();
      createAccessToken = () {
        accessTokenRequestCount += 1;
        issuanceStartedCompleter.complete();
        return accessTokenCompleter.future;
      };
      var workerRequestCount = 0;
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
        workerRequestCount += 1;
        return ResponseBody.fromString('{}', 200, headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders);
      });

      final request = withClock(
        Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
        () => geosearchDio.get<void>('/v1/addresses/search'),
      );
      await issuanceStartedCompleter.future;
      authenticatedUserId = 'user-2';
      accessTokenCompleter.complete(
        _GeosearchAccessTokenInterceptorTestData.accessToken(accessToken: 'user-1-access-token'),
      );
      DioException? thrownError;
      try {
        await request;
      } on DioException catch (error) {
        thrownError = error;
      }

      expect(
        (causeIsStateError: thrownError?.error is StateError, workerRequestCount: workerRequestCount),
        (causeIsStateError: true, workerRequestCount: 0),
      );
    });

    test('when the worker rejects a token, it should replace it and replay once', () async {
      final authorizations = <String?>[];
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
        authorizations.add(
          (invocation.positionalArguments.first as RequestOptions).headers['Authorization'] as String?,
        );
        return ResponseBody.fromString(
          '{}',
          authorizations.length == 1 ? 401 : 200,
          headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders,
        );
      });

      final response = await withClock(
        Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
        () => geosearchDio.get<void>('/v1/addresses/search'),
      );

      expect(
        (
          statusCode: response.statusCode,
          authorizations: authorizations.join(','),
          accessTokenRequestCount: accessTokenRequestCount,
        ),
        (statusCode: 200, authorizations: 'Bearer access-token-1,Bearer access-token-2', accessTokenRequestCount: 2),
      );
    });

    test('when replacement issuance fails, it should propagate without replaying the worker request', () async {
      final replacementError = StateError('Replacement geosearch access is unavailable.');
      createAccessToken = () async {
        accessTokenRequestCount += 1;
        if (accessTokenRequestCount == 2) throw replacementError;
        return _GeosearchAccessTokenInterceptorTestData.accessToken(accessToken: 'initial-access-token');
      };
      var workerRequestCount = 0;
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
        workerRequestCount += 1;
        return ResponseBody.fromString('{}', 401, headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders);
      });
      DioException? thrownError;

      try {
        await withClock(
          Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
          () => geosearchDio.get<void>('/v1/addresses/search'),
        );
      } on DioException catch (error) {
        thrownError = error;
      }

      expect(
        (
          cause: thrownError?.error,
          accessTokenRequestCount: accessTokenRequestCount,
          workerRequestCount: workerRequestCount,
        ),
        (cause: replacementError, accessTokenRequestCount: 2, workerRequestCount: 1),
      );
    });

    test('when concurrent requests are unauthorized, it should share the replacement token', () async {
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
        final authorization =
            (invocation.positionalArguments.first as RequestOptions).headers['Authorization'] as String?;
        return ResponseBody.fromString(
          '{}',
          authorization == 'Bearer access-token-1' ? 401 : 200,
          headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders,
        );
      });

      await withClock(Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime), () {
        return Future.wait<void>([
          geosearchDio.get<void>('/v1/addresses/search'),
          geosearchDio.get<void>('/v1/addresses/search'),
        ]);
      });

      expect(accessTokenRequestCount, 2);
    });

    test('when the replay is unauthorized, it should propagate without another renewal', () async {
      var workerRequestCount = 0;
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
        workerRequestCount += 1;
        return ResponseBody.fromString('{}', 401, headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders);
      });
      DioException? thrownError;

      try {
        await withClock(
          Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
          () => geosearchDio.get<void>('/v1/addresses/search'),
        );
      } on DioException catch (error) {
        thrownError = error;
      }

      expect(
        (
          statusCode: thrownError?.response?.statusCode,
          accessTokenRequestCount: accessTokenRequestCount,
          workerRequestCount: workerRequestCount,
        ),
        (statusCode: 401, accessTokenRequestCount: 2, workerRequestCount: 2),
      );
    });

    test('when separate requests are unauthorized, each should receive exactly one replay', () async {
      var workerRequestCount = 0;
      var failedRequestCount = 0;
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
        workerRequestCount += 1;
        return ResponseBody.fromString('{}', 401, headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders);
      });

      for (var requestIndex = 0; requestIndex < 2; requestIndex += 1) {
        try {
          await withClock(
            Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
            () => geosearchDio.get<void>('/v1/addresses/search'),
          );
        } on DioException {
          failedRequestCount += 1;
        }
      }

      expect(
        (
          accessTokenRequestCount: accessTokenRequestCount,
          workerRequestCount: workerRequestCount,
          failedRequestCount: failedRequestCount,
        ),
        (accessTokenRequestCount: 3, workerRequestCount: 4, failedRequestCount: 2),
      );
    });

    test('when forbidden, rate-limited, or provider requests fail, it should not replace the token', () async {
      const responseStatusCodes = <int>[403, 429, 500];
      var workerRequestCount = 0;
      when(() => geosearchAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
        final responseStatusCode = responseStatusCodes[workerRequestCount];
        workerRequestCount += 1;
        return ResponseBody.fromString(
          '{}',
          responseStatusCode,
          headers: _GeosearchAccessTokenInterceptorTestData.jsonHeaders,
        );
      });
      final receivedStatusCodes = <int?>[];

      for (final _ in responseStatusCodes) {
        try {
          await withClock(
            Clock.fixed(_GeosearchAccessTokenInterceptorTestData.currentTime),
            () => geosearchDio.get<void>('/v1/addresses/search'),
          );
        } on DioException catch (error) {
          receivedStatusCodes.add(error.response?.statusCode);
        }
      }

      expect(
        (statusCodes: receivedStatusCodes.join(','), accessTokenRequestCount: accessTokenRequestCount),
        (statusCodes: '403,429,500', accessTokenRequestCount: 1),
      );
    });
  });
}

final class _GeosearchAccessTokenInterceptorTestData {
  const _GeosearchAccessTokenInterceptorTestData._();

  static final currentTime = DateTime.utc(2026, 8, 22, 15);

  static const jsonHeaders = <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  };

  static MicroserviceAccessTokenDto accessToken({required String accessToken}) {
    return MicroserviceAccessTokenDto(
      accessToken: accessToken,
      expiresAt: currentTime.add(const Duration(minutes: 10)),
      tokenType: MicroserviceAccessTokenType.bearer,
    );
  }
}
