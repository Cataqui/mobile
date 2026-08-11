import 'dart:async';

import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/widgets/whatsapp_login_button/whatsapp_login_button_state.dart';
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
  VoidCallback? _dismissCheckingToast;
  bool _isCheckingToastVisible = false;

  void _startLogin() {
    unawaited(ref.read(whatsappLoginButtonStateProvider.notifier).openWhatsappWithCode());
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

      final loginState = ref.read(whatsappLoginButtonStateProvider.notifier);
      if (!loginState.isExchangingIntent) return;

      _isCheckingToastVisible = true;
      MateoToast.show(
        context,
        message: ref.read(translationProvider).whatsappLoginButton.checking,
        type: MateoToastType.info,
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
        _isCheckingToastVisible = false;

        MateoToast.show(
          context,
          message: ref.read(translationProvider).whatsappLoginButton.success,
          type: MateoToastType.success,
        );

        widget.onSuccess(session);
      },
      error: (_, __) {
        _cancelCheckingToastTimer();
        _isCheckingToastVisible = false;
        MateoToast.show(context, message: ref.read(translationProvider).whatsappLoginButton.error);
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

    final loginState = ref.read(whatsappLoginButtonStateProvider.notifier);
    if (!loginState.shouldTryExchangeAfterAppResume) return;

    _scheduleCheckingToast();
    unawaited(ref.read(whatsappLoginButtonStateProvider.notifier).exchangeIntent());
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final isLoading = ref.watch(whatsappLoginButtonStateProvider.select((state) => state.isLoading));

    ref.listen(whatsappLoginButtonStateProvider, _handleStateChange);

    return MateoButton(
      key: const ValueKey('whatsapp_login_button_action'),
      variant: MateoButtonVariant.primary,
      fit: MateoButtonFit.expand,
      label: i18n.whatsappLoginButton.label,
      colorScheme: context.mateo.colorScheme.buttons.whatsapp.tertiary,
      leadingIconSpacing: 6,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      isLoading: isLoading,
      onPressed: _startLogin,
      leadingIconBuilder: (state) {
        return MateoIcon.whatsapp(width: 22, height: 22, color: state.foregroundColor);
      },
    );
  }
}
