import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cataqui_app/core/providers.dart';
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
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    cacheManager = StaticMapCacheTestHelpers.create();
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
  testWidgets('when a map arrives asynchronously, it should fade in over 300 milliseconds', (tester) async {
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager);
    await StaticMapCacheTestHelpers.loadImages(tester);
    final fade = find.descendant(of: find.byType(CachedNetworkImage), matching: find.byType(FadeTransition));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<FadeTransition>(fade.first).opacity.value, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<FadeTransition>(fade.first).opacity.value, 1);
  });
  testWidgets('when reduced motion is enabled, it should disable the image fade', (tester) async {
    await _JobLocationImageTestHelpers.pump(tester, cacheManager: cacheManager, disableAnimations: true);
    expect(tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage)).fadeInDuration, Duration.zero);
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
            width: 300,
            height: 400,
            child: JobLocationImage(
              imageUrl: 'https://maps.cataqui.com/static/fixture-$latitude',
              size: .pixels960x2560,
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
