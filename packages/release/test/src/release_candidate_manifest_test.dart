import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:release/src/release_candidate_manifest.dart';
import 'package:test/test.dart';

void main() {
  final repository = Directory.systemTemp.createTempSync('candidate-manifest-');
  final appDirectory = Directory(path.join(repository.path, 'app'));
  final appPubspec = File(path.join(appDirectory.path, 'pubspec.yaml'));
  final lockfile = File(path.join(repository.path, 'pubspec.lock'));
  final localeDirectory = Directory(path.join(repository.path, 'packages', 'locale'));
  final localePubspec = File(path.join(localeDirectory.path, 'pubspec.yaml'));
  setUpAll(() {
    appDirectory.createSync();
    localeDirectory.createSync(recursive: true);
    File(path.join(repository.path, '.fvmrc')).writeAsStringSync('{"flutter":"3.44.0"}\n');
    File(path.join(repository.path, 'pubspec.yaml')).writeAsStringSync('name: workspace\n');
    Process.runSync('git', ['init', '--quiet'], workingDirectory: repository.path);
  });

  setUp(() {
    appPubspec.writeAsStringSync('version: 1.3.0+42\n');
    lockfile.writeAsStringSync('packages: {}\n');
    localePubspec.writeAsStringSync('name: locale\nversion: 1.0.0\n');
    Process.runSync('git', [
      'add',
      '.fvmrc',
      'pubspec.yaml',
      'pubspec.lock',
      'app',
      'packages/locale',
    ], workingDirectory: repository.path);
  });

  tearDownAll(() {
    repository.deleteSync(recursive: true);
  });

  test('when decoding a candidate manifest, it should return every typed field', () {
    final codeHash = List.filled(64, 'b').join();
    final manifest = ReleaseCandidateManifest.fromJson({
      'version': '1.3.0+42',
      'versionName': '1.3.0',
      'buildNumber': 42,
      'environment': 'production',
      'commitHash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'codeHash': codeHash,
    });

    expect(manifest.toJson(), {
      'version': '1.3.0+42',
      'versionName': '1.3.0',
      'buildNumber': 42,
      'environment': 'production',
      'commitHash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'codeHash': codeHash,
    });
  });

  test('when a candidate manifest field has the wrong type, it should reject the JSON', () {
    final codeHash = List.filled(64, 'b').join();

    expect(
      () => ReleaseCandidateManifest.fromJson({
        'version': '1.3.0+42',
        'versionName': '1.3.0',
        'buildNumber': '42',
        'environment': 'production',
        'commitHash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'codeHash': codeHash,
      }),
      throwsA(isA<TypeError>()),
    );
  });
}
