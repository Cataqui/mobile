import 'dart:async';

import 'package:cataqui_app/core/dtos/address_search_response_dto.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/description/create_job_description_view.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_data.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_route.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_state.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_view.dart';
import 'package:cataqui_app/views/create_job/payment/create_job_payment_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';
import '../../widgets/use_current_location_button/fake_device_location.dart';
import 'create_job_view_test_helpers.dart';

void main() {
  late MockJobRepository jobRepository;
  late MockGeosearchRepository geosearchRepository;
  late _ControllableCreateJobLocationState locationState;
  late Translations i18n;

  setUpAll(() {
    i18n = AppLocale.ptBr.buildSync();
  });

  setUp(() {
    jobRepository = MockJobRepository();
    geosearchRepository = MockGeosearchRepository();
    locationState = _ControllableCreateJobLocationState();
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

  testWidgets('when job location is opened for a draft, it should retain that draft id', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

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

  testWidgets('when location content scrolls, it should reveal the header-owned top fade', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer(
      (_) async => CreateJobViewTestHelpers.addressSearchResponse.copyWith(
        suggestions: List.generate(
          12,
          (index) =>
              CreateJobViewTestHelpers.addressSearchResponse.suggestions.first.copyWith(addressId: 'address-id-$index'),
        ),
      ),
    );
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );
    final locationView = find.byType(CreateJobLocationView);
    final topFade = find.descendant(of: locationView, matching: _topEdgeFade);
    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    await tester.drag(find.descendant(of: locationView, matching: find.byType(CustomScrollView)), const Offset(0, -80));
    await tester.pump();

    expect(_paintedFadeExtent(tester, topFade), greaterThan(0));
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

  testWidgets('when the blank location search gains focus, it should fade out and unmount the guidance', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(tester, jobRepository: jobRepository);

    await tester.tap(find.byKey(const ValueKey('create_job_location_search_field')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create_job_location_empty_guidance')), findsNothing);
  });

  testWidgets('when the initial location body is visible, it should allow outside taps to dismiss search focus', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(tester, jobRepository: jobRepository);

    expect(
      tester.widget<MateoTextField>(find.byKey(const ValueKey('create_job_location_search_field'))).unfocusOnTapOutside,
      isTrue,
    );
  });

  testWidgets('when current location is requested, it should save its coordinates and open payment', (tester) async {
    const address = DeviceLocationAddress(
      coordinates: DeviceLocationCoordinates(latitude: -23.561684, longitude: -46.655981, accuracy: 18),
      neighborhood: 'Pinheiros',
    );
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.denied],
    );
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      deviceLocation: deviceLocation,
      jobRepository: jobRepository,
    );
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobLocationView)));

    await tester.tap(find.byKey(const ValueKey('create_job_current_location_button')));
    await tester.pumpAndSettle();

    expect(
      (
        location: container.read(createJobStateProvider).location,
        paymentJobId: tester.widget<CreateJobPaymentView>(find.byType(CreateJobPaymentView)).jobId,
      ),
      (location: (latitude: -23.561684, longitude: -46.655981), paymentJobId: 'draft-job-id'),
    );
  });

  testWidgets('when the address search body is visible, it should prevent outside taps from dismissing search focus', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );
    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(
      tester.widget<MateoTextField>(find.byKey(const ValueKey('create_job_location_search_field'))).unfocusOnTapOutside,
      isFalse,
    );
  });

  testWidgets('when a blank location search loses focus, it should remount the guidance motion', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(tester, jobRepository: jobRepository);
    final initialMotion = tester.element(
      find.ancestor(
        of: find.byKey(const ValueKey('create_job_location_empty_guidance')),
        matching: find.byType(Motion),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('create_job_location_search_field')));
    await tester.pumpAndSettle();

    tester.widget<MateoTextField>(find.byKey(const ValueKey('create_job_location_search_field'))).controller!.unfocus();
    await tester.pumpAndSettle();

    expect(
      tester.element(
        find.ancestor(
          of: find.byKey(const ValueKey('create_job_location_empty_guidance')),
          matching: find.byType(Motion),
        ),
      ),
      isNot(same(initialMotion)),
    );
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
        find.text(i18n.useCurrentLocationButton.permissionGuidance).evaluate().length,
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

    expect(
      (
        scrollableView: find.byType(MateoScrollableView).evaluate().length,
        positionedAncestor: find
            .ancestor(
              of: find.byKey(const ValueKey('create_job_current_location_button')),
              matching: find.byType(Positioned),
            )
            .evaluate()
            .length,
      ),
      (scrollableView: 1, positionedAncestor: 0),
    );
  });

  testWidgets('when job location opens, it should resize its body around the keyboard', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(tester, jobRepository: jobRepository);

    expect(
      tester.widget<MateoScrollableView>(find.byType(MateoScrollableView)).keyboardViewportBehavior,
      MateoViewKeyboardViewportBehavior.resize,
    );
  });

  testWidgets('when a location query is entered, it should keep the query local without changing create-job state', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobLocationView)));
    final createJobDataBeforeSearch = container.read(createJobStateProvider);

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua das Flores');
    final searchText = tester.widget<TextField>(find.byType(TextField)).controller!.text;

    expect((searchText, container.read(createJobStateProvider)), ('Rua das Flores', createJobDataBeforeSearch));
  });

  testWidgets('when the first query is waiting for debounce, it should keep the initial location body', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

    await tester.enterText(find.byType(TextField), 'Rua');
    await tester.pump(const Duration(milliseconds: 299));

    expect(
      (
        initialBody: find.byKey(const ValueKey('create_job_location_view_content')).evaluate().length,
        skeleton: find.byKey(const ValueKey('create_job_location_search_skeleton')).evaluate().length,
        emptyMessage: find.text(i18n.createJob.location.search.empty).evaluate().length,
      ),
      (initialBody: 1, skeleton: 0, emptyMessage: 0),
    );
  });

  testWidgets('when an existing query is edited during debounce, it should keep the previous suggestions', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );
    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    await tester.enterText(find.byType(TextField), 'Rua Nova');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'Rua Nov');
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      (
        firstSuggestion: find.byKey(const ValueKey('create_job_location_suggestion_address-id-123')).evaluate().length,
        secondSuggestion: find.byKey(const ValueKey('create_job_location_suggestion_address-id-456')).evaluate().length,
        skeleton: find.byKey(const ValueKey('create_job_location_search_skeleton')).evaluate().length,
      ),
      (firstSuggestion: 1, secondSuggestion: 1, skeleton: 0),
    );
  });

  testWidgets('when a scrolled query is edited during debounce, it should preserve the current scroll offset', (
    tester,
  ) async {
    _CreateJobLocationViewTestActions.stubScrollableResults(geosearchRepository);
    await _CreateJobLocationViewTestActions.pumpLocation(tester, geosearchRepository: geosearchRepository);
    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');
    final scrollPosition = Scrollable.of(
      tester.element(find.byKey(const ValueKey('create_job_location_search_content'))),
    ).position;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
    await tester.pumpAndSettle();
    final scrolledOffset = scrollPosition.pixels;

    await tester.enterText(find.byType(TextField), 'Rua Nova');
    await tester.pump(const Duration(milliseconds: 299));

    expect(scrolledOffset > 0 && scrollPosition.pixels == scrolledOffset, isTrue);
  });

  testWidgets('when a new search starts after scrolling results, it should animate to the leading edge', (
    tester,
  ) async {
    _CreateJobLocationViewTestActions.stubScrollableResults(geosearchRepository);
    await _CreateJobLocationViewTestActions.pumpLocation(tester, geosearchRepository: geosearchRepository);
    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');
    final scrollPosition = Scrollable.of(
      tester.element(find.byKey(const ValueKey('create_job_location_search_content'))),
    ).position;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
    await tester.pumpAndSettle();
    final scrolledOffset = scrollPosition.pixels;
    when(
      () => geosearchRepository.searchAddresses(
        query: 'Rua Nova',
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) => Completer<AddressSearchResponseDto>().future);

    await tester.enterText(find.byType(TextField), 'Rua Nova');
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pump(const Duration(milliseconds: 10));
    final midpointOffset = scrollPosition.pixels;
    await tester.pump(const Duration(milliseconds: 491));

    expect(
      (
        startedScrolled: scrolledOffset > scrollPosition.minScrollExtent,
        movedTowardLeadingEdge: midpointOffset < scrolledOffset && midpointOffset > scrollPosition.minScrollExtent,
        settledOffset: scrollPosition.pixels,
      ),
      (startedScrolled: true, movedTowardLeadingEdge: true, settledOffset: scrollPosition.minScrollExtent),
    );
  });

  testWidgets('when loading replaces an empty search, it should keep the outgoing message position', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: 'Rua',
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) async => CreateJobViewTestHelpers.emptyAddressSearchResponse);
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      disableAnimations: false,
      keyboardInset: 300,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );
    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');
    final emptyMessage = find.byKey(const ValueKey('create_job_location_search_empty_transition'));
    final settledCenter = tester.getCenter(emptyMessage);
    when(
      () => geosearchRepository.searchAddresses(
        query: 'Rua Nova',
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) => Completer<AddressSearchResponseDto>().future);

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua Nova', settle: false);
    await tester.pump(const Duration(milliseconds: 15));

    expect(tester.getCenter(emptyMessage), settledCenter);
  });

  testWidgets('when an empty search is shown, it should center the message in the available search body', (
    tester,
  ) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) async => CreateJobViewTestHelpers.emptyAddressSearchResponse);
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      keyboardInset: 300,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');
    final searchContent = find.byKey(const ValueKey('create_job_location_search_content'));
    final searchSwitcher = find.descendant(of: searchContent, matching: find.byType(AnimatedSwitcher));

    expect(
      tester.getCenter(find.byKey(const ValueKey('create_job_location_search_empty_transition'))).dy,
      tester.getCenter(searchSwitcher).dy,
    );
  });

  testWidgets('when an address search is pending, it should show skeleton rows', (tester) async {
    final response = Completer<AddressSearchResponseDto>();
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) => response.future);
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua', settle: false);

    expect(find.byKey(const ValueKey('create_job_location_search_skeleton')), findsOneWidget);
  });

  testWidgets('when an address search is pending, it should expose the localized loading semantics', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) => Completer<AddressSearchResponseDto>().future);
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua', settle: false);

    expect(
      tester.widget<Skeleton>(find.byKey(const ValueKey('create_job_location_search_skeleton'))).semanticsLabel,
      i18n.createJob.location.search.loadingSemanticLabel,
    );
  });

  testWidgets('when address loading succeeds, it should fade out the skeleton before showing suggestions', (
    tester,
  ) async {
    final response = Completer<AddressSearchResponseDto>();
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) => response.future);
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      disableAnimations: false,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );
    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua', settle: false);

    response.complete(CreateJobViewTestHelpers.addressSearchResponse);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 15));
    final midpointFadeTransitions = tester
        .widgetList<FadeTransition>(
          find.descendant(
            of: find.byKey(const ValueKey('create_job_location_search_content')),
            matching: find.byType(FadeTransition),
          ),
        )
        .toList();
    final fastExitMidpoint = (
      skeleton: find.byKey(const ValueKey('create_job_location_search_skeleton')).evaluate().length,
      suggestions: find.byKey(const ValueKey('create_job_location_search_suggestions')).evaluate().length,
      fadeCount: midpointFadeTransitions.length,
      fadesAreActive: midpointFadeTransitions.every(
        (transition) => transition.opacity.value > 0 && transition.opacity.value < 1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final afterFastExitFadeTransitions = tester
        .widgetList<FadeTransition>(
          find.descendant(
            of: find.byKey(const ValueKey('create_job_location_search_content')),
            matching: find.byType(FadeTransition),
          ),
        )
        .toList();
    final afterFastExit = (
      skeleton: find.byKey(const ValueKey('create_job_location_search_skeleton')).evaluate().length,
      suggestions: find.byKey(const ValueKey('create_job_location_search_suggestions')).evaluate().length,
      fadeCount: afterFastExitFadeTransitions.length,
      incomingFadeIsActive: afterFastExitFadeTransitions.every(
        (transition) => transition.opacity.value > 0 && transition.opacity.value < 1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      (
        fastExitMidpoint: fastExitMidpoint,
        afterFastExit: afterFastExit,
        settledSkeleton: find.byKey(const ValueKey('create_job_location_search_skeleton')).evaluate().length,
        settledSuggestions: find.byKey(const ValueKey('create_job_location_search_suggestions')).evaluate().length,
      ),
      (
        fastExitMidpoint: (skeleton: 1, suggestions: 0, fadeCount: 1, fadesAreActive: true),
        afterFastExit: (skeleton: 0, suggestions: 1, fadeCount: 1, incomingFadeIsActive: true),
        settledSkeleton: 0,
        settledSuggestions: 1,
      ),
    );
  });

  testWidgets('when a new address search starts, it should fade out suggestions before showing the skeleton', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      disableAnimations: false,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );
    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');
    when(
      () => geosearchRepository.searchAddresses(
        query: 'Rua Nova',
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) => Completer<AddressSearchResponseDto>().future);

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua Nova', settle: false);
    await tester.pump(const Duration(milliseconds: 15));
    final midpointFadeTransitions = tester
        .widgetList<FadeTransition>(
          find.descendant(
            of: find.byKey(const ValueKey('create_job_location_search_content')),
            matching: find.byType(FadeTransition),
          ),
        )
        .toList();
    final fastExitMidpoint = (
      skeleton: find.byKey(const ValueKey('create_job_location_search_skeleton')).evaluate().length,
      suggestions: find.byKey(const ValueKey('create_job_location_search_suggestions')).evaluate().length,
      fadeCount: midpointFadeTransitions.length,
      fadesAreActive: midpointFadeTransitions.every(
        (transition) => transition.opacity.value > 0 && transition.opacity.value < 1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final afterFastExitFadeTransitions = tester
        .widgetList<FadeTransition>(
          find.descendant(
            of: find.byKey(const ValueKey('create_job_location_search_content')),
            matching: find.byType(FadeTransition),
          ),
        )
        .toList();
    final afterFastExit = (
      skeleton: find.byKey(const ValueKey('create_job_location_search_skeleton')).evaluate().length,
      suggestions: find.byKey(const ValueKey('create_job_location_search_suggestions')).evaluate().length,
      fadeCount: afterFastExitFadeTransitions.length,
      incomingFadeIsActive: afterFastExitFadeTransitions.every(
        (transition) => transition.opacity.value > 0 && transition.opacity.value < 1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      (
        fastExitMidpoint: fastExitMidpoint,
        afterFastExit: afterFastExit,
        settledSkeleton: find.byKey(const ValueKey('create_job_location_search_skeleton')).evaluate().length,
        settledSuggestions: find.byKey(const ValueKey('create_job_location_search_suggestions')).evaluate().length,
      ),
      (
        fastExitMidpoint: (skeleton: 0, suggestions: 1, fadeCount: 1, fadesAreActive: true),
        afterFastExit: (skeleton: 1, suggestions: 0, fadeCount: 1, incomingFadeIsActive: true),
        settledSkeleton: 1,
        settledSuggestions: 0,
      ),
    );
  });

  testWidgets('when address search succeeds, it should show every returned suggestion in API order', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    final firstSuggestion = find.byKey(const ValueKey('create_job_location_suggestion_address-id-123'));
    final secondSuggestion = find.byKey(const ValueKey('create_job_location_suggestion_address-id-456'));

    expect(
      (
        firstCount: firstSuggestion.evaluate().length,
        secondCount: secondSuggestion.evaluate().length,
        inApiOrder: tester.getTopLeft(firstSuggestion).dy < tester.getTopLeft(secondSuggestion).dy,
      ),
      (firstCount: 1, secondCount: 1, inApiOrder: true),
    );
  });

  testWidgets('when a suggestion has no secondary text, it should show only its primary line', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_location_suggestion_address-id-456')),
        matching: find.byType(Text),
      ),
      findsOneWidget,
    );
  });

  testWidgets('when address suggestions are visible, it should show the Google Maps attribution', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(find.byKey(const ValueKey('create_job_location_google_maps_attribution')), findsOneWidget);
  });

  testWidgets('when address suggestions are visible, it should pin their attribution in the search footer', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_location_search_footer')),
        matching: find.byKey(const ValueKey('create_job_location_google_maps_attribution')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('when address search returns no suggestions, it should show the localized empty message', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) async => CreateJobViewTestHelpers.emptyAddressSearchResponse);
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(find.text(i18n.createJob.location.search.empty), findsOneWidget);
  });

  testWidgets('when address search returns no suggestions, it should show the sad search icon', (tester) async {
    locationState.returnEmptyResults();
    await _CreateJobLocationViewTestActions.pumpLocation(tester, locationState: locationState);

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(find.byKey(const ValueKey('create_job_location_search_empty_icon')), findsOneWidget);
  });

  testWidgets('when address search fails, it should show the localized error message', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenThrow(Exception('Search failed'));
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(find.text(i18n.createJob.location.search.error), findsOneWidget);
  });

  testWidgets('when address search fails, it should show the double-cross animation', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenThrow(Exception('Search failed'));
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(find.byKey(const ValueKey('create_job_location_search_error_animation')), findsOneWidget);
  });

  testWidgets('when address search fails offline, it should show the localized offline message', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenThrow(CreateJobViewTestHelpers.createOfflineDioException());
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(find.text(i18n.createJob.location.search.offlineError), findsOneWidget);
  });

  testWidgets('when address search fails offline, it should show the Wi-Fi signal animation', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenThrow(CreateJobViewTestHelpers.createOfflineDioException());
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );

    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(find.byKey(const ValueKey('create_job_location_search_offline_animation')), findsOneWidget);
  });

  testWidgets('when the address query is cleared while focused, it should keep the initial guidance hidden', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );
    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    await tester.tap(find.byKey(const ValueKey('mateo_text_field_search_clear_tap_region')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create_job_location_empty_guidance')), findsNothing);
  });

  testWidgets('when the cleared address search loses focus, it should restore the initial location guidance', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );
    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');
    await tester.tap(find.byKey(const ValueKey('mateo_text_field_search_clear_tap_region')));
    await tester.pumpAndSettle();

    tester.widget<MateoTextField>(find.byKey(const ValueKey('create_job_location_search_field'))).controller!.unfocus();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create_job_location_empty_guidance')), findsOneWidget);
  });

  testWidgets('when an address suggestion is tapped, it should not request address details', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );
    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    await tester.tap(find.byKey(const ValueKey('create_job_location_suggestion_address-id-123')));
    await tester.pumpAndSettle();

    verifyNever(
      () => geosearchRepository.getAddressDetails(
        addressId: any(named: 'addressId'),
        sessionToken: any(named: 'sessionToken'),
      ),
    );
  });

  testWidgets('when an address suggestion is tapped, it should save the selection and open payment', (tester) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );
    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobLocationView)));

    await tester.tap(find.byKey(const ValueKey('create_job_location_suggestion_address-id-123')));
    await tester.pumpAndSettle();

    expect(
      (
        addressId: container.read(createJobStateProvider).addressSelection?.addressId,
        paymentJobId: tester.widget<CreateJobPaymentView>(find.byType(CreateJobPaymentView)).jobId,
      ),
      (addressId: 'address-id-123', paymentJobId: 'draft-job-id'),
    );
  });

  testWidgets('when payment is opened from location, its back button should return to the saved location', (
    tester,
  ) async {
    await _CreateJobLocationViewTestActions.openFromDescription(
      tester,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
    );
    await CreateJobViewTestHelpers.enterAddressQuery(tester, query: 'Rua');

    await tester.tap(find.byKey(const ValueKey('create_job_location_suggestion_address-id-123')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_payment_back_button')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobLocationView)));

    expect(
      (
        locationViewCount: find.byType(CreateJobLocationView).evaluate().length,
        addressId: container.read(createJobStateProvider).addressSelection?.addressId,
      ),
      (locationViewCount: 1, addressId: 'address-id-123'),
    );
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

final Finder _topEdgeFade = find.byWidgetPredicate(
  (widget) => widget is MateoEdgeFade && widget.position == MateoEdgeFadePosition.top,
);

double _paintedFadeExtent(WidgetTester tester, Finder fade) {
  return (tester.getBottomLeft(fade).dy - tester.getTopLeft(fade).dy).abs();
}

abstract final class _CreateJobLocationViewTestActions {
  static const validDescription = 'Preciso de uma pessoa para descarregar caixas.';

  static Future<void> pumpLocation(
    WidgetTester tester, {
    DeviceLocation? deviceLocation,
    MockGeosearchRepository? geosearchRepository,
    _ControllableCreateJobLocationState? locationState,
  }) async {
    await tester.pumpWidget(
      TestApp.screen(
        mediaQueryData: const MediaQueryData(
          size: Size(390, 844),
          devicePixelRatio: 1,
          padding: EdgeInsets.only(top: 47, bottom: 34),
          viewPadding: EdgeInsets.only(top: 47, bottom: 34),
          textScaler: TextScaler.noScaling,
          disableAnimations: true,
        ),
        providerOverrides: [
          translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
          if (deviceLocation != null) deviceLocationProvider.overrideWithValue(deviceLocation),
          if (geosearchRepository != null) geosearchRepositoryProvider.overrideWithValue(geosearchRepository),
          if (locationState != null) createJobLocationStateProvider.overrideWith(() => locationState),
        ],
        child: const CreateJobLocationView(jobId: 'draft-job-id'),
      ),
    );
    await tester.pumpAndSettle();
  }

  static void stubScrollableResults(MockGeosearchRepository geosearchRepository) {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer(
      (_) async => CreateJobViewTestHelpers.addressSearchResponse.copyWith(
        suggestions: List.generate(
          12,
          (index) =>
              CreateJobViewTestHelpers.addressSearchResponse.suggestions.first.copyWith(addressId: 'address-id-$index'),
        ),
      ),
    );
  }

  static Future<void> openFromDescription(
    WidgetTester tester, {
    required MockJobRepository jobRepository,
    DeviceLocation? deviceLocation,
    MockGeosearchRepository? geosearchRepository,
    bool disableAnimations = true,
    double keyboardInset = 0,
  }) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      deviceLocation: deviceLocation,
      disableAnimations: disableAnimations,
      keyboardInset: keyboardInset,
      jobRepository: jobRepository,
      geosearchRepository: geosearchRepository,
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

final class _ControllableCreateJobLocationState extends CreateJobLocationState {
  AddressSearchResponseDto _response = CreateJobViewTestHelpers.addressSearchResponse.copyWith(
    suggestions: List.generate(
      12,
      (index) =>
          CreateJobViewTestHelpers.addressSearchResponse.suggestions.first.copyWith(addressId: 'address-id-$index'),
    ),
  );

  void returnEmptyResults() => _response = CreateJobViewTestHelpers.emptyAddressSearchResponse;

  @override
  CreateJobLocationData build() => const CreateJobLocationData();

  @override
  Future<void> searchAddresses({required String query}) {
    state = state.copyWith(addressSearch: const AsyncLoading<AddressSearchResponseDto?>());
    state = state.copyWith(addressSearch: AsyncData<AddressSearchResponseDto?>(_response));
    return Future<void>.value();
  }
}
