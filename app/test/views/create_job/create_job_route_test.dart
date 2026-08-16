import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/description/create_job_description_route.dart';
import 'package:cataqui_app/views/create_job/payment/create_job_payment_route.dart';
import 'package:cataqui_app/views/create_job/payment/create_job_payment_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../utils/test_app.dart';

void main() {
  test('when building the job description location, it should use the description path', () {
    expect(const CreateJobDescriptionRoute().location, '/create-job/description');
  });

  test('when building the payment location, it should nest payment under job creation', () {
    expect(const CreateJobPaymentRoute(jobId: 'draft-job-id').location, '/create-job/draft-job-id/payment');
  });

  testWidgets('when opening payment directly, it should show payment for the requested job', (tester) async {
    const jobId = 'draft-job-id';
    final goRouter = GoRouter(
      initialLocation: const CreateJobPaymentRoute(jobId: jobId).location,
      routes: [$createJobPaymentRoute],
    );
    addTearDown(goRouter.dispose);

    await tester.pumpWidget(
      TestApp.router(
        routerConfig: goRouter,
        providerOverrides: [translationProvider.overrideWithValue(AppLocale.ptBr.buildSync())],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      (tester.widget<CreateJobPaymentView>(find.byType(CreateJobPaymentView)).jobId, goRouter.state.matchedLocation),
      (jobId, const CreateJobPaymentRoute(jobId: jobId).location),
    );
  });
}
