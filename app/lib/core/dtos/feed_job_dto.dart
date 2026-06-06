import 'package:cataqui_app/core/dtos/feed_job_location_dto.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_job_dto.freezed.dart';
part 'feed_job_dto.g.dart';

@freezed
abstract class FeedJobDto with _$FeedJobDto {
  const factory FeedJobDto({
    @JsonKey(name: 'job_id') required String jobId,
    required String title,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    required JobPaymentDto payment,
    required FeedJobLocationDto location,
  }) = _FeedJobDto;

  factory FeedJobDto.fromJson(Map<String, Object?> json) =>
      _$FeedJobDtoFromJson(json);
}
