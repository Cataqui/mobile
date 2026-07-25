import 'package:release/src/app_version.dart';

final class VerifyReleaseVersionMatchesAppCommand {
  static void run({required String releaseTag}) {
    final currentAppVersion = AppVersion.current();

    if (currentAppVersion.buildNumber <= 0) throw StateError('Release version must have a positive build number.');

    if (releaseTag != 'v${currentAppVersion.name}') {
      throw StateError('Release tag $releaseTag does not match current app version $currentAppVersion.');
    }
  }
}

void main(List<String> arguments) {
  if (arguments.length != 1) {
    throw const FormatException('Usage: verify_release_version_matches_app.dart <release-tag>');
  }

  VerifyReleaseVersionMatchesAppCommand.run(releaseTag: arguments.single);
}
