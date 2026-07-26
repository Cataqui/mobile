import 'dart:convert';

import 'package:release/src/aab/aab_build_config.dart';
import 'package:release/src/environment_variables.dart';
import 'package:test/test.dart';

void main() {
  Map<String, String> validEnvironment() => {
    'AAB_SIGNING_KEYSTORE_BASE64': base64Encode([1, 2, 3]),
    'AAB_SIGNING_KEYSTORE_PASSWORD': r'store\password:=#!',
    'AAB_SIGNING_KEY_ALIAS': 'aab-signing-key',
    'AAB_SIGNING_KEY_PASSWORD': r'key\password:=#!',
  };

  test('when every Android App Bundle value is valid, it should decode the keystore', () {
    final configuration = AabBuildConfig.fromEnv(EnvironmentVariables(values: validEnvironment()));

    expect(configuration.signingKeystoreBytes, [1, 2, 3]);
  });

  test('when the keystore is not valid Base64, it should reject the Google Play build', () {
    final environment = validEnvironment()..['AAB_SIGNING_KEYSTORE_BASE64'] = 'not base64';

    expect(() => AabBuildConfig.fromEnv(EnvironmentVariables(values: environment)), throwsStateError);
  });

  test('when the keystore decodes to an empty file, it should reject the Google Play build', () {
    final environment = validEnvironment()..['AAB_SIGNING_KEYSTORE_BASE64'] = '';

    expect(() => AabBuildConfig.fromEnv(EnvironmentVariables(values: environment)), throwsStateError);
  });

  test('when signing passwords contain property syntax, it should escape the generated Gradle values', () {
    final configuration = AabBuildConfig.fromEnv(EnvironmentVariables(values: validEnvironment()));

    expect(configuration.aabSigningPropertiesContents(keystorePath: '/tmp/signing:key.jks'), r'''
storeFile=/tmp/signing\:key.jks
storePassword=store\\password\:\=\#\!
keyAlias=aab-signing-key
keyPassword=key\\password\:\=\#\!
''');
  });
}
