import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/widgets/job_location_map/job_location_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/test_app.dart';
import 'google_maps_test_renderer.dart';

class _JobLocationMapGoldenTestHelpers {
  _JobLocationMapGoldenTestHelpers._();

  static Widget buildMap() {
    return SizedBox(
      width: 390,
      height: 300,
      child: TestApp.screen(
        mediaQueryData: const MediaQueryData(size: Size(390, 300), textScaler: TextScaler.noScaling),
        child: Center(
          child: SizedBox(
            width: 320,
            height: 240,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: JobLocationMap(
                location: (latitude: -23.55052, longitude: -46.633308),
                areaDiameterInMeters: 1200,
                offset: const Offset(0, 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  group('JobLocationMap Golden Tests', () {
    group('resting state', () {
      late GoogleMapsTestRenderer renderer;

      setUp(() {
        renderer = GoogleMapsTestRenderer()..install();
      });

      tearDown(() {
        renderer.restore();
      });

      goldenTest(
        'when rendering an approximate job area, it should match the approved golden',
        fileName: 'job_location_map_resting',
        whilePerforming: (tester) async {
          await tester.pumpAndSettle();
          return null;
        },
        builder: _JobLocationMapGoldenTestHelpers.buildMap,
      );
    });

    group('loading state', () {
      late GoogleMapsTestRenderer renderer;

      setUp(() {
        renderer = GoogleMapsTestRenderer(renderMapSurface: false)..install();
      });

      tearDown(() {
        renderer.restore();
      });

      goldenTest(
        'when the native map is still rendering, it should match the approved loading golden',
        fileName: 'job_location_map_loading',
        whilePerforming: (tester) async {
          await tester.pumpAndSettle();
          return null;
        },
        builder: _JobLocationMapGoldenTestHelpers.buildMap,
      );
    });
  });
}
