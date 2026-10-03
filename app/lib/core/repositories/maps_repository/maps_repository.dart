import 'package:cataqui_app/core/dtos/address_details_dto.dart';
import 'package:cataqui_app/core/dtos/address_search_response_dto.dart';
import 'package:dio/dio.dart';

class MapsRepository {
  const MapsRepository({required this.mapsDio});

  final Dio mapsDio;

  Future<AddressSearchResponseDto> searchAddresses({required String query, required String sessionToken}) async {
    final response = await mapsDio.query<Map<String, Object?>>(
      '/places/search',
      data: <String, Object?>{'query': query, 'sessionToken': sessionToken},
    );

    return AddressSearchResponseDto.fromJson(response.data!);
  }

  Future<AddressDetailsDto> getAddressDetails({required String addressId, required String sessionToken}) async {
    final response = await mapsDio.query<Map<String, Object?>>(
      '/places/details',
      data: <String, String>{'placeId': addressId, 'sessionToken': sessionToken},
    );

    return AddressDetailsDto.fromJson(response.data!);
  }
}
