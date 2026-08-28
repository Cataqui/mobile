import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/address_search_response_dto.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/core/enums/address_category.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import 'create_job_view_test_helpers.dart';

void main() {
  late MockJobRepository jobRepository;
  late MockGeosearchRepository geosearchRepository;

  setUp(() {
    jobRepository = MockJobRepository();
    geosearchRepository = MockGeosearchRepository();
    when(
      () => jobRepository.createDraft(description: any(named: 'description')),
    ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: JobDraftDto.fixture().copyWith(jobId: 'draft-job-id')));
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) async => CreateJobViewTestHelpers.addressSearchResponse);
  });

  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
      goldenTest(
        'when job location is halfway open, it should morph the description surface and navigation button',
        fileName: 'create_job_location_morph_midpoint',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          await _CreateJobLocationGoldenActions.openDescription(tester);
          _CreateJobLocationGoldenActions.pushLocation(tester);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          return () async {
            await tester.pumpAndSettle();
          };
        },
        builder: () => CreateJobViewTestHelpers.buildApp(
          disableAnimations: false,
          geosearchRepository: geosearchRepository,
          jobRepository: jobRepository,
        ),
      );

      goldenTest(
        'when job location is halfway closed, it should keep the description header above the morphing surface',
        fileName: 'create_job_description_morph_midpoint',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          await _CreateJobLocationGoldenActions.openLocation(tester);
          await tester.tap(find.byKey(const ValueKey('create_job_location_back_button')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          return () async {
            await tester.pumpAndSettle();
          };
        },
        builder: () => CreateJobViewTestHelpers.buildApp(
          disableAnimations: false,
          geosearchRepository: geosearchRepository,
          jobRepository: jobRepository,
        ),
      );

      goldenTest(
        'when job location settles, it should show the resting search and current-location guidance',
        fileName: 'create_job_location_settled',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          await _CreateJobLocationGoldenActions.openLocation(tester);
          return null;
        },
        builder: () => CreateJobViewTestHelpers.buildApp(
          disableAnimations: false,
          geosearchRepository: geosearchRepository,
          jobRepository: jobRepository,
        ),
      );

      goldenTest(
        'when the blank location search is focused, it should hide the current-location guidance',
        fileName: 'create_job_location_search_focused',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          await _CreateJobLocationGoldenActions.openLocation(tester);
          await tester.tap(find.byKey(const ValueKey('create_job_location_search_field')));
          await tester.pumpAndSettle();
          return null;
        },
        builder: () => CreateJobViewTestHelpers.buildApp(
          disableAnimations: false,
          geosearchRepository: geosearchRepository,
          jobRepository: jobRepository,
        ),
      );

      goldenTest(
        'when address search succeeds, it should show the returned suggestions',
        fileName: 'create_job_location_search_filled',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          when(
            () => geosearchRepository.searchAddresses(
              query: any(named: 'query'),
              sessionToken: any(named: 'sessionToken'),
            ),
          ).thenAnswer(
            (_) async => CreateJobViewTestHelpers.addressSearchResponse.copyWith(
              suggestions: [
                CreateJobViewTestHelpers.addressSearchResponse.suggestions.first.copyWith(
                  category: AddressCategory.restaurant,
                ),
                CreateJobViewTestHelpers.addressSearchResponse.suggestions.last.copyWith(
                  category: AddressCategory.park,
                ),
              ],
            ),
          );
          await _CreateJobLocationGoldenActions.openLocation(tester);
          await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua das Flores');
          return null;
        },
        builder: () => CreateJobViewTestHelpers.buildApp(
          disableAnimations: false,
          geosearchRepository: geosearchRepository,
          jobRepository: jobRepository,
        ),
      );

      goldenTest(
        'when address search is loading, it should show result-shaped skeletons',
        fileName: 'create_job_location_search_loading',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          when(
            () => geosearchRepository.searchAddresses(
              query: any(named: 'query'),
              sessionToken: any(named: 'sessionToken'),
            ),
          ).thenAnswer((_) => Completer<AddressSearchResponseDto>().future);
          await _CreateJobLocationGoldenActions.openLocation(tester);
          await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua das Flores', settle: false);
          return null;
        },
        builder: () => CreateJobViewTestHelpers.buildApp(
          disableAnimations: false,
          geosearchRepository: geosearchRepository,
          jobRepository: jobRepository,
        ),
      );

      goldenTest(
        'when address loading succeeds, it should fade halfway into the returned suggestions',
        fileName: 'create_job_location_search_fade_midpoint',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          final response = Completer<AddressSearchResponseDto>();
          when(
            () => geosearchRepository.searchAddresses(
              query: any(named: 'query'),
              sessionToken: any(named: 'sessionToken'),
            ),
          ).thenAnswer((_) => response.future);
          await _CreateJobLocationGoldenActions.openLocation(tester);
          await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua das Flores', settle: false);
          response.complete(CreateJobViewTestHelpers.addressSearchResponse);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          return () async {
            await tester.pumpAndSettle();
          };
        },
        builder: () => CreateJobViewTestHelpers.buildApp(
          disableAnimations: false,
          geosearchRepository: geosearchRepository,
          jobRepository: jobRepository,
        ),
      );

      goldenTest(
        'when address search returns no suggestions, it should show the empty message',
        fileName: 'create_job_location_search_empty',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          when(
            () => geosearchRepository.searchAddresses(
              query: any(named: 'query'),
              sessionToken: any(named: 'sessionToken'),
            ),
          ).thenAnswer((_) async => CreateJobViewTestHelpers.emptyAddressSearchResponse);
          await _CreateJobLocationGoldenActions.openLocation(tester);
          await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua das Flores');
          return null;
        },
        builder: () => CreateJobViewTestHelpers.buildApp(
          disableAnimations: false,
          geosearchRepository: geosearchRepository,
          jobRepository: jobRepository,
        ),
      );

      goldenTest(
        'when address search fails, it should show the error message',
        fileName: 'create_job_location_search_error',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          when(
            () => geosearchRepository.searchAddresses(
              query: any(named: 'query'),
              sessionToken: any(named: 'sessionToken'),
            ),
          ).thenThrow(Exception('Search failed'));
          await _CreateJobLocationGoldenActions.openLocation(tester);
          await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua das Flores');
          return null;
        },
        builder: () => CreateJobViewTestHelpers.buildApp(
          disableAnimations: false,
          geosearchRepository: geosearchRepository,
          jobRepository: jobRepository,
        ),
      );

      goldenTest(
        'when address search fails offline, it should show the offline message',
        fileName: 'create_job_location_search_offline_error',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          when(
            () => geosearchRepository.searchAddresses(
              query: any(named: 'query'),
              sessionToken: any(named: 'sessionToken'),
            ),
          ).thenThrow(CreateJobViewTestHelpers.createOfflineDioException());
          await _CreateJobLocationGoldenActions.openLocation(tester);
          await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua das Flores');
          return null;
        },
        builder: () => CreateJobViewTestHelpers.buildApp(
          disableAnimations: false,
          geosearchRepository: geosearchRepository,
          jobRepository: jobRepository,
        ),
      );
    },
  );
}

abstract final class _CreateJobLocationGoldenActions {
  static Future<void> openDescription(WidgetTester tester) async {
    await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Preciso de uma pessoa para descarregar caixas.');
    await tester.pumpAndSettle();
  }

  static Future<void> openLocation(WidgetTester tester) async {
    await openDescription(tester);
    pushLocation(tester);
    await tester.pumpAndSettle();
  }

  static void pushLocation(WidgetTester tester) {
    unawaited(
      const CreateJobLocationRoute(
        jobId: 'draft-job-id',
      ).push<void>(tester.element(find.byKey(const ValueKey('create_job_description_view')))),
    );
  }
}
