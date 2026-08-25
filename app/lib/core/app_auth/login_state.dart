import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_state.g.dart';

@riverpod
class LoginState extends _$LoginState {
  bool _isExchangeActive = false;

  @override
  AsyncValue<AuthSessionDto?> build() => const AsyncData(null);

  bool get isExchangingNotpIntent => _isExchangeActive;

  Future<void> loginWithWhatsapp({required Future<void> appReturn}) async {
    try {
      if (state.isLoading) return;

      _isExchangeActive = false;
      state = const AsyncLoading();

      final intent = (await ref.read(authRepositoryProvider).createNotpIntent(channel: AuthChannel.whatsapp)).data;

      final didOpenWhatsapp = await ref
          .read(whatsappProvider)
          .launchChat(
            number: intent.codeReceiver,
            message: ref.read(translationProvider).whatsappLoginButton.message(code: intent.code),
          );

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
      final exchangeEnvelope = await ref
          .read(authRepositoryProvider)
          .exchangeNotpIntent(intentToken: intentToken, timeoutStart: appReturn);

      final session = AuthSessionDto.fromIssuedAuthSession(exchangeEnvelope.data);
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
}
