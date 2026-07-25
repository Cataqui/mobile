import 'package:release/src/environment_variables.dart';
import 'package:test/test.dart';

void main() {
  test('when a required environment variable exists, it should return its value', () {
    final environment = EnvironmentVariables(values: const {'REQUIRED_VALUE': 'configured'});

    expect(environment.getValueOrThrow('REQUIRED_VALUE'), 'configured');
  });

  test('when a required environment variable is missing, it should reject the environment', () {
    final environment = EnvironmentVariables(values: const {});

    expect(() => environment.getValueOrThrow('REQUIRED_VALUE'), throwsStateError);
  });
}
