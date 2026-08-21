import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/description/create_job_description_view.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_route.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../mocks.dart';
import 'create_job_view_test_helpers.dart';

void main() {
  late MockJobRepository jobRepository;
  late Translations i18n;

  setUpAll(() {
    i18n = AppLocale.ptBr.buildSync();
  });

  setUp(() {
    jobRepository = MockJobRepository();
    when(
      () => jobRepository.createDraft(description: any(named: 'description')),
    ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: JobDraftDto.fixture().copyWith(jobId: 'draft-job-id')));
  });

  testWidgets('when job location is opened for a draft, it should retain that draft id', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(tester, jobRepository: jobRepository);

    expect(tester.widget<CreateJobLocationView>(find.byType(CreateJobLocationView)).jobId, 'draft-job-id');
  });

  testWidgets('when location opens while the keyboard inset remains, it should keep the search above the keyboard', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      keyboardInset: 300,
      jobRepository: jobRepository,
    );

    expect(tester.getBottomRight(find.byKey(const ValueKey('create_job_location_search_field'))).dy, 532);
  });

  testWidgets('when location opens with bottom safe-area padding, it should keep the edge fade at the screen bottom', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(tester, jobRepository: jobRepository);

    expect(tester.getBottomRight(_bottomEdgeFade).dy, 844);
  });

  testWidgets('when the location search is focused with the keyboard visible, it should move above the keyboard', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      keyboardInset: 300,
      jobRepository: jobRepository,
    );

    await tester.tap(find.byKey(const ValueKey('create_job_location_search_field')));
    await tester.pumpAndSettle();

    expect(tester.getBottomRight(find.byKey(const ValueKey('create_job_location_search_field'))).dy, 532);
  });

  testWidgets('when the location search is focused with the keyboard visible, it should move the edge fade above it', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      keyboardInset: 300,
      jobRepository: jobRepository,
    );

    await tester.tap(find.byKey(const ValueKey('create_job_location_search_field')));
    await tester.pumpAndSettle();

    expect(tester.getBottomRight(_bottomEdgeFade).dy, 544);
  });

  testWidgets('when location opens, it should place search in the view footer outside the surface Morph', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(tester, jobRepository: jobRepository);
    final search = find.byKey(const ValueKey('create_job_location_search_field'));

    expect(find.ancestor(of: search, matching: find.byType(MorphForeground)), findsOneWidget);
    expect(find.ancestor(of: search, matching: find.byType(MorphDescendant)), findsNothing);
  });

  testWidgets('when the location route opens, it should keep search outside a Morph animation', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobLocationViewTestActions.validDescription);
    await tester.pumpAndSettle();
    unawaited(
      const CreateJobLocationRoute(
        jobId: 'draft-job-id',
      ).push<void>(tester.element(find.byKey(const ValueKey('create_job_description_view')))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.ancestor(of: find.byKey(const ValueKey('create_job_location_search_field')), matching: find.byType(Morph)),
      findsNothing,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('when job location opens, it should show the localized reference content', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(tester, jobRepository: jobRepository);

    expect(
      (
        find.byKey(const ValueKey('mateo_text_field_search_placeholder')).evaluate().length,
        find.byKey(const ValueKey('create_job_current_location_button')).evaluate().length,
        find.text(i18n.createJob.location.locationPermissionGuidance).evaluate().length,
        find.text(i18n.createJob.location.emptyGuidance).evaluate().length,
        find.byKey(const ValueKey('create_job_current_location_circle')).evaluate().length,
        find.byKey(const ValueKey('create_job_location_curved_arrow')).evaluate().length,
        _bottomEdgeFade.evaluate().length,
      ),
      (1, 1, 1, 1, 1, 1, 1),
    );
  });

  testWidgets('when job location opens, it should delegate header obstruction layout to Mateo', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(tester, jobRepository: jobRepository);

    expect(find.byType(MateoView), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('create_job_current_location_button')),
        matching: find.byType(Positioned),
      ),
      findsNothing,
    );
  });

  testWidgets('when job location opens, it should extend its body behind the search footer', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(tester, jobRepository: jobRepository);

    expect(tester.widget<MateoView>(find.byType(MateoView)).extendBodyBehindFooter, isTrue);
  });

  testWidgets('when a location query is entered, it should keep the query local without changing create-job state', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(tester, jobRepository: jobRepository);
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobLocationView)));
    final createJobDataBeforeSearch = container.read(createJobStateProvider);

    await tester.enterText(find.byType(TextField), 'Rua das Flores');
    await tester.pumpAndSettle();
    final searchText = tester.widget<TextField>(find.byType(TextField)).controller!.text;

    expect((searchText, container.read(createJobStateProvider)), ('Rua das Flores', createJobDataBeforeSearch));
  });

  testWidgets('when the location back button is tapped, it should return to the saved description', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      disableAnimations: false,
      jobRepository: jobRepository,
    );

    await tester.tap(find.byKey(const ValueKey('create_job_location_back_button')));
    await tester.pumpAndSettle();
    final descriptionText = tester
        .widget<TextField>(find.descendant(of: find.byType(CreateJobDescriptionView), matching: find.byType(TextField)))
        .controller!
        .text;

    expect(descriptionText, _CreateJobLocationViewTestActions.validDescription);
  });
}

final Finder _bottomEdgeFade = find.byWidgetPredicate(
  (widget) => widget is MateoEdgeFade && widget.position == MateoEdgeFadePosition.bottom,
);

abstract final class _CreateJobLocationViewTestActions {
  static const validDescription = 'Preciso de uma pessoa para descarregar caixas.';

  static Future<void> openFromDescription(
    WidgetTester tester, {
    required MockJobRepository jobRepository,
    bool disableAnimations = true,
    double keyboardInset = 0,
  }) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: disableAnimations,
      keyboardInset: keyboardInset,
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), validDescription);
    await tester.pumpAndSettle();
    unawaited(
      const CreateJobLocationRoute(
        jobId: 'draft-job-id',
      ).push<void>(tester.element(find.byKey(const ValueKey('create_job_description_view')))),
    );
    await tester.pumpAndSettle();
  }
}
