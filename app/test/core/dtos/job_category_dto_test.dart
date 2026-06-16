import 'package:cataqui_app/core/dtos/job_category_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobCategoryDto', () {
    test('when parsing a job category, it should map the category id', () {
      final category = JobCategoryDto.fixture().copyWith(categoryId: 'afdfd9b2-203d-4528-8a1c-82b6b139039b');

      expect(category.categoryId, 'afdfd9b2-203d-4528-8a1c-82b6b139039b');
    });
  });
}
