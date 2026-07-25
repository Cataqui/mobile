part of 'repository_paths.dart';

final class AppDirectory {
  AppDirectory._({required Directory repositoryRoot}) : _directory = Directory(path.join(repositoryRoot.path, 'app'));

  static const List<String> _codePaths = ['.fvmrc', 'pubspec.yaml', 'pubspec.lock', 'app', 'packages/locale'];

  final Directory _directory;

  File get pubspecFile => File(path.join(_directory.path, 'pubspec.yaml'));
  File get changelogFile => File(path.join(_directory.path, 'CHANGELOG.md'));

  Future<String> codeHash() async {
    final repositoryRoot = _directory.parent;
    final result = await Process.run('git', ['-C', repositoryRoot.path, 'ls-files', '-z', '--', ..._codePaths]);

    if (result.exitCode != 0) throw StateError('Could not read tracked app code: ${result.stderr}');

    final relativePaths = (result.stdout as String)
        .split('\u0000')
        .where((relativePath) => relativePath.isNotEmpty)
        .toList();

    if (relativePaths.isEmpty) throw StateError('App code is empty.');

    for (final codePath in _codePaths) {
      final containsCode = relativePaths.any(
        (relativePath) => relativePath == codePath || path.isWithin(codePath, relativePath),
      );

      if (!containsCode) throw StateError('Missing tracked app code path $codePath.');
    }

    relativePaths.sort();

    final hashInputBytes = BytesBuilder(copy: false);

    for (final relativePath in relativePaths) {
      final filePath = path.normalize(path.join(repositoryRoot.path, relativePath));

      if (!path.isWithin(repositoryRoot.path, filePath)) {
        throw StateError('App code escaped the repository root.');
      }

      if (FileSystemEntity.typeSync(filePath, followLinks: false) != FileSystemEntityType.file) {
        throw StateError('App code is not a regular file: $relativePath.');
      }

      hashInputBytes
        ..add(utf8.encode(path.posix.joinAll(path.split(relativePath))))
        ..addByte(0)
        ..add(await File(filePath).readAsBytes())
        ..addByte(0);
    }

    return sha256.convert(hashInputBytes.takeBytes()).toString();
  }
}
