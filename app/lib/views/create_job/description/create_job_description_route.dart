import 'package:cataqui_app/views/create_job/description/create_job_description_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'create_job_description_route.g.dart';

@TypedGoRoute<CreateJobDescriptionRoute>(path: '/create-job/description')
class CreateJobDescriptionRoute extends GoRouteData with $CreateJobDescriptionRoute {
  const CreateJobDescriptionRoute();

  static const pushDuration = Duration(milliseconds: 340);
  static const popDuration = Duration(milliseconds: 320);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return CustomTransitionPage<void>(
      key: state.pageKey,
      opaque: false,
      barrierColor: context.mateo.colorScheme.overlay.scrim,
      barrierDismissible: false,
      transitionDuration: disableAnimations ? Duration.zero : pushDuration,
      reverseTransitionDuration: disableAnimations ? Duration.zero : popDuration,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
        child: const CreateJobDescriptionView(),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final position = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic));

        return SlideTransition(position: position, child: child);
      },
    );
  }
}
