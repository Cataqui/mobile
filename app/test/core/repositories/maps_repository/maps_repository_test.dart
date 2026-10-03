import 'package:cataqui_app/core/dtos/address_details_dto.dart';
import 'package:cataqui_app/core/dtos/address_search_attribution_dto.dart';
import 'package:cataqui_app/core/dtos/address_suggestion_dto.dart';
import 'package:cataqui_app/core/enums/address_category.dart';
import 'package:cataqui_app/core/repositories/maps_repository/maps_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

void main() {
  late MockDio dio;
  late MapsRepository repository;

  setUp(() {
    dio = MockDio();
    repository = MapsRepository(mapsDio: dio);
  });

  group('MapsRepository', () {
    group('searchAddresses', () {
      test('when the query is blank, it should forward it to maps unchanged', () async {
        _MapsRepositoryTestData.stubAddressSearchRequest(dio: dio);

        await repository.searchAddresses(query: '   ', sessionToken: 'session-token');

        verify(
          () => dio.query<Map<String, Object?>>(
            '/places/search',
            data: <String, Object?>{'query': '   ', 'sessionToken': 'session-token'},
          ),
        ).called(1);
      });

      test('when searching an address, it should send the worker query contract', () async {
        _MapsRepositoryTestData.stubAddressSearchRequest(dio: dio);

        await repository.searchAddresses(query: '  Avenida Paulista  ', sessionToken: 'session-token');

        verify(
          () => dio.query<Map<String, Object?>>(
            '/places/search',
            data: <String, Object?>{'query': '  Avenida Paulista  ', 'sessionToken': 'session-token'},
          ),
        ).called(1);
      });

      test('when maps returns suggestions, it should map provider-neutral address data', () async {
        _MapsRepositoryTestData.stubAddressSearchRequest(dio: dio);

        final response = await repository.searchAddresses(query: 'Avenida Paulista', sessionToken: 'session-token');

        expect(
          (suggestion: response.suggestions.single, attribution: response.attribution),
          (
            suggestion: const AddressSuggestionDto(
              addressId: 'address-id-123',
              fullText: 'Avenida Paulista, Bela Vista, São Paulo - SP, Brasil',
              primaryText: 'Avenida Paulista',
              secondaryText: 'Bela Vista, São Paulo - SP, Brasil',
              category: AddressCategory.racingVenue,
            ),
            attribution: const AddressSearchAttributionDto(text: 'Google Maps'),
          ),
        );
      });
    });

    group('getAddressDetails', () {
      test('when requesting address details, it should send the selected address and session to the worker', () async {
        _MapsRepositoryTestData.stubAddressDetailsRequest(dio: dio);

        await repository.getAddressDetails(addressId: 'address/id 123', sessionToken: 'session-token');

        verify(
          () => dio.query<Map<String, Object?>>(
            '/places/details',
            data: <String, String>{'placeId': 'address/id 123', 'sessionToken': 'session-token'},
          ),
        ).called(1);
      });

      test('when maps returns address details, it should return only coordinates', () async {
        _MapsRepositoryTestData.stubAddressDetailsRequest(dio: dio);

        final details = await repository.getAddressDetails(addressId: 'address-id-123', sessionToken: 'session-token');

        expect(details, const AddressDetailsDto(latitude: -23.561684, longitude: -46.655981));
      });
    });
  });
}

final class _MapsRepositoryTestData {
  const _MapsRepositoryTestData._();

  static void stubAddressSearchRequest({required MockDio dio}) {
    when(() => dio.query<Map<String, Object?>>(any(), data: any<Map<String, Object?>>(named: 'data'))).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: const <String, Object?>{
          'suggestions': <Object?>[
            <String, Object?>{
              'placeId': 'address-id-123',
              'fullText': 'Avenida Paulista, Bela Vista, São Paulo - SP, Brasil',
              'primaryText': 'Avenida Paulista',
              'secondaryText': 'Bela Vista, São Paulo - SP, Brasil',
              'category': 'RACING_VENUE',
            },
          ],
          'attribution': <String, Object?>{'text': 'Google Maps'},
        },
        requestOptions: RequestOptions(path: '/places/search'),
      ),
    );
  }

  static void stubAddressDetailsRequest({required MockDio dio}) {
    when(() => dio.query<Map<String, Object?>>(any(), data: any<Map<String, Object?>>(named: 'data'))).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: const <String, Object?>{'latitude': -23.561684, 'longitude': -46.655981},
        requestOptions: RequestOptions(path: '/places/details'),
      ),
    );
  }
}
