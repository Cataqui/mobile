import 'package:dio/dio.dart';

final class RateLimitedDioException extends DioException {
  RateLimitedDioException({required super.requestOptions, required this.retryAfter, super.response, super.stackTrace})
    : super(
        type: DioExceptionType.badResponse,
        message: 'The request was rate limited. Try again after ${retryAfter.inSeconds} seconds.',
      );

  final Duration retryAfter;
}
