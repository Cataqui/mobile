import 'dart:io';

import 'package:release/src/environment_variables.dart';
import 'package:release/src/release_candidate_manifest.dart';

final class WriteCandidateManifestCommand {
  static Future<void> run() async {
    final environmentVariables = EnvironmentVariables.current();

    final manifest = await ReleaseCandidateManifest.write(
      commitHash: environmentVariables.getValueOrThrow('CANDIDATE_COMMIT_HASH'),
    );

    stdout.writeln(manifest.path);
  }
}

Future<void> main() => WriteCandidateManifestCommand.run();
