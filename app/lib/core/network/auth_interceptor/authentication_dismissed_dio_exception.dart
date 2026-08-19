import 'package:dio/dio.dart';

final class AuthenticationDismissedDioException extends DioException {
  AuthenticationDismissedDioException({required super.requestOptions})
    : super(type: DioExceptionType.cancel, message: 'Authentication was dismissed before the request could continue.');
}
