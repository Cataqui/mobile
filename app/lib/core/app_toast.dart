import 'package:cataqui_app/core/network/auth_interceptor/authentication_dismissed_dio_exception.dart';
import 'package:flutter/widgets.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class AppToast {
  const AppToast();

  void maybeShowError(
    BuildContext context, {
    required Object? error,
    required String message,
    MateoToastIconBuilder? iconBuilder,
  }) {
    if (error is AuthenticationDismissedDioException) return;

    MateoToast.show(context, message: message, type: MateoToastType.error, iconBuilder: iconBuilder);
  }

  void showSuccess(BuildContext context, {required String message}) {
    MateoToast.show(context, message: message, type: MateoToastType.success);
  }

  void showInfo(
    BuildContext context, {
    required String message,
    MateoToastIconBuilder? iconBuilder,
    Duration? duration,
    bool dismissible = true,
  }) {
    MateoToast.show(
      context,
      message: message,
      type: MateoToastType.info,
      iconBuilder: iconBuilder,
      duration: duration,
      dismissible: dismissible,
    );
  }
}
