import 'dart:async';

import 'package:cataqui_app/core/dtos/address_search_attribution_dto.dart';
import 'package:cataqui_app/core/dtos/address_search_response_dto.dart';
import 'package:cataqui_app/core/dtos/address_suggestion_dto.dart';
import 'package:cataqui_app/core/enums/address_category.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/repositories/geosearch_repository/geosearch_repository.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/description/create_job_description_route.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_route.dart';
import 'package:cataqui_app/views/create_job/payment/create_job_payment_route.dart';
import 'package:cataqui_app/views/create_job/payment/create_job_payment_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../utils/test_app.dart';
import 'create_job_test_state.dart';

abstract final class CreateJobViewTestHelpers {
  static const openButtonKey = ValueKey('open_create_job');
  static const addressSearchResponse = AddressSearchResponseDto(
    suggestions: <AddressSuggestionDto>[
      AddressSuggestionDto(
        addressId: 'address-id-123',
        fullText: 'Avenida Paulista, Bela Vista, São Paulo - SP, Brasil',
        primaryText: 'Avenida Paulista',
        category: AddressCategory.street,
        secondaryText: 'Bela Vista, São Paulo - SP, Brasil',
      ),
      AddressSuggestionDto(
        addressId: 'address-id-456',
        fullText: 'Rua Augusta, Consolação, São Paulo - SP, Brasil',
        primaryText: 'Rua Augusta',
        category: AddressCategory.street,
      ),
    ],
    attribution: AddressSearchAttributionDto(text: 'Google Maps'),
  );
  static const emptyAddressSearchResponse = AddressSearchResponseDto(
    suggestions: <AddressSuggestionDto>[],
    attribution: AddressSearchAttributionDto(text: 'Google Maps'),
  );

  static DioException createOfflineDioException() {
    return DioException(
      requestOptions: RequestOptions(path: '/v1/addresses/search'),
      type: DioExceptionType.connectionError,
      error: const OfflineConnectionDioException(message: 'No internet connection'),
    );
  }

  static Future<void> enterAddressQuery(WidgetTester tester, {required String query, bool settle = true}) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(const Duration(milliseconds: 301));
    if (settle) await tester.pumpAndSettle();
  }

  static Future<void> precachePaymentImages(WidgetTester tester) async {
    await tester.runAsync(
      () => CreateJobPaymentView.precacheImages(
        tester.element(find.byKey(const ValueKey('create_job_description_view'))),
      ),
    );
    await tester.pump();
  }

  static Future<void> openPayment(WidgetTester tester, {bool settle = true}) async {
    unawaited(
      const CreateJobPaymentRoute(
        jobId: 'draft-job-id',
      ).push<void>(tester.element(find.byKey(const ValueKey('create_job_description_view')))),
    );
    if (!settle) return;

    await tester.pumpAndSettle();
  }

  static Future<void> pumpPayment(
    WidgetTester tester, {
    Size screenSize = const Size(390, 844),
    double keyboardInset = 0,
    bool disableAnimations = true,
    CreateJobData initialCreateJobData = const CreateJobData(currencyCode: 'BRL'),
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = screenSize
      ..padding = FakeViewPadding(top: 47, bottom: keyboardInset > 0 ? 0 : 34)
      ..viewPadding = const FakeViewPadding(top: 47, bottom: 34)
      ..viewInsets = FakeViewPadding(bottom: keyboardInset);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      TestApp.screen(
        mediaQueryData: MediaQueryData(
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
          createJobStateProvider.overrideWith(() => CreateJobTestState(initialData: initialCreateJobData)),
        ],
        child: const CreateJobPaymentView(jobId: 'draft-job-id'),
      ),
    );
    await tester.runAsync(() => CreateJobPaymentView.precacheImages(tester.element(find.byType(CreateJobPaymentView))));
    await tester.pumpAndSettle();
  }

  static Future<void> pumpDescription(
    WidgetTester tester, {
    AssetBundle? assetBundle,
    DeviceLocation? deviceLocation,
    Key? repaintBoundaryKey,
    Size screenSize = const Size(390, 844),
    double keyboardInset = 0,
    bool disableAnimations = true,
    bool useViewMediaQuery = false,
    CreateJobData? initialCreateJobData,
    GeosearchRepository? geosearchRepository,
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
        deviceLocation: deviceLocation,
        repaintBoundaryKey: repaintBoundaryKey,
        screenSize: screenSize,
        keyboardInset: keyboardInset,
        disableAnimations: disableAnimations,
        useViewMediaQuery: useViewMediaQuery,
        initialCreateJobData: initialCreateJobData,
        geosearchRepository: geosearchRepository,
        jobRepository: jobRepository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(openButtonKey));
    await tester.pumpAndSettle();
  }

  static Widget buildApp({
    AssetBundle? assetBundle,
    DeviceLocation? deviceLocation,
    Key? repaintBoundaryKey,
    Size screenSize = const Size(390, 844),
    double keyboardInset = 0,
    bool disableAnimations = true,
    bool useViewMediaQuery = false,
    CreateJobData? initialCreateJobData,
    GeosearchRepository? geosearchRepository,
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
        if (deviceLocation != null) deviceLocationProvider.overrideWithValue(deviceLocation),
        if (geosearchRepository != null) geosearchRepositoryProvider.overrideWithValue(geosearchRepository),
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
          $createJobLocationRoute,
          $createJobPaymentRoute,
        ],
      ),
    );

    final bundledApp = assetBundle == null ? app : DefaultAssetBundle(bundle: assetBundle, child: app);
    if (repaintBoundaryKey == null) return bundledApp;

    return RepaintBoundary(key: repaintBoundaryKey, child: bundledApp);
  }
}
