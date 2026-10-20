import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/static_map/enums/static_map_size.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/job_location_image/enums/job_location_image_feedback_state.dart';
import 'package:cataqui_app/widgets/job_location_image/job_location_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../mocks.dart';
import '../../utils/static_map_cache_test_helpers.dart';
import '../../utils/test_app.dart';

void main() {
  late MockStaticMapCacheManager cacheManager;
  late MockStaticMapFile corruptFile;
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    cacheManager = StaticMapCacheTestHelpers.create(usePortrait: true);
    corruptFile = MockStaticMapFile();
    when(corruptFile.readAsBytes).thenAnswer((_) async => Uint8List.fromList([0, 1, 2, 3]));
  });
  testWidgets(
    'when a phone has high display density, it should request the square preset independently of display density',
    (tester) async {
      await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(
        (image.imageUrl, image.cacheKey),
        (
          'https://maps.cataqui.com/static/v1/fixture_reference_-23_0.webp?size=480x480',
          'https://maps.cataqui.com/static/v1/fixture_reference_-23_0.webp?size=480x480',
        ),
      );
    },
  );
  testWidgets('when a caller requests the tall size, it should request the tall preset', (tester) async {
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, size: .tall);
    expect(
      tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage)).imageUrl,
      'https://maps.cataqui.com/static/v1/fixture_reference_-23_0.webp?size=480x1280',
    );
  });

  for (final size in StaticMapSize.values) {
    testWidgets('when a ${size.value} map is cropped, it should display only the required OpenStreetMap credit', (
      tester,
    ) async {
      await _JobLocationImageTestHelpers.pump(
        tester,
        cacheManager: cacheManager,
        size: size,
        width: 222,
        height: 277.5,
      );
      await StaticMapCacheTestHelpers.loadImages(tester);
      await tester.pumpAndSettle();
      expect(
        (
          find.text('© OpenStreetMap').evaluate().length,
          find.text('Protomaps').evaluate().length,
          find.textContaining('Geoapify').evaluate().length,
        ),
        (1, 0, 0),
      );
    });
  }
  for (final imageUrl in [
    'https://maps.cataqui.com/static/v1/fixture_reference.webp?size=480x1280',
    'https://maps.cataqui.com/static/v1/fixture_reference.webp#map',
    'https://maps.cataqui.com/static/legacy',
  ]) {
    testWidgets('when a map reference is invalid ($imageUrl), it should show retry without a network request', (
      tester,
    ) async {
      await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, imageUrl: imageUrl);
      expect(
        (
          find.byKey(const ValueKey(JobLocationImageFeedbackState.error)).evaluate().length,
          find.byType(CachedNetworkImage).evaluate().length,
        ),
        (1, 0),
      );
    });
  }
  testWidgets('when an invalid map reference is retried, it should leave the image cache alone', (tester) async {
    await _JobLocationImageTestHelpers.pump(
      tester,
      cacheManager: cacheManager,
      imageUrl: 'https://maps.cataqui.com/static/legacy',
    );
    await tester.tap(find.bySemanticsLabel(AppLocale.ptBr.buildSync().jobLocationImage.retry));
    await tester.pumpAndSettle();
    verifyNever(() => cacheManager.removeFile(any()));
  });
  testWidgets('when a visible map changes size, it should reset loading feedback and request the selected preset', (
    tester,
  ) async {
    when(
      () => cacheManager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) => const Stream<FileResponse>.empty());
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, settle: false);
    await tester.pump(const Duration(seconds: 1));
    await _JobLocationImageTestHelpers.pump(
      tester,
      cacheManager: cacheManager,
      width: 360,
      height: 540,
      size: .tall,
      settle: false,
    );
    expect(
      (
        tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage)).imageUrl,
        find.byType(Motion).evaluate().length,
      ),
      ('https://maps.cataqui.com/static/v1/fixture_reference_-23_0.webp?size=480x1280', 0),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('when a map is slow, it should delay the bouncing ball for one second and clear it when disabled', (
    tester,
  ) async {
    when(
      () => cacheManager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) => const Stream<FileResponse>.empty());
    final semantics = tester.ensureSemantics();
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, settle: false);
    await tester.pump(const Duration(milliseconds: 999));
    expect(find.byType(Motion), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(Motion), findsOneWidget);
    final bounce = tester.widget<Motion>(find.byType(Motion)).effect! as MoveMotionEffect;
    expect(bounce.playback, MotionPlayback.loop);
    expect([bounce.curve.transform(0), bounce.curve.transform(0.5), bounce.curve.transform(1)], [0, 1, 0]);
    await tester.pump(const Duration(milliseconds: 280));
    expect(find.bySemanticsLabel(AppLocale.ptBr.buildSync().jobLocationImage.loading), findsOneWidget);
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, enabled: false, settle: false);
    expect(find.byType(Motion), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
  testWidgets('when the request changes, it should restart the feedback delay', (tester) async {
    when(
      () => cacheManager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) => const Stream<FileResponse>.empty());
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, settle: false);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(Motion), findsOneWidget);
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, latitude: -24, settle: false);
    expect(find.byType(Motion), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(Motion), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('when a decoded map is reused, it should appear immediately without feedback', (tester) async {
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
    await StaticMapCacheTestHelpers.loadImages(tester);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, settle: false);
    expect(find.byType(Motion), findsNothing);
    expect(tester.widgetList<RawImage>(find.byType(RawImage)).any((image) => image.image != null), isTrue);
  });
  testWidgets('when a map loads, it should expose one labeled image to assistive technology', (tester) async {
    final semantics = tester.ensureSemantics();
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
    await StaticMapCacheTestHelpers.loadImages(tester);
    await tester.pumpAndSettle();
    final imageNode = tester.getSemantics(
      find.bySemanticsLabel(AppLocale.ptBr.buildSync().jobLocationImage.semanticLabel),
    );
    var imageCount = imageNode.getSemanticsData().flagsCollection.isImage ? 1 : 0;
    imageNode.visitChildren((node) {
      if (node.getSemanticsData().flagsCollection.isImage) imageCount++;
      return true;
    });
    expect((imageNode.getSemanticsData().flagsCollection.isImage, imageCount), (true, 1));
    semantics.dispose();
  });

  testWidgets('when a map arrives asynchronously, it should be fully visible on its first ready frame', (tester) async {
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
    await StaticMapCacheTestHelpers.loadImages(tester);
    final fade = find.descendant(of: find.byType(CachedNetworkImage), matching: find.byType(FadeTransition));
    expect(tester.widget<FadeTransition>(fade.first).opacity.value, 1);
  });
  testWidgets('when reduced motion is enabled, it should disable the image fade', (tester) async {
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, disableAnimations: true);
    expect(tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage)).fadeInDuration, Duration.zero);
  });
  testWidgets('when normal motion is enabled, it should show and replace map pixels without an image fade', (
    tester,
  ) async {
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
    final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect((image.fadeInDuration, image.fadeOutDuration), (Duration.zero, Duration.zero));
  });
  testWidgets('when an image loads, it should fetch the public image without authentication', (tester) async {
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
    expect(tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage)).httpHeaders, isNull);
  });
  testWidgets('when display density is high, it should leave decode dimensions unrestricted', (tester) async {
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
    final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect((image.memCacheWidth, image.memCacheHeight), (null, null));
  });
  testWidgets('when a map finishes loading, it should decode the stored portrait resolution', (tester) async {
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
    await StaticMapCacheTestHelpers.loadImages(tester);
    final decodedDimensions = tester
        .widgetList<RawImage>(find.descendant(of: find.byType(CachedNetworkImage), matching: find.byType(RawImage)))
        .where((image) => image.image != null)
        .map((image) => (image.image!.width, image.image!.height))
        .toSet();
    expect(decodedDimensions, {(960, 2560)});
  });
  testWidgets('when a map fails before feedback appears, it should retry with the same ready URL', (tester) async {
    final semantics = tester.ensureSemantics();
    when(
      () => cacheManager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) => Stream<FileResponse>.error(Exception('provider failure')));
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
    await tester.tap(find.bySemanticsLabel(AppLocale.ptBr.buildSync().jobLocationImage.retry));
    await tester.pumpAndSettle();
    verify(
      () => cacheManager.getFileStream(any(), key: any(named: 'key'), headers: null, withProgress: true),
    ).called(2);
    semantics.dispose();
  });
  testWidgets('when fresh cached map bytes cannot decode, retry should replace only that image and show the map', (
    tester,
  ) async {
    const mapKey = 'https://maps.cataqui.com/static/v1/fixture_reference_-23_0.webp?size=480x480';
    const otherMapKey = 'another cached map';
    final replacementFile = await cacheManager.getSingleFile(mapKey);
    final cachedKeys = {mapKey, otherMapKey};
    final removedKeys = <String>[];
    when(() => cacheManager.removeFile(any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments.single as String;
      removedKeys.add(key);
      cachedKeys.remove(key);
    });
    when(
      () => cacheManager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer(
      (_) => Stream<FileResponse>.value(
        FileInfo(
          cachedKeys.contains(mapKey) ? corruptFile : replacementFile,
          cachedKeys.contains(mapKey) ? FileSource.Cache : FileSource.Online,
          DateTime.utc(2100),
          mapKey,
        ),
      ),
    );
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
    await _JobLocationImageTestHelpers.waitForDecode(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(AppLocale.ptBr.buildSync().jobLocationImage.retry));
    await tester.pump();
    await _JobLocationImageTestHelpers.waitForDecode(tester, stopOnError: false);
    await tester.pumpAndSettle();
    expect(
      [
        removedKeys,
        tester.widgetList<RawImage>(find.byType(RawImage)).any((image) => image.image != null),
        cachedKeys.contains(otherMapKey),
      ],
      [
        [mapKey],
        true,
        true,
      ],
    );
  });
  group('retry while removing a failed cached map', () {
    late Completer<void> removal;
    late List<String> requestedKeys;
    late List<String> removedKeys;
    setUp(() {
      requestedKeys = [];
      removedKeys = [];
      when(() => cacheManager.removeFile(any())).thenAnswer((invocation) {
        removedKeys.add(invocation.positionalArguments.single as String);
        return removal.future;
      });
      when(
        () => cacheManager.getFileStream(
          any(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
          withProgress: any(named: 'withProgress'),
        ),
      ).thenAnswer((invocation) {
        requestedKeys.add(invocation.namedArguments[#key]! as String);
        return Stream<FileResponse>.error(Exception('map unavailable'));
      });
    });
    testWidgets('when retry is tapped twice before removal finishes, it should reload the same map once', (
      tester,
    ) async {
      removal = Completer<void>();
      await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
      final retry = find.bySemanticsLabel(AppLocale.ptBr.buildSync().jobLocationImage.retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      removal.complete();
      await tester.pumpAndSettle();
      expect((removedKeys.length, requestedKeys.length, requestedKeys.first == requestedKeys.last), (1, 2, true));
    });
    testWidgets('when the map closes during cache removal, it should finish without updating a disposed widget', (
      tester,
    ) async {
      removal = Completer<void>();
      await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
      await tester.tap(find.bySemanticsLabel(AppLocale.ptBr.buildSync().jobLocationImage.retry));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      removal.complete();
      await tester.pumpAndSettle();
      expect((tester.takeException(), removedKeys.length, requestedKeys.length), (null, 1, 1));
    });
    testWidgets('when the viewport changes during cache removal, it should leave the newly requested map alone', (
      tester,
    ) async {
      removal = Completer<void>();
      await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
      await tester.tap(find.bySemanticsLabel(AppLocale.ptBr.buildSync().jobLocationImage.retry));
      await tester.pumpAndSettle();
      await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, width: 360, height: 540, size: .tall);
      final newImageKey = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage)).key;
      removal.complete();
      await tester.pumpAndSettle();
      expect(
        (
          requestedKeys.length,
          removedKeys.single == requestedKeys.first,
          tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage)).key == newImageKey,
        ),
        (2, true, true),
      );
    });
    testWidgets('when the map is disabled during cache removal, it should finish without another image request', (
      tester,
    ) async {
      removal = Completer<void>();
      await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
      await tester.tap(find.bySemanticsLabel(AppLocale.ptBr.buildSync().jobLocationImage.retry));
      await tester.pumpAndSettle();
      await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, enabled: false);
      removal.complete();
      await tester.pumpAndSettle();
      expect((tester.takeException(), removedKeys.length, requestedKeys.length), (null, 1, 1));
    });
    testWidgets('when cache removal fails, it should keep retry available and allow a later successful attempt', (
      tester,
    ) async {
      removal = Completer<void>();
      await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
      final retry = find.bySemanticsLabel(AppLocale.ptBr.buildSync().jobLocationImage.retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      removal.completeError(Exception('cache file cannot be removed'));
      await tester.pumpAndSettle();
      removal = Completer<void>();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      removal.complete();
      await tester.pumpAndSettle();
      expect(
        (tester.takeException(), removedKeys.length, requestedKeys.length, retry.evaluate().length),
        (null, 2, 2, 1),
      );
    });
  });
  testWidgets('when a map fails, it should keep the map description and retry as separate accessible elements', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    when(
      () => cacheManager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) => Stream<FileResponse>.error(Exception('provider failure')));
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
    final i18n = AppLocale.ptBr.buildSync().jobLocationImage;
    expect(
      (
        find.bySemanticsLabel(i18n.semanticLabel).evaluate().length,
        find.bySemanticsLabel(i18n.retry).evaluate().length,
      ),
      (1, 1),
    );
    semantics.dispose();
  });

  testWidgets('when a slow map fails, loading and retry should scale and fade in sequence at the same position', (
    tester,
  ) async {
    final responses = StreamController<FileResponse>.broadcast();
    addTearDown(responses.close);
    when(
      () => cacheManager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) => responses.stream);
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, settle: false);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 280));
    final loading = find.byKey(const ValueKey(JobLocationImageFeedbackState.loading));
    final retry = find.byKey(const ValueKey(JobLocationImageFeedbackState.error));
    final loadingCenter = tester.getCenter(loading);
    responses.addError(Exception('map failed after loading'));
    await tester.pump();
    await tester.pump();
    expect(tester.getCenter(retry), loadingCenter);
    await tester.pump(const Duration(milliseconds: 70));
    expect(_JobLocationImageTestHelpers.opacity(tester, loading), inExclusiveRange(0, 1));
    expect(_JobLocationImageTestHelpers.opacity(tester, retry), 0);
    expect(_JobLocationImageTestHelpers.scale(tester, loading), inExclusiveRange(0.8, 1));
    await tester.pump(const Duration(milliseconds: 140));
    expect(_JobLocationImageTestHelpers.opacity(tester, loading), 0);
    expect(_JobLocationImageTestHelpers.opacity(tester, retry), inExclusiveRange(0, 1));
    expect(_JobLocationImageTestHelpers.scale(tester, retry), inExclusiveRange(0.8, 1));
    await tester.pump(const Duration(milliseconds: 90));
    expect(loading, findsNothing);
    expect(_JobLocationImageTestHelpers.opacity(tester, retry), 1);
    await tester.tap(retry);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    expect(_JobLocationImageTestHelpers.opacity(tester, retry), inExclusiveRange(0, 1));
    expect(_JobLocationImageTestHelpers.opacity(tester, loading), 0);
    await tester.pump(const Duration(milliseconds: 140));
    expect(_JobLocationImageTestHelpers.opacity(tester, retry), 0);
    expect(_JobLocationImageTestHelpers.opacity(tester, loading), inExclusiveRange(0, 1));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
  testWidgets('when a card is outside the active window, it should make no image request', (tester) async {
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, enabled: false);
    verifyNever(
      () => cacheManager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    );
  });
}

abstract final class _JobLocationImageTestHelpers {
  static Future<void> waitForDecode(WidgetTester tester, {bool stopOnError = true}) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1)));
      await tester.pump(const Duration(milliseconds: 20));
      if ((stopOnError && find.byKey(const ValueKey(JobLocationImageFeedbackState.error)).evaluate().isNotEmpty) ||
          tester.widgetList<RawImage>(find.byType(RawImage)).any((image) => image.image != null)) {
        return;
      }
    }
  }

  static double opacity(WidgetTester tester, Finder feedback) =>
      tester.widget<FadeTransition>(find.ancestor(of: feedback, matching: find.byType(FadeTransition))).opacity.value;

  static double scale(WidgetTester tester, Finder feedback) =>
      tester.widget<ScaleTransition>(find.ancestor(of: feedback, matching: find.byType(ScaleTransition))).scale.value;

  static Future<void> pump(
    WidgetTester tester, {
    required MockStaticMapCacheManager cacheManager,
    bool enabled = true,
    bool settle = true,
    bool disableAnimations = false,
    double latitude = -23,
    double width = 300,
    double height = 400,
    String? imageUrl,
    StaticMapSize size = .square,
  }) async {
    await tester.pumpWidget(
      TestApp.screen(
        mediaQueryData: MediaQueryData(
          size: const Size(390, 780),
          devicePixelRatio: 3,
          disableAnimations: disableAnimations,
        ),
        providerOverrides: [staticMapCacheManagerProvider.overrideWith((ref) => cacheManager)],
        child: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: JobLocationImage(
              imageUrl:
                  imageUrl ??
                  'https://maps.cataqui.com/static/v1/fixture_reference_${latitude.toString().replaceAll('.', '_')}.webp',
              size: size,
              enabled: enabled,
            ),
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
    if (!settle) await tester.pump();
  }
}
