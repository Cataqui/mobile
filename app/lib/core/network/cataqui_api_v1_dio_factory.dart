import 'package:cataqui_app/core/config/app_config.dart';
import 'package:cataqui_app/core/network/rate_limit/rate_limit_interceptor.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

final class CataquiApiV1DioFactory {
  const CataquiApiV1DioFactory._();

  static Dio create({
    required AppConfig appConfig,
    required String languageTag,
    required CookieJar cookieJar,
    Interceptor? authInterceptor,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: '${appConfig.cataquiApiUrl}/v1',
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: <String, String>{Headers.acceptHeader: Headers.jsonContentType, 'accept-language': languageTag},
      ),
    );

    dio.interceptors.add(CookieManager(cookieJar));
    dio.interceptors.add(RateLimitInterceptor());

    if (authInterceptor != null) dio.interceptors.add(authInterceptor);

    if (appConfig.isDevelopment) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, logPrint: (object) => debugPrint(object.toString())),
      );
    }

    dio.interceptors.add(OfflineErrorDioInterceptor());

    return dio;
  }
}
