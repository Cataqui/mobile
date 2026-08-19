import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:cataqui_app/widgets/login_sheet/login_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../views/feed/feed_view_test_helpers.dart';

void main() {
  setUp(FeedViewTestHelpers.mockGoogleMapsPlatform);

  goldenTest(
    'when account access is required over the feed, it should match the approved login sheet',
    fileName: 'login_sheet',
    constraints: const BoxConstraints.tightFor(width: 390, height: 844),
    whilePerforming: (tester) async {
      await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(FeedView));
      unawaited(LoginSheet.show(context: tester.element(find.byType(FeedView))));
      await tester.pumpAndSettle();
      final keysImageFinder = find.descendant(of: find.byType(LoginSheet), matching: find.byType(Image));
      await tester.runAsync(() => LoginSheet.precacheImages(tester.element(keysImageFinder)));
      await tester.pumpAndSettle();

      return null;
    },
    builder: () {
      return FeedViewTestHelpers.buildFeedViewApp(
        feedState: FakeFeedState(initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataWithJobs(count: 3))),
        disableAnimations: true,
      );
    },
  );
}
