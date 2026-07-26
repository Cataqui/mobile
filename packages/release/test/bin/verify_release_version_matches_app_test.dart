import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:release/src/directories/directories.dart';
import 'package:test/test.dart';

import '../../bin/verify_release_version_matches_app.dart';

void main() {
  final repository = Directory.systemTemp.createTempSync('verify-release-version-matches-app-');
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

  test('when the deployment tag matches the app version, it should accept the release', () {
    Directories.runWithRootForTesting(
      root: repository,
      body: () => expect(() => VerifyReleaseVersionMatchesAppCommand.run(releaseTag: 'v1.3.0'), returnsNormally),
    );
  });

  test('when the app version has no positive build number, it should reject the release', () {
    pubspec.writeAsStringSync('name: cataqui_app\nversion: 1.3.0\n');

    Directories.runWithRootForTesting(
      root: repository,
      body: () => expect(() => VerifyReleaseVersionMatchesAppCommand.run(releaseTag: 'v1.3.0'), throwsStateError),
    );
  });

  test('when the deployment tag differs from the app version, it should reject the release', () {
    Directories.runWithRootForTesting(
      root: repository,
      body: () => expect(() => VerifyReleaseVersionMatchesAppCommand.run(releaseTag: 'v1.3.1'), throwsStateError),
    );
  });
}
