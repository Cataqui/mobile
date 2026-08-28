import 'dart:async';

import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/network/auth_interceptor/authentication_dismissed_dio_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

abstract base class InterceptorWithAuth extends Interceptor {
  InterceptorWithAuth({
    required this.requestDio,
    required this.getOrAuthenticateSession,
    required this.retriedAfterUnauthorizedKey,
  });

  @protected
  final Dio requestDio;

  @protected
  final Future<AuthSessionDto?> Function() getOrAuthenticateSession;

  @protected
  final String retriedAfterUnauthorizedKey;

  @protected
  Future<RequestAuthorization?> getAuthorization({
    required AuthSessionDto authenticatedSession,
    required bool forceRefresh,
  });

  Future<void> _authenticateRequest({
    required RequestOptions options,
    required RequestInterceptorHandler handler,
  }) async {
    try {
      final authenticatedSession = await getOrAuthenticateSession();
      if (authenticatedSession == null) {
        handler.reject(AuthenticationDismissedDioException(requestOptions: options));
        return;
      }

      final authorization = await getAuthorization(authenticatedSession: authenticatedSession, forceRefresh: false);
      if (authorization == null) {
        handler.reject(AuthenticationDismissedDioException(requestOptions: options));
        return;
      }

      options.headers['Authorization'] = _formatAuthorization(authorization);
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
      final authenticatedSession = await getOrAuthenticateSession();
      if (authenticatedSession == null) {
        handler.next(AuthenticationDismissedDioException(requestOptions: error.requestOptions));
        return;
      }

      final currentAuthorization = await getAuthorization(
        authenticatedSession: authenticatedSession,
        forceRefresh: false,
      );
      final requestAuthorization = error.requestOptions.headers['Authorization'];
      final canReuseCurrentAuthorization =
          currentAuthorization != null && requestAuthorization != _formatAuthorization(currentAuthorization);
      final authorization = canReuseCurrentAuthorization
          ? currentAuthorization
          : await getAuthorization(authenticatedSession: authenticatedSession, forceRefresh: true);

      if (authorization == null) {
        handler.next(AuthenticationDismissedDioException(requestOptions: error.requestOptions));
        return;
      }

      error.requestOptions.headers['Authorization'] = _formatAuthorization(authorization);
      error.requestOptions.extra[retriedAfterUnauthorizedKey] = true;
      handler.resolve(await requestDio.fetch<Object?>(error.requestOptions));
    } on DioException catch (retryError) {
      handler.next(retryError);
    } on Object catch (retryError, stackTrace) {
      handler.next(DioException(requestOptions: error.requestOptions, error: retryError, stackTrace: stackTrace));
    }
  }

  String _formatAuthorization(RequestAuthorization authorization) {
    return '${authorization.scheme} ${authorization.token}';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    unawaited(_authenticateRequest(options: options, handler: handler));
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode != 401 || err.requestOptions.extra[retriedAfterUnauthorizedKey] == true) {
      handler.next(err);
      return;
    }

    unawaited(_retryUnauthorizedRequest(error: err, handler: handler));
  }
}

final class RequestAuthorization {
  const RequestAuthorization({required this.scheme, required this.token});

  final String scheme;
  final String token;
}
