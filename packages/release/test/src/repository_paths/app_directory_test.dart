import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:release/src/directories/directories.dart';
import 'package:test/test.dart';

void main() {
  test('when accessing the app absolute path, it should return the app directory path', () {
    expect(Directories.app.absolutePath, path.join(Directories.root.path, 'app'));
  });

  test('when accessing the app pubspec, it should return the app pubspec file', () {
    expect(Directories.app.pubspecFile.path, path.join(Directories.root.path, 'app', 'pubspec.yaml'));
  });

  test('when accessing the app changelog, it should return the app changelog file', () {
    expect(Directories.app.changelogFile.path, path.join(Directories.root.path, 'app', 'CHANGELOG.md'));
  });

  test('when hashing tracked app code, it should return a valid hash', () async {
    final repository = Directory.systemTemp.createTempSync('app-directory-code-hash-');
    addTearDown(() => repository.deleteSync(recursive: true));
    Directory(path.join(repository.path, 'app')).createSync(recursive: true);
    Directory(path.join(repository.path, 'packages', 'locale')).createSync(recursive: true);
    File(path.join(repository.path, '.fvmrc')).writeAsStringSync('{"flutter":"3.44.0"}\n');
    File(path.join(repository.path, 'pubspec.yaml')).writeAsStringSync('name: workspace\n');
    File(path.join(repository.path, 'pubspec.lock')).writeAsStringSync('packages: {}\n');
    File(path.join(repository.path, 'app', 'pubspec.yaml')).writeAsStringSync('version: 1.3.0+42\n');
    File(path.join(repository.path, 'packages', 'locale', 'pubspec.yaml')).writeAsStringSync('name: locale\n');
    Process.runSync('git', ['init', '--quiet'], workingDirectory: repository.path);
    Process.runSync('git', [
      'add',
      '.fvmrc',
      'pubspec.yaml',
      'pubspec.lock',
      'app',
      'packages/locale',
    ], workingDirectory: repository.path);

    final hash = await Directories.runWithRootForTesting(root: repository, body: () => Directories.app.codeHash());

    expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
  });
}
