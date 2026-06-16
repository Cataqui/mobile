import 'package:cataqui_app/core/dtos/job_enums.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Translations t;

  setUpAll(() async {
    t = await AppLocale.ptBr.build();
  });

  group('JobPaymentDto', () {
    group('JSON parsing', () {
      test('when parsing a job payment, it should map the minimum amount', () {
        final payment = JobPaymentDto.fixture().copyWith(minAmount: 120);

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

    group('formatPayment', () {
      test(r'when payment type is fixed with BRL and daily, it should format with R$ and /dia', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 120,
          amountPeriod: JobPaymentAmountPeriod.daily,
          currency: 'BRL',
        );

        final result = payment.formatPayment(t);

        expect(result.contains(r'R$'), isTrue);
        expect(result.contains('120'), isTrue);
        expect(result.contains('/dia'), isTrue);
      });

      test(r'when payment type is fixed with USD and hourly, it should format with $ and /hora', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 20,
          amountPeriod: JobPaymentAmountPeriod.hourly,
          currency: 'USD',
        );

        final result = payment.formatPayment(t);

        expect(result.contains(r'$'), isTrue);
        expect(result.contains('20'), isTrue);
        expect(result.contains('/hora'), isTrue);
      });

      test('when payment type is range, it should include "+"', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.range,
          minAmount: 150,
          amountPeriod: JobPaymentAmountPeriod.daily,
          currency: 'BRL',
        );

        final result = payment.formatPayment(t);

        expect(result.contains('+'), isTrue);
      });

      test('when payment type is flexible, it should return "Negociável"', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.flexible,
          minAmount: 0,
          amountPeriod: JobPaymentAmountPeriod.single,
          currency: 'BRL',
        );

        final result = payment.formatPayment(t);

        expect(result, equals('Negociável'));
      });

      test('when payment type is other, it should show no period suffix', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.other,
          minAmount: 500,
          amountPeriod: JobPaymentAmountPeriod.monthly,
          currency: 'BRL',
        );

        final result = payment.formatPayment(t);

        expect(result.contains('/'), isFalse);
      });

      test('when payment type is unknown, it should show no period suffix', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.unknown,
          minAmount: 100,
          amountPeriod: JobPaymentAmountPeriod.daily,
          currency: 'BRL',
        );

        final result = payment.formatPayment(t);

        expect(result.contains('/'), isFalse);
      });

      test('when amount is an integer, it should have no decimal places', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 120,
          amountPeriod: JobPaymentAmountPeriod.single,
          currency: 'BRL',
        );

        final result = payment.formatPayment(t);

        expect(result.contains(','), isFalse);
      });

      test('when amount is fractional, it should show decimal places', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 150.5,
          amountPeriod: JobPaymentAmountPeriod.single,
          currency: 'BRL',
        );

        final result = payment.formatPayment(t);

        expect(result.contains(','), isTrue);
      });

      test('when amount period is single, it should have no period suffix', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 100,
          amountPeriod: JobPaymentAmountPeriod.single,
          currency: 'BRL',
        );

        final result = payment.formatPayment(t);

        expect(result.contains('/'), isFalse);
      });

      test('when amount period is unknown, it should have no period suffix', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 100,
          amountPeriod: JobPaymentAmountPeriod.unknown,
          currency: 'BRL',
        );

        final result = payment.formatPayment(t);

        expect(result.contains('/'), isFalse);
      });
    });
  });
}
