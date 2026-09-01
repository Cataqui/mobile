import 'package:cataqui_app/core/dtos/address_search_response_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_location_data.freezed.dart';

@freezed
abstract class PostLocationData with _$PostLocationData {
  const factory PostLocationData({
    @Default(AsyncData<AddressSearchResponseDto?>(null)) AsyncValue<AddressSearchResponseDto?> addressSearch,
  }) = _PostLocationData;
}
