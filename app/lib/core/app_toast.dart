import 'package:cataqui_app/core/network/auth_interceptor/authentication_dismissed_dio_exception.dart';
import 'package:flutter/widgets.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class AppToast {
  const AppToast();

  void maybeShowError(BuildContext context, {required Object? error, required String message, Widget? icon}) {
    if (error is AuthenticationDismissedDioException) return;

    showMateoToast(
      context: context,
      toast: MateoToast(message: message, status: .error, icon: icon),
    );
  }

  void showSuccess(BuildContext context, {required String message}) {
    showMateoToast(
      context: context,
      toast: MateoToast(message: message, status: .success),
    );
  }

  void showInfo(
    BuildContext context, {
    required String message,
    Widget? icon,
    Duration? duration,
    bool dismissible = true,
  }) {
    showMateoToast(
      context: context,
      toast: MateoToast(message: message, status: .info, icon: icon),
      duration: duration,
      dismissible: dismissible,
    );
  }

  void showLoading(BuildContext context, {required String message, Duration? duration, bool dismissible = true}) {
    showMateoToast(
      context: context,
      toast: MateoToast(message: message, status: .loading),
      duration: duration,
      dismissible: dismissible,
    );
  }
}
