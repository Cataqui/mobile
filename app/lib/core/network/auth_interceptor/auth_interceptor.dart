import 'dart:async';

import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/network/auth_interceptor/authentication_dismissed_dio_exception.dart';
import 'package:clock/clock.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  const AuthInterceptor({
    required this.unauthenticatedDio,
    required this.readSession,
    required this.refreshSession,
    required this.refreshSessionInBackground,
  });

  static const refreshThreshold = Duration(minutes: 5);

  final Dio unauthenticatedDio;
  final AuthSessionDto? Function() readSession;
  final Future<AuthSessionDto?> Function() refreshSession;
  final Future<void> Function() refreshSessionInBackground;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    unawaited(_authenticateRequest(options: options, handler: handler));
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final session = readSession();

    if (session != null && session.accessTokenExpiresAt.difference(clock.now()) < refreshThreshold) {
      unawaited(refreshSessionInBackground());
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    unawaited(_retryUnauthorizedRequest(error: err, handler: handler));
  }

  Future<void> _authenticateRequest({
    required RequestOptions options,
    required RequestInterceptorHandler handler,
  }) async {
    try {
      final currentSession = readSession();

      final session = currentSession != null && currentSession.accessTokenExpiresAt.isAfter(clock.now())
          ? currentSession
          : await refreshSession();

      if (session == null) {
        handler.reject(AuthenticationDismissedDioException(requestOptions: options));

        return;
      }

      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      handler.next(options);
    } on DioException catch (error) {
      handler.reject(error);
    } on Object catch (error, stackTrace) {
      handler.reject(DioException(requestOptions: options, error: error, stackTrace: stackTrace));
    }
  }

  Future<void> _retryUnauthorizedRequest({
    required DioException error,
    required ErrorInterceptorHandler handler,
  }) async {
    try {
      final requestAuthorization = error.requestOptions.headers['Authorization'];
      final currentSession = readSession();

      final hasNewValidSession =
          currentSession != null &&
          currentSession.accessTokenExpiresAt.isAfter(clock.now()) &&
          requestAuthorization != 'Bearer ${currentSession.accessToken}';

      final session = hasNewValidSession ? currentSession : await refreshSession();

      if (session == null) {
        handler.next(AuthenticationDismissedDioException(requestOptions: error.requestOptions));
        return;
      }

      error.requestOptions.headers['Authorization'] = 'Bearer ${session.accessToken}';
      handler.resolve(await unauthenticatedDio.fetch<dynamic>(error.requestOptions));
    } on DioException catch (retryError) {
      handler.next(retryError);
    } on Object catch (retryError, stackTrace) {
      handler.next(DioException(requestOptions: error.requestOptions, error: retryError, stackTrace: stackTrace));
    }
  }
}
