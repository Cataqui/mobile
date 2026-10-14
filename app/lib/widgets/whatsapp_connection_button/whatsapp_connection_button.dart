import 'dart:async';

import 'package:cataqui_app/core/app_auth/whatsapp_connection_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/network/rate_limit/rate_limited_dio_exception.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class WhatsappConnectionButton extends ConsumerStatefulWidget {
  const WhatsappConnectionButton({required this.onSuccess, super.key});

  static const checkingToastDelay = Duration(seconds: 3);

  final void Function(AuthSessionDto session) onSuccess;

  @override
  ConsumerState<WhatsappConnectionButton> createState() => _WhatsappConnectionButtonState();
}

class _WhatsappConnectionButtonState extends ConsumerState<WhatsappConnectionButton> with WidgetsBindingObserver {
  Timer? _checkingToastTimer;
  Completer<void>? _appReturnCompleter;
  VoidCallback? _dismissCheckingToast;

  void _startConnection() {
    if (ref.read(whatsappConnectionStateProvider).isLoading) return;

    final appReturn = Completer<void>();
    _appReturnCompleter = appReturn;

    unawaited(ref.read(whatsappConnectionStateProvider.notifier).connectToWhatsapp(appReturn: appReturn.future));
  }

  void _cancelCheckingToastTimer() {
    _checkingToastTimer?.cancel();
    _checkingToastTimer = null;
  }

  void _scheduleCheckingToast() {
    _cancelCheckingToastTimer();

    _checkingToastTimer = Timer(WhatsappConnectionButton.checkingToastDelay, () {
      _checkingToastTimer = null;
      if (!mounted) return;

      final whatsappConnectionState = ref.read(whatsappConnectionStateProvider.notifier);
      if (!whatsappConnectionState.isExchangingNotpIntent) return;

      final toastContext = Navigator.of(context, rootNavigator: true).context;

      _dismissCheckingToast = () {
        if (toastContext.mounted) dismissMateoToast(context: toastContext);
      };

      ref
          .read(appToastProvider)
          .showLoading(
            context,
            message: ref.read(translationProvider).whatsappConnectionButton.checking,
            duration: const .untilDismissed(),
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
            .showSuccess(context, message: ref.read(translationProvider).whatsappConnectionButton.success);

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
                  ? i18n.whatsappConnectionButton.rateLimited
                  : i18n.whatsappConnectionButton.error,
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

    final appReturn = _appReturnCompleter;
    if (appReturn == null || appReturn.isCompleted) return;

    appReturn.complete();
    _scheduleCheckingToast();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final isLoading = ref.watch(whatsappConnectionStateProvider.select((state) => state.isLoading));

    ref.listen(whatsappConnectionStateProvider, _handleStateChange);

    return MateoButton(
      presentation: .label(
        variant: .primary,
        width: .fill,
        label: i18n.whatsappConnectionButton.label,
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
      key: const ValueKey('whatsapp_connection_button_action'),
      isLoading: isLoading,
      onPressed: _startConnection,
    );
  }
}
