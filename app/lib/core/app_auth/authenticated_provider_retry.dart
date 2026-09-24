import 'package:cataqui_app/core/network/auth_interceptor/authentication_dismissed_dio_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class AuthenticatedProviderRetry {
  static Duration? retry(int retryCount, Object error) {
    if (error is AuthenticationDismissedDioException) return null;
    if (error is DioException && error.response?.statusCode == 401) return null;
    return ProviderContainer.defaultRetry(retryCount, error);
  }
}
