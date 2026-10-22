import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_metadata_dto.freezed.dart';
part 'account_metadata_dto.g.dart';

@freezed
abstract class AccountMetadataDto with _$AccountMetadataDto {
  const factory AccountMetadataDto({required bool onboardingCompleted}) = _AccountMetadataDto;

  factory AccountMetadataDto.fromJson(Map<String, Object?> json) => _$AccountMetadataDtoFromJson(json);

  factory AccountMetadataDto.fixture() => const AccountMetadataDto(onboardingCompleted: false);
}
