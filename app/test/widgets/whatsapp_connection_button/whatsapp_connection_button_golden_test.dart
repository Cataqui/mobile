import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/created_notp_intent_dto.dart';
import 'package:cataqui_app/core/dtos/notp_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:cataqui_app/widgets/whatsapp_connection_button/whatsapp_connection_button.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import 'whatsapp_connection_button_test_helpers.dart';

void main() {
  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
      late MockAuthRepository authRepository;
      late MockWhatsapp whatsapp;

      setUp(() {
        authRepository = MockAuthRepository();
        whatsapp = MockWhatsapp();
        WhatsappConnectionButtonTestHelpers.stubSuccessfulRegistration(
          authRepository: authRepository,
          whatsapp: whatsapp,
        );
        WhatsappConnectionButtonTestHelpers.stubSuccessfulExchange(authRepository: authRepository);
      });

      group('WhatsappConnectionButton Golden Tests', () {
        goldenTest(
          'when the WhatsApp connection button is resting, it should match the approved appearance',
          fileName: 'whatsapp_connection_button_resting',
          constraints: const BoxConstraints.tightFor(width: 390, height: 220),
          builder: () =>
              WhatsappConnectionButtonTestHelpers.goldenScenario(authRepository: authRepository, whatsapp: whatsapp),
        );

        goldenTest(
          'when preparing WhatsApp connection, it should match the approved loading appearance',
          fileName: 'whatsapp_connection_button_loading',
          constraints: const BoxConstraints.tightFor(width: 390, height: 220),
          whilePerforming: (tester) async {
            when(
              () => authRepository.createNotpIntent(channel: AuthChannel.whatsapp),
            ).thenAnswer((_) => Completer<ApiEnvelopeDto<CreatedNotpIntentDto>>().future);
            await tester.tap(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey));
            await tester.pump();

            return null;
          },
          builder: () =>
              WhatsappConnectionButtonTestHelpers.goldenScenario(authRepository: authRepository, whatsapp: whatsapp),
        );

        goldenTest(
          'when returning from WhatsApp, it should match the approved checking feedback',
          fileName: 'whatsapp_connection_button_checking',
          constraints: const BoxConstraints.tightFor(width: 390, height: 220),
          whilePerforming: (tester) async {
            final exchangeCompleter = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
            when(
              () => authRepository.exchangeNotpIntent(intentToken: WhatsappConnectionButtonTestHelpers.intentToken),
            ).thenAnswer((_) => exchangeCompleter.future);
            await WhatsappConnectionButtonTestHelpers.startConnection(tester: tester);
            await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
            await tester.pump(WhatsappConnectionButton.checkingToastDelay);

            return null;
          },
          builder: () =>
              WhatsappConnectionButtonTestHelpers.goldenScenario(authRepository: authRepository, whatsapp: whatsapp),
        );

        goldenTest(
          'when WhatsApp connection fails, it should match the approved retryable error feedback',
          fileName: 'whatsapp_connection_button_error',
          constraints: const BoxConstraints.tightFor(width: 390, height: 220),
          whilePerforming: (tester) async {
            when(
              () => authRepository.createNotpIntent(channel: AuthChannel.whatsapp),
            ).thenThrow(StateError('registration failed'));
            await tester.tap(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey));
            await tester.pump();

            return null;
          },
          builder: () =>
              WhatsappConnectionButtonTestHelpers.goldenScenario(authRepository: authRepository, whatsapp: whatsapp),
        );

        goldenTest(
          'when WhatsApp connection succeeds, it should match the approved authenticated feedback',
          fileName: 'whatsapp_connection_button_success',
          constraints: const BoxConstraints.tightFor(width: 390, height: 220),
          whilePerforming: (tester) async {
            await WhatsappConnectionButtonTestHelpers.startConnection(tester: tester);
            await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
            await tester.pump();

            return null;
          },
          builder: () =>
              WhatsappConnectionButtonTestHelpers.goldenScenario(authRepository: authRepository, whatsapp: whatsapp),
        );
      });
    },
  );
}
