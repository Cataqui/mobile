import 'dart:io';

import 'package:release/src/aab/aab_build_config.dart';
import 'package:release/src/aab/aab_manager.dart';
import 'package:release/src/environment_variables.dart';

final class BuildAabCommand {
  static Future<void> run() async {
    final environmentVariables = EnvironmentVariables.current();

    if (environmentVariables.getValueOrThrow('ENVIRONMENT') != 'production') {
      throw StateError('Release AABs require ENVIRONMENT=production.');
    }

    final aabBuildConfig = AabBuildConfig.fromEnv(environmentVariables);
    final appBundle = await AabManager.build(aabConfig: aabBuildConfig);

    stdout.writeln('AAB created at ${appBundle.path}.');
  }
}

Future<void> main() => BuildAabCommand.run();
