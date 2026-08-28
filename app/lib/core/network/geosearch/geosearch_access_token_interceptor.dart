import 'dart:async';

import 'package:cataqui_app/core/dtos/microservice_access_token_dto.dart';
import 'package:cataqui_app/core/repositories/auth_repository/auth_repository.dart';
import 'package:clock/clock.dart';
import 'package:dio/dio.dart';

final class GeosearchAccessTokenInterceptor extends Interceptor {
  GeosearchAccessTokenInterceptor({
    required this.geosearchDio,
    required this.authRepository,
    required this.readAuthenticatedUserId,
  });

  final Dio geosearchDio;
  final AuthRepository authRepository;
  final String? Function() readAuthenticatedUserId;

  static const refreshThreshold = Duration(seconds: 30);
  static const _retriedAfterUnauthorizedKey = 'geosearchRetriedAfterUnauthorized';

  Future<MicroserviceAccessTokenDto>? _activeAccessTokenRequest;
  MicroserviceAccessTokenDto? _accessToken;
  String? _accessTokenUserId;

  Future<void> _authenticateRequest({
    required RequestOptions options,
    required RequestInterceptorHandler handler,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      options.headers['Authorization'] = '${accessToken.tokenType.value} ${accessToken.accessToken}';
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
      final currentAccessToken = _readValidAccessToken();
      final requestAuthorization = error.requestOptions.headers['Authorization'];
      final hasNewAccessToken =
          currentAccessToken != null &&
          requestAuthorization != '${currentAccessToken.tokenType.value} ${currentAccessToken.accessToken}';
      final accessToken = hasNewAccessToken ? currentAccessToken : await _getAccessToken(forceRefresh: true);

      error.requestOptions.headers['Authorization'] = '${accessToken.tokenType.value} ${accessToken.accessToken}';
      error.requestOptions.extra[_retriedAfterUnauthorizedKey] = true;
      handler.resolve(await geosearchDio.fetch<Object?>(error.requestOptions));
    } on DioException catch (retryError) {
      handler.next(retryError);
    } on Object catch (retryError, stackTrace) {
      handler.next(DioException(requestOptions: error.requestOptions, error: retryError, stackTrace: stackTrace));
    }
  }

  Future<MicroserviceAccessTokenDto> _getAccessToken({bool forceRefresh = false}) {
    if (!forceRefresh) {
      final accessToken = _readValidAccessToken();
      if (accessToken != null) return Future<MicroserviceAccessTokenDto>.value(accessToken);
    }

    final activeAccessTokenRequest = _activeAccessTokenRequest;
    if (activeAccessTokenRequest != null) return activeAccessTokenRequest;

    late final Future<MicroserviceAccessTokenDto> accessTokenRequest;
    accessTokenRequest = _issueAccessToken().whenComplete(() {
      if (identical(_activeAccessTokenRequest, accessTokenRequest)) {
        _activeAccessTokenRequest = null;
      }
    });
    _activeAccessTokenRequest = accessTokenRequest;

    return accessTokenRequest;
  }

  MicroserviceAccessTokenDto? _readValidAccessToken() {
    final authenticatedUserId = readAuthenticatedUserId();
    final accessToken = _accessToken;

    if (authenticatedUserId != null &&
        authenticatedUserId == _accessTokenUserId &&
        accessToken != null &&
        accessToken.expiresAt.difference(clock.now()) > refreshThreshold) {
      return accessToken;
    }

    _accessToken = null;
    _accessTokenUserId = null;
    return null;
  }

  Future<MicroserviceAccessTokenDto> _issueAccessToken() async {
    final issuingUserId = readAuthenticatedUserId();
    if (issuingUserId == null) {
      throw StateError('A geosearch access token cannot be issued without an authenticated user.');
    }

    final accessToken = (await authRepository.createGeosearchAccessToken()).data;
    if (readAuthenticatedUserId() != issuingUserId) {
      throw StateError('The authenticated user changed while issuing a geosearch access token.');
    }

    _accessToken = accessToken;
    _accessTokenUserId = issuingUserId;
    return accessToken;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    unawaited(_authenticateRequest(options: options, handler: handler));
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode != 401 || err.requestOptions.extra[_retriedAfterUnauthorizedKey] == true) {
      handler.next(err);
      return;
    }

    unawaited(_retryUnauthorizedRequest(error: err, handler: handler));
  }
}
