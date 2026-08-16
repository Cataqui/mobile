import 'package:cataqui_app/views/create_job/payment/create_job_payment_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'create_job_payment_route.g.dart';

@TypedGoRoute<CreateJobPaymentRoute>(path: '/create-job/:jobId/payment')
class CreateJobPaymentRoute extends GoRouteData with $CreateJobPaymentRoute {
  const CreateJobPaymentRoute({required this.jobId});

  static const _transitionDuration = Duration(milliseconds: 400);

  final String jobId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return CustomTransitionPage<void>(
      key: state.pageKey,
      opaque: false,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      transitionDuration: disableAnimations ? Duration.zero : _transitionDuration,
      reverseTransitionDuration: disableAnimations ? Duration.zero : _transitionDuration,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
        child: CreateJobPaymentView(key: const ValueKey('create_job_payment_view'), jobId: jobId),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }
}
