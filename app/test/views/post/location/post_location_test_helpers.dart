import 'package:cataqui_app/core/dtos/address_search_attribution_dto.dart';
import 'package:cataqui_app/core/dtos/address_search_response_dto.dart';
import 'package:cataqui_app/core/dtos/address_suggestion_dto.dart';
import 'package:cataqui_app/core/enums/address_category.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/post/post_data.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:cataqui_app/views/post/post_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../../mocks.dart';
import '../../../utils/test_app.dart';
import '../post_test_state.dart';

abstract final class PostLocationTestHelpers {
  static const firstSuggestion = AddressSuggestionDto(
    addressId: 'address-id-123',
    fullText: 'Avenida Paulista, Bela Vista, São Paulo - SP, Brasil',
    primaryText: 'Avenida Paulista',
    category: AddressCategory.street,
    secondaryText: 'Bela Vista, São Paulo - SP, Brasil',
  );
  static const secondSuggestion = AddressSuggestionDto(
    addressId: 'address-id-456',
    fullText: 'Rua Augusta, Consolação, São Paulo - SP, Brasil',
    primaryText: 'Rua Augusta',
    category: AddressCategory.street,
  );
  static const addressSearchResponse = AddressSearchResponseDto(
    suggestions: <AddressSuggestionDto>[firstSuggestion, secondSuggestion],
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
    await tester.enterText(find.byKey(const ValueKey('post_location_search_field')), query);
    await tester.pump(const Duration(milliseconds: 301));
    if (settle) await tester.pumpAndSettle();
  }

  static Future<void> openLocation(
    WidgetTester tester, {
    MockGeosearchRepository? geosearchRepository,
    Device? device,
    DeviceLocation? deviceLocation,
    PostData initialPostData = const PostData(),
    bool disableAnimations = true,
    double keyboardInset = 0,
    TargetPlatform? targetPlatform,
  }) async {
    await pumpPost(
      tester,
      geosearchRepository: geosearchRepository,
      device: device,
      deviceLocation: deviceLocation,
      initialPostData: initialPostData,
      disableAnimations: disableAnimations,
      keyboardInset: keyboardInset,
      targetPlatform: targetPlatform,
    );
    await tester.tap(find.byKey(const ValueKey('post_location_chip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  static Future<void> pumpPost(
    WidgetTester tester, {
    MockGeosearchRepository? geosearchRepository,
    Device? device,
    DeviceLocation? deviceLocation,
    PostData initialPostData = const PostData(),
    bool disableAnimations = true,
    double keyboardInset = 0,
    Widget child = const PostView(),
    TargetPlatform? targetPlatform,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844)
      ..padding = FakeViewPadding(top: 47, bottom: keyboardInset > 0 ? 0 : 34)
      ..viewPadding = const FakeViewPadding(top: 47, bottom: 34)
      ..viewInsets = FakeViewPadding(bottom: keyboardInset);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      TestApp.screen(
        targetPlatform: targetPlatform,
        mediaQueryData: MediaQueryData(
          size: const Size(390, 844),
          devicePixelRatio: 1,
          padding: EdgeInsets.only(top: 47, bottom: keyboardInset > 0 ? 0 : 34),
          viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
          textScaler: TextScaler.noScaling,
          disableAnimations: disableAnimations,
        ),
        providerOverrides: [
          translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
          postStateProvider.overrideWith(() => PostTestState(initialData: initialPostData)),
          if (device != null) deviceProvider.overrideWithValue(device),
          if (geosearchRepository != null) geosearchRepositoryProvider.overrideWithValue(geosearchRepository),
          if (deviceLocation != null) deviceLocationProvider.overrideWithValue(deviceLocation),
        ],
        child: child,
      ),
    );
    await tester.pumpAndSettle();
    if (device == null) return;

    final lookupContext = tester.element(find.byWidget(child));
    await ProviderScope.containerOf(lookupContext).read(deviceCornerRadiiProvider.notifier).preload(lookupContext);
    await tester.pump();
  }
}
