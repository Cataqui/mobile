import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:release/src/directories/directories.dart';

final class EnvironmentVariables {
  EnvironmentVariables({required this.values});

  factory EnvironmentVariables.current({Map<String, String>? overrides}) {
    final file = File(path.join(Directories.root.path, '.env'));
    final fileValues = <String, String>{};

    if (file.existsSync()) {
      final lines = const LineSplitter().convert(file.readAsStringSync());

      for (var index = 0; index < lines.length; index += 1) {
        final line = lines[index].trimLeft();
        if (line.isEmpty || line.startsWith('#')) continue;

        final separatorIndex = line.indexOf('=');
        if (separatorIndex <= 0) {
          throw FormatException('Invalid environment entry on line ${index + 1} of ${file.path}.');
        }

        final name = line.substring(0, separatorIndex).trim();
        if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name)) {
          throw FormatException('Invalid environment variable name on line ${index + 1} of ${file.path}.');
        }

        fileValues[name] = line.substring(separatorIndex + 1);
      }
    }

    return EnvironmentVariables(values: {...fileValues, ...(overrides ?? Platform.environment)});
  }

  final Map<String, String> values;

  String getValueOrThrow(String name) {
    final value = values[name];

    if (value == null || value.isEmpty) throw StateError('Missing required environment variable $name.');

    return value;
  }
}
