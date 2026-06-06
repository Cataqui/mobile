import 'package:cataqui_app/core/dtos/job_enums.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dto_json_fixtures.dart';

void main() {
  group('JobPaymentDto', () {
    test('when parsing a job payment, it should map the minimum amount', () {
      final payment = JobPaymentDto.fromJson(
        detailedJobJson['payment']! as Map<String, Object?>,
      );

      expect(payment.minAmount, 120);
    });

    test('when parsing an unknown payment type, it should use unknown', () {
      final payment = JobPaymentDto.fromJson(const <String, Object?>{
        'type': 'BONUS',
        'min_amount': 120,
        'amount_period': 'SINGLE',
        'currency': 'BRL',
      });

      expect(payment.type, JobPaymentType.unknown);
    });
  });
}
