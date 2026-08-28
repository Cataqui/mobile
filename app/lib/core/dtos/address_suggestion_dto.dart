import 'package:cataqui_app/core/enums/address_category.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_suggestion_dto.freezed.dart';
part 'address_suggestion_dto.g.dart';

@freezed
abstract class AddressSuggestionDto with _$AddressSuggestionDto {
  const factory AddressSuggestionDto({
    @JsonKey(required: true) required String addressId,
    @JsonKey(required: true) required String fullText,
    @JsonKey(required: true) required String primaryText,
    @JsonKey(required: true) required AddressCategory category,
    String? secondaryText,
  }) = _AddressSuggestionDto;

  factory AddressSuggestionDto.fromJson(Map<String, Object?> json) => _$AddressSuggestionDtoFromJson(json);
}
