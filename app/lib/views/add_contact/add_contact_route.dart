import 'package:cataqui_app/core/app_router/app_route_data.dart';
import 'package:cataqui_app/views/add_contact/add_contact_view.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'add_contact_route.g.dart';

@TypedGoRoute<AddContactRoute>(path: '/add-contact')
class AddContactRoute extends AppRouteData with $AddContactRoute {
  const AddContactRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return MateoPage<void>(
      key: state.pageKey,
      transition: const .slide(direction: .up),
      child: const AddContactView(),
    );
  }
}
