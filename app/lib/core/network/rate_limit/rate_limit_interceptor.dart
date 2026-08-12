import 'dart:io';

import 'package:cataqui_app/core/network/rate_limit/rate_limited_dio_exception.dart';
import 'package:dio/dio.dart';

final class RateLimitInterceptor extends Interceptor {
  Duration _getRetryDelay(DioException error) {
    final retryAfterHeader = error.response?.headers.value(HttpHeaders.retryAfterHeader)?.trim();
    final retryAfterSeconds = retryAfterHeader == null ? null : int.tryParse(retryAfterHeader);
    if (retryAfterSeconds != null) return Duration(seconds: retryAfterSeconds.clamp(0, 86400));

    if (retryAfterHeader != null) {
      try {
        final retryAt = HttpDate.parse(retryAfterHeader);
        final delay = retryAt.difference(DateTime.now().toUtc());
        return delay.isNegative ? Duration.zero : delay;
      } on FormatException {
        // Continue to the provider response body when Retry-After is malformed.
      }
    }

    final responseData = error.response?.data;
    if (responseData case final Map<Object?, Object?> responseBody) {
      final bodyRetryAfterSeconds = responseBody['retryAfterSeconds'];
      if (bodyRetryAfterSeconds is num) {
        return Duration(seconds: bodyRetryAfterSeconds.toInt().clamp(0, 86400));
      }
    }

    return const Duration(seconds: 60);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode != HttpStatus.tooManyRequests) {
      handler.next(err);
      return;
    }

    handler.reject(
      RateLimitedDioException(
        requestOptions: err.requestOptions,
        response: err.response,
        retryAfter: _getRetryDelay(err),
        stackTrace: err.stackTrace,
      ),
    );
  }
}
