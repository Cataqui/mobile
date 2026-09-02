import 'package:cataqui_app/core/enums/address_category.dart';
import 'package:cataqui_app/widgets/job_location_map/job_location_map_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

void main() {
  group('JobLocationMapColorScheme', () {
    test('when resolving light brightness, it should use the configured background and location overlay', () {
      final palette = MateoPalette();
      final colorScheme = JobLocationMapColorScheme.fromBrightness(brightness: Brightness.light, palette: palette);

      expect(
        (
          background: colorScheme.background,
          allGeometry: colorScheme.all.geometry,
          locationRadius: colorScheme.locationRadius,
        ),
        (background: palette.neutral[2], allGeometry: null, locationRadius: palette.green[9].withValues(alpha: 0.12)),
      );
    });

    test('when resolving configured POI icon colors, it should reuse the matching address category colors', () {
      final palette = MateoPalette();
      final colorScheme = JobLocationMapColorScheme.light(palette: palette);

      expect(
        (
          other: colorScheme.pointOfInterest.labelsIcon,
          attraction: colorScheme.pointOfInterestAttraction.labelsIcon,
          business: colorScheme.pointOfInterestBusiness.labelsIcon,
          government: colorScheme.pointOfInterestGovernment.labelsIcon,
          medical: colorScheme.pointOfInterestMedical.labelsIcon,
          park: colorScheme.pointOfInterestPark.labelsIcon,
          placeOfWorship: colorScheme.pointOfInterestPlaceOfWorship.labelsIcon,
          school: colorScheme.pointOfInterestSchool.labelsIcon,
          sportsComplex: colorScheme.pointOfInterestSportsComplex.labelsIcon,
        ),
        (
          other: null,
          attraction: null,
          business: null,
          government: null,
          medical: null,
          park: AddressCategory.park.color(palette: palette),
          placeOfWorship: null,
          school: null,
          sportsComplex: null,
        ),
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
