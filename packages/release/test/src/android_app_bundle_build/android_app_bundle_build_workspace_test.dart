import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:release/src/aab/aab_build_config.dart';
import 'package:release/src/aab/aab_manager.dart';
import 'package:release/src/environment_variables.dart';
import 'package:test/test.dart';

void main() {
  late Directory repository;
  late File aabSigningProperties;
  late AabManager workspace;

  setUp(() {
    repository = Directory.systemTemp.createTempSync('android-app-bundle-build-workspace-');
    Directory(path.join(repository.path, 'app', 'android')).createSync(recursive: true);
    aabSigningProperties = File(path.join(repository.path, 'app', 'android', 'aab-signing.properties'));
    final configuration = AabBuildConfig.fromEnv(
      EnvironmentVariables(
        values: {
          'AAB_SIGNING_KEYSTORE_BASE64': base64Encode([1, 2, 3]),
          'AAB_SIGNING_KEYSTORE_PASSWORD': 'store-password',
          'AAB_SIGNING_KEY_ALIAS': 'aab-signing-key',
          'AAB_SIGNING_KEY_PASSWORD': 'key-password',
        },
      ),
    );
    workspace = AabManager(repositoryRoot: repository, aabConfig: configuration);
  });

  tearDown(() {
    repository.deleteSync(recursive: true);
  });

  test('when preparing an Android App Bundle build, it should materialize the decoded keystore', () async {
    late List<int> materializedKeystore;

    await workspace.runWithSigning(
      action: () async {
        final storeFileLine = aabSigningProperties.readAsLinesSync().singleWhere(
          (line) => line.startsWith('storeFile='),
        );
        materializedKeystore = File(storeFileLine.substring('storeFile='.length)).readAsBytesSync();
      },
    );

    expect(materializedKeystore, [1, 2, 3]);
  });

  test(
    'when no local AAB signing properties existed, it should remove the temporary adapter after the build',
    () async {
      await workspace.runWithSigning(action: () async {});

      expect(aabSigningProperties.existsSync(), isFalse);
    },
  );

  test('when local AAB signing properties existed, it should restore them after the build', () async {
    aabSigningProperties.writeAsStringSync('developer signing configuration');

    await workspace.runWithSigning(action: () async {});

    expect(aabSigningProperties.readAsStringSync(), 'developer signing configuration');
  });

  test(
    'when local AAB signing properties existed, it should restore their original permissions after the build',
    () async {
      aabSigningProperties.writeAsStringSync('developer signing configuration');
      Process.runSync('chmod', ['640', aabSigningProperties.path]);

      await workspace.runWithSigning(action: () async {});

      expect(aabSigningProperties.statSync().mode & 0x1ff, 0x1a0);
    },
  );

  test('when the build fails, it should still restore local AAB signing properties', () async {
    aabSigningProperties.writeAsStringSync('developer signing configuration');

    try {
      await workspace.runWithSigning<void>(
        action: () async {
          throw const FormatException('build failed');
        },
      );
    } on FormatException {
      // The restoration is the behavior under test.
    }

    expect(aabSigningProperties.readAsStringSync(), 'developer signing configuration');
  });

  test('when the build finishes, it should delete the temporary keystore', () async {
    late String materializedKeystorePath;

    await workspace.runWithSigning(
      action: () async {
        final storeFileLine = aabSigningProperties.readAsLinesSync().singleWhere(
          (line) => line.startsWith('storeFile='),
        );
        materializedKeystorePath = storeFileLine.substring('storeFile='.length);
      },
    );

    expect(File(materializedKeystorePath).existsSync(), isFalse);
  });
}
