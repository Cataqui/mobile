import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobCreationFlowData', () {
    test('when the flow starts, it should not contain description text', () {
      const data = JobCreationFlowData();

      expect(data.descriptionText, isNull);
    });

    test('when copying with raw description text, it should preserve the text exactly', () {
      const data = JobCreationFlowData();

      expect(data.copyWith(descriptionText: '  descrição original  ').descriptionText, '  descrição original  ');
    });
  });
}
