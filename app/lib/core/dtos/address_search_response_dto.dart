import 'package:cataqui_app/core/dtos/address_search_attribution_dto.dart';
import 'package:cataqui_app/core/dtos/address_suggestion_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_search_response_dto.freezed.dart';
part 'address_search_response_dto.g.dart';

@freezed
abstract class AddressSearchResponseDto with _$AddressSearchResponseDto {
  const factory AddressSearchResponseDto({
    @JsonKey(required: true) required List<AddressSuggestionDto> suggestions,
    @JsonKey(required: true) required AddressSearchAttributionDto attribution,
  }) = _AddressSearchResponseDto;

  factory AddressSearchResponseDto.fromJson(Map<String, Object?> json) => _$AddressSearchResponseDtoFromJson(json);
}
