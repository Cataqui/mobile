import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_dto.freezed.dart';
part 'user_profile_dto.g.dart';

@freezed
abstract class UserProfileDto with _$UserProfileDto {
  const factory UserProfileDto({required String userId, required String displayIdentifier}) = _UserProfileDto;

  factory UserProfileDto.fromJson(Map<String, Object?> json) => _$UserProfileDtoFromJson(json);

  factory UserProfileDto.fixture() =>
      const UserProfileDto(userId: '4963fef0-b62a-4760-9f99-675fdc42a896', displayIdentifier: 'Ana Silva');
}
