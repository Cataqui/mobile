import 'package:cataqui_app/core/dtos/job_category_dto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dto_json_fixtures.dart';

void main() {
  group('JobCategoryDto', () {
    test('when parsing a job category, it should map the category id', () {
      final category = JobCategoryDto.fromJson(
        detailedJobJson['category']! as Map<String, Object?>,
      );

      expect(category.categoryId, 'afdfd9b2-203d-4528-8a1c-82b6b139039b');
    });
  });
}
