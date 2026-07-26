part of 'directories.dart';

final class ReleasesDirectory {
  ReleasesDirectory._({required this.directory});

  final Directory directory;

  ReleaseVersionDirectory operator [](String version) {
    final directoryName = 'v$version';

    if (path.basename(directoryName) != directoryName) {
      throw ArgumentError.value(version, 'version', 'Version must not contain path separators.');
    }

    return ReleaseVersionDirectory._(directory: Directory(path.join(directory.path, directoryName)));
  }
}
