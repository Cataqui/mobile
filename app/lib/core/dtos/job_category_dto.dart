import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_category_dto.freezed.dart';
part 'job_category_dto.g.dart';

@freezed
abstract class JobCategoryDto with _$JobCategoryDto {
  const factory JobCategoryDto({
    @JsonKey(name: 'category_id') required String categoryId,
    required String name,
    required String slug,
  }) = _JobCategoryDto;

  factory JobCategoryDto.fromJson(Map<String, Object?> json) =>
      _$JobCategoryDtoFromJson(json);

  factory JobCategoryDto.fixture() => const JobCategoryDto(
    categoryId: 'afdfd9b2-203d-4528-8a1c-82b6b139039b',
    name: 'Outro',
    slug: 'other',
  );
}
