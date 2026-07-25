import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:release/src/repository_paths/repository_paths.dart';
import 'package:test/test.dart';

void main() {
  late Directory repository;

  setUp(() {
    repository = Directory.systemTemp.createTempSync('release-version-directory-');
  });

  tearDown(() {
    repository.deleteSync(recursive: true);
  });

  test('when accessing a release manifest, it should return the release manifest file', () {
    Directories.runWithRootForTesting(
      root: repository,
      body: () {
        final release = Directories.distribution.releases['1.3.1'];

        expect(
          release.manifest.path,
          path.join(repository.path, 'distribution', 'releases', 'v1.3.1', 'manifest.json'),
        );
      },
    );
  });

  test('when accessing localized store notes, it should return the locale release notes file', () {
    Directories.runWithRootForTesting(
      root: repository,
      body: () {
        final release = Directories.distribution.releases['1.3.1'];

        expect(
          release.setReleaseNotesForLocale(locale: 'pt-BR').path,
          path.join(repository.path, 'distribution', 'releases', 'v1.3.1', 'pt-BR.txt'),
        );
      },
    );
  });

  test('when localized store notes do not exist, it should create the locale release notes file', () {
    Directories.runWithRootForTesting(
      root: repository,
      body: () {
        final release = Directories.distribution.releases['1.3.1'];

        expect(release.setReleaseNotesForLocale(locale: 'pt-BR').existsSync(), isTrue);
      },
    );
  });

  test('when a store locale contains a path separator, it should reject the locale', () {
    Directories.runWithRootForTesting(
      root: repository,
      body: () {
        final release = Directories.distribution.releases['1.3.1'];

        expect(() => release.setReleaseNotesForLocale(locale: '../pt-BR'), throwsArgumentError);
      },
    );
  });
}
