import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/microservice_access_token_dto.dart';
import 'package:cataqui_app/core/network/auth_interceptor/interceptor_with_auth.dart';
import 'package:cataqui_app/core/repositories/auth_repository/auth_repository.dart';
import 'package:clock/clock.dart';
import 'package:dio/dio.dart';

final class GeosearchAccessTokenInterceptor extends InterceptorWithAuth {
  GeosearchAccessTokenInterceptor({
    required Dio geosearchDio,
    required this.authRepository,
    required this.readAuthenticatedUserId,
    required super.getOrAuthenticateSession,
  }) : super(requestDio: geosearchDio, retriedAfterUnauthorizedKey: 'geosearchRetriedAfterUnauthorized');

  final AuthRepository authRepository;
  final String? Function() readAuthenticatedUserId;

  static const refreshThreshold = Duration(seconds: 30);
  Future<MicroserviceAccessTokenDto>? _activeAccessTokenRequest;
  MicroserviceAccessTokenDto? _accessToken;
  String? _accessTokenUserId;

  @override
  Future<RequestAuthorization> getAuthorization({
    required AuthSessionDto authenticatedSession,
    required bool forceRefresh,
  }) async {
    final accessToken = await _getAccessToken(issuingUserId: authenticatedSession.userId, forceRefresh: forceRefresh);
    return RequestAuthorization(scheme: accessToken.tokenType.value, token: accessToken.accessToken);
  }

  Future<MicroserviceAccessTokenDto> _getAccessToken({required String issuingUserId, bool forceRefresh = false}) {
    if (!forceRefresh) {
      final accessToken = _readValidAccessToken();
      if (accessToken != null) return Future<MicroserviceAccessTokenDto>.value(accessToken);
    }

    final activeAccessTokenRequest = _activeAccessTokenRequest;
    if (activeAccessTokenRequest != null) return activeAccessTokenRequest;

    late final Future<MicroserviceAccessTokenDto> accessTokenRequest;
    accessTokenRequest = _issueAccessToken(issuingUserId: issuingUserId).whenComplete(() {
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

  Future<MicroserviceAccessTokenDto> _issueAccessToken({required String issuingUserId}) async {
    final accessToken = (await authRepository.createGeosearchAccessToken()).data;
    if (readAuthenticatedUserId() != issuingUserId) {
      throw StateError('The authenticated user changed while issuing a geosearch access token.');
    }

    _accessToken = accessToken;
    _accessTokenUserId = issuingUserId;
    return accessToken;
  }
}
