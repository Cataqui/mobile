import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_search_attribution_dto.freezed.dart';
part 'address_search_attribution_dto.g.dart';

@freezed
abstract class AddressSearchAttributionDto with _$AddressSearchAttributionDto {
  const factory AddressSearchAttributionDto({@JsonKey(required: true) required String text}) =
      _AddressSearchAttributionDto;

  factory AddressSearchAttributionDto.fromJson(Map<String, Object?> json) =>
      _$AddressSearchAttributionDtoFromJson(json);
}
