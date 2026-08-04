import 'package:cataqui_app/views/poster_onboarding/poster_onboarding_view/poster_onboarding_view.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'poster_onboarding_route.g.dart';

@TypedGoRoute<PosterOnboardingRoute>(path: '/poster-onboarding')
class PosterOnboardingRoute extends GoRouteData with $PosterOnboardingRoute {
  const PosterOnboardingRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return MateoPage(
      key: state.pageKey,
      child: const PosterOnboardingView(),
      transition: MateoPageTransition.wash(
        direction: MateoPageTransitionDirection.down,
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}
