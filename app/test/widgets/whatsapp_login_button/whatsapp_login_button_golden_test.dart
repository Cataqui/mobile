import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/dtos/registered_auth_intent_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:cataqui_app/widgets/whatsapp_login_button/whatsapp_login_button.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import 'whatsapp_login_button_test_helpers.dart';

void main() {
  late MockAuthRepository authRepository;
  late MockWhatsapp whatsapp;

  setUp(() {
    authRepository = MockAuthRepository();
    whatsapp = MockWhatsapp();
    WhatsappLoginButtonTestHelpers.stubSuccessfulRegistration(authRepository: authRepository, whatsapp: whatsapp);
    WhatsappLoginButtonTestHelpers.stubSuccessfulExchange(authRepository: authRepository);
  });

  group('WhatsappLoginButton Golden Tests', () {
    goldenTest(
      'when the WhatsApp login button is resting, it should match the approved appearance',
      fileName: 'whatsapp_login_button_resting',
      constraints: const BoxConstraints.tightFor(width: 390, height: 220),
      builder: () => WhatsappLoginButtonTestHelpers.goldenScenario(authRepository: authRepository, whatsapp: whatsapp),
    );

    goldenTest(
      'when preparing WhatsApp login, it should match the approved loading appearance',
      fileName: 'whatsapp_login_button_loading',
      constraints: const BoxConstraints.tightFor(width: 390, height: 220),
      whilePerforming: (tester) async {
        when(
          () => authRepository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp),
        ).thenAnswer((_) => Completer<ApiEnvelopeDto<RegisteredAuthIntentDto>>().future);
        await tester.tap(find.byKey(WhatsappLoginButtonTestHelpers.buttonKey));
        await tester.pump();

        return null;
      },
      builder: () => WhatsappLoginButtonTestHelpers.goldenScenario(authRepository: authRepository, whatsapp: whatsapp),
    );

    goldenTest(
      'when returning from WhatsApp, it should match the approved checking feedback',
      fileName: 'whatsapp_login_button_checking',
      constraints: const BoxConstraints.tightFor(width: 390, height: 220),
      whilePerforming: (tester) async {
        final exchangeCompleter = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
        when(
          () => authRepository.exchangeInboundMessageAuthIntent(
            intentToken: WhatsappLoginButtonTestHelpers.intentToken,
            timeoutStart: any(named: 'timeoutStart'),
          ),
        ).thenAnswer((_) => exchangeCompleter.future);
        await WhatsappLoginButtonTestHelpers.startLogin(tester: tester);
        await WhatsappLoginButtonTestHelpers.resumeApp(tester: tester);
        await tester.pump(WhatsappLoginButton.checkingToastDelay);

        return null;
      },
      builder: () => WhatsappLoginButtonTestHelpers.goldenScenario(authRepository: authRepository, whatsapp: whatsapp),
    );

    goldenTest(
      'when WhatsApp login fails, it should match the approved retryable error feedback',
      fileName: 'whatsapp_login_button_error',
      constraints: const BoxConstraints.tightFor(width: 390, height: 220),
      whilePerforming: (tester) async {
        when(
          () => authRepository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp),
        ).thenThrow(StateError('registration failed'));
        await tester.tap(find.byKey(WhatsappLoginButtonTestHelpers.buttonKey));
        await tester.pump();

        return null;
      },
      builder: () => WhatsappLoginButtonTestHelpers.goldenScenario(authRepository: authRepository, whatsapp: whatsapp),
    );

    goldenTest(
      'when WhatsApp login succeeds, it should match the approved authenticated feedback',
      fileName: 'whatsapp_login_button_success',
      constraints: const BoxConstraints.tightFor(width: 390, height: 220),
      whilePerforming: (tester) async {
        await WhatsappLoginButtonTestHelpers.startLogin(tester: tester);
        await WhatsappLoginButtonTestHelpers.resumeApp(tester: tester);
        await tester.pump();

        return null;
      },
      builder: () => WhatsappLoginButtonTestHelpers.goldenScenario(authRepository: authRepository, whatsapp: whatsapp),
    );
  });
}
