import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_job_location_dto.freezed.dart';
part 'user_job_location_dto.g.dart';

@freezed
abstract class UserJobLocationDto with _$UserJobLocationDto {
  const factory UserJobLocationDto({
    required String title,
    required double latitude,
    required double longitude,
    required num areaRadius,
  }) = _UserJobLocationDto;

  factory UserJobLocationDto.fromJson(Map<String, Object?> json) => _$UserJobLocationDtoFromJson(json);

  factory UserJobLocationDto.fixture() =>
      const UserJobLocationDto(title: 'Rua Pardal Branco, 32', latitude: -23.55, longitude: -46.63, areaRadius: 2000);
}
