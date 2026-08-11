import 'dart:async';

import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/onboarding/onboarding_route.dart';
import 'package:cataqui_app/views/onboarding/onboarding_view.dart';
import 'package:cataqui_app/views/poster_onboarding/poster_onboarding_route.dart';
import 'package:cataqui_app/views/poster_onboarding/poster_onboarding_view/poster_onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';

abstract final class OnboardingRouteTestHelpers {
  static GoRouter router() {
    return GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(key: ValueKey('onboarding_feed_destination')),
        ),
        $onboardingRoute,
        $posterOnboardingRoute,
      ],
    );
  }

  static Future<void> pumpRouter({
    required WidgetTester tester,
    required GoRouter goRouter,
    required bool disableAnimations,
    required MockSharedPreferencesAsync prefs,
  }) async {
    final secureStorage = MockFlutterSecureStorage();
    when(() => secureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    final providerContainer = ProviderContainer(
      overrides: [
        sharedPreferencesAsyncProvider.overrideWithValue(prefs),
        secureStorageProvider.overrideWithValue(secureStorage),
        translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
      ],
    );
    addTearDown(providerContainer.dispose);
    await providerContainer.read(appStorageStateProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providerContainer,
        child: TestApp.router(
          routerConfig: goRouter,
          mediaQueryData: MediaQueryData(disableAnimations: disableAnimations),
        ),
      ),
    );
    if (disableAnimations) {
      await tester.pumpAndSettle();
      return;
    }
    await tester.pump();
  }
}

void main() {
  late MockSharedPreferencesAsync prefs;

  setUp(() {
    prefs = MockSharedPreferencesAsync();
    when(() => prefs.getBool(any())).thenAnswer((_) async => false);
    when(() => prefs.setBool(any(), any())).thenAnswer((_) async {});
  });

  testWidgets('when opening the onboarding route, it should show the onboarding screen', (tester) async {
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: true,
      prefs: prefs,
    );

    expect(find.byType(OnboardingView), findsOneWidget);
  });

  testWidgets('when tapping post work, it should open poster onboarding', (tester) async {
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: true,
      prefs: prefs,
    );
    await tester.tap(find.byKey(const ValueKey('onboarding_post_job_button')));
    await tester.pumpAndSettle();

    expect(find.byType(PosterOnboardingView), findsOneWidget);
  });

  testWidgets('when poster onboarding covers onboarding, it should dispose the hidden onboarding screen', (
    tester,
  ) async {
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: true,
      prefs: prefs,
    );
    await tester.tap(find.byKey(const ValueKey('onboarding_post_job_button')));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingView, skipOffstage: false), findsNothing);
  });

  testWidgets('when returning from poster onboarding, it should show the original onboarding screen', (tester) async {
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: true,
      prefs: prefs,
    );
    await tester.tap(find.byKey(const ValueKey('onboarding_post_job_button')));
    await tester.pumpAndSettle();
    goRouter.pop();
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingView), findsOneWidget);
  });

  testWidgets('when tapping the poster onboarding back button, it should return to the original onboarding screen', (
    tester,
  ) async {
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: true,
      prefs: prefs,
    );
    await tester.tap(find.byKey(const ValueKey('onboarding_post_job_button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('poster_onboarding_back_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('poster_onboarding_back_button')));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingView), findsOneWidget);
  });

  testWidgets('when tapping post work, it should not mark onboarding as completed', (tester) async {
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: true,
      prefs: prefs,
    );
    await tester.tap(find.byKey(const ValueKey('onboarding_post_job_button')));
    await tester.pumpAndSettle();

    verifyNever(() => prefs.setBool('completed_onboarding', true));
  });

  testWidgets('when the intro is still playing, tapping the hidden view-jobs action should not leave onboarding', (
    tester,
  ) async {
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: false,
      prefs: prefs,
    );
    await tester.tap(find.byKey(const ValueKey('onboarding_view_jobs_button')), warnIfMissed: false);
    await tester.pump();

    expect(find.byType(OnboardingView), findsOneWidget);
  });

  testWidgets('when reduced motion is enabled, tapping view jobs should open the feed immediately', (tester) async {
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: true,
      prefs: prefs,
    );
    await tester.tap(find.byKey(const ValueKey('onboarding_view_jobs_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboarding_feed_destination')), findsOneWidget);
  });

  testWidgets('when the intro completes, tapping view jobs should replace onboarding with the feed', (tester) async {
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: false,
      prefs: prefs,
    );
    await tester.pump(const Duration(milliseconds: 2624));
    await tester.pump(const Duration(milliseconds: 576));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.tap(find.byKey(const ValueKey('onboarding_view_jobs_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboarding_feed_destination')), findsOneWidget);
  });

  testWidgets('when view jobs replaces onboarding, the feed should not keep a back destination', (tester) async {
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: true,
      prefs: prefs,
    );
    await tester.tap(find.byKey(const ValueKey('onboarding_view_jobs_button')));
    await tester.pumpAndSettle();

    expect(goRouter.canPop(), isFalse);
  });

  testWidgets('when tapping view jobs, it should persist onboarding completion before opening the feed', (
    tester,
  ) async {
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: true,
      prefs: prefs,
    );

    await tester.tap(find.byKey(const ValueKey('onboarding_view_jobs_button')));
    await tester.pumpAndSettle();

    verify(() => prefs.setBool('completed_onboarding', true)).called(1);
  });

  testWidgets('when tapping view jobs twice while completion is saving, it should persist only once', (tester) async {
    final pendingWrite = Completer<void>();
    when(() => prefs.setBool('completed_onboarding', true)).thenAnswer((_) => pendingWrite.future);
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: true,
      prefs: prefs,
    );

    await tester.tap(find.byKey(const ValueKey('onboarding_view_jobs_button')));
    await tester.tap(find.byKey(const ValueKey('onboarding_view_jobs_button')));

    verify(() => prefs.setBool('completed_onboarding', true)).called(1);
    pendingWrite.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('when saving onboarding completion fails, it should still open the feed', (tester) async {
    when(() => prefs.setBool('completed_onboarding', true)).thenThrow(StateError('storage unavailable'));
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (_) {};
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: true,
      prefs: prefs,
    );

    await tester.tap(find.byKey(const ValueKey('onboarding_view_jobs_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboarding_feed_destination')), findsOneWidget);
  });

  testWidgets('when saving onboarding completion fails, it should report the storage error', (tester) async {
    final storageError = StateError('storage unavailable');
    when(() => prefs.setBool('completed_onboarding', true)).thenThrow(storageError);
    final reportedErrors = <FlutterErrorDetails>[];
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = reportedErrors.add;
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    final goRouter = OnboardingRouteTestHelpers.router();
    addTearDown(goRouter.dispose);
    await OnboardingRouteTestHelpers.pumpRouter(
      tester: tester,
      goRouter: goRouter,
      disableAnimations: true,
      prefs: prefs,
    );

    await tester.tap(find.byKey(const ValueKey('onboarding_view_jobs_button')));
    await tester.pumpAndSettle();

    expect(reportedErrors.single.exception, same(storageError));
  });
}
