import 'package:release/src/app_version.dart';
import 'package:release/src/directories/directories.dart';

final class Changelog {
  Changelog._();

  static String currentVersion() {
    final changelogFileContent = Directories.app.changelogFile.readAsStringSync();
    final currentAppVersionName = AppVersion.current().name;
    final currentVersionHeadingPattern = RegExp(
      '^## .*\\b${RegExp.escape(currentAppVersionName)}\\b.*\$',
      multiLine: true,
    );

    final currentVersionHeadingMatch = currentVersionHeadingPattern.firstMatch(changelogFileContent);
    if (currentVersionHeadingMatch == null) {
      throw StateError('Changelog does not contain version $currentAppVersionName');
    }

    final contentAfterCurrentVersionHeading = changelogFileContent.substring(currentVersionHeadingMatch.end);
    final nextVersionHeadingMatch = RegExp('^## ', multiLine: true).firstMatch(contentAfterCurrentVersionHeading);

    final currentVersionSection = nextVersionHeadingMatch == null
        ? contentAfterCurrentVersionHeading
        : contentAfterCurrentVersionHeading.substring(0, nextVersionHeadingMatch.start);

    final currentVersionReleaseNotes = currentVersionSection.trim();

    if (currentVersionReleaseNotes.isEmpty) throw StateError('Changelog section for $currentAppVersionName is empty');

    return currentVersionReleaseNotes;
  }
}
