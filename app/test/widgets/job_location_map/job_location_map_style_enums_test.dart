import 'package:cataqui_app/widgets/job_location_map/job_location_map_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobLocationMapVisibility', () {
    test('when serializing visibility values, it should use the Google Maps visibility tokens', () {
      final serializedValues = <Object?>[
        const JobLocationMapStyleStyler(visibility: JobLocationMapVisibility.hidden).toJson()['visibility'],
        const JobLocationMapStyleStyler(visibility: JobLocationMapVisibility.visible).toJson()['visibility'],
        const JobLocationMapStyleStyler(visibility: JobLocationMapVisibility.simplified).toJson()['visibility'],
      ];

      expect(serializedValues, <String>['off', 'on', 'simplified']);
    });
  });
}
