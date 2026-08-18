import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateJobData', () {
    test('when description creation starts, it should not contain description text', () {
      const data = CreateJobData(currencyCode: 'BRL');

      expect(data.descriptionText, isNull);
    });

    test('when copying with raw description text, it should preserve the text exactly', () {
      const data = CreateJobData(currencyCode: 'BRL');

      expect(data.copyWith(descriptionText: '  descrição original  ').descriptionText, '  descrição original  ');
    });

    test('when job creation starts, it should use zero as the minimum payment amount', () {
      const data = CreateJobData(currencyCode: 'BRL');

      expect(data.paymentMinimumAmount, '0');
    });

    test('when job creation starts, it should use zero as the maximum payment amount', () {
      const data = CreateJobData(currencyCode: 'BRL');

      expect(data.paymentMaximumAmount, '0');
    });

    test('when job creation starts, it should not be creating a draft', () {
      const data = CreateJobData(currencyCode: 'BRL');

      expect(data.isCreatingDraft, isFalse);
    });

    test('when the currency code is BRL in Portuguese, it should resolve the Brazilian real symbol', () {
      const data = CreateJobData(currencyCode: 'BRL');

      expect(data.currencySymbol(AppLocale.ptBr.buildSync()), r'R$');
    });

    test('when the currency code is USD in Portuguese, it should resolve the US dollar symbol', () {
      const data = CreateJobData(currencyCode: 'USD');

      expect(data.currencySymbol(AppLocale.ptBr.buildSync()), r'$');
    });
  });
}
