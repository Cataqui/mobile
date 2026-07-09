import 'package:cataqui_app/core/dtos/job_category_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobCategoryDto', () {
    test('when parsing a job category, it should map the category id', () {
      final category = JobCategoryDto.fromJson(const <String, Object?>{
        'category_id': 'afdfd9b2-203d-4528-8a1c-82b6b139039b',
        'name': 'Outro',
        'slug': 'other',
      });

      expect(category.categoryId, 'afdfd9b2-203d-4528-8a1c-82b6b139039b');
    });
  });
}
