import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/description/create_job_description_route.dart';
import 'package:cataqui_app/views/create_job/payment/create_job_payment_route.dart';
import 'package:cataqui_app/views/create_job/payment/create_job_payment_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../utils/test_app.dart';
import 'create_job_test_state.dart';

abstract final class CreateJobViewTestHelpers {
  static const openButtonKey = ValueKey('open_create_job');

  static Future<void> precachePaymentImages(WidgetTester tester) async {
    await tester.runAsync(
      () => CreateJobPaymentView.precacheImages(
        tester.element(find.byKey(const ValueKey('create_job_description_view'))),
      ),
    );
    await tester.pump();
  }

  static Future<void> pumpDescription(
    WidgetTester tester, {
    AssetBundle? assetBundle,
    Size screenSize = const Size(390, 844),
    double keyboardInset = 0,
    bool disableAnimations = true,
    bool useViewMediaQuery = false,
    CreateJobData? initialCreateJobData,
    JobRepository? jobRepository,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = screenSize
      ..padding = FakeViewPadding(top: 47, bottom: keyboardInset > 0 ? 0 : 34)
      ..viewPadding = const FakeViewPadding(top: 47, bottom: 34)
      ..viewInsets = FakeViewPadding(bottom: keyboardInset);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      buildApp(
        assetBundle: assetBundle,
        screenSize: screenSize,
        keyboardInset: keyboardInset,
        disableAnimations: disableAnimations,
        useViewMediaQuery: useViewMediaQuery,
        initialCreateJobData: initialCreateJobData,
        jobRepository: jobRepository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(openButtonKey));
    await tester.pumpAndSettle();
  }

  static Widget buildApp({
    AssetBundle? assetBundle,
    Size screenSize = const Size(390, 844),
    double keyboardInset = 0,
    bool disableAnimations = true,
    bool useViewMediaQuery = false,
    CreateJobData? initialCreateJobData,
    JobRepository? jobRepository,
  }) {
    final routeObserver = RouteObserver<ModalRoute<void>>();

    final app = TestApp.router(
      mediaQueryData: useViewMediaQuery
          ? null
          : MediaQueryData(
              size: screenSize,
              devicePixelRatio: 1,
              padding: EdgeInsets.only(top: 47, bottom: keyboardInset > 0 ? 0 : 34),
              viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
              viewInsets: EdgeInsets.only(bottom: keyboardInset),
              textScaler: TextScaler.noScaling,
              disableAnimations: disableAnimations,
            ),
      providerOverrides: [
        translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
        routeObserverProvider.overrideWithValue(routeObserver),
        if (jobRepository != null) jobRepositoryProvider.overrideWithValue(jobRepository),
        if (initialCreateJobData != null)
          createJobStateProvider.overrideWith(() => CreateJobTestState(initialData: initialCreateJobData)),
      ],
      routerConfig: GoRouter(
        observers: [routeObserver],
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              floatingActionButton: MateoFloatingActionButton(
                key: openButtonKey,
                semanticLabel: AppLocale.ptBr.buildSync().feed.jobCreationButtonSemanticLabel,
                onPressed: () => unawaited(const CreateJobDescriptionRoute().push(context)),
                iconBuilder: (state) =>
                    MateoIcon.plusSignal(width: state.iconSize, height: state.iconSize, color: state.foregroundColor),
              ),
            ),
          ),
          $createJobDescriptionRoute,
          $createJobPaymentRoute,
        ],
      ),
    );

    if (assetBundle == null) return app;

    return DefaultAssetBundle(bundle: assetBundle, child: app);
  }
}
