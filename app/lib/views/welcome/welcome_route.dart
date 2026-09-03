import 'dart:async';

import 'package:cataqui_app/core/app_router/app_route_data.dart';
import 'package:cataqui_app/views/welcome/welcome_view/welcome_view.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'welcome_route.g.dart';

@TypedGoRoute<WelcomeRoute>(path: '/welcome')
class WelcomeRoute extends AppRouteData with $WelcomeRoute {
  const WelcomeRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    unawaited(WelcomeView.precacheImages(context));
    return MateoPage(key: state.pageKey, maintainState: false, child: const WelcomeView());
  }
}
