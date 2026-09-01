import 'dart:async';

import 'package:cataqui_app/core/dtos/address_search_response_dto.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/post/location/enums/post_location_morph_tag.dart';
import 'package:cataqui_app/views/post/location/post_location_view.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:cataqui_app/views/post/post_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../../fakes.dart';
import '../../../mocks.dart';
import 'post_location_test_helpers.dart';

void main() {
  late MockGeosearchRepository geosearchRepository;
  late Translations i18n;

  setUpAll(() {
    i18n = AppLocale.ptBr.buildSync();
  });

  setUp(() {
    geosearchRepository = MockGeosearchRepository();
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) async => PostLocationTestHelpers.addressSearchResponse);
  });

  testWidgets('when the location chip is tapped, it should open the custom overlay above the composer', (tester) async {
    await PostLocationTestHelpers.openLocation(tester);

    expect(
      (
        locationView: find.byType(PostLocationView).evaluate().length,
        descriptionInput: find.byKey(const ValueKey('post_description_input')).evaluate().length,
        overlaySurface: find.byKey(const ValueKey('post_location_view_surface')).evaluate().length,
      ),
      (locationView: 1, descriptionInput: 1, overlaySurface: 1),
    );
  });

  testWidgets('when the location chip renders, it should expose one labeled button', (tester) async {
    final semantics = tester.ensureSemantics();
    await PostLocationTestHelpers.pumpPost(tester);

    final tap = find.ancestor(of: find.byKey(const ValueKey('post_location_chip')), matching: find.byType(MateoTap));
    final data = tester.getSemantics(tap).getSemanticsData();
    final matchingLabels = find.bySemanticsLabel(i18n.post.location.chipTitle).evaluate().length;
    semantics.dispose();

    expect((button: data.flagsCollection.isButton, matchingLabels: matchingLabels), (button: true, matchingLabels: 1));
  });

  testWidgets('when the location chip is activated through semantics, it should open the location overlay', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await PostLocationTestHelpers.pumpPost(tester);

    final node = tester.getSemantics(
      find.ancestor(of: find.byKey(const ValueKey('post_location_chip')), matching: find.byType(MateoTap)),
    );
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    semantics.dispose();

    expect(find.byType(PostLocationView), findsOneWidget);
  });

  testWidgets('when the location chip is tapped, it should present location on a distinct modal route', (tester) async {
    await PostLocationTestHelpers.openLocation(tester);

    final composerRoute = ModalRoute.of(tester.element(find.byKey(const ValueKey('post_description_input'))));
    final locationRoute = ModalRoute.of(tester.element(find.byType(PostLocationView)));

    expect(
      (isDistinct: !identical(composerRoute, locationRoute), isModal: locationRoute is PageRouteBuilder<void>),
      (isDistinct: true, isModal: true),
    );
  });

  testWidgets('when the location modal transitions, it should use independent opening and closing durations', (
    tester,
  ) async {
    await PostLocationTestHelpers.openLocation(tester, disableAnimations: false);
    final locationRoute = ModalRoute.of(tester.element(find.byType(PostLocationView)))!;

    expect(
      (opening: locationRoute.transitionDuration, closing: locationRoute.reverseTransitionDuration),
      (opening: const Duration(milliseconds: 320), closing: const Duration(milliseconds: 270)),
    );
  });

  testWidgets('when the location overlay opens, it should keep the keyboard visible', (tester) async {
    await PostLocationTestHelpers.openLocation(tester);

    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('when the location overlay closes, it should restore the composer focus', (tester) async {
    await PostLocationTestHelpers.pumpPost(tester);
    final descriptionFocusNode = tester
        .widget<TextField>(find.byKey(const ValueKey('post_description_input')))
        .focusNode!;
    await tester.tap(find.byKey(const ValueKey('post_location_chip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('post_location_close_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(descriptionFocusNode.hasFocus, isTrue);
  });

  testWidgets('when the location content is tapped, it should keep the search focused', (tester) async {
    await PostLocationTestHelpers.openLocation(tester);
    final searchController = tester
        .widget<MateoTextField>(find.byKey(const ValueKey('post_location_search_field')))
        .controller!;
    await tester.tap(find.byKey(const ValueKey('post_location_empty_guidance')));
    await tester.pump();

    expect(searchController.hasFocus, isTrue);
  });

  testWidgets('when the location overlay opens, it should keep one surface Morph endpoint on each route', (
    tester,
  ) async {
    await PostLocationTestHelpers.openLocation(tester);

    final endpoints = find
        .byWidgetPredicate((widget) => widget is Morph && widget.tag == PostLocationMorphTag.surface)
        .evaluate();

    expect(
      (endpointCount: endpoints.length, routeCount: endpoints.map(ModalRoute.of).toSet().length),
      (endpointCount: 2, routeCount: 2),
    );
  });

  testWidgets('when location settles, its surface should fill the screen', (tester) async {
    await PostLocationTestHelpers.openLocation(tester);

    final surface = find.byKey(const ValueKey('post_location_view_surface'));
    final size = MediaQuery.sizeOf(tester.element(surface));

    expect(tester.getRect(surface), Offset.zero & size);
  });

  testWidgets('when location opens, it should use only the top Mateo edge fade', (tester) async {
    await PostLocationTestHelpers.openLocation(tester);

    final view = tester.widget<MateoScrollableView>(find.byKey(const ValueKey('post_location_view')));

    expect((top: view.edgeFade?.top != null, bottom: view.edgeFade?.bottom != null), (top: true, bottom: false));
  });
  testWidgets('when the overlay close action is tapped, it should dismiss the location overlay', (tester) async {
    await PostLocationTestHelpers.openLocation(tester);

    await tester.tap(find.byKey(const ValueKey('post_location_close_button')));
    await tester.pumpAndSettle();

    expect(find.byType(PostLocationView), findsNothing);
  });

  testWidgets('when system back is invoked from location, it should restore the composer', (tester) async {
    await PostLocationTestHelpers.openLocation(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(PostLocationView), findsNothing);
  });

  testWidgets('when location opens, it should use the lightweight modal scrim', (tester) async {
    await PostLocationTestHelpers.openLocation(tester, disableAnimations: false);

    expect(tester.widget<AnimatedModalBarrier>(find.byType(AnimatedModalBarrier)).color.value?.a, 0.1);
  });

  testWidgets('when location opens with reduced motion, it should settle in the custom overlay', (tester) async {
    await PostLocationTestHelpers.openLocation(tester);

    expect(find.byType(PostLocationView), findsOneWidget);
  });

  testWidgets('when location opens, it should show its controls and search guidance', (tester) async {
    await PostLocationTestHelpers.openLocation(tester);

    expect(
      (
        search: find.byKey(const ValueKey('post_location_search_field')).evaluate().length,
        currentLocation: find.byKey(const ValueKey('post_current_location_button')).evaluate().length,
        guidance: find.text(i18n.post.location.emptyGuidance).evaluate().length,
        attribution: find.byKey(const ValueKey('post_location_google_maps_attribution')).evaluate().length,
      ),
      (search: 1, currentLocation: 1, guidance: 1, attribution: 1),
    );
  });

  testWidgets('when a query is waiting for debounce, it should not show search results yet', (tester) async {
    await PostLocationTestHelpers.openLocation(tester, geosearchRepository: geosearchRepository);

    await tester.enterText(find.byKey(const ValueKey('post_location_search_field')), 'Rua');
    await tester.pump(const Duration(milliseconds: 299));

    expect(find.byKey(const ValueKey('post_location_search_content')), findsNothing);
  });

  testWidgets('when a nonblank query is waiting for debounce, it should keep the current location button', (
    tester,
  ) async {
    await PostLocationTestHelpers.openLocation(tester, geosearchRepository: geosearchRepository);

    await tester.enterText(find.byKey(const ValueKey('post_location_search_field')), 'Rua');
    await tester.pump();

    expect(find.byKey(const ValueKey('post_current_location_button')), findsOneWidget);
  });

  testWidgets('when an address search is loading, it should hide the current location button', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) => Completer<AddressSearchResponseDto>().future);
    await PostLocationTestHelpers.openLocation(tester, geosearchRepository: geosearchRepository);

    await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua', settle: false);

    expect(find.byKey(const ValueKey('post_current_location_button')), findsNothing);
  });

  testWidgets('when an address search finishes, it should keep the current location button hidden', (tester) async {
    await PostLocationTestHelpers.openLocation(tester, geosearchRepository: geosearchRepository);

    await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(find.byKey(const ValueKey('post_current_location_button')), findsNothing);
  });

  testWidgets('when an address search fails, it should keep the current location button hidden', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenThrow(StateError('search failed'));
    await PostLocationTestHelpers.openLocation(tester, geosearchRepository: geosearchRepository);

    await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(find.byKey(const ValueKey('post_current_location_button')), findsNothing);
  });

  testWidgets('when an address search is pending, it should show localized skeleton semantics', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) => Completer<AddressSearchResponseDto>().future);
    await PostLocationTestHelpers.openLocation(tester, geosearchRepository: geosearchRepository);

    await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua', settle: false);

    expect(
      tester.widget<Skeleton>(find.byKey(const ValueKey('post_location_search_skeleton'))).semanticsLabel,
      i18n.post.location.search.loadingSemanticLabel,
    );
  });

  testWidgets('when address search succeeds, it should show suggestions in API order', (tester) async {
    await PostLocationTestHelpers.openLocation(tester, geosearchRepository: geosearchRepository);

    await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua');
    final first = find.byKey(const ValueKey('post_location_suggestion_address-id-123'));
    final second = find.byKey(const ValueKey('post_location_suggestion_address-id-456'));

    expect(
      (
        firstCount: first.evaluate().length,
        secondCount: second.evaluate().length,
        ordered: tester.getTopLeft(first).dy < tester.getTopLeft(second).dy,
      ),
      (firstCount: 1, secondCount: 1, ordered: true),
    );
  });

  testWidgets('when address search returns no suggestions, it should show the localized empty state', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) async => PostLocationTestHelpers.emptyAddressSearchResponse);
    await PostLocationTestHelpers.openLocation(tester, geosearchRepository: geosearchRepository);

    await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(find.text(i18n.post.location.search.empty), findsOneWidget);
  });

  testWidgets('when address search fails, it should show the localized generic error', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenThrow(StateError('search failed'));
    await PostLocationTestHelpers.openLocation(tester, geosearchRepository: geosearchRepository);

    await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(find.text(i18n.post.location.search.error), findsOneWidget);
  });

  testWidgets('when address search fails offline, it should show the localized offline error', (tester) async {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenThrow(PostLocationTestHelpers.createOfflineDioException());
    await PostLocationTestHelpers.openLocation(tester, geosearchRepository: geosearchRepository);

    await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua');

    expect(find.text(i18n.post.location.search.offlineError), findsOneWidget);
  });

  testWidgets('when a suggestion is selected, it should return with its id and primary label in post state', (
    tester,
  ) async {
    await PostLocationTestHelpers.openLocation(tester, geosearchRepository: geosearchRepository);
    final container = ProviderScope.containerOf(tester.element(find.byType(PostView)));
    await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua');

    final suggestion = find.byKey(const ValueKey('post_location_suggestion_address-id-123'));
    await tester.ensureVisible(suggestion);
    await tester.pumpAndSettle();
    await tester.tap(suggestion);
    await tester.pumpAndSettle();

    expect(
      (
        addressId: container.read(postStateProvider).addressSelection?.addressId,
        label: container.read(postStateProvider).locationTitle,
        chipLabelCount: find.text(PostLocationTestHelpers.firstSuggestion.primaryText).evaluate().length,
      ),
      (addressId: 'address-id-123', label: 'Avenida Paulista', chipLabelCount: 1),
    );
  });

  testWidgets('when a suggestion is selected, it should keep the overlay open until the updated chip renders', (
    tester,
  ) async {
    await PostLocationTestHelpers.openLocation(tester, geosearchRepository: geosearchRepository);
    await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua');
    final locationRoute = ModalRoute.of(tester.element(find.byType(PostLocationView)))!;
    final suggestion = find.byKey(const ValueKey('post_location_suggestion_address-id-123'));
    await tester.ensureVisible(suggestion);
    await tester.pumpAndSettle();

    await tester.tap(suggestion);

    expect(locationRoute.isCurrent, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('when a suggestion is selected, it should not request address details', (tester) async {
    await PostLocationTestHelpers.openLocation(tester, geosearchRepository: geosearchRepository);
    await PostLocationTestHelpers.enterAddressQuery(tester, query: 'Rua');

    final suggestion = find.byKey(const ValueKey('post_location_suggestion_address-id-123'));
    await tester.ensureVisible(suggestion);
    await tester.pumpAndSettle();
    await tester.tap(suggestion);
    await tester.pumpAndSettle();

    verifyNever(
      () => geosearchRepository.getAddressDetails(
        addressId: any(named: 'addressId'),
        sessionToken: any(named: 'sessionToken'),
      ),
    );
  });

  testWidgets('when current location is selected, it should return with coordinates and a concise chip label', (
    tester,
  ) async {
    const address = DeviceLocationAddress(
      coordinates: DeviceLocationCoordinates(latitude: -23.561684, longitude: -46.655981, accuracy: 18),
      neighborhood: 'Pinheiros',
      city: 'São Paulo',
    );
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.denied],
    );
    await PostLocationTestHelpers.openLocation(tester, deviceLocation: deviceLocation);
    final container = ProviderScope.containerOf(tester.element(find.byType(PostView)));

    await tester.tap(find.byKey(const ValueKey('post_current_location_button')));
    await tester.pumpAndSettle();

    expect(
      (
        location: container.read(postStateProvider).location,
        label: container.read(postStateProvider).locationTitle,
        chipLabelCount: find.text('Pinheiros, São Paulo').evaluate().length,
      ),
      (location: (latitude: -23.561684, longitude: -46.655981), label: 'Pinheiros, São Paulo', chipLabelCount: 1),
    );
  });

  testWidgets('when current location resolves, it should finish the button transition before closing', (tester) async {
    const address = DeviceLocationAddress(
      coordinates: DeviceLocationCoordinates(latitude: -23.561684, longitude: -46.655981, accuracy: 18),
      neighborhood: 'Pinheiros',
      city: 'São Paulo',
    );
    final addressCompleter = Completer<DeviceLocationAddress>();
    final deviceLocation = FakeDeviceLocation(
      address: address,
      addressCompleter: addressCompleter,
      permissionStatuses: [DeviceLocationPermissionStatus.denied],
    );
    await PostLocationTestHelpers.openLocation(tester, deviceLocation: deviceLocation, disableAnimations: false);
    final locationRoute = ModalRoute.of(tester.element(find.byType(PostLocationView)))!;
    await tester.tap(find.byKey(const ValueKey('post_current_location_button')));
    await tester.pump(const Duration(milliseconds: 350));

    addressCompleter.complete(address);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 199));

    expect(locationRoute.animation!.status, AnimationStatus.completed);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
  });
}
