import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_details_dto.freezed.dart';
part 'address_details_dto.g.dart';

@freezed
abstract class AddressDetailsDto with _$AddressDetailsDto {
  const factory AddressDetailsDto({
    @JsonKey(required: true) required double latitude,
    @JsonKey(required: true) required double longitude,
  }) = _AddressDetailsDto;

  factory AddressDetailsDto.fromJson(Map<String, Object?> json) => _$AddressDetailsDtoFromJson(json);
}
