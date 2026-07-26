import 'package:release/src/directories/directories.dart';
import 'package:release/src/release_candidate_manifest.dart';

final class VerifyCurrentCodeMatchesReleaseCandidateCommand {
  static Future<void> run() async {
    final currentReleaseCandidateManifest = ReleaseCandidateManifest.current();
    final currentCodeHash = await Directories.app.codeHash();

    if (currentReleaseCandidateManifest.codeHash != currentCodeHash) {
      throw StateError('The current code does not match the code of the currently approved release candidate.');
    }
  }
}

Future<void> main() => VerifyCurrentCodeMatchesReleaseCandidateCommand.run();
