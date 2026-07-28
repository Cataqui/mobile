import 'package:cataqui_app/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('when the flavor is development, it should use the staging Cataquí API', () {
      const config = AppConfig(flavor: 'development');

      expect(config.cataquiApiUrl, 'https://staging.api.cataqui.com');
    });

    test('when the flavor is production, it should use the production Cataquí API', () {
      const config = AppConfig(flavor: 'production');

      expect(config.cataquiApiUrl, 'https://api.cataqui.com');
    });

    test('when the flavor is unsupported, it should reject API URL resolution', () {
      const config = AppConfig(flavor: 'unsupported');

      expect(() => config.cataquiApiUrl, throwsStateError);
    });

    test('when the flavor is development, it should enable development behavior', () {
      const config = AppConfig(flavor: 'development');

      expect(config.isDevelopment, isTrue);
    });

    test('when the flavor is production, it should disable development behavior', () {
      const config = AppConfig(flavor: 'production');

      expect(config.isDevelopment, isFalse);
    });
  });
}
