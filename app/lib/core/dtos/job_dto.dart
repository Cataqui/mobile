import 'package:cataqui_app/core/dtos/job_category_dto.dart';
import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/dtos/job_enums.dart';
import 'package:cataqui_app/core/dtos/job_location_dto.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_dto.freezed.dart';
part 'job_dto.g.dart';

@freezed
abstract class JobDto with _$JobDto {
  const factory JobDto({
    @JsonKey(name: 'job_id') required String jobId,
    required String title,
    required String description,
    required JobContactDto contact,
    required JobLocationDto location,
    required JobCategoryDto category,
    required JobPaymentDto payment,
    @JsonKey(unknownEnumValue: JobStatus.unknown) required JobStatus status,
    @JsonKey(unknownEnumValue: JobType.unknown) required JobType type,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _JobDto;

  factory JobDto.fromJson(Map<String, Object?> json) => _$JobDtoFromJson(json);
}
