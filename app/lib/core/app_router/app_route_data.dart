import 'package:go_router/go_router.dart';

abstract class AppRouteData extends GoRouteData {
  const AppRouteData();

  bool get requiresAuthentication => false;
}
