import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_router/app_route_data.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
class AppRouter extends _$AppRouter {
  final Map<String, Future<void>> _activeProtectedNavigations = {};

  @override
  void build() {}

  Future<void> push(BuildContext context, AppRouteData appRoute) {
    return _navigate(context, appRoute, () async {
      unawaited(appRoute.push<void>(context).then<void>((_) {}));
    });
  }

  Future<void> go(BuildContext context, AppRouteData appRoute) {
    return _navigate(context, appRoute, () async => appRoute.go(context));
  }

  Future<void> _navigate(BuildContext context, AppRouteData appRoute, Future<void> Function() navigate) {
    if (!context.mounted) return Future<void>.value();
    if (!appRoute.requiresAuthentication) return navigate();

    final activeNavigation = _activeProtectedNavigations[appRoute.location];
    if (activeNavigation != null) return activeNavigation;

    late final Future<void> navigation;
    navigation = _authenticateAndNavigate(context, navigate).whenComplete(() {
      if (identical(_activeProtectedNavigations[appRoute.location], navigation)) {
        _activeProtectedNavigations.remove(appRoute.location);
      }
    });
    _activeProtectedNavigations[appRoute.location] = navigation;

    return navigation;
  }

  Future<void> _authenticateAndNavigate(BuildContext context, Future<void> Function() navigate) async {
    final appAuthState = ref.read(appAuthStateProvider.notifier);
    if (appAuthState.hasUsableLocalCredentials) {
      if (!appAuthState.hasValidSession) unawaited(appAuthState.refreshSessionInBackground());
      await navigate();
      return;
    }

    late final AuthSessionDto? session;

    try {
      session = await appAuthState.getOrAuthenticateSession();
    } on Object catch (error) {
      final overlayContext = ref.read(rootNavigatorKeyProvider).currentState?.overlay?.context;
      if (overlayContext == null || !overlayContext.mounted) return;

      ref
          .read(appToastProvider)
          .maybeShowError(
            overlayContext,
            error: error,
            message: ref.read(translationProvider).whatsappLoginButton.error,
          );
      return;
    }

    if (session == null || !context.mounted) return;

    await navigate();
  }
}
