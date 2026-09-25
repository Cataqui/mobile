import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/dtos/user_job_detail/user_job_detail_location_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_job_detail_dto.freezed.dart';
part 'user_job_detail_dto.g.dart';

@freezed
abstract class UserJobDetailDto with _$UserJobDetailDto {
  const factory UserJobDetailDto({
    required String jobId,
    required String title,
    required String description,
    required String descriptionSummary,
    required JobContactDto? contact,
    required UserJobDetailLocationDto location,
    required String? payment,
    @JsonKey(unknownEnumValue: JobStatus.unknown) required JobStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserJobDetailDto;

  factory UserJobDetailDto.fromJson(Map<String, Object?> json) => _$UserJobDetailDtoFromJson(json);
}
