import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_job_location_dto.freezed.dart';
part 'feed_job_location_dto.g.dart';

@freezed
abstract class FeedJobLocationDto with _$FeedJobLocationDto {
  const factory FeedJobLocationDto({
    required String neighborhood,
  }) = _FeedJobLocationDto;

  factory FeedJobLocationDto.fromJson(Map<String, Object?> json) =>
      _$FeedJobLocationDtoFromJson(json);
}
