import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/my_post_card/my_post_card.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';
import '../../../utils/static_map_cache_test_helpers.dart';
import '../../../utils/test_app.dart';

void main() {
  late MockStaticMapCacheManager manager;
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    manager = StaticMapCacheTestHelpers.create();
  });
  goldenTest(
    'when a profile post has a map, it should retain its details over the image',
    fileName: 'my_post_card_static_map',
    constraints: const BoxConstraints.tightFor(width: 320, height: 400),
    builder: () => TestApp.screen(
      mediaQueryData: const MediaQueryData(disableAnimations: true),
      child: TickerMode(
        enabled: false,
        child: MyPostCard(job: UserJobSummaryDto.fixture().copyWith(createdAt: DateTime.utc(2026, 9, 23, 12))),
      ),
    ),
    pumpWidget: (tester, widget) =>
        withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () => tester.pumpWidget(widget)),
    whilePerforming: (tester) async {
      await withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () async {
        await StaticMapCacheTestHelpers.loadImages(tester);
        await tester.pump(const Duration(milliseconds: 300));
      });
      return null;
    },
  );
  goldenTest(
    'when a profile map fails, it should keep the retry visible below the post details',
    fileName: 'my_post_card_map_error',
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
      return _MyPostCardGoldenHelpers.build(manager);
    },
    pumpWidget: _MyPostCardGoldenHelpers.pump,
  );
  goldenTest(
    'when a profile map takes one second, it should keep details available above the bouncing loader',
    fileName: 'my_post_card_map_loading',
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
      return _MyPostCardGoldenHelpers.build(manager);
    },
    pumpWidget: _MyPostCardGoldenHelpers.pump,
    pumpBeforeTest: (tester) async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    },
  );
  goldenTest(
    'when a profile post is loading, it should preserve the skeleton card',
    fileName: 'my_post_card_skeleton',
    constraints: const BoxConstraints.tightFor(width: 320, height: 400),
    builder: () => const TestApp.screen(child: TickerMode(enabled: false, child: MyPostCard.skeleton())),
  );
  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(
      ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false, diffThreshold: 0),
    ),
    run: () {
      goldenTest(
        'when a narrow card has a long title and description, it should keep its details legible over the full map',
        fileName: 'my_post_card_long_header_static_map',
        constraints: const BoxConstraints.tightFor(width: 280, height: 350),
        builder: () => _MyPostCardGoldenHelpers.build(manager, job: _MyPostCardGoldenHelpers.longHeaderJob),
        pumpWidget: _MyPostCardGoldenHelpers.pump,
        whilePerforming: (tester) async {
          await StaticMapCacheTestHelpers.loadImages(tester);
          await tester.pumpAndSettle();
          return null;
        },
      );
      goldenTest(
        'when a narrow card with a long header fails to load its map, it should leave the retry icon uncovered',
        fileName: 'my_post_card_long_header_map_error',
        constraints: const BoxConstraints.tightFor(width: 280, height: 350),
        builder: () {
          when(
            () => manager.getFileStream(
              any(),
              key: any(named: 'key'),
              headers: any(named: 'headers'),
              withProgress: any(named: 'withProgress'),
            ),
          ).thenAnswer((_) => Stream<FileResponse>.error(Exception('unavailable')));
          return _MyPostCardGoldenHelpers.build(manager, job: _MyPostCardGoldenHelpers.longHeaderJob);
        },
        pumpWidget: _MyPostCardGoldenHelpers.pump,
      );
    },
  );
}

abstract final class _MyPostCardGoldenHelpers {
  static UserJobSummaryDto get longHeaderJob => UserJobSummaryDto.fixture().copyWith(
    title: 'Montar e desmontar estruturas para festa',
    descriptionSummary:
        'Precisamos de ajuda para organizar os móveis e montar as estruturas durante uma festa no bairro.',
  );

  static Widget build(MockStaticMapCacheManager manager, {UserJobSummaryDto? job}) => TestApp.screen(
    mediaQueryData: const MediaQueryData(disableAnimations: true),
    providerOverrides: [staticMapCacheManagerProvider.overrideWith((ref) => manager)],
    child: TickerMode(
      enabled: false,
      child: MyPostCard(job: (job ?? UserJobSummaryDto.fixture()).copyWith(createdAt: DateTime.utc(2026, 9, 23, 12))),
    ),
  );

  static Future<void> pump(WidgetTester tester, Widget widget) =>
      withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () => tester.pumpWidget(widget));
}
