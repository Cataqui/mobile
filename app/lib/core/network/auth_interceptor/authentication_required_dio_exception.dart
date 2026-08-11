import 'package:dio/dio.dart';

final class AuthenticationRequiredDioException extends DioException {
  AuthenticationRequiredDioException({required super.requestOptions})
    : super(type: DioExceptionType.unknown, message: 'Authentication is required to complete this request.');
}
