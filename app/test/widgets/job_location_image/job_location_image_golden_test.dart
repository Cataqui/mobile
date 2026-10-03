import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/widgets/job_location_image/job_location_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import '../../utils/static_map_cache_test_helpers.dart';
import '../../utils/test_app.dart';

void main() {
  late MockStaticMapCacheManager manager;
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    manager = StaticMapCacheTestHelpers.create();
  });
  for (final size in [const Size(320, 400), const Size(440, 600)]) {
    goldenTest(
      'when the map is loaded on a ${size.width.toInt()} wide phone, it should crop without distortion',
      fileName: 'job_location_image_loaded_${size.width.toInt()}',
      constraints: BoxConstraints.tight(size),
      builder: () => _JobLocationImageGoldenHelpers.build(manager),
      whilePerforming: (tester) async {
        await StaticMapCacheTestHelpers.loadImages(tester);
        await tester.pumpAndSettle();
        return null;
      },
    );
  }
  goldenTest(
    'when a map starts loading, it should show only the neutral background',
    fileName: 'job_location_image_loading',
    pumpBeforeTest: (tester) => tester.pump(),
    constraints: const BoxConstraints.tightFor(width: 320, height: 400),
    builder: () {
      when(
        () => manager.getFileStream(
          any(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
          withProgress: any(named: 'withProgress'),
        ),
      ).thenAnswer((_) => const Stream<FileResponse>.empty());
      return _JobLocationImageGoldenHelpers.build(manager);
    },
  );
  goldenTest(
    'when a map is slow, it should show the neutral bouncing ball',
    fileName: 'job_location_image_loading_delayed',
    constraints: const BoxConstraints.tightFor(width: 320, height: 400),
    pumpBeforeTest: (tester) async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 400));
    },
    builder: () {
      when(
        () => manager.getFileStream(
          any(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
          withProgress: any(named: 'withProgress'),
        ),
      ).thenAnswer((_) => const Stream<FileResponse>.empty());
      return _JobLocationImageGoldenHelpers.build(manager);
    },
  );
  goldenTest(
    'when a map fails, it should show a localized retry',
    fileName: 'job_location_image_error',
    constraints: const BoxConstraints.tightFor(width: 320, height: 400),
    builder: () {
      when(
        () => manager.getFileStream(
          any(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
          withProgress: any(named: 'withProgress'),
        ),
      ).thenAnswer((_) => Stream<FileResponse>.error(Exception('unavailable')));
      return _JobLocationImageGoldenHelpers.build(manager);
    },
  );
}

abstract final class _JobLocationImageGoldenHelpers {
  static Widget build(MockStaticMapCacheManager manager) => TestApp.screen(
    providerOverrides: [staticMapCacheManagerProvider.overrideWith((ref) => manager)],
    child: const SizedBox.expand(
      child: JobLocationImage(imageUrl: 'https://maps.cataqui.com/static/fixture', size: .pixels960x2560),
    ),
  );
}
