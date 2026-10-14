import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/notp_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:cataqui_app/core/network/rate_limit/rate_limited_dio_exception.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/whatsapp_connection_button/whatsapp_connection_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import 'whatsapp_connection_button_test_helpers.dart';

void main() {
  late MockAuthRepository authRepository;
  late MockWhatsapp whatsapp;
  late Translations i18n;

  setUp(() {
    authRepository = MockAuthRepository();
    whatsapp = MockWhatsapp();
    i18n = AppLocale.ptBr.buildSync();
    WhatsappConnectionButtonTestHelpers.stubSuccessfulRegistration(authRepository: authRepository, whatsapp: whatsapp);
    WhatsappConnectionButtonTestHelpers.stubSuccessfulExchange(authRepository: authRepository);
  });

  group('WhatsappConnectionButton', () {
    testWidgets('when the button is resting, it should show the localized WhatsApp connection label', (tester) async {
      await WhatsappConnectionButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (_) {},
      );
      expect(
        find.descendant(
          of: find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey),
          matching: find.text('Conectar WhatsApp'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('when WhatsApp opens and the person has not returned, it should keep the button loading', (
      tester,
    ) async {
      await WhatsappConnectionButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (_) {},
      );

      await WhatsappConnectionButtonTestHelpers.startConnection(tester: tester);

      expect(tester.widget<MateoButton>(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey)).isLoading, isTrue);
    });

    testWidgets('when the app resumes before WhatsApp launch completes, it should still complete connection', (
      tester,
    ) async {
      final whatsappLaunch = Completer<bool>();
      when(
        () => whatsapp.chat(message: WhatsappConnectionButtonTestHelpers.message),
      ).thenAnswer((_) => whatsappLaunch.future);
      AuthSessionDto? authenticatedSession;
      await WhatsappConnectionButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (session) => authenticatedSession = session,
      );
      await WhatsappConnectionButtonTestHelpers.startConnection(tester: tester);

      await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
      whatsappLaunch.complete(true);
      await tester.pumpAndSettle();

      expect(authenticatedSession, WhatsappConnectionButtonTestHelpers.authSession);
    });

    testWidgets(
      'when the connection button is tapped twice before rebuilding, it should keep the active return signal',
      (tester) async {
        AuthSessionDto? authenticatedSession;
        await WhatsappConnectionButtonTestHelpers.pumpButton(
          tester: tester,
          authRepository: authRepository,
          whatsapp: whatsapp,
          onSuccess: (session) => authenticatedSession = session,
        );

        await tester.tap(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey));
        await tester.tap(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey));
        await tester.pumpAndSettle();
        await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
        await tester.pumpAndSettle();

        expect(authenticatedSession, WhatsappConnectionButtonTestHelpers.authSession);
      },
    );

    testWidgets(
      'when connection remains incomplete after returning from WhatsApp, it should wait three seconds then keep the checking message visible beyond five seconds',
      (tester) async {
        final exchangeCompleter = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
        when(
          () => authRepository.exchangeNotpIntent(intentToken: WhatsappConnectionButtonTestHelpers.intentToken),
        ).thenAnswer((_) => exchangeCompleter.future);
        await WhatsappConnectionButtonTestHelpers.pumpButton(
          tester: tester,
          authRepository: authRepository,
          whatsapp: whatsapp,
          onSuccess: (_) {},
        );
        await WhatsappConnectionButtonTestHelpers.startConnection(tester: tester);

        await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
        await tester.pump(WhatsappConnectionButton.checkingToastDelay - const Duration(milliseconds: 1));
        final checkingToastCountBeforeDelay = find.text(i18n.whatsappConnectionButton.checking).evaluate().length;
        await tester.pump(const Duration(milliseconds: 1));

        await tester.pump(const Duration(seconds: 10));
        await tester.pump();

        expect(
          (
            beforeDelay: checkingToastCountBeforeDelay,
            afterDelay: find.text(i18n.whatsappConnectionButton.checking).evaluate().length,
          ),
          (beforeDelay: 0, afterDelay: 1),
        );
      },
    );

    testWidgets(
      'when connection is still being checked and the person taps the checking message, it should remain visible',
      (tester) async {
        final exchangeCompleter = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
        when(
          () => authRepository.exchangeNotpIntent(intentToken: WhatsappConnectionButtonTestHelpers.intentToken),
        ).thenAnswer((_) => exchangeCompleter.future);

        await WhatsappConnectionButtonTestHelpers.pumpButton(
          tester: tester,
          authRepository: authRepository,
          whatsapp: whatsapp,
          onSuccess: (_) {},
        );

        await WhatsappConnectionButtonTestHelpers.startConnection(tester: tester);
        await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
        await tester.pump(WhatsappConnectionButton.checkingToastDelay);

        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text(i18n.whatsappConnectionButton.checking));
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(i18n.whatsappConnectionButton.checking), findsOneWidget);
      },
    );

    for (final succeeds in [true, false]) {
      testWidgets(
        'when connection ${succeeds ? 'succeeds' : 'fails'} after the checking message appears, it should replace it with the result',
        (tester) async {
          final exchangeCompleter = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
          when(
            () => authRepository.exchangeNotpIntent(intentToken: WhatsappConnectionButtonTestHelpers.intentToken),
          ).thenAnswer((_) => exchangeCompleter.future);
          await WhatsappConnectionButtonTestHelpers.pumpButton(
            tester: tester,
            authRepository: authRepository,
            whatsapp: whatsapp,
            onSuccess: (_) {
              unawaited(
                tester
                    .state<NavigatorState>(find.byType(Navigator).first)
                    .pushReplacement(MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink())),
              );
            },
          );
          await WhatsappConnectionButtonTestHelpers.startConnection(tester: tester);
          await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
          await tester.pump(const Duration(seconds: 3));

          if (succeeds) {
            exchangeCompleter.complete(WhatsappConnectionButtonTestHelpers.issuedSessionEnvelope);
          } else {
            exchangeCompleter.completeError(StateError('exchange failed'));
          }
          await tester.pumpAndSettle();

          expect(
            (
              checking: find.text(i18n.whatsappConnectionButton.checking).evaluate().length,
              result: find
                  .text(succeeds ? i18n.whatsappConnectionButton.success : i18n.whatsappConnectionButton.error)
                  .evaluate()
                  .length,
            ),
            (checking: 0, result: 1),
          );
        },
      );
    }

    testWidgets('when connection preparation fails, it should show an error and enable another attempt', (
      tester,
    ) async {
      when(
        () => authRepository.createNotpIntent(channel: AuthChannel.whatsapp),
      ).thenThrow(StateError('registration failed'));
      await WhatsappConnectionButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (_) {},
      );

      await tester.tap(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey));
      await tester.pump();
      final button = tester.widget<MateoButton>(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey));

      expect(
        (
          errorToast: find.text(i18n.whatsappConnectionButton.error).evaluate().length,
          enabled: button.onPressed != null,
        ),
        (errorToast: 1, enabled: true),
      );
    });

    testWidgets('when connection is rate limited, it should ask the person to wait before trying again', (
      tester,
    ) async {
      when(() => authRepository.createNotpIntent(channel: AuthChannel.whatsapp)).thenThrow(
        RateLimitedDioException(
          requestOptions: RequestOptions(path: '/auth/notp/intents'),
          retryAfter: const Duration(seconds: 60),
        ),
      );
      await WhatsappConnectionButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (_) {},
      );

      await tester.tap(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey));
      await tester.pump();

      expect(find.text(i18n.whatsappConnectionButton.rateLimited), findsOneWidget);
    });

    testWidgets('when connection succeeds after returning from WhatsApp, it should show the success toast', (
      tester,
    ) async {
      await WhatsappConnectionButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (_) {},
      );
      await WhatsappConnectionButtonTestHelpers.startConnection(tester: tester);

      await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
      await tester.pump();

      expect(find.text(i18n.whatsappConnectionButton.success), findsOneWidget);
    });

    testWidgets(
      'when connection succeeds within three seconds of returning from WhatsApp, it should not show a late checking toast',
      (tester) async {
        await WhatsappConnectionButtonTestHelpers.pumpButton(
          tester: tester,
          authRepository: authRepository,
          whatsapp: whatsapp,
          onSuccess: (_) {},
        );
        await WhatsappConnectionButtonTestHelpers.startConnection(tester: tester);

        await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
        await tester.pump(WhatsappConnectionButton.checkingToastDelay);

        expect(find.text(i18n.whatsappConnectionButton.checking), findsNothing);
      },
    );

    testWidgets('when connection succeeds, it should deliver the complete authenticated session', (tester) async {
      AuthSessionDto? deliveredSession;
      await WhatsappConnectionButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (session) => deliveredSession = session,
      );
      await WhatsappConnectionButtonTestHelpers.startConnection(tester: tester);

      await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
      await tester.pump();

      expect(deliveredSession, WhatsappConnectionButtonTestHelpers.authSession);
    });

    testWidgets('when the app resumes twice after connection succeeds, it should deliver the session only once', (
      tester,
    ) async {
      var successCount = 0;
      await WhatsappConnectionButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (_) => successCount += 1,
      );
      await WhatsappConnectionButtonTestHelpers.startConnection(tester: tester);

      await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
      await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
      await tester.pump();

      expect(successCount, 1);
    });

    testWidgets('when the button is disposed while checking connection, it should remove the checking toast', (
      tester,
    ) async {
      final exchangeCompleter = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
      when(
        () => authRepository.exchangeNotpIntent(intentToken: WhatsappConnectionButtonTestHelpers.intentToken),
      ).thenAnswer((_) => exchangeCompleter.future);
      await WhatsappConnectionButtonTestHelpers.pumpButton(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
        onSuccess: (_) {},
      );
      await WhatsappConnectionButtonTestHelpers.startConnection(tester: tester);
      await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
      await tester.pump(WhatsappConnectionButton.checkingToastDelay);

      unawaited(
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .pushReplacement(MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink())),
      );
      await tester.pumpAndSettle();

      expect(find.text(i18n.whatsappConnectionButton.checking), findsNothing);
    });
  });
}
