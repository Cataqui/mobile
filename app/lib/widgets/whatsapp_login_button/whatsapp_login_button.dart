import 'dart:async';

import 'package:cataqui_app/core/app_auth/login_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/network/rate_limit/rate_limited_dio_exception.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class WhatsappLoginButton extends ConsumerStatefulWidget {
  const WhatsappLoginButton({required this.onSuccess, super.key});

  static const checkingToastDelay = Duration(seconds: 3);

  final void Function(AuthSessionDto session) onSuccess;

  @override
  ConsumerState<WhatsappLoginButton> createState() => _WhatsappLoginButtonState();
}

class _WhatsappLoginButtonState extends ConsumerState<WhatsappLoginButton> with WidgetsBindingObserver {
  Timer? _checkingToastTimer;
  Completer<void>? _appReturnCompleter;
  VoidCallback? _dismissCheckingToast;

  void _startLogin() {
    final appReturn = Completer<void>();
    _appReturnCompleter = appReturn;

    unawaited(ref.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future));
  }

  void _cancelCheckingToastTimer() {
    _checkingToastTimer?.cancel();
    _checkingToastTimer = null;
  }

  void _scheduleCheckingToast() {
    _cancelCheckingToastTimer();

    _checkingToastTimer = Timer(WhatsappLoginButton.checkingToastDelay, () {
      _checkingToastTimer = null;
      if (!mounted) return;

      final loginState = ref.read(loginStateProvider.notifier);
      if (!loginState.isExchangingNotpIntent) return;

      final toastContext = Navigator.of(context, rootNavigator: true).context;

      _dismissCheckingToast = () {
        if (toastContext.mounted) dismissMateoToast(context: toastContext);
      };

      ref
          .read(appToastProvider)
          .showLoading(
            context,
            message: ref.read(translationProvider).whatsappLoginButton.checking,
            duration: const Duration(days: 365),
            dismissible: false,
          );
    });
  }

  void _handleStateChange(AsyncValue<AuthSessionDto?>? previous, AsyncValue<AuthSessionDto?> next) {
    next.when(
      data: (session) {
        if (session == null) return;

        _cancelCheckingToastTimer();
        _appReturnCompleter = null;
        _dismissCheckingToast?.call();
        _dismissCheckingToast = null;

        ref
            .read(appToastProvider)
            .showSuccess(context, message: ref.read(translationProvider).whatsappLoginButton.success);

        widget.onSuccess(session);
      },
      error: (error, _) {
        _cancelCheckingToastTimer();
        _appReturnCompleter = null;
        _dismissCheckingToast?.call();
        _dismissCheckingToast = null;
        final i18n = ref.read(translationProvider);
        ref
            .read(appToastProvider)
            .maybeShowError(
              context,
              error: error,
              message: error is RateLimitedDioException
                  ? i18n.whatsappLoginButton.rateLimited
                  : i18n.whatsappLoginButton.error,
            );
      },
      loading: () {},
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelCheckingToastTimer();
    final dismissCheckingToast = _dismissCheckingToast;
    if (dismissCheckingToast != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => dismissCheckingToast());
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;

    final loginState = ref.read(loginStateProvider.notifier);
    final appReturn = _appReturnCompleter;
    if (!loginState.isExchangingNotpIntent || appReturn == null || appReturn.isCompleted) return;

    appReturn.complete();
    _scheduleCheckingToast();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final isLoading = ref.watch(loginStateProvider.select((state) => state.isLoading));

    ref.listen(loginStateProvider, _handleStateChange);

    return MateoButton(
      presentation: .label(
        variant: .primary,
        width: .fill,
        label: i18n.whatsappLoginButton.label,
        colorScheme: switch (MateoTheme.of(context).brightness) {
          Brightness.light => MateoButtonColorScheme(
            background: const Color(0xFF002002),

            foreground: const Color(0xFF25D366),
            backgroundDisabled: MateoTheme.of(context).palette.neutral[4],
            foregroundDisabled: MateoTheme.of(context).palette.neutral[9],
          ),
          Brightness.dark => throw UnsupportedError('Dark contact-action colors are not supported.'),
        },
        leadingIcon: const MateoIcon(.whatsapp),
      ),
      key: const ValueKey('whatsapp_login_button_action'),
      isLoading: isLoading,
      onPressed: _startLogin,
    );
  }
}
