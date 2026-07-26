import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:release/src/app_version.dart';
import 'package:release/src/directories/directories.dart';
import 'package:test/test.dart';

void main() {
  final repository = Directory.systemTemp.createTempSync('app-version-');
  final appDirectory = Directory(path.join(repository.path, 'app'));
  final pubspec = File(path.join(appDirectory.path, 'pubspec.yaml'));

  setUpAll(() {
    appDirectory.createSync();
    File(path.join(repository.path, 'pubspec.yaml')).writeAsStringSync('name: workspace\n');
  });

  setUp(() {
    pubspec.writeAsStringSync('name: cataqui_app\nversion: 1.3.0+42\n');
  });

  tearDownAll(() {
    repository.deleteSync(recursive: true);
  });

  test('when reading a pubspec, it should parse the version name and build number', () {
    Directories.runWithRootForTesting(
      root: repository,
      body: () => expect(AppVersion.current().toString(), '1.3.0+42'),
    );
  });

  test('when a pubspec omits the build number, it should use zero as the fallback', () {
    pubspec.writeAsStringSync('name: cataqui_app\nversion: 1.4.0\n');

    Directories.runWithRootForTesting(root: repository, body: () => expect(AppVersion.current().buildNumber, 0));
  });

  test('when setting a build number, it should preserve the semantic version', () {
    Directories.runWithRootForTesting(
      root: repository,
      body: () {
        final updated = AppVersion.current().setBuildNumber(buildNumber: 50);

        expect(updated.name, '1.3.0');
      },
    );
  });

  test('when setting a build number, it should use exactly the provided value', () {
    Directories.runWithRootForTesting(
      root: repository,
      body: () {
        final updated = AppVersion.current().setBuildNumber(buildNumber: 10);

        expect(updated.buildNumber, 10);
      },
    );
  });

  test('when setting a build number, it should preserve pubspec comments and whitespace', () {
    pubspec.writeAsStringSync('''
name: cataqui_app

version: 1.3.0+42 # managed by release tooling
''');

    Directories.runWithRootForTesting(
      root: repository,
      body: () => AppVersion.current().setBuildNumber(buildNumber: 50),
    );

    expect(pubspec.readAsStringSync(), '''
name: cataqui_app

version: 1.3.0+50 # managed by release tooling
''');
  });
}
