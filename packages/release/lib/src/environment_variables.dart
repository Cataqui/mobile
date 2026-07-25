final class EnvironmentVariables {
  EnvironmentVariables({required this.values});

  final Map<String, String> values;

  String getValueOrThrow(String name) {
    final value = values[name];

    if (value == null || value.isEmpty) throw StateError('Missing required environment variable $name.');

    return value;
  }
}
