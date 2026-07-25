import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:release/src/release_candidate_manifest.dart';
import 'package:release/src/repository_paths/repository_paths.dart';
import 'package:test/test.dart';

void main() {
  final repository = Directory.systemTemp.createTempSync('candidate-manifest-');
  final appDirectory = Directory(path.join(repository.path, 'app'));
  final appPubspec = File(path.join(appDirectory.path, 'pubspec.yaml'));
  final lockfile = File(path.join(repository.path, 'pubspec.lock'));
  final localeDirectory = Directory(path.join(repository.path, 'packages', 'locale'));
  final localePubspec = File(path.join(localeDirectory.path, 'pubspec.yaml'));
  final apk = File(path.join(repository.path, 'app.apk'));

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
    apk.writeAsStringSync('apk');
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
    final androidApkHash = List.filled(64, 'c').join();
    final manifest = ReleaseCandidateManifest.fromJson({
      'version': '1.3.0+42',
      'versionName': '1.3.0',
      'buildNumber': 42,
      'environment': 'production',
      'cataquiApiUrl': 'https://api.example.com',
      'commitHash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'codeHash': codeHash,
      'androidApkHash': androidApkHash,
    });

    expect(manifest.toJson(), {
      'version': '1.3.0+42',
      'versionName': '1.3.0',
      'buildNumber': 42,
      'environment': 'production',
      'cataquiApiUrl': 'https://api.example.com',
      'commitHash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'codeHash': codeHash,
      'androidApkHash': androidApkHash,
    });
  });

  test('when a candidate manifest field has the wrong type, it should reject the JSON', () {
    final codeHash = List.filled(64, 'b').join();
    final androidApkHash = List.filled(64, 'c').join();

    expect(
      () => ReleaseCandidateManifest.fromJson({
        'version': '1.3.0+42',
        'versionName': '1.3.0',
        'buildNumber': '42',
        'environment': 'production',
        'cataquiApiUrl': 'https://api.example.com',
        'commitHash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'codeHash': codeHash,
        'androidApkHash': androidApkHash,
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('when the production API URL is not HTTPS, it should reject the candidate', () {
    Directories.runWithRootForTesting(
      root: repository,
      body: () => expect(
        ReleaseCandidateManifest.write(
          commitHash: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          apiUrl: 'http://api.example.com',
          apk: apk,
        ),
        throwsFormatException,
      ),
    );
  });
}
