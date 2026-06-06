import 'package:cataqui_app/core/config/app_config.dart';
import 'package:cataqui_app/core/config/env.dart';
import 'package:cataqui_app/core/repositories/feed_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) {
  return AppConfig(environment: Env.environment, cataquiApiUrl: Env.cataquiApiUrl);
}

@Riverpod(keepAlive: true)
Dio cataquiDio(Ref ref) {
  final appConfig = ref.watch(appConfigProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: appConfig.cataquiApiUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: const <String, String>{
        Headers.acceptHeader: Headers.jsonContentType,
        Headers.contentTypeHeader: Headers.jsonContentType,
      },
    ),
  );

  if (appConfig.isDevelopment) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, logPrint: (object) => debugPrint(object.toString())),
    );
  }

  return dio;
}

@Riverpod(keepAlive: true)
FeedRepository feedRepository(Ref ref) {
  return FeedRepository(dio: ref.watch(cataquiDioProvider));
}
