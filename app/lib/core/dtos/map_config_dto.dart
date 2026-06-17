import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_config_dto.freezed.dart';
part 'map_config_dto.g.dart';

@freezed
abstract class MapConfigDto with _$MapConfigDto {
  const factory MapConfigDto({
    @JsonKey(name: 'query_params') required String queryParams,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
    @JsonKey(name: 'map_version') required String mapVersion,
    @JsonKey(name: 'tiles_url_template') required String tilesUrlTemplate,
    @JsonKey(name: 'glyph_url_template') required String glyphUrlTemplate,
    @Default(0) @JsonKey(name: 'tile_min_zoom') num tileMinZoom,
    @Default(14) @JsonKey(name: 'tile_max_zoom') num tileMaxZoom,
  }) = _MapConfigDto;

  factory MapConfigDto.fromJson(Map<String, Object?> json) => _$MapConfigDtoFromJson(json);

  factory MapConfigDto.fixture() => MapConfigDto(
    queryParams: 'style=streets&lang=pt-BR',
    expiresAt: DateTime.parse('2026-06-17T12:00:00.000Z'),
    mapVersion: '1.0.0',
    tilesUrlTemplate: 'https://tiles.cataqui.dev/v1/{z}/{x}/{y}.png',
    glyphUrlTemplate: 'https://tiles.cataqui.dev/v1/glyphs/{fontstack}/{range}.pbf',
    tileMinZoom: 0,
    tileMaxZoom: 16,
  );
}
