import 'package:cataqui_app/views/create_job/location/create_job_location_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'create_job_location_route.g.dart';

@TypedGoRoute<CreateJobLocationRoute>(path: '/create-job/:jobId/location')
class CreateJobLocationRoute extends GoRouteData with $CreateJobLocationRoute {
  const CreateJobLocationRoute({required this.jobId});

  final String jobId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return CustomTransitionPage<void>(
      key: state.pageKey,
      opaque: true,
      barrierColor: context.mateo.colorScheme.background,
      barrierDismissible: false,
      transitionDuration: disableAnimations ? Duration.zero : const Duration(milliseconds: 300),
      reverseTransitionDuration: disableAnimations ? Duration.zero : const Duration(milliseconds: 300),
      child: CreateJobLocationView(key: const ValueKey('create_job_location_view'), jobId: jobId),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }
}
