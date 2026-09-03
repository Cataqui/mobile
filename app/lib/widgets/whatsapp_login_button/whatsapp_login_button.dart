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
  bool _isCheckingToastVisible = false;

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

      _isCheckingToastVisible = true;
      ref
          .read(appToastProvider)
          .showInfo(
            context,
            message: ref.read(translationProvider).whatsappLoginButton.checking,
            iconBuilder: (state) => Center(
              child: MateoCircularLoadingIndicator(
                color: context.mateo.palette.blue[9],
                trackColor: context.mateo.palette.blue[6],
              ),
            ),
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
        _isCheckingToastVisible = false;

        ref
            .read(appToastProvider)
            .showSuccess(context, message: ref.read(translationProvider).whatsappLoginButton.success);

        widget.onSuccess(session);
      },
      error: (error, _) {
        _cancelCheckingToastTimer();
        _appReturnCompleter = null;
        _isCheckingToastVisible = false;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dismissCheckingToast = MateoToastMessenger.maybeOf(context)?.dismissActive;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelCheckingToastTimer();

    if (_isCheckingToastVisible) _dismissCheckingToast?.call();

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
      presentation: MateoButtonPresentation(
        variant: MateoButtonVariant.primary,
        fit: MateoButtonFit.expand,
        label: i18n.whatsappLoginButton.label,
        colorScheme: context.mateo.colorScheme.buttons.whatsapp.tertiary,
        leadingIconSpacing: 6,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        leadingIconBuilder: (state) {
          return MateoIcon.whatsapp(width: 22, height: 22, color: state.foregroundColor);
        },
      ),
      key: const ValueKey('whatsapp_login_button_action'),
      isLoading: isLoading,
      onPressed: _startLogin,
    );
  }
}
