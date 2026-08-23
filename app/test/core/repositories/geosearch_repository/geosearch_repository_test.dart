import 'package:cataqui_app/core/dtos/address_details_dto.dart';
import 'package:cataqui_app/core/dtos/address_search_attribution_dto.dart';
import 'package:cataqui_app/core/dtos/address_suggestion_dto.dart';
import 'package:cataqui_app/core/repositories/geosearch_repository/geosearch_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

void main() {
  late MockDio dio;
  late GeosearchRepository repository;

  setUp(() {
    dio = MockDio();
    repository = GeosearchRepository(geosearchDio: dio);
  });

  group('GeosearchRepository', () {
    group('searchAddresses', () {
      test('when the query is blank, it should forward it to geosearch unchanged', () async {
        _GeosearchRepositoryTestData.stubAddressSearchRequest(dio: dio);

        await repository.searchAddresses(query: '   ', sessionToken: 'session-token');

        verify(
          () => dio.query<Map<String, Object?>>(
            '/v1/addresses/search',
            data: <String, Object?>{'query': '   ', 'sessionToken': 'session-token'},
          ),
        ).called(1);
      });

      test('when searching an address, it should send the worker query contract', () async {
        _GeosearchRepositoryTestData.stubAddressSearchRequest(dio: dio);

        await repository.searchAddresses(query: '  Avenida Paulista  ', sessionToken: 'session-token');

        verify(
          () => dio.query<Map<String, Object?>>(
            '/v1/addresses/search',
            data: <String, Object?>{'query': '  Avenida Paulista  ', 'sessionToken': 'session-token'},
          ),
        ).called(1);
      });

      test('when geosearch returns suggestions, it should map provider-neutral address data', () async {
        _GeosearchRepositoryTestData.stubAddressSearchRequest(dio: dio);

        final response = await repository.searchAddresses(query: 'Avenida Paulista', sessionToken: 'session-token');

        expect(
          (suggestion: response.suggestions.single, attribution: response.attribution),
          (
            suggestion: const AddressSuggestionDto(
              addressId: 'address-id-123',
              fullText: 'Avenida Paulista, Bela Vista, São Paulo - SP, Brasil',
              primaryText: 'Avenida Paulista',
              secondaryText: 'Bela Vista, São Paulo - SP, Brasil',
            ),
            attribution: const AddressSearchAttributionDto(text: 'Google Maps'),
          ),
        );
      });
    });

    group('getAddressDetails', () {
      test('when requesting address details, it should send the selected address and session to the worker', () async {
        _GeosearchRepositoryTestData.stubAddressDetailsRequest(dio: dio);

        await repository.getAddressDetails(addressId: 'address/id 123', sessionToken: 'session-token');

        verify(
          () => dio.query<Map<String, Object?>>(
            '/v1/addresses/details',
            data: <String, String>{'addressId': 'address/id 123', 'sessionToken': 'session-token'},
          ),
        ).called(1);
      });

      test('when geosearch returns address details, it should return only coordinates', () async {
        _GeosearchRepositoryTestData.stubAddressDetailsRequest(dio: dio);

        final details = await repository.getAddressDetails(addressId: 'address-id-123', sessionToken: 'session-token');

        expect(details, const AddressDetailsDto(latitude: -23.561684, longitude: -46.655981));
      });
    });
  });
}

final class _GeosearchRepositoryTestData {
  const _GeosearchRepositoryTestData._();

  static void stubAddressSearchRequest({required MockDio dio}) {
    when(() => dio.query<Map<String, Object?>>(any(), data: any<Map<String, Object?>>(named: 'data'))).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: const <String, Object?>{
          'suggestions': <Object?>[
            <String, Object?>{
              'addressId': 'address-id-123',
              'fullText': 'Avenida Paulista, Bela Vista, São Paulo - SP, Brasil',
              'primaryText': 'Avenida Paulista',
              'secondaryText': 'Bela Vista, São Paulo - SP, Brasil',
            },
          ],
          'attribution': <String, Object?>{'text': 'Google Maps'},
        },
        requestOptions: RequestOptions(path: '/v1/addresses/search'),
      ),
    );
  }

  static void stubAddressDetailsRequest({required MockDio dio}) {
    when(() => dio.query<Map<String, Object?>>(any(), data: any<Map<String, Object?>>(named: 'data'))).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        data: const <String, Object?>{'latitude': -23.561684, 'longitude': -46.655981},
        requestOptions: RequestOptions(path: '/v1/addresses/details'),
      ),
    );
  }
}
