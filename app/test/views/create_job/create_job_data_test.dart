import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateJobData', () {
    test('when description creation starts, it should not contain description text', () {
      const data = CreateJobData();

      expect(data.descriptionText, isNull);
    });

    test('when copying with raw description text, it should preserve the text exactly', () {
      const data = CreateJobData();

      expect(data.copyWith(descriptionText: '  descrição original  ').descriptionText, '  descrição original  ');
    });

    test('when job creation starts, it should use the default payment amount', () {
      const data = CreateJobData();

      expect(data.paymentAmount, '0');
    });

    test('when job creation starts, it should not be creating a draft', () {
      const data = CreateJobData();

      expect(data.isCreatingDraft, isFalse);
    });
  });
}
