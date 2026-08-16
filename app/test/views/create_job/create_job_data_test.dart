import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateJobData', () {
    test('when description creation starts, it should not contain description text', () {
      const data = CreateJobData(currencyHint: 'BRL');

      expect(data.descriptionText, isNull);
    });

    test('when copying with raw description text, it should preserve the text exactly', () {
      const data = CreateJobData(currencyHint: 'BRL');

      expect(data.copyWith(descriptionText: '  descrição original  ').descriptionText, '  descrição original  ');
    });

    test('when job creation starts, it should use the default payment amount', () {
      const data = CreateJobData(currencyHint: 'BRL');

      expect(data.paymentAmount, '0');
    });

    test('when job creation starts, it should not be creating a draft', () {
      const data = CreateJobData(currencyHint: 'BRL');

      expect(data.isCreatingDraft, isFalse);
    });

    test('when the currency hint is BRL in Portuguese, it should resolve the Brazilian real symbol', () {
      const data = CreateJobData(currencyHint: 'BRL');

      expect(data.currencySymbol(AppLocale.ptBr.buildSync()), r'R$');
    });

    test('when the currency hint is USD in Portuguese, it should resolve the US dollar symbol', () {
      const data = CreateJobData(currencyHint: 'USD');

      expect(data.currencySymbol(AppLocale.ptBr.buildSync()), r'$');
    });
  });
}
