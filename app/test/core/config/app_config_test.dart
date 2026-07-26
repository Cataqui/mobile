import 'package:cataqui_app/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('when the environment is development, it should use the staging Cataquí API', () {
      const config = AppConfig(environment: 'development');

      expect(config.cataquiApiUrl, 'https://staging.api.cataqui.com');
    });

    test('when the environment is production, it should use the production Cataquí API', () {
      const config = AppConfig(environment: 'production');

      expect(config.cataquiApiUrl, 'https://api.cataqui.com');
    });

    test('when the environment is unsupported, it should reject API URL resolution', () {
      const config = AppConfig(environment: 'unsupported');

      expect(() => config.cataquiApiUrl, throwsStateError);
    });

    test('when the environment is development, it should enable development behavior', () {
      const config = AppConfig(environment: 'development');

      expect(config.isDevelopment, isTrue);
    });

    test('when the environment is production, it should disable development behavior', () {
      const config = AppConfig(environment: 'production');

      expect(config.isDevelopment, isFalse);
    });
  });
}
