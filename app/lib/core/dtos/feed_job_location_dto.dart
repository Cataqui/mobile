import 'package:cataqui_app/core/dtos/map_config_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_job_location_dto.freezed.dart';
part 'feed_job_location_dto.g.dart';

@freezed
abstract class FeedJobLocationDto with _$FeedJobLocationDto {
  const factory FeedJobLocationDto({
    required String neighborhood,
    required double latitude,
    required double longitude,
    @JsonKey(name: 'area_radius') required num areaRadius,
    @JsonKey(name: 'map_config') required MapConfigDto mapConfig,
  }) = _FeedJobLocationDto;

  factory FeedJobLocationDto.fromJson(Map<String, Object?> json) => _$FeedJobLocationDtoFromJson(json);

  factory FeedJobLocationDto.fixture() => FeedJobLocationDto(
    neighborhood: 'Centro',
    latitude: -23.556391,
    longitude: -46.844076,
    areaRadius: 2000,
    mapConfig: MapConfigDto.fixture(),
  );
}
