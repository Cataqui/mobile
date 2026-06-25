import 'package:cataqui_app/app.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'views/feed/feed_view_test_helpers.dart';

class _CataquiAppTestHelpers {
  _CataquiAppTestHelpers._();

  static Future<void> pumpCataquiApp(WidgetTester tester) async {
    FeedViewTestHelpers.mockHapticFeedback(tester);
    FeedViewTestHelpers.mockPlatformViews(tester);
    FeedViewTestHelpers.mockMapChannels();

    final fakeFeedState = FakeFeedState(initialAsyncValue: const AsyncValue.data(FeedData(jobs: [], hasMore: false)));

    await tester.pumpWidget(
      ProviderScope(overrides: [feedStateProvider.overrideWith(() => fakeFeedState)], child: const CataquiApp()),
    );
  }
}

void main() {
  group('CataquiApp', () {
    group('system chrome', () {
      testWidgets('when built, it should set the status bar color to transparent', (tester) async {
        await _CataquiAppTestHelpers.pumpCataquiApp(tester);

        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.ancestor(of: find.byType(MaterialApp), matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)),
        );

        expect(region.value.statusBarColor, Colors.transparent);
      });

      testWidgets('when built, it should use dark status bar icons', (tester) async {
        await _CataquiAppTestHelpers.pumpCataquiApp(tester);

        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.ancestor(of: find.byType(MaterialApp), matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)),
        );

        expect(region.value.statusBarIconBrightness, Brightness.dark);
      });

      testWidgets('when built, it should set iOS status bar brightness to light', (tester) async {
        await _CataquiAppTestHelpers.pumpCataquiApp(tester);

        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.ancestor(of: find.byType(MaterialApp), matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)),
        );

        expect(region.value.statusBarBrightness, Brightness.light);
      });

      testWidgets('when built, it should set the navigation bar color to transparent', (tester) async {
        await _CataquiAppTestHelpers.pumpCataquiApp(tester);

        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.ancestor(of: find.byType(MaterialApp), matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)),
        );

        expect(region.value.systemNavigationBarColor, Colors.transparent);
      });

      testWidgets('when built, it should set the navigation bar divider color to transparent', (tester) async {
        await _CataquiAppTestHelpers.pumpCataquiApp(tester);

        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.ancestor(of: find.byType(MaterialApp), matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)),
        );

        expect(region.value.systemNavigationBarDividerColor, Colors.transparent);
      });

      testWidgets('when built, it should set the systemNavigationBarContrastEnforced to false', (tester) async {
        await _CataquiAppTestHelpers.pumpCataquiApp(tester);

        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.ancestor(of: find.byType(MaterialApp), matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)),
        );

        expect(region.value.systemNavigationBarContrastEnforced, false);
      });

      testWidgets('when built, it should use dark navigation bar icons', (tester) async {
        await _CataquiAppTestHelpers.pumpCataquiApp(tester);

        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.ancestor(of: find.byType(MaterialApp), matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)),
        );

        expect(region.value.systemNavigationBarIconBrightness, Brightness.dark);
      });
    });
  });
}
