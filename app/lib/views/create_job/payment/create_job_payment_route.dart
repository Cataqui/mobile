import 'dart:async';

import 'package:cataqui_app/views/create_job/payment/create_job_payment_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'create_job_payment_route.g.dart';

@TypedGoRoute<CreateJobPaymentRoute>(path: '/create-job/:jobId/payment')
class CreateJobPaymentRoute extends GoRouteData with $CreateJobPaymentRoute {
  const CreateJobPaymentRoute({required this.jobId});

  final String jobId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    unawaited(CreateJobPaymentView.precacheImages(context));
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return CustomTransitionPage<void>(
      key: state.pageKey,
      opaque: true,
      barrierColor: context.mateo.colorScheme.background,
      barrierDismissible: false,
      transitionDuration: disableAnimations ? Duration.zero : const Duration(milliseconds: 300),
      reverseTransitionDuration: disableAnimations ? Duration.zero : const Duration(milliseconds: 300),
      child: CreateJobPaymentView(key: const ValueKey('create_job_payment_view'), jobId: jobId),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }
}
