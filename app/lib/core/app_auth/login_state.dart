import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/notp_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_state.g.dart';

@riverpod
class LoginState extends _$LoginState {
  static const _exchangeIntentTimeout = Duration(seconds: 30);

  bool _isExchangeActive = false;

  @override
  AsyncValue<AuthSessionDto?> build() => const AsyncData(null);

  bool get isExchangingNotpIntent => _isExchangeActive;

  Future<void> loginWithWhatsapp({required Future<void> appReturn}) async {
    try {
      if (state.isLoading) return;

      _isExchangeActive = false;
      state = const AsyncLoading();

      final intent = (await ref.read(authRepositoryProvider).createNotpIntent(channel: .whatsapp)).data;
      if (!ref.mounted) return;

      final didOpenWhatsapp = await ref
          .read(whatsappProvider(identifier: intent.codeReceiver))
          .chat(message: ref.read(translationProvider).whatsappLoginButton.message(code: intent.code));

      if (!didOpenWhatsapp) throw StateError('WhatsApp could not be opened.');
      if (!ref.mounted) return;

      _isExchangeActive = true;
      unawaited(_exchangeNotpIntent(intentToken: intent.intentToken, appReturn: appReturn));
    } on Object catch (error, stackTrace) {
      if (!ref.mounted) return;

      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> _exchangeNotpIntent({required String intentToken, required Future<void> appReturn}) async {
    try {
      final issuedSession = await _waitForIssuedSession(intentToken: intentToken, appReturn: appReturn);
      if (issuedSession == null) return;

      final session = AuthSessionDto.fromIssuedAuthSession(issuedSession);
      await appReturn;

      if (!ref.mounted) return;

      _isExchangeActive = false;

      await ref.read(appAuthStateProvider.notifier).setSession(session);
      if (!ref.mounted) return;

      state = AsyncData(session);
    } on Object catch (error, stackTrace) {
      await appReturn;
      if (!ref.mounted) return;

      _isExchangeActive = false;
      state = AsyncError(error, stackTrace);
    }
  }

  Future<IssuedAuthSessionDto?> _waitForIssuedSession({
    required String intentToken,
    required Future<void> appReturn,
  }) async {
    DateTime? exchangeDeadline;
    unawaited(
      appReturn.then((_) {
        exchangeDeadline = clock.now().add(_exchangeIntentTimeout);
      }),
    );

    while (ref.mounted) {
      final envelope = await ref.read(authRepositoryProvider).exchangeNotpIntent(intentToken: intentToken);
      if (!ref.mounted) return null;

      switch (envelope.data) {
        case PendingNotpIntentExchangeDto(:final retryAfterSeconds):
          await Future<void>.delayed(Duration(seconds: retryAfterSeconds));
          if (!ref.mounted) return null;

          final deadline = exchangeDeadline;
          if (deadline != null && !clock.now().isBefore(deadline)) {
            throw TimeoutException(
              'NOTP intent exchange did not complete within $_exchangeIntentTimeout.',
              _exchangeIntentTimeout,
            );
          }

        case final IssuedAuthSessionDto session:
          return session;
      }
    }

    return null;
  }
}
