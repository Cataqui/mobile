import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import 'create_job_view_test_helpers.dart';

void main() {
  late MockJobRepository jobRepository;

  setUp(() {
    jobRepository = MockJobRepository();
    when(
      () => jobRepository.createDraft(description: any(named: 'description')),
    ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: JobDraftDto.fixture().copyWith(jobId: 'draft-job-id')));
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
        builder: () => CreateJobViewTestHelpers.buildApp(disableAnimations: false, jobRepository: jobRepository),
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
        builder: () => CreateJobViewTestHelpers.buildApp(disableAnimations: false, jobRepository: jobRepository),
      );

      goldenTest(
        'when job location settles, it should show the resting search and current-location guidance',
        fileName: 'create_job_location_settled',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          await _CreateJobLocationGoldenActions.openLocation(tester);
          return null;
        },
        builder: () => CreateJobViewTestHelpers.buildApp(disableAnimations: false, jobRepository: jobRepository),
      );

      goldenTest(
        'when a location query is entered, it should show the focused search presentation with a clear action',
        fileName: 'create_job_location_search_filled',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          await _CreateJobLocationGoldenActions.openLocation(tester);
          await tester.enterText(find.byType(TextField), 'Rua das Flores');
          await tester.pumpAndSettle();
          return null;
        },
        builder: () => CreateJobViewTestHelpers.buildApp(disableAnimations: false, jobRepository: jobRepository),
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
