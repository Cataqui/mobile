import 'package:cataqui_app/core/dtos/onboarding_local_progress_dto/onboarding_local_progress_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scenario in [
    (name: null, serverCompleted: false, completed: false),
    (name: '', serverCompleted: false, completed: false),
    (name: '  ', serverCompleted: false, completed: false),
    (name: ' Ana ', serverCompleted: false, completed: true),
    (name: null, serverCompleted: true, completed: true),
  ]) {
    test(
      'when name is ${scenario.name} and server completion is ${scenario.serverCompleted}, it should compute completion as ${scenario.completed}',
      () {
        final progress = OnboardingLocalProgressDto(
          name: scenario.name,
          serverConfirmedCompleted: scenario.serverCompleted,
        );

        expect(progress.completed, scenario.completed);
      },
    );
  }
}
