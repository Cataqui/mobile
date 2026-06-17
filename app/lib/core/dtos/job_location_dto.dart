import 'package:cataqui_app/core/dtos/map_config_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_location_dto.freezed.dart';
part 'job_location_dto.g.dart';

@freezed
abstract class JobLocationDto with _$JobLocationDto {
  const factory JobLocationDto({
    required String neighborhood,
    required String city,
    required String state,
    required String country,
    required double latitude,
    required double longitude,
    @JsonKey(name: 'area_radius') required num areaRadius,
    @JsonKey(name: 'map_config') required MapConfigDto mapConfig,
    String? street,
  }) = _JobLocationDto;

  factory JobLocationDto.fromJson(Map<String, Object?> json) => _$JobLocationDtoFromJson(json);

  factory JobLocationDto.fixture() => JobLocationDto(
    neighborhood: 'Centro',
    city: 'São Paulo',
    state: 'SP',
    country: 'BR',
    latitude: -23.556391,
    longitude: -46.844076,
    areaRadius: 2000,
    mapConfig: MapConfigDto.fixture(),
    street: 'Rua das Flores, 123',
  );
}
