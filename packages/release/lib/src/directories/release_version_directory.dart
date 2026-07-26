part of 'directories.dart';

final class ReleaseVersionDirectory {
  ReleaseVersionDirectory._({required this.directory});

  final Directory directory;

  File get manifest => File(path.join(directory.path, 'manifest.json'));

  File setReleaseNotesForLocale({required String locale}) {
    final fileName = '$locale.txt';

    if (path.basename(fileName) != fileName) {
      throw ArgumentError.value(locale, 'locale', 'Locale must not contain path separators.');
    }

    final file = File(path.join(directory.path, fileName))..createSync(recursive: true);
    return file;
  }
}
