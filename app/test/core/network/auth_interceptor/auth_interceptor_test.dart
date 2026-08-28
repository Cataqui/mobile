import 'dart:async';

import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/network/auth_interceptor/auth_interceptor.dart';
import 'package:cataqui_app/core/network/auth_interceptor/authentication_dismissed_dio_exception.dart';
import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/protected'));
  });

  group('AuthInterceptor', () {
    late Dio authenticatedDio;
    late Dio unauthenticatedDio;
    late MockHttpClientAdapter authenticatedAdapter;
    late MockHttpClientAdapter unauthenticatedAdapter;
    late AuthSessionDto? session;
    late int foregroundRefreshCount;
    late int backgroundRefreshCount;
    late Future<AuthSessionDto?> Function() getOrAuthenticateSession;
    late Future<AuthSessionDto?> Function() refreshSession;
    late Future<void> Function() refreshSessionInBackground;

    setUp(() {
      authenticatedDio = Dio();
      unauthenticatedDio = Dio();
      authenticatedAdapter = MockHttpClientAdapter();
      unauthenticatedAdapter = MockHttpClientAdapter();
      authenticatedDio.httpClientAdapter = authenticatedAdapter;
      unauthenticatedDio.httpClientAdapter = unauthenticatedAdapter;
      session = null;
      foregroundRefreshCount = 0;
      backgroundRefreshCount = 0;
      getOrAuthenticateSession = () async => session;
      refreshSession = () async {
        foregroundRefreshCount += 1;
        return session;
      };
      refreshSessionInBackground = () async {
        backgroundRefreshCount += 1;
      };
      authenticatedDio.interceptors.add(
        AuthInterceptor(
          unauthenticatedDio: unauthenticatedDio,
          getCurrentSession: () => session,
          getOrAuthenticateSession: () => getOrAuthenticateSession(),
          refreshSession: () => refreshSession(),
          refreshSessionInBackground: () => refreshSessionInBackground(),
        ),
      );
    });

    tearDown(() {
      authenticatedDio.close(force: true);
      unauthenticatedDio.close(force: true);
    });

    test('when the access token is valid, it should send the bearer token without refreshing', () async {
      final currentTime = DateTime.utc(2026, 8, 11, 15);
      session = AuthSessionDto.fixture().copyWith(
        accessToken: 'valid-access-token',
        accessTokenExpiresAt: currentTime.add(const Duration(minutes: 10)),
      );
      String? authorization;
      when(() => authenticatedAdapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
        authorization = (invocation.positionalArguments.first as RequestOptions).headers['Authorization'] as String?;
        return ResponseBody.fromString('{}', 200, headers: _AuthInterceptorTestData.jsonHeaders);
      });

      await withClock(Clock.fixed(currentTime), () => authenticatedDio.get<void>('/protected'));

      expect(
        (authorization: authorization, foregroundRefreshCount: foregroundRefreshCount),
        (authorization: 'Bearer valid-access-token', foregroundRefreshCount: 0),
      );
    });

    test('when the access token is expired, it should refresh before sending the request', () async {
      final currentTime = DateTime.utc(2026, 8, 11, 15);
      final expiredSession = AuthSessionDto.fixture().copyWith(
        accessToken: 'expired-access-token',
        accessTokenExpiresAt: currentTime,
      );
      final refreshedSession = expiredSession.copyWith(
        accessToken: 'refreshed-access-token',
        accessTokenExpiresAt: currentTime.add(const Duration(minutes: 10)),
      );
      session = expiredSession;
      refreshSession = () async {
        foregroundRefreshCount += 1;
        session = refreshedSession;
        return refreshedSession;
      };
      getOrAuthenticateSession = () => refreshSession();
      String? authorization;
      when(() => authenticatedAdapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
        authorization = (invocation.positionalArguments.first as RequestOptions).headers['Authorization'] as String?;
        return ResponseBody.fromString('{}', 200, headers: _AuthInterceptorTestData.jsonHeaders);
      });

      await withClock(Clock.fixed(currentTime), () => authenticatedDio.get<void>('/protected'));

      expect(
        (authorization: authorization, foregroundRefreshCount: foregroundRefreshCount),
        (authorization: 'Bearer refreshed-access-token', foregroundRefreshCount: 1),
      );
    });

    test('when login is dismissed before a protected request, it should reject without sending the request', () async {
      DioException? thrownError;
      var requestCount = 0;
      when(() => authenticatedAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
        requestCount += 1;
        return ResponseBody.fromString('{}', 200, headers: _AuthInterceptorTestData.jsonHeaders);
      });

      try {
        await authenticatedDio.get<void>('/protected');
      } on DioException catch (error) {
        thrownError = error;
      }

      expect(
        (errorType: thrownError.runtimeType, dioType: thrownError?.type, requestCount: requestCount),
        (errorType: AuthenticationDismissedDioException, dioType: DioExceptionType.cancel, requestCount: 0),
      );
    });

    test('when a protected response is unauthorized, it should refresh and replay once with the new token', () async {
      final currentTime = DateTime.utc(2026, 8, 11, 15);
      final originalSession = AuthSessionDto.fixture().copyWith(
        accessToken: 'original-access-token',
        accessTokenExpiresAt: currentTime.add(const Duration(minutes: 10)),
      );
      final refreshedSession = originalSession.copyWith(accessToken: 'refreshed-access-token');
      session = originalSession;
      refreshSession = () async {
        foregroundRefreshCount += 1;
        session = refreshedSession;
        return refreshedSession;
      };
      var authenticatedRequestCount = 0;
      var retryRequestCount = 0;
      String? retryAuthorization;
      when(() => authenticatedAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
        authenticatedRequestCount += 1;
        return ResponseBody.fromString('{}', 401, headers: _AuthInterceptorTestData.jsonHeaders);
      });
      when(() => unauthenticatedAdapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
        retryRequestCount += 1;
        retryAuthorization =
            (invocation.positionalArguments.first as RequestOptions).headers['Authorization'] as String?;
        return ResponseBody.fromString('{}', 200, headers: _AuthInterceptorTestData.jsonHeaders);
      });

      final response = await withClock(Clock.fixed(currentTime), () => authenticatedDio.get<void>('/protected'));

      expect(
        (
          statusCode: response.statusCode,
          authenticatedRequestCount: authenticatedRequestCount,
          retryRequestCount: retryRequestCount,
          foregroundRefreshCount: foregroundRefreshCount,
          retryAuthorization: retryAuthorization,
        ),
        (
          statusCode: 200,
          authenticatedRequestCount: 1,
          retryRequestCount: 1,
          foregroundRefreshCount: 1,
          retryAuthorization: 'Bearer refreshed-access-token',
        ),
      );
    });

    test('when another request already rotated the token, it should replay a 401 without refreshing again', () async {
      final currentTime = DateTime.utc(2026, 8, 11, 15);
      final originalSession = AuthSessionDto.fixture().copyWith(
        accessToken: 'original-access-token',
        accessTokenExpiresAt: currentTime.add(const Duration(minutes: 10)),
      );
      final rotatedSession = originalSession.copyWith(accessToken: 'rotated-access-token');
      session = originalSession;
      when(() => authenticatedAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
        session = rotatedSession;
        return ResponseBody.fromString('{}', 401, headers: _AuthInterceptorTestData.jsonHeaders);
      });
      String? retryAuthorization;
      when(() => unauthenticatedAdapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
        retryAuthorization =
            (invocation.positionalArguments.first as RequestOptions).headers['Authorization'] as String?;
        return ResponseBody.fromString('{}', 200, headers: _AuthInterceptorTestData.jsonHeaders);
      });

      await withClock(Clock.fixed(currentTime), () => authenticatedDio.get<void>('/protected'));

      expect(
        (retryAuthorization: retryAuthorization, foregroundRefreshCount: foregroundRefreshCount),
        (retryAuthorization: 'Bearer rotated-access-token', foregroundRefreshCount: 0),
      );
    });

    test('when login is dismissed after a 401, it should cancel without replaying the request', () async {
      final currentTime = DateTime.utc(2026, 8, 11, 15);
      session = AuthSessionDto.fixture().copyWith(accessTokenExpiresAt: currentTime.add(const Duration(minutes: 10)));
      refreshSession = () async {
        foregroundRefreshCount += 1;
        session = null;
        return null;
      };
      when(
        () => authenticatedAdapter.fetch(any(), any(), any()),
      ).thenAnswer((_) async => ResponseBody.fromString('{}', 401, headers: _AuthInterceptorTestData.jsonHeaders));
      var retryRequestCount = 0;
      when(() => unauthenticatedAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
        retryRequestCount += 1;
        return ResponseBody.fromString('{}', 200, headers: _AuthInterceptorTestData.jsonHeaders);
      });
      DioException? thrownError;

      try {
        await withClock(Clock.fixed(currentTime), () => authenticatedDio.get<void>('/protected'));
      } on DioException catch (error) {
        thrownError = error;
      }

      expect(
        (
          errorType: thrownError.runtimeType,
          dioType: thrownError?.type,
          foregroundRefreshCount: foregroundRefreshCount,
          retryRequestCount: retryRequestCount,
        ),
        (
          errorType: AuthenticationDismissedDioException,
          dioType: DioExceptionType.cancel,
          foregroundRefreshCount: 1,
          retryRequestCount: 0,
        ),
      );
    });

    test('when the replay is also unauthorized, it should propagate the retry 401 without another refresh', () async {
      final currentTime = DateTime.utc(2026, 8, 11, 15);
      final originalSession = AuthSessionDto.fixture().copyWith(
        accessToken: 'original-access-token',
        accessTokenExpiresAt: currentTime.add(const Duration(minutes: 10)),
      );
      final refreshedSession = originalSession.copyWith(accessToken: 'refreshed-access-token');
      session = originalSession;
      refreshSession = () async {
        foregroundRefreshCount += 1;
        session = refreshedSession;
        return refreshedSession;
      };
      var retryRequestCount = 0;
      when(
        () => authenticatedAdapter.fetch(any(), any(), any()),
      ).thenAnswer((_) async => ResponseBody.fromString('{}', 401, headers: _AuthInterceptorTestData.jsonHeaders));
      when(() => unauthenticatedAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
        retryRequestCount += 1;
        return ResponseBody.fromString('{}', 401, headers: _AuthInterceptorTestData.jsonHeaders);
      });
      DioException? thrownError;

      try {
        await withClock(Clock.fixed(currentTime), () => authenticatedDio.get<void>('/protected'));
      } on DioException catch (error) {
        thrownError = error;
      }

      expect(
        (
          statusCode: thrownError?.response?.statusCode,
          foregroundRefreshCount: foregroundRefreshCount,
          retryRequestCount: retryRequestCount,
        ),
        (statusCode: 401, foregroundRefreshCount: 1, retryRequestCount: 1),
      );
    });

    test('when a successful response leaves less than five minutes, it should refresh without delaying it', () async {
      final currentTime = DateTime.utc(2026, 8, 11, 15);
      session = AuthSessionDto.fixture().copyWith(
        accessTokenExpiresAt: currentTime.add(const Duration(minutes: 5) - const Duration(microseconds: 1)),
      );
      final backgroundRefreshCompleter = Completer<void>();
      refreshSessionInBackground = () {
        backgroundRefreshCount += 1;
        return backgroundRefreshCompleter.future;
      };
      when(
        () => authenticatedAdapter.fetch(any(), any(), any()),
      ).thenAnswer((_) async => ResponseBody.fromString('{}', 200, headers: _AuthInterceptorTestData.jsonHeaders));

      final response = await withClock(Clock.fixed(currentTime), () {
        return authenticatedDio.get<void>('/protected').timeout(const Duration(seconds: 1));
      });
      backgroundRefreshCompleter.complete();

      expect(
        (statusCode: response.statusCode, backgroundRefreshCount: backgroundRefreshCount),
        (statusCode: 200, backgroundRefreshCount: 1),
      );
    });

    test('when five minutes remain after a successful response, it should not refresh in the background', () async {
      final currentTime = DateTime.utc(2026, 8, 11, 15);
      session = AuthSessionDto.fixture().copyWith(
        accessTokenExpiresAt: currentTime.add(AuthInterceptor.refreshThreshold),
      );
      when(
        () => authenticatedAdapter.fetch(any(), any(), any()),
      ).thenAnswer((_) async => ResponseBody.fromString('{}', 200, headers: _AuthInterceptorTestData.jsonHeaders));

      await withClock(Clock.fixed(currentTime), () => authenticatedDio.get<void>('/protected'));

      expect(backgroundRefreshCount, 0);
    });

    test('when a non-authentication response fails, it should propagate without refreshing', () async {
      final currentTime = DateTime.utc(2026, 8, 11, 15);
      session = AuthSessionDto.fixture().copyWith(accessTokenExpiresAt: currentTime.add(const Duration(minutes: 10)));
      when(
        () => authenticatedAdapter.fetch(any(), any(), any()),
      ).thenAnswer((_) async => ResponseBody.fromString('{}', 403, headers: _AuthInterceptorTestData.jsonHeaders));
      DioException? thrownError;

      try {
        await withClock(Clock.fixed(currentTime), () => authenticatedDio.get<void>('/protected'));
      } on DioException catch (error) {
        thrownError = error;
      }

      expect(
        (statusCode: thrownError?.response?.statusCode, foregroundRefreshCount: foregroundRefreshCount),
        (statusCode: 403, foregroundRefreshCount: 0),
      );
    });
  });
}

class _AuthInterceptorTestData {
  const _AuthInterceptorTestData._();

  static const jsonHeaders = <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  };
}
