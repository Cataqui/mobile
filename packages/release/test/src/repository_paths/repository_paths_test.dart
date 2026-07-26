import 'dart:io';

import 'package:release/src/directories/directories.dart';
import 'package:test/test.dart';

void main() {
  test('when accessing repository paths, it should locate the workspace root', () {
    expect(File('${Directories.root.path}/pubspec.yaml').existsSync(), isTrue);
  });

  test('when a test provides a repository root, it should isolate paths to that test', () {
    final repository = Directory.systemTemp.createTempSync('repository-paths-');
    addTearDown(() => repository.deleteSync(recursive: true));

    Directories.runWithRootForTesting(root: repository, body: () => expect(Directories.root.path, repository.path));
  });
}
