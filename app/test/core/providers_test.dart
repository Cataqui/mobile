import 'package:cataqui_app/core/config/app_config.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

void main() {
  group('cataquiApiV1DioProvider', () {
    test('when read, it should prefix the configured Cataquí API root URL with v1', () {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(environment: 'development'))],
      );

      addTearDown(container.dispose);

      final dio = container.read(cataquiApiV1DioProvider);

      expect(dio.options.baseUrl, 'https://staging.api.cataqui.com/v1');
    });

    test('when resolving an endpoint, it should keep the v1 API prefix', () {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(environment: 'development'))],
      );

      addTearDown(container.dispose);

      final dio = container.read(cataquiApiV1DioProvider);

      expect(
        RequestOptions(baseUrl: dio.options.baseUrl, path: '/feed').uri.toString(),
        'https://staging.api.cataqui.com/v1/feed',
      );
    });

    test('when read, it should include the accept-language header from the current locale', () {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(environment: 'development'))],
      );

      addTearDown(container.dispose);

      final dio = container.read(cataquiApiV1DioProvider);

      expect(dio.options.headers['accept-language'], 'pt-BR');
    });

    test('when environment is development, it should include request logging', () {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(environment: 'development'))],
      );
      addTearDown(container.dispose);

      final dio = container.read(cataquiApiV1DioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is LogInterceptor), isTrue);
    });

    test('when environment is production, it should skip request logging', () {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(environment: 'production'))],
      );
      addTearDown(container.dispose);

      final dio = container.read(cataquiApiV1DioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is LogInterceptor), isFalse);
    });

    test('when environment is production, it should register the offline error interceptor', () {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(environment: 'production'))],
      );
      addTearDown(container.dispose);

      final dio = container.read(cataquiApiV1DioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is OfflineErrorDioInterceptor), isTrue);
    });
  });
}
