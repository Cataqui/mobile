import 'package:cataqui_app/core/app_router/app_route_data.dart';
import 'package:cataqui_app/views/me/me_view.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'me_route.g.dart';

@TypedGoRoute<MeRoute>(path: '/me')
class MeRoute extends AppRouteData with $MeRoute {
  const MeRoute();

  @override
  bool get requiresAuthentication => true;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return MateoPage<void>(
      allowSnapshotting: false,
      key: state.pageKey,
      transition: const .slide(direction: .up),
      child: const MeView(),
    );
  }
}
