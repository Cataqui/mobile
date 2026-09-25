import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_job_detail_location_dto.freezed.dart';
part 'user_job_detail_location_dto.g.dart';

@freezed
abstract class UserJobDetailLocationDto with _$UserJobDetailLocationDto {
  const factory UserJobDetailLocationDto({
    required String title,
    required double latitude,
    required double longitude,
    required num areaRadius,
  }) = _UserJobDetailLocationDto;

  factory UserJobDetailLocationDto.fromJson(Map<String, Object?> json) => _$UserJobDetailLocationDtoFromJson(json);
}
