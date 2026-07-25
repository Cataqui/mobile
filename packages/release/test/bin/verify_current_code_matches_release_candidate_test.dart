import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:release/src/release_candidate_manifest.dart';
import 'package:release/src/repository_paths/repository_paths.dart';
import 'package:test/test.dart';

import '../../bin/verify_current_code_matches_release_candidate.dart';

void main() {
  final repository = Directory.systemTemp.createTempSync('verify-current-code-matches-release-candidate-');
  final appDirectory = Directory(path.join(repository.path, 'app'));
  final appPubspec = File(path.join(appDirectory.path, 'pubspec.yaml'));
  final lockfile = File(path.join(repository.path, 'pubspec.lock'));
  final localeDirectory = Directory(path.join(repository.path, 'packages', 'locale'));
  final localePubspec = File(path.join(localeDirectory.path, 'pubspec.yaml'));
  final apk = File(path.join(repository.path, 'app.apk'));

  setUpAll(() {
    appDirectory.createSync(recursive: true);
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

  test('when current code matches the release candidate, it should accept the code', () async {
    await Directories.runWithRootForTesting(
      root: repository,
      body: () async {
        await ReleaseCandidateManifest.write(
          commitHash: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          apiUrl: 'https://api.example.com',
          apk: apk,
        );

        expect(VerifyCurrentCodeMatchesReleaseCandidateCommand.run(), completes);
      },
    );
  });

  test('when app code differs from the release candidate, it should reject the code', () async {
    await Directories.runWithRootForTesting(
      root: repository,
      body: () => ReleaseCandidateManifest.write(
        commitHash: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        apiUrl: 'https://api.example.com',
        apk: apk,
      ),
    );
    appPubspec.writeAsStringSync('version: 1.3.0+43\n');

    Directories.runWithRootForTesting(
      root: repository,
      body: () => expect(VerifyCurrentCodeMatchesReleaseCandidateCommand.run(), throwsStateError),
    );
  });

  test('when locale code differs from the release candidate, it should reject the code', () async {
    await Directories.runWithRootForTesting(
      root: repository,
      body: () => ReleaseCandidateManifest.write(
        commitHash: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        apiUrl: 'https://api.example.com',
        apk: apk,
      ),
    );
    localePubspec.writeAsStringSync('name: locale\nversion: 1.0.1\n');

    Directories.runWithRootForTesting(
      root: repository,
      body: () => expect(VerifyCurrentCodeMatchesReleaseCandidateCommand.run(), throwsStateError),
    );
  });

  test('when the dependency lock differs from the release candidate, it should reject the code', () async {
    await Directories.runWithRootForTesting(
      root: repository,
      body: () => ReleaseCandidateManifest.write(
        commitHash: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        apiUrl: 'https://api.example.com',
        apk: apk,
      ),
    );
    lockfile.writeAsStringSync('packages: changed\n');

    Directories.runWithRootForTesting(
      root: repository,
      body: () => expect(VerifyCurrentCodeMatchesReleaseCandidateCommand.run(), throwsStateError),
    );
  });
}
