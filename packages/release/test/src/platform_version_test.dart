import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:release/src/repository_paths/repository_paths.dart';
import 'package:test/test.dart';

void main() {
  test('when Android builds the app, it should read the pubspec version name', () {
    final root = Directories.root.path;
    final gradle = File(path.join(root, 'app', 'android', 'app', 'build.gradle.kts')).readAsStringSync();

    expect(gradle, contains('versionName = flutter.versionName'));
  });

  test('when Android builds the app, it should read the pubspec build number', () {
    final root = Directories.root.path;
    final gradle = File(path.join(root, 'app', 'android', 'app', 'build.gradle.kts')).readAsStringSync();

    expect(gradle, contains('versionCode = flutter.versionCode'));
  });

  test('when iOS builds the app, it should read the pubspec version name', () {
    final root = Directories.root.path;
    final plist = File(path.join(root, 'app', 'ios', 'Runner', 'Info.plist')).readAsStringSync();

    expect(plist, contains(r'$(FLUTTER_BUILD_NAME)'));
  });

  test('when iOS builds the app, it should read the pubspec build number', () {
    final root = Directories.root.path;
    final plist = File(path.join(root, 'app', 'ios', 'Runner', 'Info.plist')).readAsStringSync();

    expect(plist, contains(r'$(FLUTTER_BUILD_NUMBER)'));
  });

  test('when release workflows build the app, they should not override the pubspec version', () {
    final root = Directories.root.path;
    final workflow = File(path.join(root, '.github', 'workflows', 'release.yml')).readAsStringSync();

    expect(RegExp('--build-(?:name|number)').allMatches(workflow), isEmpty);
  });

  test('when Android builds the app, it should use the shared mobile identifier', () {
    final root = Directories.root.path;
    final gradle = File(path.join(root, 'app', 'android', 'app', 'build.gradle.kts')).readAsStringSync();

    expect(gradle, contains('applicationId = "com.cataqui.mobile"'));
  });
}
