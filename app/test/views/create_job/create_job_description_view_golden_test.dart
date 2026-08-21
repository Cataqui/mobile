import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:flutter/widgets.dart';
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
    ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
  });

  group('CreateJobDescriptionView Golden Tests', () {
    goldenTest(
      'when the description surface opens with no description, it should keep the continue action hidden',
      fileName: 'create_job_view',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();

        return null;
      },
      builder: () => CreateJobViewTestHelpers.buildApp(jobRepository: jobRepository),
    );

    goldenTest(
      'when meaningful description text is entered, it should show the continue action',
      fileName: 'create_job_view_typed',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de ajuda');
        await tester.pumpAndSettle();

        return null;
      },
      builder: () => CreateJobViewTestHelpers.buildApp(jobRepository: jobRepository),
    );

    goldenTest(
      'when a long description scrolls beneath the heading, it should keep the heading visible',
      fileName: 'create_job_view_scrolled',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), List<String>.filled(30, 'Preciso de ajuda hoje').join('\n'));
        await tester.pumpAndSettle();
        await tester.drag(find.byKey(const ValueKey('create_job_prompt_text_area')), const Offset(0, -100));
        await tester.pumpAndSettle();

        return null;
      },
      builder: () => CreateJobViewTestHelpers.buildApp(jobRepository: jobRepository),
    );

    goldenTest(
      'when meaningful description text starts with motion enabled, it should pop the continue action into view',
      fileName: 'create_job_view_continue_mid_pop',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de ajuda');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        return null;
      },
      builder: () => CreateJobViewTestHelpers.buildApp(disableAnimations: false, jobRepository: jobRepository),
    );

    goldenTest(
      'when continuing with a short description, it should show the error toast above the description surface',
      fileName: 'create_job_view_description_too_short_toast',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), '123456789');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        return null;
      },
      builder: () => CreateJobViewTestHelpers.buildApp(jobRepository: jobRepository),
    );

    goldenTest(
      'when draft creation is pending, it should show the loading continue action',
      fileName: 'create_job_view_loading',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
        addTearDown(() {
          if (!response.isCompleted) response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
        });
        when(
          () => jobRepository.createDraft(description: any(named: 'description')),
        ).thenAnswer((_) => response.future);
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
        await tester.pump(const Duration(milliseconds: 100));

        return null;
      },
      builder: () => CreateJobViewTestHelpers.buildApp(jobRepository: jobRepository),
    );

    goldenTest(
      'when continuing with an oversized description, it should show the length error toast',
      fileName: 'create_job_view_description_too_long_toast',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), '${List<String>.filled(2000, 'aaaa ').join()}a');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        return null;
      },
      builder: () => CreateJobViewTestHelpers.buildApp(jobRepository: jobRepository),
    );

    goldenTest(
      'when draft creation fails, it should show the request error toast and restore the continue action',
      fileName: 'create_job_view_create_draft_error',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        when(
          () => jobRepository.createDraft(description: any(named: 'description')),
        ).thenThrow(Exception('request failed'));
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        return null;
      },
      builder: () => CreateJobViewTestHelpers.buildApp(jobRepository: jobRepository),
    );
  });
}
