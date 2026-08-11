import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/whatsapp_login_button/whatsapp_login_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import 'whatsapp_login_button_test_helpers.dart';

void main() {
  late MockAuthRepository authRepository;
  late MockWhatsapp whatsapp;
  late Translations i18n;

  setUp(() {
    authRepository = MockAuthRepository();
    whatsapp = MockWhatsapp();
    i18n = AppLocale.ptBr.buildSync();
    WhatsappLoginButtonTestHelpers.stubSuccessfulRegistration(authRepository: authRepository, whatsapp: whatsapp);
    WhatsappLoginButtonTestHelpers.stubSuccessfulExchange(authRepository: authRepository);
  });

  group('WhatsappLoginButton', () {
    testWidgets('when the button is resting, it should show the localized WhatsApp login label', (tester) async {
      await WhatsappLoginButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (_) {},
      );
      final button = tester.widget<MateoButton>(find.byKey(WhatsappLoginButtonTestHelpers.buttonKey));

      expect(button.label, i18n.whatsappLoginButton.label);
    });

    testWidgets('when WhatsApp opens and the person has not returned, it should keep the button loading', (
      tester,
    ) async {
      await WhatsappLoginButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (_) {},
      );

      await WhatsappLoginButtonTestHelpers.startLogin(tester: tester);

      expect(tester.widget<MateoButton>(find.byKey(WhatsappLoginButtonTestHelpers.buttonKey)).isLoading, isTrue);
    });

    testWidgets(
      'when login remains incomplete after returning from WhatsApp, it should wait three seconds before showing that it is being checked',
      (tester) async {
        final exchangeCompleter = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
        when(
          () => authRepository.exchangeInboundMessageAuthIntent(
            intentToken: WhatsappLoginButtonTestHelpers.intentToken,
            timeoutStart: any(named: 'timeoutStart'),
          ),
        ).thenAnswer((_) => exchangeCompleter.future);
        await WhatsappLoginButtonTestHelpers.pumpButton(
          tester: tester,
          authRepository: authRepository,
          whatsapp: whatsapp,
          onSuccess: (_) {},
        );
        await WhatsappLoginButtonTestHelpers.startLogin(tester: tester);

        await WhatsappLoginButtonTestHelpers.resumeApp(tester: tester);
        await tester.pump(WhatsappLoginButton.checkingToastDelay - const Duration(milliseconds: 1));
        final checkingToastCountBeforeDelay = find.text(i18n.whatsappLoginButton.checking).evaluate().length;
        await tester.pump(const Duration(milliseconds: 1));

        expect(
          (
            beforeDelay: checkingToastCountBeforeDelay,
            afterDelay: find.text(i18n.whatsappLoginButton.checking).evaluate().length,
          ),
          (beforeDelay: 0, afterDelay: 1),
        );
      },
    );

    testWidgets(
      'when login is still being checked and the person taps the checking message, it should remain visible',
      (tester) async {
        final exchangeCompleter = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
        when(
          () => authRepository.exchangeInboundMessageAuthIntent(
            intentToken: WhatsappLoginButtonTestHelpers.intentToken,
            timeoutStart: any(named: 'timeoutStart'),
          ),
        ).thenAnswer((_) => exchangeCompleter.future);

        await WhatsappLoginButtonTestHelpers.pumpButton(
          tester: tester,
          authRepository: authRepository,
          whatsapp: whatsapp,
          onSuccess: (_) {},
        );

        await WhatsappLoginButtonTestHelpers.startLogin(tester: tester);
        await WhatsappLoginButtonTestHelpers.resumeApp(tester: tester);
        await tester.pump(WhatsappLoginButton.checkingToastDelay);

        await tester.tap(find.byKey(const Key('mateo_toast_surface')));
        await tester.pump();

        expect(find.text(i18n.whatsappLoginButton.checking), findsOneWidget);
      },
    );

    testWidgets('when login preparation fails, it should show an error and enable another attempt', (tester) async {
      when(
        () => authRepository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp),
      ).thenThrow(StateError('registration failed'));
      await WhatsappLoginButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (_) {},
      );

      await tester.tap(find.byKey(WhatsappLoginButtonTestHelpers.buttonKey));
      await tester.pump();
      final button = tester.widget<MateoButton>(find.byKey(WhatsappLoginButtonTestHelpers.buttonKey));

      expect(
        (errorToast: find.text(i18n.whatsappLoginButton.error).evaluate().length, enabled: button.onPressed != null),
        (errorToast: 1, enabled: true),
      );
    });

    testWidgets('when login succeeds after returning from WhatsApp, it should show the success toast', (tester) async {
      await WhatsappLoginButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (_) {},
      );
      await WhatsappLoginButtonTestHelpers.startLogin(tester: tester);

      await WhatsappLoginButtonTestHelpers.resumeApp(tester: tester);
      await tester.pump();

      expect(find.text(i18n.whatsappLoginButton.success), findsOneWidget);
    });

    testWidgets(
      'when login succeeds within three seconds of returning from WhatsApp, it should not show a late checking toast',
      (tester) async {
        await WhatsappLoginButtonTestHelpers.pumpButton(
          tester: tester,
          authRepository: authRepository,
          whatsapp: whatsapp,
          onSuccess: (_) {},
        );
        await WhatsappLoginButtonTestHelpers.startLogin(tester: tester);

        await WhatsappLoginButtonTestHelpers.resumeApp(tester: tester);
        await tester.pump(WhatsappLoginButton.checkingToastDelay);

        expect(find.text(i18n.whatsappLoginButton.checking), findsNothing);
      },
    );

    testWidgets('when login succeeds, it should deliver the complete authenticated session', (tester) async {
      AuthSessionDto? deliveredSession;
      await WhatsappLoginButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (session) => deliveredSession = session,
      );
      await WhatsappLoginButtonTestHelpers.startLogin(tester: tester);

      await WhatsappLoginButtonTestHelpers.resumeApp(tester: tester);
      await tester.pump();

      expect(deliveredSession, WhatsappLoginButtonTestHelpers.authSession);
    });

    testWidgets('when the app resumes twice after login succeeds, it should deliver the session only once', (
      tester,
    ) async {
      var successCount = 0;
      await WhatsappLoginButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (_) => successCount += 1,
      );
      await WhatsappLoginButtonTestHelpers.startLogin(tester: tester);

      await WhatsappLoginButtonTestHelpers.resumeApp(tester: tester);
      await WhatsappLoginButtonTestHelpers.resumeApp(tester: tester);
      await tester.pump();

      expect(successCount, 1);
    });

    testWidgets('when the button is disposed while checking login, it should remove the checking toast', (
      tester,
    ) async {
      final exchangeCompleter = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
      when(
        () => authRepository.exchangeInboundMessageAuthIntent(
          intentToken: WhatsappLoginButtonTestHelpers.intentToken,
          timeoutStart: any(named: 'timeoutStart'),
        ),
      ).thenAnswer((_) => exchangeCompleter.future);
      await WhatsappLoginButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (_) {},
      );
      await WhatsappLoginButtonTestHelpers.startLogin(tester: tester);
      await WhatsappLoginButtonTestHelpers.resumeApp(tester: tester);
      await tester.pump(WhatsappLoginButton.checkingToastDelay);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(find.text(i18n.whatsappLoginButton.checking), findsNothing);
    });
  });
}
