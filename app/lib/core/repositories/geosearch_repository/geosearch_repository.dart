import 'package:cataqui_app/core/dtos/address_details_dto.dart';
import 'package:cataqui_app/core/dtos/address_search_response_dto.dart';
import 'package:dio/dio.dart';

class GeosearchRepository {
  const GeosearchRepository({required this.geosearchDio});

  final Dio geosearchDio;

  Future<AddressSearchResponseDto> searchAddresses({required String query, required String sessionToken}) async {
    final response = await geosearchDio.query<Map<String, Object?>>(
      '/v1/addresses/search',
      data: <String, Object?>{'query': query, 'sessionToken': sessionToken},
    );

    return AddressSearchResponseDto.fromJson(response.data!);
  }

  Future<AddressDetailsDto> getAddressDetails({required String addressId, required String sessionToken}) async {
    final response = await geosearchDio.query<Map<String, Object?>>(
      '/v1/addresses/details',
      data: <String, String>{'addressId': addressId, 'sessionToken': sessionToken},
    );

    return AddressDetailsDto.fromJson(response.data!);
  }
}
