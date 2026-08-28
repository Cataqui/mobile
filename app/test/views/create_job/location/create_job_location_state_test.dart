import 'dart:async';

import 'package:cataqui_app/core/dtos/address_search_attribution_dto.dart';
import 'package:cataqui_app/core/dtos/address_search_response_dto.dart';
import 'package:cataqui_app/core/dtos/address_suggestion_dto.dart';
import 'package:cataqui_app/core/enums/address_category.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

void main() {
  late MockGeosearchRepository geosearchRepository;
  late List<({String query, String sessionToken})> searchRequests;

  setUp(() {
    geosearchRepository = MockGeosearchRepository();
    searchRequests = <({String query, String sessionToken})>[];
    _CreateJobLocationStateTestData.stubSearch(geosearchRepository: geosearchRepository, requests: searchRequests);
  });

  group('CreateJobLocationState', () {
    group('searchAddresses', () {
      testWidgets('when queries change during the debounce, it should search only the latest trimmed query', (
        tester,
      ) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        final notifier = container.read(createJobLocationStateProvider.notifier);

        unawaited(notifier.searchAddresses(query: 'Avenida'));
        final latestSearch = notifier.searchAddresses(query: '  Rua Augusta  ');
        final requestCountBeforeDebounce = searchRequests.length;
        await _CreateJobLocationStateTestData.elapseDebounce(tester);
        await latestSearch;

        expect(
          (
            beforeDebounce: requestCountBeforeDebounce,
            requestCount: searchRequests.length,
            requestQuery: searchRequests.single.query,
          ),
          (beforeDebounce: 0, requestCount: 1, requestQuery: 'Rua Augusta'),
        );
      });

      testWidgets('when only surrounding whitespace changes, it should not search the same query again', (
        tester,
      ) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        final notifier = container.read(createJobLocationStateProvider.notifier);
        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida Paulista');

        final repeatedSearch = notifier.searchAddresses(query: ' Avenida Paulista ');
        await _CreateJobLocationStateTestData.elapseDebounce(tester);
        await repeatedSearch;

        expect(searchRequests.length, 1);
      });

      testWidgets('when the debounce elapses, it should expose the search as loading', (tester) async {
        final response = Completer<AddressSearchResponseDto>();
        _CreateJobLocationStateTestData.stubSearch(
          geosearchRepository: geosearchRepository,
          requests: searchRequests,
          response: response.future,
        );
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);

        final search = container
            .read(createJobLocationStateProvider.notifier)
            .searchAddresses(query: 'Avenida Paulista');
        final isLoadingBeforeDebounce = container.read(createJobLocationStateProvider).addressSearch.isLoading;
        await _CreateJobLocationStateTestData.elapseDebounce(tester);

        expect(
          (
            beforeDebounce: isLoadingBeforeDebounce,
            afterDebounce: container.read(createJobLocationStateProvider).addressSearch.isLoading,
          ),
          (beforeDebounce: false, afterDebounce: true),
        );
        response.complete(_CreateJobLocationStateTestData.firstSearchResponse);
        await tester.pump();
        await search;
      });

      testWidgets('when an address search succeeds, it should expose the returned addresses and attribution', (
        tester,
      ) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);

        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida Paulista');

        expect(
          container.read(createJobLocationStateProvider).addressSearch.value,
          _CreateJobLocationStateTestData.firstSearchResponse,
        );
      });

      testWidgets('when an address search fails, it should expose the search error', (tester) async {
        _CreateJobLocationStateTestData.stubSearch(
          geosearchRepository: geosearchRepository,
          requests: searchRequests,
          error: StateError('search failed'),
        );
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);

        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida Paulista');

        expect(
          container.read(createJobLocationStateProvider).addressSearch,
          isA<AsyncError<AddressSearchResponseDto?>>(),
        );
      });

      testWidgets('when a blank query replaces address results, it should clear them without querying geosearch', (
        tester,
      ) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida Paulista');

        final blankSearch = container.read(createJobLocationStateProvider.notifier).searchAddresses(query: '   ');
        await _CreateJobLocationStateTestData.elapseDebounce(tester);
        await blankSearch;

        expect(
          (
            searchValue: container.read(createJobLocationStateProvider).addressSearch.value,
            requestCount: searchRequests.length,
          ),
          (searchValue: null, requestCount: 1),
        );
      });

      testWidgets('when a blank query cancels a pending search, it should settle without querying geosearch', (
        tester,
      ) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        final notifier = container.read(createJobLocationStateProvider.notifier);
        var pendingSearchCompleted = false;
        final pendingSearch = notifier.searchAddresses(query: 'Avenida Paulista').whenComplete(() {
          pendingSearchCompleted = true;
        });

        await notifier.searchAddresses(query: '   ');
        await tester.pump();

        try {
          expect(
            (
              pendingSearchCompleted: pendingSearchCompleted,
              searchHasError: container.read(createJobLocationStateProvider).addressSearch.hasError,
              requestCount: searchRequests.length,
            ),
            (pendingSearchCompleted: true, searchHasError: false, requestCount: 0),
          );
        } finally {
          await _CreateJobLocationStateTestData.elapseDebounce(tester);
          await pendingSearch;
        }
      });

      testWidgets(
        'when the provider is disposed during a pending search, it should settle without querying geosearch',
        (tester) async {
          final container = ProviderContainer(
            overrides: [geosearchRepositoryProvider.overrideWithValue(geosearchRepository)],
          )..listen(createJobLocationStateProvider, (_, _) {}, fireImmediately: true);
          var pendingSearchCompleted = false;
          final pendingSearch = container
              .read(createJobLocationStateProvider.notifier)
              .searchAddresses(query: 'Avenida Paulista')
              .whenComplete(() {
                pendingSearchCompleted = true;
              });

          container.dispose();
          await tester.pump();

          try {
            expect(
              (pendingSearchCompleted: pendingSearchCompleted, requestCount: searchRequests.length),
              (pendingSearchCompleted: true, requestCount: 0),
            );
          } finally {
            await _CreateJobLocationStateTestData.elapseDebounce(tester);
            await pendingSearch;
          }
        },
      );

      testWidgets('when a newer query supersedes a running search, it should settle the older search immediately', (
        tester,
      ) async {
        final firstResponse = Completer<AddressSearchResponseDto>();
        final secondResponse = Completer<AddressSearchResponseDto>();
        _CreateJobLocationStateTestData.stubSearchForQuery(
          geosearchRepository: geosearchRepository,
          requests: searchRequests,
          query: 'Avenida Paulista',
          response: firstResponse.future,
        );
        _CreateJobLocationStateTestData.stubSearchForQuery(
          geosearchRepository: geosearchRepository,
          requests: searchRequests,
          query: 'Rua Augusta',
          response: secondResponse.future,
        );
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        final notifier = container.read(createJobLocationStateProvider.notifier);
        var firstSearchCompleted = false;
        final firstSearch = notifier.searchAddresses(query: 'Avenida Paulista').whenComplete(() {
          firstSearchCompleted = true;
        });
        await _CreateJobLocationStateTestData.elapseDebounce(tester);

        final secondSearch = notifier.searchAddresses(query: 'Rua Augusta');
        await tester.pump();

        try {
          expect(
            (
              firstSearchCompleted: firstSearchCompleted,
              searchIsLoading: container.read(createJobLocationStateProvider).addressSearch.isLoading,
              requestCount: searchRequests.length,
            ),
            (firstSearchCompleted: true, searchIsLoading: true, requestCount: 1),
          );
        } finally {
          await _CreateJobLocationStateTestData.elapseDebounce(tester);
          secondResponse.complete(_CreateJobLocationStateTestData.secondSearchResponse);
          await tester.pump();
          await secondSearch;
          firstResponse.complete(_CreateJobLocationStateTestData.firstSearchResponse);
          await tester.pump();
          await firstSearch;
        }
      });

      testWidgets('when an older request finishes after a newer query, it should keep the newer address results', (
        tester,
      ) async {
        final firstResponse = Completer<AddressSearchResponseDto>();
        final secondResponse = Completer<AddressSearchResponseDto>();
        _CreateJobLocationStateTestData.stubSearchForQuery(
          geosearchRepository: geosearchRepository,
          requests: searchRequests,
          query: 'Avenida Paulista',
          response: firstResponse.future,
        );
        _CreateJobLocationStateTestData.stubSearchForQuery(
          geosearchRepository: geosearchRepository,
          requests: searchRequests,
          query: 'Rua Augusta',
          response: secondResponse.future,
        );
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        final notifier = container.read(createJobLocationStateProvider.notifier);

        final firstSearch = notifier.searchAddresses(query: 'Avenida Paulista');
        await _CreateJobLocationStateTestData.elapseDebounce(tester);
        final secondSearch = notifier.searchAddresses(query: 'Rua Augusta');
        await _CreateJobLocationStateTestData.elapseDebounce(tester);
        secondResponse.complete(_CreateJobLocationStateTestData.secondSearchResponse);
        await tester.pump();
        await secondSearch;
        firstResponse.complete(_CreateJobLocationStateTestData.firstSearchResponse);
        await tester.pump();
        await firstSearch;

        expect(
          container.read(createJobLocationStateProvider).addressSearch.value,
          _CreateJobLocationStateTestData.secondSearchResponse,
        );
      });

      testWidgets('when multiple queries belong to one autocomplete session, it should reuse one UUID token', (
        tester,
      ) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida');
        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida Paulista');

        expect(
          (
            sameToken: searchRequests.first.sessionToken == searchRequests.last.sessionToken,
            isUuidV4: _CreateJobLocationStateTestData.uuidV4Pattern.hasMatch(searchRequests.first.sessionToken),
          ),
          (sameToken: true, isUuidV4: true),
        );
      });

      testWidgets('when a blank query abandons autocomplete, it should use a new token for the next session', (
        tester,
      ) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        final notifier = container.read(createJobLocationStateProvider.notifier);
        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida Paulista');
        await notifier.searchAddresses(query: '   ');

        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Rua Augusta');

        expect(searchRequests.last.sessionToken, isNot(searchRequests.first.sessionToken));
      });

      testWidgets('when a new or blank query starts, it should preserve the saved coordinates', (tester) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        final createJobNotifier = container.read(createJobStateProvider.notifier);
        final locationNotifier = container.read(createJobLocationStateProvider.notifier);
        createJobNotifier.setLocation(latitude: -23.561684, longitude: -46.655981);

        final nonBlankSearch = locationNotifier.searchAddresses(query: 'Rua Augusta');
        final afterNonBlankQuery = container.read(createJobStateProvider).location;
        await _CreateJobLocationStateTestData.elapseDebounce(tester);
        await nonBlankSearch;
        await locationNotifier.searchAddresses(query: '   ');

        expect(
          (afterNonBlankQuery: afterNonBlankQuery, afterBlankQuery: container.read(createJobStateProvider).location),
          (
            afterNonBlankQuery: (latitude: -23.561684, longitude: -46.655981),
            afterBlankQuery: (latitude: -23.561684, longitude: -46.655981),
          ),
        );
      });
    });

    group('selectAddress', () {
      testWidgets('when no autocomplete session exists, it should not save an address selection', (tester) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);

        container
            .read(createJobLocationStateProvider.notifier)
            .selectAddress(addressId: _CreateJobLocationStateTestData.firstSuggestion.addressId);
        await tester.pump(const Duration(milliseconds: 1));

        expect(container.read(createJobStateProvider).addressSelection, isNull);
      });

      testWidgets('when autocomplete is active, it should save the address id supplied by the UI', (tester) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida Paulista');

        container
            .read(createJobLocationStateProvider.notifier)
            .selectAddress(addressId: _CreateJobLocationStateTestData.secondSuggestion.addressId);

        expect(container.read(createJobStateProvider).addressSelection, (
          addressId: _CreateJobLocationStateTestData.secondSuggestion.addressId,
          sessionToken: searchRequests.single.sessionToken,
        ));
      });

      testWidgets('when a blank query abandons autocomplete, it should not save an address selection', (tester) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        final notifier = container.read(createJobLocationStateProvider.notifier);
        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida Paulista');
        await notifier.searchAddresses(query: '   ');

        notifier.selectAddress(addressId: _CreateJobLocationStateTestData.firstSuggestion.addressId);

        expect(container.read(createJobStateProvider).addressSelection, isNull);
      });

      testWidgets('when an address is selected, it should save its id with the autocomplete session token', (
        tester,
      ) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida Paulista');

        container
            .read(createJobLocationStateProvider.notifier)
            .selectAddress(addressId: _CreateJobLocationStateTestData.firstSuggestion.addressId);

        expect(container.read(createJobStateProvider).addressSelection, (
          addressId: _CreateJobLocationStateTestData.firstSuggestion.addressId,
          sessionToken: searchRequests.single.sessionToken,
        ));
      });

      testWidgets('when an address is selected, it should clear previously resolved coordinates', (tester) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        container.read(createJobStateProvider.notifier).setLocation(latitude: -23.561684, longitude: -46.655981);
        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida Paulista');

        container
            .read(createJobLocationStateProvider.notifier)
            .selectAddress(addressId: _CreateJobLocationStateTestData.firstSuggestion.addressId);

        expect(container.read(createJobStateProvider).location, isNull);
      });

      testWidgets('when an address is selected, it should rotate the token before the next search session', (
        tester,
      ) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        final notifier = container.read(createJobLocationStateProvider.notifier);
        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida Paulista');
        notifier.selectAddress(addressId: _CreateJobLocationStateTestData.firstSuggestion.addressId);

        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Rua Augusta');

        expect(searchRequests.last.sessionToken, isNot(searchRequests.first.sessionToken));
      });

      testWidgets('when an address was already selected, it should not replace it without a new search', (
        tester,
      ) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        final notifier = container.read(createJobLocationStateProvider.notifier);
        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida Paulista');
        notifier.selectAddress(addressId: _CreateJobLocationStateTestData.firstSuggestion.addressId);
        final firstSelection = container.read(createJobStateProvider).addressSelection;

        notifier.selectAddress(addressId: _CreateJobLocationStateTestData.firstSuggestion.addressId);

        expect(container.read(createJobStateProvider).addressSelection, firstSelection);
      });

      testWidgets('when a new or blank query starts, it should preserve the deferred address selection', (
        tester,
      ) async {
        final container = _CreateJobLocationStateTestData.createContainer(geosearchRepository: geosearchRepository);
        final notifier = container.read(createJobLocationStateProvider.notifier);
        await _CreateJobLocationStateTestData.search(tester: tester, container: container, query: 'Avenida Paulista');
        notifier.selectAddress(addressId: _CreateJobLocationStateTestData.firstSuggestion.addressId);
        final firstSelection = container.read(createJobStateProvider).addressSelection;

        final newSearch = notifier.searchAddresses(query: 'Rua Augusta');
        final afterNewQuery = container.read(createJobStateProvider).addressSelection;
        await _CreateJobLocationStateTestData.elapseDebounce(tester);
        await newSearch;
        notifier.selectAddress(addressId: _CreateJobLocationStateTestData.secondSuggestion.addressId);
        final afterNewSelection = container.read(createJobStateProvider).addressSelection;
        await notifier.searchAddresses(query: '   ');

        expect(
          (
            afterNewQuery: afterNewQuery,
            afterNewSelection: afterNewSelection,
            afterBlankQuery: container.read(createJobStateProvider).addressSelection,
          ),
          (
            afterNewQuery: firstSelection,
            afterNewSelection: (
              addressId: _CreateJobLocationStateTestData.secondSuggestion.addressId,
              sessionToken: searchRequests.last.sessionToken,
            ),
            afterBlankQuery: (
              addressId: _CreateJobLocationStateTestData.secondSuggestion.addressId,
              sessionToken: searchRequests.last.sessionToken,
            ),
          ),
        );
      });
    });
  });
}

abstract final class _CreateJobLocationStateTestData {
  static final uuidV4Pattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  static const firstSuggestion = AddressSuggestionDto(
    addressId: 'address-id-123',
    fullText: 'Avenida Paulista, Bela Vista, Sao Paulo - SP, Brasil',
    primaryText: 'Avenida Paulista',
    category: AddressCategory.street,
    secondaryText: 'Bela Vista, Sao Paulo - SP, Brasil',
  );
  static const secondSuggestion = AddressSuggestionDto(
    addressId: 'address-id-456',
    fullText: 'Rua Augusta, Consolacao, Sao Paulo - SP, Brasil',
    primaryText: 'Rua Augusta',
    category: AddressCategory.street,
    secondaryText: 'Consolacao, Sao Paulo - SP, Brasil',
  );
  static const firstSearchResponse = AddressSearchResponseDto(
    suggestions: <AddressSuggestionDto>[firstSuggestion],
    attribution: AddressSearchAttributionDto(text: 'Google Maps'),
  );
  static const secondSearchResponse = AddressSearchResponseDto(
    suggestions: <AddressSuggestionDto>[secondSuggestion],
    attribution: AddressSearchAttributionDto(text: 'Google Maps'),
  );
  static ProviderContainer createContainer({required MockGeosearchRepository geosearchRepository}) {
    final container = ProviderContainer(overrides: [geosearchRepositoryProvider.overrideWithValue(geosearchRepository)])
      ..listen(createJobLocationStateProvider, (_, _) {}, fireImmediately: true)
      ..listen(createJobStateProvider, (_, _) {}, fireImmediately: true);
    addTearDown(container.dispose);
    return container;
  }

  static Future<void> elapseDebounce(WidgetTester tester) {
    return tester.pump(const Duration(milliseconds: 301));
  }

  static Future<void> search({
    required WidgetTester tester,
    required ProviderContainer container,
    required String query,
  }) async {
    final result = container.read(createJobLocationStateProvider.notifier).searchAddresses(query: query);
    await elapseDebounce(tester);
    await result;
  }

  static void stubSearch({
    required MockGeosearchRepository geosearchRepository,
    required List<({String query, String sessionToken})> requests,
    Future<AddressSearchResponseDto>? response,
    Object? error,
  }) {
    when(
      () => geosearchRepository.searchAddresses(
        query: any(named: 'query'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((invocation) {
      requests.add(searchRequest(invocation));
      if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
      return response ?? Future<AddressSearchResponseDto>.value(firstSearchResponse);
    });
  }

  static void stubSearchForQuery({
    required MockGeosearchRepository geosearchRepository,
    required List<({String query, String sessionToken})> requests,
    required String query,
    required Future<AddressSearchResponseDto> response,
  }) {
    when(
      () => geosearchRepository.searchAddresses(
        query: query,
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((invocation) {
      requests.add(searchRequest(invocation));
      return response;
    });
  }

  static ({String query, String sessionToken}) searchRequest(Invocation invocation) {
    return (
      query: invocation.namedArguments[#query]! as String,
      sessionToken: invocation.namedArguments[#sessionToken]! as String,
    );
  }
}
