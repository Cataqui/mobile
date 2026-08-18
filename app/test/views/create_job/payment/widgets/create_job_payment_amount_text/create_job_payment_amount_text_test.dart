import 'package:flutter_test/flutter_test.dart';

import 'create_job_payment_amount_text_test_host.dart';

void main() {
  testWidgets('when the currency is US dollars, it should expose the localized dollar amount', (tester) async {
    await tester.pumpWidget(CreateJobPaymentAmountTextTestHost.buildApp(initialAmount: '1,200', currencyCode: 'USD'));
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();

    expect(find.bySemanticsLabel(r'$ 1,200'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('when the default zero changes to a non-zero digit, it should expose the new amount', (tester) async {
    await tester.pumpWidget(CreateJobPaymentAmountTextTestHost.buildApp(initialAmount: '0'));
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();

    await CreateJobPaymentAmountTextTestHost.updateAmount(tester, amount: '5');
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(r'R$ 5'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('when reduced motion is enabled, it should immediately expose an updated amount', (tester) async {
    await tester.pumpWidget(
      CreateJobPaymentAmountTextTestHost.buildApp(initialAmount: '1,200', disableAnimations: true),
    );
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();

    await CreateJobPaymentAmountTextTestHost.updateAmount(tester, amount: '12,001');

    expect(find.bySemanticsLabel(r'R$ 12,001'), findsOneWidget);
    semantics.dispose();
  });
}
