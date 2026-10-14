import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:cataqui_app/widgets/whatsapp_connection_sheet/whatsapp_connection_sheet.dart';
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/test_app.dart';
import '../../views/feed/feed_view_test_helpers.dart';

void main() {
  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
      goldenTest(
        'when WhatsApp connection is required over the feed, it should match the approved connection sheet',
        fileName: 'whatsapp_connection_sheet',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        pumpWidget: TestApp.pumpGolden,
        pumpBeforeTest: TestApp.settleGolden,
        whilePerforming: (tester) => withClock(Clock.fixed(DateTime(2025, 6, 15, 20)), () async {
          await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(FeedView));
          unawaited(WhatsappConnectionSheet.show(context: tester.element(find.byType(FeedView))));
          await tester.pumpAndSettle();
          final keysImageFinder = find.descendant(
            of: find.byType(WhatsappConnectionSheet),
            matching: find.byType(Image),
          );
          await tester.runAsync(() => WhatsappConnectionSheet.precacheImages(tester.element(keysImageFinder)));
          await tester.pumpAndSettle();

          return null;
        }),
        builder: () {
          return FeedViewTestHelpers.buildFeedViewApp(
            feedState: FakeFeedState(initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataWithJobs(count: 3))),
            disableAnimations: true,
          );
        },
      );
    },
  );
}
