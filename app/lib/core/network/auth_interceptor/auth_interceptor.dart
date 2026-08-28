import 'dart:async';

import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/network/auth_interceptor/interceptor_with_auth.dart';
import 'package:clock/clock.dart';
import 'package:dio/dio.dart';

final class AuthInterceptor extends InterceptorWithAuth {
  AuthInterceptor({
    required Dio unauthenticatedDio,
    required this.getCurrentSession,
    required super.getOrAuthenticateSession,
    required this.refreshSession,
    required this.refreshSessionInBackground,
  }) : super(requestDio: unauthenticatedDio, retriedAfterUnauthorizedKey: 'authRetriedAfterUnauthorized');

  static const refreshThreshold = Duration(minutes: 5);

  final AuthSessionDto? Function() getCurrentSession;
  final Future<AuthSessionDto?> Function() refreshSession;
  final Future<void> Function() refreshSessionInBackground;

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final session = getCurrentSession();

    if (session != null && session.accessTokenExpiresAt.difference(clock.now()) < refreshThreshold) {
      unawaited(refreshSessionInBackground());
    }

    handler.next(response);
  }

  @override
  Future<RequestAuthorization?> getAuthorization({
    required AuthSessionDto authenticatedSession,
    required bool forceRefresh,
  }) async {
    final session = forceRefresh ? await refreshSession() : getCurrentSession() ?? authenticatedSession;
    if (session == null || !session.accessTokenExpiresAt.isAfter(clock.now())) return null;

    return RequestAuthorization(scheme: 'Bearer', token: session.accessToken);
  }
}
