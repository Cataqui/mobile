import 'package:cataqui_app/views/onboarding/onboarding_view.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

part 'onboarding_route.g.dart';

@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  const OnboardingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const OnboardingView();
}
