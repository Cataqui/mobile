import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/address_search_response_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/post/post_data.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:cataqui_app/views/post/post_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';
import '../../../utils/test_app.dart';
import '../post_test_state.dart';
import 'post_location_test_helpers.dart';

void main() {
  late MockGeosearchRepository geosearchRepository;

  setUp(() {
    geosearchRepository = MockGeosearchRepository();
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) async => PostLocationTestHelpers.addressSearchResponse);
  });

  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
      goldenTest(
        'when location is halfway open, it should show the surface morph and scrim transition',
        fileName: 'post_location_overlay_open_midpoint',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('post_location_chip')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 175));

          return () async {
            await tester.pump(const Duration(milliseconds: 175));
          };
        },
        builder: () => _PostLocationViewGoldenTestHelpers.buildPostView(
          geosearchRepository: geosearchRepository,
          disableAnimations: false,
        ),
      );

      goldenTest(
        'when location settles, it should show the custom overlay controls',
        fileName: 'post_location_settled',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          await _PostLocationViewGoldenTestHelpers.openLocation(tester);
          return null;
        },
        builder: () => _PostLocationViewGoldenTestHelpers.buildPostView(
          geosearchRepository: geosearchRepository,
          disableAnimations: false,
        ),
      );

      goldenTest(
        'when the blank search is focused, it should show its focused control state',
        fileName: 'post_location_search_focused',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          await _PostLocationViewGoldenTestHelpers.openLocation(tester);
          tester.widget<MateoTextField>(find.byKey(const ValueKey('post_location_search_field'))).controller!.focus();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          return null;
        },
        builder: () => _PostLocationViewGoldenTestHelpers.buildPostView(
          geosearchRepository: geosearchRepository,
          disableAnimations: false,
        ),
      );

      goldenTest(
        'when address search succeeds, it should show the returned suggestions',
        fileName: 'post_location_search_filled',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          await _PostLocationViewGoldenTestHelpers.openLocation(tester);
          await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua das Flores');
          return null;
        },
        builder: () => _PostLocationViewGoldenTestHelpers.buildPostView(
          geosearchRepository: geosearchRepository,
          disableAnimations: false,
        ),
      );

      goldenTest(
        'when address search is loading, it should show result-shaped skeletons',
        fileName: 'post_location_search_loading',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          when(
            () => geosearchRepository.searchAddresses(
              query: any(named: 'query'),
              sessionToken: any(named: 'sessionToken'),
            ),
          ).thenAnswer((_) => Completer<AddressSearchResponseDto>().future);
          await _PostLocationViewGoldenTestHelpers.openLocation(tester);
          await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua das Flores', settle: false);
          return null;
        },
        builder: () => _PostLocationViewGoldenTestHelpers.buildPostView(geosearchRepository: geosearchRepository),
      );

      goldenTest(
        'when address search returns no suggestions, it should show the empty state',
        fileName: 'post_location_search_empty',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          when(
            () => geosearchRepository.searchAddresses(
              query: any(named: 'query'),
              sessionToken: any(named: 'sessionToken'),
            ),
          ).thenAnswer((_) async => PostLocationTestHelpers.emptyAddressSearchResponse);
          await _PostLocationViewGoldenTestHelpers.openLocation(tester);
          await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua das Flores');
          return null;
        },
        builder: () => _PostLocationViewGoldenTestHelpers.buildPostView(
          geosearchRepository: geosearchRepository,
          disableAnimations: false,
        ),
      );

      goldenTest(
        'when address search fails, it should show the generic error state',
        fileName: 'post_location_search_error',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          when(
            () => geosearchRepository.searchAddresses(
              query: any(named: 'query'),
              sessionToken: any(named: 'sessionToken'),
            ),
          ).thenThrow(StateError('Search failed'));
          await _PostLocationViewGoldenTestHelpers.openLocation(tester);
          await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua das Flores');
          return null;
        },
        builder: () => _PostLocationViewGoldenTestHelpers.buildPostView(
          geosearchRepository: geosearchRepository,
          disableAnimations: false,
        ),
      );

      goldenTest(
        'when address search fails offline, it should show the offline error state',
        fileName: 'post_location_search_offline_error',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          when(
            () => geosearchRepository.searchAddresses(
              query: any(named: 'query'),
              sessionToken: any(named: 'sessionToken'),
            ),
          ).thenThrow(PostLocationTestHelpers.createOfflineDioException());
          await _PostLocationViewGoldenTestHelpers.openLocation(tester);
          await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua das Flores');
          return null;
        },
        builder: () => _PostLocationViewGoldenTestHelpers.buildPostView(
          geosearchRepository: geosearchRepository,
          disableAnimations: false,
        ),
      );
    },
  );
}

abstract final class _PostLocationViewGoldenTestHelpers {
  static Future<void> openLocation(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('post_location_chip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
  }

  static Widget buildPostView({required MockGeosearchRepository geosearchRepository, bool disableAnimations = true}) {
    return SizedBox(
      width: 390,
      height: 844,
      child: TestApp.screen(
        mediaQueryData: MediaQueryData(size: const Size(390, 844), disableAnimations: disableAnimations),
        providerOverrides: [
          translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
          postStateProvider.overrideWith(() => PostTestState(initialData: const PostData())),
          geosearchRepositoryProvider.overrideWithValue(geosearchRepository),
        ],
        child: const PostView(),
      ),
    );
  }
}
