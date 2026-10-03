import 'package:freezed_annotation/freezed_annotation.dart';

part 'fuzzy_job_location_dto.freezed.dart';
part 'fuzzy_job_location_dto.g.dart';

@freezed
abstract class FuzzyJobLocationDto with _$FuzzyJobLocationDto {
  const factory FuzzyJobLocationDto({
    required double latitude,
    required double longitude,
    required String imageUrl,
    required num areaRadius,
  }) = _FuzzyJobLocationDto;

  factory FuzzyJobLocationDto.fromJson(Map<String, Object?> json) => _$FuzzyJobLocationDtoFromJson(json);

  factory FuzzyJobLocationDto.fixture() => const FuzzyJobLocationDto(
    latitude: -23.556391,
    longitude: -46.844076,
    areaRadius: 2000,
    imageUrl: 'https://maps.cataqui.com/static/fixture',
  );
}
