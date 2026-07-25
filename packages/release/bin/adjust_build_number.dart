import 'dart:io';

import 'package:release/src/app_version.dart';

final class AdjustBuildNumberCommand {
  static AppVersion run({required int minimumBuildNumber}) {
    if (minimumBuildNumber <= 0) {
      throw ArgumentError.value(minimumBuildNumber, 'minimumBuildNumber', 'Build number must be positive.');
    }

    final currentVersion = AppVersion.current();
    if (currentVersion.buildNumber >= minimumBuildNumber) return currentVersion;

    return currentVersion.setBuildNumber(buildNumber: minimumBuildNumber);
  }
}

void main(List<String> arguments) {
  if (arguments.length != 1) throw ArgumentError('Usage: adjust_build_number <minimum-build-number>');

  final minimumBuildNumber = int.parse(arguments.single);
  stdout.writeln(AdjustBuildNumberCommand.run(minimumBuildNumber: minimumBuildNumber));
}
