import 'dart:async';

import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/core/enums/job_status.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/static_map/enums/static_map_size.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/me/my_post_card/my_post_card.dart';
import 'package:cataqui_app/widgets/job_location_image/job_location_image.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';
import '../../../utils/static_map_cache_test_helpers.dart';
import '../../../utils/test_app.dart';

void main() {
  late MockStaticMapCacheManager cacheManager;
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    cacheManager = StaticMapCacheTestHelpers.create();
  });
  for (final status in [JobStatus.active, JobStatus.archived]) {
    testWidgets('when a post is $status, it should announce its status', (tester) async {
      await _MyPostCardTestHelpers.pump(tester, UserJobSummaryDto.fixture().copyWith(status: status));
      final i18n = AppLocale.ptBr.buildSync().me.myPosts;
      expect(
        find.bySemanticsLabel(status == JobStatus.active ? i18n.activeStatus : i18n.inactiveStatus),
        findsOneWidget,
      );
    });
  }
  testWidgets('when a profile post renders, it should request the square map with its image permission', (
    tester,
  ) async {
    final job = UserJobSummaryDto.fixture();
    await _MyPostCardTestHelpers.pump(tester, job);
    final image = tester.widget<JobLocationImage>(find.byType(JobLocationImage));
    expect((image.imageUrl, image.size), (job.location.imageUrl, StaticMapSize.pixels960x960));
  });
  testWidgets('when a post moves, it should display the new ready image', (tester) async {
    final job = UserJobSummaryDto.fixture();
    await _MyPostCardTestHelpers.pump(tester, job);
    await _MyPostCardTestHelpers.pump(
      tester,
      job.copyWith(location: job.location.copyWith(imageUrl: 'https://imagedelivery.net/fixture/replaced/q80')),
    );
    expect(
      tester.widget<JobLocationImage>(find.byType(JobLocationImage)).imageUrl,
      'https://imagedelivery.net/fixture/replaced/q80',
    );
  });
  testWidgets('when a profile card loads, it should not create native map views', (tester) async {
    await _MyPostCardTestHelpers.pump(tester, UserJobSummaryDto.fixture());
    expect(find.byWidgetPredicate((widget) => widget is PlatformViewLink || widget is UiKitView), findsNothing);
  });
  testWidgets('when the full-card map loads, it should retain the stored square resolution', (tester) async {
    await _MyPostCardTestHelpers.pump(tester, UserJobSummaryDto.fixture(), cacheManager: cacheManager);
    await StaticMapCacheTestHelpers.loadImages(tester);
    final decodedDimensions = tester
        .widgetList<RawImage>(find.descendant(of: find.byType(JobLocationImage), matching: find.byType(RawImage)))
        .where((image) => image.image != null)
        .map((image) => (image.image!.width, image.image!.height))
        .toSet();
    expect(decodedDimensions, {(960, 960)});
  });
  testWidgets('when a profile post is loading, it should not request a map image', (tester) async {
    await tester.pumpWidget(const TestApp.screen(child: SizedBox(width: 390, child: MyPostCard.skeleton())));
    await tester.pump();
    expect(find.byType(JobLocationImage), findsNothing);
  });
  for (final width in [280.0, 320.0]) {
    testWidgets(
      'when the full-card map fails on a ${width.toInt()} wide card, it should let the user retry without opening the post',
      (tester) async {
        final semantics = tester.ensureSemantics();
        when(
          () => cacheManager.getFileStream(
            any(),
            key: any(named: 'key'),
            headers: any(named: 'headers'),
            withProgress: any(named: 'withProgress'),
          ),
        ).thenAnswer((_) => Stream<FileResponse>.error(Exception('unavailable')));
        await _MyPostCardTestHelpers.pump(
          tester,
          UserJobSummaryDto.fixture().copyWith(
            title: 'Montar e desmontar estruturas para festa',
            descriptionSummary:
                'Precisamos de ajuda para organizar os móveis e montar as estruturas durante uma festa no bairro.',
          ),
          cacheManager: cacheManager,
          width: width,
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.bySemanticsLabel(AppLocale.ptBr.buildSync().jobLocationImage.retry));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        verify(
          () => cacheManager.getFileStream(
            any(),
            key: any(named: 'key'),
            headers: any(named: 'headers'),
            withProgress: any(named: 'withProgress'),
          ),
        ).called(2);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}

abstract final class _MyPostCardTestHelpers {
  static Future<void> pump(
    WidgetTester tester,
    UserJobSummaryDto job, {
    MockStaticMapCacheManager? cacheManager,
    double width = 390,
  }) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () async {
      await tester.pumpWidget(
        TestApp.screen(
          providerOverrides: [
            if (cacheManager != null) staticMapCacheManagerProvider.overrideWith((ref) => cacheManager),
          ],
          child: Center(
            child: SizedBox(
              width: width,
              child: MyPostCard(job: job.copyWith(createdAt: DateTime.utc(2026, 9, 23, 12))),
            ),
          ),
        ),
      );
      // The active-status indicator intentionally repeats its animation.
      await tester.pump(const Duration(milliseconds: 300));
    });
  }
}
