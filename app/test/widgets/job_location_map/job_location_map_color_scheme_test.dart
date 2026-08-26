import 'package:cataqui_app/widgets/job_location_map/job_location_map_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

void main() {
  group('JobLocationMapColorScheme', () {
    test('when resolving light brightness, it should return the approved light map colors', () {
      expect(
        JobLocationMapColorScheme.fromBrightness(brightness: Brightness.light, palette: MateoPalette()).background,
        MateoPalette().neutral[2],
      );
    });

    test('when resolving dark brightness, it should reject the unsupported map appearance', () {
      expect(
        () => JobLocationMapColorScheme.fromBrightness(brightness: Brightness.dark, palette: MateoPalette()),
        throwsUnsupportedError,
      );
    });
  });
}
