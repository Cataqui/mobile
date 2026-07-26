import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:release/src/changelog.dart';
import 'package:release/src/directories/directories.dart';
import 'package:test/test.dart';

void main() {
  final repository = Directory.systemTemp.createTempSync('changelog-');
  final appDirectory = Directory(path.join(repository.path, 'app'));
  final changelog = File(path.join(appDirectory.path, 'CHANGELOG.md'));

  setUpAll(() {
    appDirectory.createSync();
    File(path.join(repository.path, 'pubspec.yaml')).writeAsStringSync('name: workspace\n');
    File(path.join(appDirectory.path, 'pubspec.yaml')).writeAsStringSync('version: 1.3.0+42\n');
  });

  tearDownAll(() {
    repository.deleteSync(recursive: true);
  });

  test('when multiple releases exist, it should return only the requested release', () {
    changelog.writeAsStringSync('''
# Changelog

## [1.3.0](https://example.com)

- Added nearby jobs.

## 1.2.0

- Older change.
''');

    Directories.runWithRootForTesting(
      root: repository,
      body: () => expect(Changelog.currentVersion(), '- Added nearby jobs.'),
    );
  });

  test('when the requested release is missing, it should reject the changelog', () {
    changelog.writeAsStringSync('# Changelog\n');

    Directories.runWithRootForTesting(root: repository, body: () => expect(Changelog.currentVersion, throwsStateError));
  });
}
