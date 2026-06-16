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
          'max_amount': 200,
          'amount_period': 'SINGLE',
          'currency': 'BRL',
          'note': '',
        });

        expect(payment.type, JobPaymentType.unknown);
      });

      test('when min_amount is missing from JSON, it should default to null', () {
        final payment = JobPaymentDto.fromJson(const <String, Object?>{
          'type': 'FLEXIBLE',
          'amount_period': 'SINGLE',
          'currency': 'BRL',
          'note': '',
        });

        expect(payment.minAmount, isNull);
      });

      test('when max_amount is missing from JSON, it should default to null', () {
        final payment = JobPaymentDto.fromJson(const <String, Object?>{
          'type': 'FLEXIBLE',
          'amount_period': 'SINGLE',
          'currency': 'BRL',
          'note': '',
        });

        expect(payment.maxAmount, isNull);
      });
    });

    group('nullable amounts', () {
      test('when creating a flexible payment, minAmount should default to null', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.flexible,
          amountPeriod: JobPaymentAmountPeriod.single,
          currency: 'BRL',
          note: '',
        );

        expect(payment.minAmount, isNull);
      });

      test('when creating a flexible payment, maxAmount should default to null', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.flexible,
          amountPeriod: JobPaymentAmountPeriod.single,
          currency: 'BRL',
          note: '',
        );

        expect(payment.maxAmount, isNull);
      });
    });

    group('formatPayment', () {
      test(r'when payment type is fixed with BRL and daily, it should format with R$ and /dia', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 120,
          maxAmount: 0,
          amountPeriod: JobPaymentAmountPeriod.daily,
          currency: 'BRL',
          note: '',
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
          maxAmount: 0,
          amountPeriod: JobPaymentAmountPeriod.hourly,
          currency: 'USD',
          note: '',
        );

        final result = payment.formatPayment(t);

        expect(result.contains(r'$'), isTrue);
        expect(result.contains('20'), isTrue);
        expect(result.contains('/hora'), isTrue);
      });

      test('when payment type is range, it should show max amount with up-to prefix', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.range,
          minAmount: 150,
          maxAmount: 250,
          amountPeriod: JobPaymentAmountPeriod.daily,
          currency: 'BRL',
          note: '',
        );

        final result = payment.formatPayment(t);

        expect(result.contains('Até'), isTrue);
        expect(result.contains(r'R$'), isTrue);
        expect(result.contains('250'), isTrue);
        expect(result.contains('150'), isFalse);
        expect(result.contains(' - '), isFalse);
        expect(result.contains('/dia'), isTrue);
      });

      test('when payment type is flexible, it should return "Negociável"', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.flexible,
          amountPeriod: JobPaymentAmountPeriod.single,
          currency: 'BRL',
          note: '',
        );

        final result = payment.formatPayment(t);

        expect(result, equals('Negociável'));
      });

      test('when payment type is other, it should return "Outro"', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.other,
          amountPeriod: JobPaymentAmountPeriod.monthly,
          currency: 'BRL',
          note: '',
        );

        final result = payment.formatPayment(t);

        expect(result, equals('Outro'));
      });

      test('when payment type is unknown, it should return "Desconhecido"', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.unknown,
          amountPeriod: JobPaymentAmountPeriod.daily,
          currency: 'BRL',
          note: '',
        );

        final result = payment.formatPayment(t);

        expect(result, equals('Desconhecido'));
      });

      test('when amount is an integer, it should have no decimal places', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 120,
          maxAmount: 0,
          amountPeriod: JobPaymentAmountPeriod.single,
          currency: 'BRL',
          note: '',
        );

        final result = payment.formatPayment(t);

        expect(result.contains(','), isFalse);
      });

      test('when amount is fractional, it should show decimal places', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 150.5,
          maxAmount: 0,
          amountPeriod: JobPaymentAmountPeriod.single,
          currency: 'BRL',
          note: '',
        );

        final result = payment.formatPayment(t);

        expect(result.contains(','), isTrue);
      });

      test('when amount period is single, it should have no period suffix', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 100,
          maxAmount: 0,
          amountPeriod: JobPaymentAmountPeriod.single,
          currency: 'BRL',
          note: '',
        );

        final result = payment.formatPayment(t);

        expect(result.contains('/'), isFalse);
      });

      test('when amount period is unknown, it should have no period suffix', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 100,
          maxAmount: 0,
          amountPeriod: JobPaymentAmountPeriod.unknown,
          currency: 'BRL',
          note: '',
        );

        final result = payment.formatPayment(t);

        expect(result.contains('/'), isFalse);
      });

      test('when payment type is range with fractional max, it should show decimal places', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.range,
          minAmount: 150,
          maxAmount: 250.5,
          amountPeriod: JobPaymentAmountPeriod.single,
          currency: 'BRL',
          note: '',
        );

        final result = payment.formatPayment(t);

        expect(result.contains('Até'), isTrue);
        expect(result.contains('250,50'), isTrue);
      });

      test('when note is provided, it should be accessible', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 100,
          maxAmount: 0,
          amountPeriod: JobPaymentAmountPeriod.single,
          currency: 'BRL',
          note: 'Urgente',
        );

        expect(payment.note, 'Urgente');
      });
    });
  });
}
