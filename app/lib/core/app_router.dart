import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter()
      : _router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const FeedView(),
            ),
          ],
        );

  final GoRouter _router;

  RouterConfig<Object> get routerConfig => _router;

  void go(String location) => _router.go(location);

  Future<T?> push<T extends Object?>(String location) => _router.push<T>(location);

  void pop<T extends Object?>([T? result]) => _router.pop<T>(result);

  bool canPop() => _router.canPop();
}
