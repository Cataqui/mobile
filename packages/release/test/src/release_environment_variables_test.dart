import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:release/src/directories/directories.dart';
import 'package:release/src/environment_variables.dart';
import 'package:test/test.dart';

void main() {
  final temporaryDirectory = Directory.systemTemp.createTempSync('release-environment-variables-');
  final environmentFile = File(path.join(temporaryDirectory.path, '.env'));

  tearDown(() {
    if (environmentFile.existsSync()) environmentFile.deleteSync();
  });

  tearDownAll(() {
    temporaryDirectory.deleteSync(recursive: true);
  });

  test('when a required environment variable exists, it should return its value', () {
    final environment = EnvironmentVariables(values: const {'REQUIRED_VALUE': 'configured'});

    expect(environment.getValueOrThrow('REQUIRED_VALUE'), 'configured');
  });

  test('when a required environment variable is missing, it should reject the environment', () {
    final environment = EnvironmentVariables(values: const {});

    expect(() => environment.getValueOrThrow('REQUIRED_VALUE'), throwsStateError);
  });

  test('when a dotenv file contains signing values, it should preserve special characters in their values', () {
    environmentFile.writeAsStringSync('PASSWORD=aB!#:=\\\\value\n');

    final environment = Directories.runWithRootForTesting(
      root: temporaryDirectory,
      body: () => EnvironmentVariables.current(overrides: const {}),
    );

    expect(environment.getValueOrThrow('PASSWORD'), r'aB!#:=\\value');
  });

  test('when a process value overrides a dotenv value, it should use the process value', () {
    environmentFile.writeAsStringSync('ENVIRONMENT=development\n');

    final environment = Directories.runWithRootForTesting(
      root: temporaryDirectory,
      body: () => EnvironmentVariables.current(overrides: const {'ENVIRONMENT': 'production'}),
    );

    expect(environment.getValueOrThrow('ENVIRONMENT'), 'production');
  });

  test('when a dotenv entry is malformed, it should reject the file', () {
    environmentFile.writeAsStringSync('MALFORMED\n');

    expect(
      () => Directories.runWithRootForTesting(
        root: temporaryDirectory,
        body: () => EnvironmentVariables.current(overrides: const {}),
      ),
      throwsFormatException,
    );
  });
}
