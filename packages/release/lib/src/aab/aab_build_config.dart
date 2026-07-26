import 'dart:convert';
import 'dart:typed_data';

import 'package:release/src/environment_variables.dart';

final class AabBuildConfig {
  AabBuildConfig._({
    required this.signingKeystoreBytes,
    required this.signingKeystorePassword,
    required this.signingKeyAlias,
    required this.signingKeyPassword,
  });

  factory AabBuildConfig.fromEnv(EnvironmentVariables environmentVariables) {
    final encodedKeystore = environmentVariables.getValueOrThrow('AAB_SIGNING_KEYSTORE_BASE64');
    late final Uint8List keystoreBytes;

    try {
      keystoreBytes = base64Decode(encodedKeystore);
    } on FormatException {
      throw StateError('AAB_SIGNING_KEYSTORE_BASE64 must contain valid Base64.');
    }

    if (keystoreBytes.isEmpty) throw StateError('AAB_SIGNING_KEYSTORE_BASE64 must not decode to an empty file.');

    return AabBuildConfig._(
      signingKeystoreBytes: keystoreBytes,
      signingKeystorePassword: environmentVariables.getValueOrThrow('AAB_SIGNING_KEYSTORE_PASSWORD'),
      signingKeyAlias: environmentVariables.getValueOrThrow('AAB_SIGNING_KEY_ALIAS'),
      signingKeyPassword: environmentVariables.getValueOrThrow('AAB_SIGNING_KEY_PASSWORD'),
    );
  }

  final Uint8List signingKeystoreBytes;
  final String signingKeystorePassword;
  final String signingKeyAlias;
  final String signingKeyPassword;

  String aabSigningPropertiesContents({required String keystorePath}) {
    return '''
storeFile=${_escapePropertyValue(keystorePath)}
storePassword=${_escapePropertyValue(signingKeystorePassword)}
keyAlias=${_escapePropertyValue(signingKeyAlias)}
keyPassword=${_escapePropertyValue(signingKeyPassword)}
''';
  }

  String _escapePropertyValue(String value) {
    final buffer = StringBuffer();

    for (var index = 0; index < value.length; index += 1) {
      final character = value[index];
      final escapedCharacter = switch (character) {
        r'\' => r'\\',
        '\t' => r'\t',
        '\n' => r'\n',
        '\r' => r'\r',
        '\f' => r'\f',
        '=' => r'\=',
        ':' => r'\:',
        '#' => r'\#',
        '!' => r'\!',
        ' ' when index == 0 => r'\ ',
        _ => character,
      };
      buffer.write(escapedCharacter);
    }

    return buffer.toString();
  }
}
