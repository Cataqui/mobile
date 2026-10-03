import 'package:cataqui_app/core/enums/contact_method.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_contact_dto.freezed.dart';
part 'saved_contact_dto.g.dart';

@freezed
abstract class SavedContactDto with _$SavedContactDto {
  const factory SavedContactDto({
    required String contactId,
    @JsonKey(unknownEnumValue: ContactMethod.unknown) required ContactMethod method,
    required String identifier,
  }) = _SavedContactDto;

  factory SavedContactDto.fromJson(Map<String, Object?> json) => _$SavedContactDtoFromJson(json);

  factory SavedContactDto.fixture() => const SavedContactDto(
    contactId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    method: .whatsapp,
    identifier: '+5511999999999',
  );
}
