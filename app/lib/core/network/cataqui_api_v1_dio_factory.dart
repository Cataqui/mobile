import 'package:cataqui_app/core/config/app_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

final class CataquiApiV1DioFactory {
  const CataquiApiV1DioFactory._();

  static Dio create({required AppConfig appConfig, required String languageTag, Interceptor? authInterceptor}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: '${appConfig.cataquiApiUrl}/v1',
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: <String, String>{
          Headers.acceptHeader: Headers.jsonContentType,
          Headers.contentTypeHeader: Headers.jsonContentType,
          'accept-language': languageTag,
        },
      ),
    );

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
