import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/views/job/job_view.dart';
import 'package:cataqui_app/views/post/post_data.dart';
import 'package:cataqui_app/views/post/post_route.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:cataqui_app/views/post/post_view.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:cataqui_app/widgets/offline_error_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';
import '../post/post_test_state.dart';
import 'feed_view_test_helpers.dart';

void main() {
  late Translations i18n;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
  });

  group('FeedView', () {
    group('published post return', () {
      late MockJobRepository jobRepository;

      setUp(() {
        jobRepository = MockJobRepository();
        when(
          () => jobRepository.createJob(
            description: 'Preciso de ajuda para descarregar caixas.',
            latitude: -23.561684,
            longitude: -46.655981,
            contactMethod: .whatsapp,
            contactIdentifier: '+5511999999999',
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenAnswer(
          (_) async => ApiEnvelopeDto.fixture(
            data: JobDto.fixture().copyWith(jobId: 'new-post', title: 'Meu trampo'),
          ),
        );
      });

      Future<void> publishToFeed(WidgetTester tester, {bool startFromSecondJob = false}) async {
        await FeedViewTestHelpers.pumpFeedRoute(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 2)),
          settle: false,
          providerOverrides: [
            jobRepositoryProvider.overrideWithValue(jobRepository),
            postStateProvider.overrideWith(
              () => PostTestState(
                initialData: const PostData(
                  descriptionText: 'Preciso de ajuda para descarregar caixas.',
                  contact: (contactMethod: JobContactMethod.whatsapp, identifier: '+5511999999999'),
                  location: (latitude: -23.561684, longitude: -46.655981),
                  locationTitle: 'Pinheiros',
                ),
              ),
            ),
          ],
        );

        if (startFromSecondJob) {
          final feedController = tester.widget<SnapList>(find.byType(SnapList)).controller!;
          unawaited(feedController.next());
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(feedController.index, 1);
        }

        await tester.tap(find.byKey(const ValueKey('feed_job_creation_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('post_publish_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();
        expect(find.byType(FeedView), findsOneWidget);
        expect(find.byType(MateoToast), findsNothing);
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();
      }

      testWidgets('Publish returns to Feed with the new job first and a five-second pointer toast', (tester) async {
        await publishToFeed(tester);
        await tester.pump(const Duration(milliseconds: 199));
        expect(find.byType(MateoToast), findsNothing);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();

        expect(find.byType(PostView), findsNothing);
        expect(find.byType(FeedView), findsOneWidget);
        final toast = tester.widget<MateoToast>(find.byType(MateoToast));
        expect(toast.status, MateoToastStatus.neutral);
        expect(toast.message, i18n.feed.recentlyPosted.toastMessage);
        expect(tester.widget<FeedJobCard>(find.byType(FeedJobCard).first).feedJob.jobId, 'new-post');
        expect(find.byKey(const ValueKey('post_published_pointer')), findsOneWidget);
        await tester.pump(const Duration(seconds: 4));
        expect(find.byType(MateoToast), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(MateoToast), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('Publish returns to the first card after starting from a later job', (tester) async {
        await publishToFeed(tester, startFromSecondJob: true);

        final feedController = tester.widget<SnapList>(find.byType(SnapList)).controller!;
        expect(feedController.index, 0);
        expect(tester.widget<FeedJobCard>(find.byType(FeedJobCard).first).feedJob.jobId, 'new-post');
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('the published post toast leaves when another route opens', (tester) async {
        await publishToFeed(tester);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();
        expect(find.byType(MateoToast), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('feed_job_creation_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.byType(PostView), findsOneWidget);
        expect(find.byType(MateoToast), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('the published post toast leaves when the next job is selected', (tester) async {
        await publishToFeed(tester);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();
        expect(find.byType(MateoToast), findsOneWidget);

        await FeedViewTestHelpers.swipeAwayCurrentJob(tester, title: 'Meu trampo');
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        expect(tester.widget<SnapList>(find.byType(SnapList)).controller!.index, 1);
        expect(find.byType(MateoToast), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('moving to the next job during the wait prevents the toast', (tester) async {
        await publishToFeed(tester);
        await FeedViewTestHelpers.swipeAwayCurrentJob(tester, title: 'Meu trampo');
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.widget<SnapList>(find.byType(SnapList)).controller!.index, 1);
        expect(find.byType(MateoToast), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('leaving Feed during the wait prevents the toast', (tester) async {
        await publishToFeed(tester);
        final router = GoRouter.of(tester.element(find.byType(FeedView)));
        unawaited(router.push<void>(const PostRoute().location));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        expect(find.byType(PostView), findsOneWidget);
        expect(find.byType(MateoToast), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    testWidgets('FeedRoute shows the MateoToast supplied by its caller', (tester) async {
      await FeedViewTestHelpers.pumpFeedRoute(
        tester: tester,
        feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 2)),
        settle: false,
      );

      const FeedRoute(
        $extra: (toast: MateoToast(message: 'Aviso temporário', status: .info)),
      ).go(tester.element(find.byType(FeedView)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      final toast = tester.widget<MateoToast>(find.byType(MateoToast));
      expect(toast.status, MateoToastStatus.info);
      expect(toast.message, 'Aviso temporário');
      await tester.pump(const Duration(seconds: 4));
      expect(find.byType(MateoToast), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(MateoToast), findsNothing);
      await FeedViewTestHelpers.pumpAndCleanUp(tester);
    });

    group('chrome', () {
      testWidgets('when the view renders in any state, it should show the current city button', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.text(i18n.feed.locationAvailability.cityLabel), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the current city button renders, it should provide a 48 pixel touch target', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );

        expect(
          tester
              .getSize(
                find.byWidgetPredicate(
                  (widget) => widget is MateoButton && widget.presentation.variant == MateoButtonVariant.tertiary,
                ),
              )
              .height,
          greaterThanOrEqualTo(48),
        );
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the current city button is tapped, it should explain where Cataquí is available', (
        tester,
      ) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.tap(find.text(i18n.feed.locationAvailability.cityLabel));
        await tester.pumpAndSettle();

        expect(find.text(i18n.feed.locationAvailability.message), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the availability message is open and the close button is tapped, it should close the message', (
        tester,
      ) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.tap(find.text(i18n.feed.locationAvailability.cityLabel));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(MateoSheetViewHeader), matching: find.byType(MateoButton)));
        await tester.pumpAndSettle();

        expect(find.text(i18n.feed.locationAvailability.message), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the view renders in any state, it should not show the search bar', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.text(i18n.feed.searchPlaceholder), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the job creation button renders, it should provide a 48 pixel touch target', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        final tapTargetFinder = find.descendant(
          of: find.byKey(const ValueKey('feed_job_creation_button')),
          matching: find.byType(MateoPress),
        );

        expect(tester.getSize(tapTargetFinder).height, greaterThanOrEqualTo(48));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the job creation button renders, it should describe the create-job action', (tester) async {
        final semantics = tester.ensureSemantics();
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );

        try {
          expect(find.bySemanticsLabel(i18n.feed.jobCreationButtonSemanticLabel), findsOneWidget);
        } finally {
          semantics.dispose();
        }
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when tapped, the job creation button should open the post flow', (tester) async {
        await FeedViewTestHelpers.pumpFeedRoute(tester: tester);
        await tester.tap(find.byKey(const ValueKey('feed_job_creation_button')));
        await tester.pumpAndSettle();

        expect(find.byType(PostView), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when tapped twice, the job creation button should open only one post route', (tester) async {
        await FeedViewTestHelpers.pumpFeedRoute(tester: tester);
        final jobCreationButton = tester.widget<MateoButton>(find.byKey(const ValueKey('feed_job_creation_button')));
        jobCreationButton.onPressed?.call();
        jobCreationButton.onPressed?.call();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('post_close_button')));
        await tester.pumpAndSettle();

        expect(find.byType(FeedView), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when post is opened and closed twice, the job creation button should open it a third time', (
        tester,
      ) async {
        await FeedViewTestHelpers.pumpFeedRoute(tester: tester);

        for (var cycle = 0; cycle < 2; cycle += 1) {
          await tester.tap(find.byKey(const ValueKey('feed_job_creation_button')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('post_close_button')));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(const ValueKey('feed_job_creation_button')));
        await tester.pumpAndSettle();

        expect(find.byType(PostView), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the job creation keyboard opens, it should keep the underlying feed viewport unchanged', (
        tester,
      ) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        final view = find.descendant(of: find.byType(FeedView), matching: find.byType(MateoView));
        final originalRect = tester.getRect(view);
        addTearDown(tester.view.resetViewInsets);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(tester.getRect(view), originalRect);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when post covers an active feed snap, it should return with the feed settled', (tester) async {
        await FeedViewTestHelpers.pumpFeedRoute(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          settle: false,
        );
        final controller = tester.widget<SnapList>(find.byType(SnapList)).controller!;
        bool? completed;
        unawaited(controller.next().then((value) => completed = value));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        await tester.tap(find.byKey(const ValueKey('feed_job_creation_button')));
        await tester.pumpAndSettle();
        addTearDown(tester.view.resetViewInsets);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('post_close_button')));
        final returningPositions = <double?>[];
        for (var frame = 0; frame < 25; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          returningPositions.add(controller.position);
        }
        await tester.pump();

        expect(
          (
            controller.position,
            controller.index,
            controller.isMoving,
            completed,
            returningPositions.every((position) => position == 1),
          ),
          (1, 1, false, true, true),
        );
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('initial loading', () {
      testWidgets('when feedState is loading, it should render the skeleton FeedJobCard', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
        );
        expect(find.byType(FeedJobCard), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is loading, it should not render error title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
        );
        expect(find.text(i18n.feed.error.title), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is loading, it should not render empty title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
        );
        expect(find.text(i18n.feed.empty.title), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('initial error', () {
      testWidgets('when feedState is error, it should render the error title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
        );
        await tester.pump();
        expect(find.text(i18n.feed.error.title), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is error, it should render the error description', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
        );
        await tester.pump();
        expect(find.text(i18n.feed.error.description), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is error, it should render the retry button', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
        );
        await tester.pump();
        expect(find.text(i18n.feed.error.retryButtonTitle), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is error, it should not render skeleton loading', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
        );
        await tester.pump();
        expect(find.byType(Skeleton), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is error, it should not render empty title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
        );
        await tester.pump();
        expect(find.text(i18n.feed.empty.title), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('initial offline error', () {
      testWidgets('when initial error is offline, it should render the OfflineErrorState', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(
            initialAsyncValue: AsyncError(FeedViewTestHelpers.offlineDioException(), StackTrace.current),
          ),
        );
        await tester.pump();
        expect(find.byType(OfflineErrorState), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when initial error is offline, it should render the offline title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(
            initialAsyncValue: AsyncError(FeedViewTestHelpers.offlineDioException(), StackTrace.current),
          ),
        );
        await tester.pump();
        expect(find.text(i18n.feed.offline.title), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when initial error is offline, it should render the offline description', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(
            initialAsyncValue: AsyncError(FeedViewTestHelpers.offlineDioException(), StackTrace.current),
          ),
        );
        await tester.pump();
        expect(find.text(i18n.feed.offline.description), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when initial error is offline, it should render the offline retry button', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(
            initialAsyncValue: AsyncError(FeedViewTestHelpers.offlineDioException(), StackTrace.current),
          ),
        );
        await tester.pump();
        expect(find.text(i18n.feed.offline.retryButtonTitle), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when initial error is offline, it should not render the generic error title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(
            initialAsyncValue: AsyncError(FeedViewTestHelpers.offlineDioException(), StackTrace.current),
          ),
        );
        await tester.pump();
        expect(find.text(i18n.feed.error.title), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('data — empty', () {
      testWidgets('when the empty state fits the body, it should remain vertically centered below the header', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );

        final contentFinder = find.ancestor(of: find.text(i18n.feed.empty.title), matching: find.byType(Column));

        expect(
          tester.getCenter(contentFinder).dy,
          closeTo(tester.getCenter(find.byType(SingleChildScrollView).last).dy + 20, 0.01),
        );
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the empty state fits in the feed viewport, it should have no scroll extent', (tester) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );

        final scrollableState = tester.state<ScrollableState>(
          find.descendant(of: find.byType(SingleChildScrollView).last, matching: find.byType(Scrollable)),
        );

        expect(scrollableState.position.maxScrollExtent, 0);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the empty state fits in the feed viewport, dragging it should not move the content', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        final titleFinder = find.text(i18n.feed.empty.title);
        final topBeforeDrag = tester.getTopLeft(titleFinder).dy;

        await tester.drag(titleFinder, const Offset(0, -100));
        await tester.pumpAndSettle();

        expect(tester.getTopLeft(titleFinder).dy, topBeforeDrag);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the empty state does not fit in the feed viewport, it should become scrollable', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );

        final scrollableState = tester.state<ScrollableState>(
          find.descendant(of: find.byType(SingleChildScrollView).last, matching: find.byType(Scrollable)),
        );

        expect(scrollableState.position.maxScrollExtent, greaterThan(0));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when scrolling a compact empty state to the end, it should keep the action in the viewport', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        final scrollableState = tester.state<ScrollableState>(
          find.descendant(of: find.byType(SingleChildScrollView).last, matching: find.byType(Scrollable)),
        );

        scrollableState.position.jumpTo(scrollableState.position.maxScrollExtent);
        await tester.pumpAndSettle();

        final viewportBottom = tester.getBottomRight(find.byType(MateoView)).dy;
        final buttonBottom = tester.getBottomRight(find.byKey(const ValueKey('feed_empty_adjust_area_button'))).dy;
        expect(buttonBottom, lessThan(viewportBottom));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData is empty, it should render the empty title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.text(i18n.feed.empty.title), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData is empty, it should render the empty description', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.text(i18n.feed.empty.description), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData is empty, it should render the adjust area button', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.text(i18n.feed.empty.adjustAreaButtonTitle), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the adjust area button is tapped, it should explain where Cataquí is available', (
        tester,
      ) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.byKey(const ValueKey('feed_empty_adjust_area_button')));
        await tester.pumpAndSettle();

        expect(find.text(i18n.feed.locationAvailability.message), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData is empty, it should not render SnapList', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.byWidgetPredicate((w) => w is SnapList), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('data — with jobs', () {
      testWidgets('a recently published first job uses the full feed card area', (tester) async {
        final feedData = FeedViewTestHelpers.feedDataWithJobs(count: 2);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => feedData),
          hasSeenSwipeFeedHint: false,
          toast: MateoToast(message: i18n.feed.recentlyPosted.toastMessage, status: .neutral),
        );

        expect(find.text(i18n.feed.swipeUpHint.caption), findsNothing);
        expect(find.byKey(const ValueKey('feed_recently_posted_pointer')), findsNothing);
        expect(tester.widget<FeedJobCard>(find.byType(FeedJobCard).first).feedJob.jobId, 'job_0');
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData has jobs, it should render SnapList', (tester) async {
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => true);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );
        await tester.pump();
        expect(find.byWidgetPredicate((w) => w is SnapList), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData has jobs, it should rest after the intrinsic header without clipping motion', (
        tester,
      ) async {
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => true);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );

        final listFinder = find.byType(SnapList);
        final cityButtonFinder = find.byWidgetPredicate(
          (widget) => widget is MateoButton && widget.presentation.variant == MateoButtonVariant.tertiary,
        );
        final restingTop = tester.getTopLeft(listFinder).dy;
        expect(restingTop, tester.getBottomLeft(cityButtonFinder).dy + 10);

        final gesture = await tester.startGesture(tester.getCenter(listFinder));
        await gesture.moveBy(const Offset(0, -100));
        await tester.pump();

        expect(tester.getTopLeft(find.byType(FeedJobCard).first).dy, lessThan(restingTop));
        await gesture.up();
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData has jobs, it should render FeedJobCard for the current job', (tester) async {
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => true);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );
        await tester.pump();
        expect(find.text('Descarregar Caminhão'), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the visible job card tap action runs, it should navigate to that job detail', (tester) async {
        final goRouter = GoRouter(
          observers: [MateoNavigatorObserver()],
          initialLocation: const FeedRoute().location,
          routes: [$feedRoute, $jobRoute],
        );
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => true);
        FeedViewTestHelpers.mockHapticFeedback(tester);
        FeedViewTestHelpers.mockPlatformViews(tester);

        await tester.pumpWidget(
          TestApp.router(
            routerConfig: goRouter,
            providerOverrides: [
              feedStateProvider.overrideWith(
                () => FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
              ),
              sharedPreferencesAsyncProvider.overrideWithValue(prefs),
              goRouterProvider.overrideWithValue(goRouter),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pump();
        final feedJobCard = find.byType(FeedJobCard).first;
        final tapAnimation = tester.widget<MateoPress>(
          find.descendant(of: feedJobCard, matching: find.byType(MateoPress)),
        );
        await tapAnimation.onPressed!(Future<void>.value());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(find.byType(JobView), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feed cards are built, it should key them by jobId', (tester) async {
        final feedData = FeedViewTestHelpers.feedDataWithJobs(count: 3);
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => true);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => feedData),
          prefs: prefs,
        );
        await tester.pump();

        final feed = tester.widget<SnapList>(find.byType(SnapList));
        expect(feed.itemBuilder!(tester.element(find.byType(SnapList)), 0).key, ValueKey(feedData.jobs.first.jobId));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when loading more jobs fails, it should center the retry state in the reveal below the last card', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataWithPaginationError),
        );

        await FeedViewTestHelpers.swipeAwayCurrentJob(tester);

        final contentFinder = find.ancestor(
          of: find.text(i18n.feed.loadingMore.error.title),
          matching: find.byType(Column),
        );
        final feedFinder = find.byType(SnapList);
        final feedRect = tester.getRect(feedFinder);
        final lastCardBottom = tester
            .getBottomLeft(
              find.byKey(ValueKey(FeedViewTestHelpers.feedDataWithPaginationError().jobs.single.jobId)).last,
            )
            .dy;
        expect(lastCardBottom, greaterThan(feedRect.top));
        expect(tester.getTopLeft(contentFinder).dy - lastCardBottom, closeTo(100, 0.01));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      for (final loading in [false, true]) {
        testWidgets(
          'when revealing the ${loading ? 'loading' : 'end'} state, it should center within the reveal below the last card',
          (tester) async {
            tester.view.physicalSize = const Size(390, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final data = loading
                ? FeedViewTestHelpers.feedDataWithLoadingMore()
                : FeedViewTestHelpers.feedDataWithPaginationEnd();
            await FeedViewTestHelpers.pumpFeedView(
              tester: tester,
              feedState: FakeFeedState(buildResult: () => data),
            );
            await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
            final viewport = tester.getRect(find.byType(SnapList));
            final lastCardBottom = tester.getBottomLeft(find.byKey(ValueKey(data.jobs.single.jobId)).last).dy;
            final content = loading
                ? find.descendant(of: find.byType(SnapList), matching: find.byType(MateoLoadingIndicator)).first
                : find.ancestor(of: find.text(i18n.feed.empty.title), matching: find.byType(Column));
            expect(lastCardBottom, greaterThan(viewport.top));
            expect(tester.getTopLeft(content).dy - lastCardBottom, closeTo(loading ? 50 : 100, 0.01));
            await FeedViewTestHelpers.pumpAndCleanUp(tester);
          },
        );
      }

      testWidgets('when dragging down from a compact end state, it should return to the previous job', (tester) async {
        tester.view.physicalSize = const Size(390, 400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataWithPaginationEnd),
        );
        await FeedViewTestHelpers.swipeAwayCurrentJob(tester);

        final scrollableState = tester.state<ScrollableState>(
          find.descendant(of: find.byType(SingleChildScrollView).last, matching: find.byType(Scrollable)),
        );
        scrollableState.position.jumpTo(scrollableState.position.minScrollExtent);
        await tester.pump();

        await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, 300));
        await tester.pumpAndSettle();

        final feed = tester.widget<SnapList>(find.byType(SnapList));
        expect((feed.controller!.index, feed.controller!.position), (0, 0));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when showing the terminal state, it should fill the body below the feed header', (tester) async {
        tester.view.physicalSize = const Size(390, 400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataWithPaginationEnd),
        );
        await FeedViewTestHelpers.swipeAwayCurrentJob(tester);

        final feedRect = tester.getRect(find.byType(SnapList));
        final terminalScrollRect = tester.getRect(find.byType(SingleChildScrollView).last);

        expect(feedRect.top, greaterThan(tester.getTopLeft(find.byType(MateoView)).dy));
        expect(terminalScrollRect, feedRect);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when an iOS terminal state has no scroll extent, dragging toward nothing should not bounce', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataWithPaginationEnd),
          scrollBehavior: const _AlwaysBouncingScrollBehavior(),
        );
        await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
        final titleFinder = find.text(i18n.feed.empty.title);
        final titleTop = tester.getTopLeft(titleFinder).dy;
        final scrollableState = tester.state<ScrollableState>(
          find.descendant(of: find.byType(SingleChildScrollView).last, matching: find.byType(Scrollable)),
        );
        final gesture = await tester.startGesture(tester.getCenter(titleFinder));

        expect(scrollableState.position.maxScrollExtent, scrollableState.position.minScrollExtent);
        await gesture.moveBy(const Offset(0, -100));
        await tester.pump();

        expect(tester.getTopLeft(titleFinder).dy, titleTop);
        await gesture.cancel();
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('when an iOS terminal state has no scroll extent, dragging down should return to the job', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataWithPaginationEnd),
          scrollBehavior: const _AlwaysBouncingScrollBehavior(),
        );
        await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
        final scrollableState = tester.state<ScrollableState>(
          find.descendant(of: find.byType(SingleChildScrollView).last, matching: find.byType(Scrollable)),
        );

        expect(scrollableState.position.maxScrollExtent, scrollableState.position.minScrollExtent);
        await tester.drag(find.text(i18n.feed.empty.title), const Offset(0, 300));
        await tester.pumpAndSettle();

        expect(find.byType(FeedJobCard), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('when dragging down from a compact pagination error, it should return to the previous job', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataWithPaginationError),
        );
        await FeedViewTestHelpers.swipeAwayCurrentJob(tester);

        final scrollableState = tester.state<ScrollableState>(
          find.descendant(of: find.byType(SingleChildScrollView).last, matching: find.byType(Scrollable)),
        );
        scrollableState.position.jumpTo(scrollableState.position.minScrollExtent);
        await tester.pump();

        await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, 300));
        await tester.pumpAndSettle();

        final feed = tester.widget<SnapList>(find.byType(SnapList));
        expect((feed.controller!.index, feed.controller!.position), (0, 0));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('feed state keys', () {
      // Each feed state must be wrapped in a KeyedSubtree with a unique key
      // so state changes are correctly detected. Without distinct keys,
      // Flutter would reuse the same element for same-type widgets
      // (e.g., Center→Center for loading→error).
      testWidgets(
        'when feedState is loading, it should wrap the loading widget in a KeyedSubtree with ValueKey feed_loading',
        (tester) async {
          await FeedViewTestHelpers.pumpFeedView(
            tester: tester,
            feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
          );
          expect(find.byKey(const ValueKey('feed_loading')), findsOneWidget);
          await FeedViewTestHelpers.pumpAndCleanUp(tester);
        },
      );

      testWidgets(
        'when feedState is error, it should wrap the error widget in a KeyedSubtree with ValueKey feed_error',
        (tester) async {
          await FeedViewTestHelpers.pumpFeedView(
            tester: tester,
            feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
          );
          await tester.pump();
          expect(find.byKey(const ValueKey('feed_error')), findsOneWidget);
          await FeedViewTestHelpers.pumpAndCleanUp(tester);
        },
      );

      testWidgets('when feedData is empty, it should wrap the empty widget in a KeyedSubtree with ValueKey feed_data', (
        tester,
      ) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        // Uses 'feed_data' (same as data with jobs) because empty IS data
        // — the FeedData state, not a separate loading/error state.
        // The empty and non-empty builders both return different root
        // widgets, so the shared key keeps the element tree stable.
        expect(find.byKey(const ValueKey('feed_data')), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData has jobs, it should wrap the data widget in a KeyedSubtree with ValueKey feed_data', (
        tester,
      ) async {
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => true);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );
        await tester.pump();
        // Same 'feed_data' key as the empty state — keeps the same entry
        // so empty→jobs is an in-place update, not a transition.
        expect(find.byKey(const ValueKey('feed_data')), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('swipe-up hint overlay', () {
      late MockSharedPreferencesAsync prefs;

      setUp(() {
        prefs = MockSharedPreferencesAsync();
        when(() => prefs.setBool(any(), any())).thenAnswer((_) async {});
      });

      testWidgets('when the user has not seen the hint, it should show the swipe-up hint overlay', (tester) async {
        when(() => prefs.getBool(any())).thenAnswer((_) async => false);

        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );

        await tester.pump();
        expect(find.text(i18n.feed.swipeUpHint.caption), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the user has not seen the hint, it should not show the overlay while the feed is loading', (
        tester,
      ) async {
        when(() => prefs.getBool(any())).thenAnswer((_) async => false);

        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
          prefs: prefs,
        );

        expect(find.text(i18n.feed.swipeUpHint.caption), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the feed has no jobs, it should not show the swipe-up hint overlay', (tester) async {
        when(() => prefs.getBool(any())).thenAnswer((_) async => false);

        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
          prefs: prefs,
        );
        await tester.pump();
        expect(find.text(i18n.feed.swipeUpHint.caption), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the user has already seen the hint, it should not show the overlay', (tester) async {
        when(() => prefs.getBool(any())).thenAnswer((_) async => true);

        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );
        await tester.pump();
        expect(find.text(i18n.feed.swipeUpHint.caption), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the only job is swiped, it should dismiss the hint and remember it after reopening', (
        tester,
      ) async {
        var hasSeenHint = false;
        when(() => prefs.getBool(any())).thenAnswer(
          (invocation) async => invocation.positionalArguments.single == 'seen_swipe_feed_hint' && hasSeenHint,
        );
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 1, hasMore: false)),
          prefs: prefs,
        );
        when(() => prefs.setBool('seen_swipe_feed_hint', true)).thenAnswer((_) async => hasSeenHint = true);
        expect(find.text(i18n.feed.swipeUpHint.caption), findsOneWidget);

        await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        expect(find.text(i18n.feed.swipeUpHint.caption), findsNothing);
        expect(hasSeenHint, isTrue);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);

        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 1, hasMore: false)),
          prefs: prefs,
        );
        expect(find.text(i18n.feed.swipeUpHint.caption), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets(
        'when the user swipes up past the first job, the overlay should disappear and the seen flag should be persisted',
        (tester) async {
          when(() => prefs.getBool(any())).thenAnswer((_) async => false);

          await FeedViewTestHelpers.pumpFeedView(
            tester: tester,
            feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
            prefs: prefs,
          );

          await tester.pump();
          expect(find.text(i18n.feed.swipeUpHint.caption), findsOneWidget);

          await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump();
          await tester.pump();

          verify(() => prefs.setBool('seen_swipe_feed_hint', true)).called(1);
          expect(find.text(i18n.feed.swipeUpHint.caption), findsNothing);
          await FeedViewTestHelpers.pumpAndCleanUp(tester);
        },
      );
    });

    group('map preparation', () {
      setUp(FeedViewTestHelpers.mockGoogleMapsPlatform);

      testWidgets('when the swipe-up hint is appearing, it should prepare the current and next job maps behind it', (
        tester,
      ) async {
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => false);

        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );

        // Let the hint appear animation start (post frame callback)
        await tester.pump();

        expect(find.byType(GoogleMap, skipOffstage: false), findsNWidgets(2));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the swipe-up hint finishes appearing, it should prepare the current and next job maps', (
        tester,
      ) async {
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => false);

        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );

        // Let the hint appear animation start
        await tester.pump();

        // Wait for the appear animation to finish and gate to release
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 900));

        // The current and next maps should now mount.
        expect(find.byType(GoogleMap, skipOffstage: false), findsNWidgets(2));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets(
        'when the user swipes before the hint finishes appearing, it should show the next job location map immediately',
        (tester) async {
          final prefs = MockSharedPreferencesAsync();
          when(() => prefs.getBool(any())).thenAnswer((_) async => false);

          await FeedViewTestHelpers.pumpFeedView(
            tester: tester,
            feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
            prefs: prefs,
          );

          // Let the hint appear animation start
          await tester.pump();

          // Swipe before appear animation completes
          await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
          await tester.pump();

          // Map should mount immediately (gate released by notification)
          expect(find.byType(GoogleMap, skipOffstage: false), findsAtLeastNWidgets(1));
          await FeedViewTestHelpers.pumpAndCleanUp(tester);
        },
      );
    });
  });
}

class _AlwaysBouncingScrollBehavior extends ScrollBehavior {
  const _AlwaysBouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
