import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/registered_auth_intent_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/whatsapp_login_button/whatsapp_login_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';

abstract final class WhatsappLoginButtonTestHelpers {
  static const intentToken = 'kJ3YFf0SYkZp6gWlMTq3up5ELXWRw_zTuF8j0M5tJgI';
  static const code = 'AUTH-K7F9Q2M8VD';
  static const codeReceiver = '5511988887777';
  static const buttonKey = ValueKey('whatsapp_login_button_action');

  static final registeredIntentEnvelope = ApiEnvelopeDto.fixture(
    data: RegisteredAuthIntentDto.fixture().copyWith(intentToken: intentToken, code: code, codeReceiver: codeReceiver),
  );
  static final IssuedAuthSessionDto issuedSession =
      AuthIntentExchangeResultDto.issuedSessionFixture() as IssuedAuthSessionDto;
  static final issuedSessionEnvelope = ApiEnvelopeDto.fixture(data: issuedSession);
  static final authSession = AuthSessionDto.fromIssuedAuthSession(issuedSession);

  static Future<void> pumpButton({
    required WidgetTester tester,
    required MockAuthRepository authRepository,
    required MockWhatsapp whatsapp,
    required void Function(AuthSessionDto session) onSuccess,
  }) async {
    await tester.pumpWidget(
      TestApp(
        mediaQueryData: const MediaQueryData(disableAnimations: true),
        providerOverrides: [
          translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
          authRepositoryProvider.overrideWithValue(authRepository),
          whatsappProvider.overrideWithValue(whatsapp),
        ],
        child: SizedBox(width: 342, child: WhatsappLoginButton(onSuccess: onSuccess)),
      ),
    );
    await tester.pumpAndSettle();
  }

  static Widget goldenScenario({required MockAuthRepository authRepository, required MockWhatsapp whatsapp}) {
    return SizedBox(
      width: 390,
      height: 220,
      child: TestApp(
        mediaQueryData: const MediaQueryData(size: Size(390, 220), disableAnimations: true),
        providerOverrides: [
          translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
          authRepositoryProvider.overrideWithValue(authRepository),
          whatsappProvider.overrideWithValue(whatsapp),
        ],
        child: const SizedBox(width: 342, child: WhatsappLoginButton(onSuccess: _ignoreSession)),
      ),
    );
  }

  static void stubSuccessfulRegistration({required MockAuthRepository authRepository, required MockWhatsapp whatsapp}) {
    when(
      () => authRepository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp),
    ).thenAnswer((_) async => registeredIntentEnvelope);
    when(() => whatsapp.launchChat(number: codeReceiver, message: code)).thenAnswer((_) async => true);
  }

  static void stubSuccessfulExchange({required MockAuthRepository authRepository}) {
    when(
      () => authRepository.exchangeInboundMessageAuthIntent(
        intentToken: intentToken,
        timeoutStart: any(named: 'timeoutStart'),
      ),
    ).thenAnswer((_) async => issuedSessionEnvelope);
  }

  static Future<void> startLogin({required WidgetTester tester}) async {
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();
  }

  static Future<void> resumeApp({required WidgetTester tester}) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  }

  static void _ignoreSession(AuthSessionDto session) {}
}
