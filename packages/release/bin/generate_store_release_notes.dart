import 'package:http/http.dart' as http;
import 'package:release/src/ai_release_notes_generator.dart';
import 'package:release/src/app_version.dart';
import 'package:release/src/directories/directories.dart';
import 'package:release/src/environment_variables.dart';

final class GenerateStoreReleaseNotesCommand {
  static Future<void> run() async {
    final environment = EnvironmentVariables.current();
    final httpClient = http.Client();

    try {
      final generator = AIReleaseNotesGenerator(httpClient: httpClient, environmentVariables: environment);
      final generatedReleaseNotes = await generator.generate();
      final currentAppVersion = AppVersion.current();
      final currentVersionDirectory = Directories.distribution.releases[currentAppVersion.name];

      for (final localization in generatedReleaseNotes.localizations) {
        final file = currentVersionDirectory.setReleaseNotesForLocale(locale: localization.locale);
        await file.writeAsString('${localization.formattedReleaseNote}\n');
      }
    } finally {
      httpClient.close();
    }
  }
}

Future<void> main() => GenerateStoreReleaseNotesCommand.run();
