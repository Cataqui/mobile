import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Translations i18n;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
  });

  group('JobPaymentDto', () {
    group('JSON parsing', () {
      test('when parsing a job payment, it should map the minimum amount', () {
        final payment = JobPaymentDto.fromJson(const <String, Object?>{
          'type': 'FIXED',
          'minAmount': 120,
          'maxAmount': 200,
          'amountPeriod': 'SINGLE',
          'currency': 'BRL',
          'note': '',
        });

        expect(payment.minAmount, 120);
      });

      test('when parsing an unknown payment type, it should use other', () {
        final payment = JobPaymentDto.fromJson(const <String, Object?>{
          'type': 'BONUS',
          'minAmount': 120,
          'maxAmount': 200,
          'amountPeriod': 'SINGLE',
          'currency': 'BRL',
          'note': '',
        });

        expect(payment.type, JobPaymentType.other);
      });

      test('when minAmount is missing from JSON, it should default to null', () {
        final payment = JobPaymentDto.fromJson(const <String, Object?>{
          'type': 'FLEXIBLE',
          'amountPeriod': 'SINGLE',
          'currency': 'BRL',
          'note': '',
        });

        expect(payment.minAmount, isNull);
      });

      test('when maxAmount is missing from JSON, it should default to null', () {
        final payment = JobPaymentDto.fromJson(const <String, Object?>{
          'type': 'FLEXIBLE',
          'amountPeriod': 'SINGLE',
          'currency': 'BRL',
          'note': '',
        });

        expect(payment.maxAmount, isNull);
      });

      test('when serializing a job payment, it should use camelCase keys', () {
        final json = JobPaymentDto.fixture().toJson();

        expect(json.keys, containsAll(<String>['amountPeriod', 'minAmount', 'maxAmount']));
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

        final result = payment.formatPayment(i18n);

        expect(result.contains(r'R$'), isTrue);
        expect(result.contains('120'), isTrue);
        expect(result.contains(i18n.jobPayment.paymentPeriodDaily), isTrue);
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

        final result = payment.formatPayment(i18n);

        expect(result.contains(r'$'), isTrue);
        expect(result.contains('20'), isTrue);
        expect(result.contains(i18n.jobPayment.paymentPeriodHourly), isTrue);
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

        final result = payment.formatPayment(i18n);

        expect(result.contains('Até'), isTrue);
        expect(result.contains(r'R$'), isTrue);
        expect(result.contains('250'), isTrue);
        expect(result.contains('150'), isFalse);
        expect(result.contains(' - '), isFalse);
        expect(result.contains(i18n.jobPayment.paymentPeriodDaily), isTrue);
      });

      test('when payment type is flexible, it should return "Negociável"', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.flexible,
          amountPeriod: JobPaymentAmountPeriod.single,
          currency: 'BRL',
          note: '',
        );

        final result = payment.formatPayment(i18n);

        expect(result, equals(i18n.jobPayment.paymentFlexible));
      });

      test('when payment type is other, it should return "Outro"', () {
        const payment = JobPaymentDto(
          type: JobPaymentType.other,
          amountPeriod: JobPaymentAmountPeriod.monthly,
          currency: 'BRL',
          note: '',
        );

        final result = payment.formatPayment(i18n);

        expect(result, equals(i18n.jobPayment.paymentOther));
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

        final result = payment.formatPayment(i18n);

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

        final result = payment.formatPayment(i18n);

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

        final result = payment.formatPayment(i18n);

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

        final result = payment.formatPayment(i18n);

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

        final result = payment.formatPayment(i18n);

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
