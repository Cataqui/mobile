import 'dart:convert';
import 'dart:typed_data';

import 'package:cataqui_app/core/network/rate_limit/rate_limit_interceptor.dart';
import 'package:cataqui_app/core/network/rate_limit/rate_limited_dio_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

final class _RateLimitResponseAdapter implements HttpClientAdapter {
  _RateLimitResponseAdapter({required this.body, this.retryAfterHeader});

  final Map<String, Object?> body;
  final String? retryAfterHeader;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount += 1;
    return ResponseBody.fromString(
      jsonEncode(body),
      429,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        if (retryAfterHeader != null) 'retry-after': <String>[retryAfterHeader!],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('RateLimitInterceptor', () {
    test('when Retry-After contains seconds, it should reject once with the header delay', () async {
      final adapter = _RateLimitResponseAdapter(
        body: <String, Object?>{'errorCode': 'RATE_LIMITED', 'retryAfterSeconds': 60},
        retryAfterHeader: '12',
      );
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(RateLimitInterceptor());

      await expectLater(
        dio.get<void>('https://api.cataqui.com/v1/feed'),
        throwsA(
          isA<RateLimitedDioException>().having((error) => error.retryAfter, 'retryAfter', const Duration(seconds: 12)),
        ),
      );
      expect(adapter.requestCount, 1);
    });

    test('when Retry-After is absent, it should use the provider body delay', () async {
      final adapter = _RateLimitResponseAdapter(
        body: <String, Object?>{'errorCode': 'RATE_LIMITED', 'retryAfterSeconds': 23},
      );
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(RateLimitInterceptor());

      await expectLater(
        dio.get<void>('https://api.cataqui.com/v1/feed'),
        throwsA(
          isA<RateLimitedDioException>().having((error) => error.retryAfter, 'retryAfter', const Duration(seconds: 23)),
        ),
      );
    });

    test('when the edge response has no retry delay, it should use sixty seconds', () async {
      final adapter = _RateLimitResponseAdapter(body: <String, Object?>{'errorCode': 'RATE_LIMITED'});
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(RateLimitInterceptor());

      await expectLater(
        dio.get<void>('https://api.cataqui.com/v1/feed'),
        throwsA(
          isA<RateLimitedDioException>().having((error) => error.retryAfter, 'retryAfter', const Duration(seconds: 60)),
        ),
      );
    });
  });
}
