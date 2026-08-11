import 'package:cataqui_app/core/auth/auth_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'whatsapp_login_button_state.g.dart';

@riverpod
class WhatsappLoginButtonState extends _$WhatsappLoginButtonState {
  String? _intentToken;
  bool _isExchangeActive = false;

  @override
  AsyncValue<AuthSessionDto?> build() => const AsyncData(null);

  bool get shouldTryExchangeAfterAppResume => _intentToken != null && !_isExchangeActive;
  bool get isExchangingIntent => _isExchangeActive;

  Future<void> openWhatsappWithCode() async {
    try {
      if (state.isLoading) return;

      _intentToken = null;
      _isExchangeActive = false;
      state = const AsyncLoading();

      final intent =
          (await ref.read(authRepositoryProvider).registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp)).data;

      final didOpenWhatsapp = await ref
          .read(whatsappProvider)
          .launchChat(number: intent.codeReceiver, message: intent.code);

      if (!didOpenWhatsapp) throw StateError('WhatsApp could not be opened.');
      if (!ref.mounted) return;

      _intentToken = intent.intentToken;
    } on Object catch (error, stackTrace) {
      if (!ref.mounted) return;

      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> exchangeIntent() async {
    try {
      final intentToken = _intentToken;
      if (intentToken == null || _isExchangeActive) return;

      _isExchangeActive = true;

      final exchangeEnvelope = await ref
          .read(authRepositoryProvider)
          .exchangeInboundMessageAuthIntent(intentToken: intentToken);

      final session = AuthSessionDto.fromIssuedAuthSession(exchangeEnvelope.data);

      if (!ref.mounted) return;

      _intentToken = null;
      _isExchangeActive = false;

      ref.read(authStateProvider.notifier).setSession(session);
      state = AsyncData(session);
    } on Object catch (error, stackTrace) {
      if (!ref.mounted) return;

      _intentToken = null;
      _isExchangeActive = false;
      state = AsyncError(error, stackTrace);
    }
  }
}
