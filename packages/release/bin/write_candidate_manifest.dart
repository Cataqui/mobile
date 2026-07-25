import 'dart:io';

import 'package:release/src/environment_variables.dart';
import 'package:release/src/release_candidate_manifest.dart';

final class WriteCandidateManifestCommand {
  static Future<void> run() async {
    final environmentVariables = EnvironmentVariables(values: Platform.environment);

    final manifest = await ReleaseCandidateManifest.write(
      commitHash: environmentVariables.getValueOrThrow('CANDIDATE_COMMIT_HASH'),
      apiUrl: environmentVariables.getValueOrThrow('CANDIDATE_API_URL'),
      apk: File(environmentVariables.getValueOrThrow('ANDROID_APK_PATH')),
    );

    stdout.writeln(manifest.path);
  }
}

Future<void> main() => WriteCandidateManifestCommand.run();
