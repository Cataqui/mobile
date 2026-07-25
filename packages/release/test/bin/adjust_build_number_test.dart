import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:release/src/repository_paths/repository_paths.dart';
import 'package:test/test.dart';

import '../../bin/adjust_build_number.dart';

void main() {
  final repository = Directory.systemTemp.createTempSync('adjust-build-number-');
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

  test('when TestFlight requires a higher build number, it should set that build number', () {
    Directories.runWithRootForTesting(
      root: repository,
      body: () => expect(AdjustBuildNumberCommand.run(minimumBuildNumber: 50).buildNumber, 50),
    );
  });

  test('when the app already has a higher build number, it should preserve the app build number', () {
    pubspec.writeAsStringSync('name: cataqui_app\nversion: 1.3.0+52\n');

    Directories.runWithRootForTesting(
      root: repository,
      body: () => expect(AdjustBuildNumberCommand.run(minimumBuildNumber: 50).buildNumber, 52),
    );
  });

  test('when the required build number is not positive, it should reject the build number', () {
    Directories.runWithRootForTesting(
      root: repository,
      body: () => expect(() => AdjustBuildNumberCommand.run(minimumBuildNumber: 0), throwsArgumentError),
    );
  });
}
