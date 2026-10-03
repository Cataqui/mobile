import 'package:cataqui_app/core/enums/contact_method.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_dto.freezed.dart';
part 'contact_dto.g.dart';

@freezed
abstract class ContactDto with _$ContactDto {
  const factory ContactDto({
    @JsonKey(unknownEnumValue: ContactMethod.unknown) required ContactMethod method,
    required String identifier,
  }) = _ContactDto;

  factory ContactDto.fromJson(Map<String, Object?> json) => _$ContactDtoFromJson(json);

  factory ContactDto.fixture() => const ContactDto(method: .whatsapp, identifier: '+5511999999999');
}
