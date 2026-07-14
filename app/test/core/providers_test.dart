import 'package:cataqui_app/core/config/app_config.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cataquiDioProvider', () {
    test('when read, it should use the configured Cataqui API base URL', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(environment: 'development', cataquiApiUrl: 'https://api.test.cataqui.com'),
          ),
        ],
      );

      addTearDown(container.dispose);

      final dio = container.read(cataquiDioProvider);

      expect(dio.options.baseUrl, 'https://api.test.cataqui.com');
    });

    test('when read, it should include the accept-language header from the current locale', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(environment: 'development', cataquiApiUrl: 'https://api.test.cataqui.com'),
          ),
        ],
      );

      addTearDown(container.dispose);

      final dio = container.read(cataquiDioProvider);

      expect(dio.options.headers['accept-language'], 'pt-BR');
    });

    test('when environment is development, it should include request logging', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(environment: 'development', cataquiApiUrl: 'https://api.test.cataqui.com'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final dio = container.read(cataquiDioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is LogInterceptor), isTrue);
    });

    test('when environment is production, it should skip request logging', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(environment: 'production', cataquiApiUrl: 'https://api.test.cataqui.com'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final dio = container.read(cataquiDioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is LogInterceptor), isFalse);
    });
  });
}
