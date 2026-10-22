import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/dtos/account_metadata_dto.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/notp_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/welcome/welcome_view/welcome_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';
import '../../../widgets/whatsapp_connection_button/whatsapp_connection_button_test_helpers.dart';
import 'welcome_login_test_helpers.dart';
import 'welcome_view_test_helpers.dart';

void main() {
  late MockAuthRepository authRepository;
  late MockMeRepository meRepository;
  late MockWhatsapp whatsapp;
  late GoRouter router;
  late Completer<ApiEnvelopeDto<AccountMetadataDto>> metadataRequest;
  late Translations i18n;

  setUp(() {
    authRepository = MockAuthRepository();
    meRepository = MockMeRepository();
    whatsapp = MockWhatsapp();
    router = WelcomeLoginTestHelpers.createRouter();
    i18n = AppLocale.ptBr.buildSync();
    addTearDown(router.dispose);
    WhatsappConnectionButtonTestHelpers.stubSuccessfulRegistration(authRepository: authRepository, whatsapp: whatsapp);
    WhatsappConnectionButtonTestHelpers.stubSuccessfulExchange(authRepository: authRepository);
    when(() => meRepository.getMetadata()).thenAnswer((_) {
      metadataRequest = Completer<ApiEnvelopeDto<AccountMetadataDto>>();
      return metadataRequest.future;
    });
  });

  group('Welcome login metadata', () {
    for (final onboardingCompleted in [true, false]) {
      testWidgets('when onboardingCompleted=$onboardingCompleted, it should choose the matching destination', (
        tester,
      ) async {
        await tester.pumpWidget(
          WelcomeLoginTestHelpers.app(
            router: router,
            authRepository: authRepository,
            meRepository: meRepository,
            whatsapp: whatsapp,
          ),
        );
        await tester.pump();
        await WelcomeLoginTestHelpers.login(tester);
        verify(() => meRepository.getMetadata()).called(1);

        metadataRequest.complete(
          ApiEnvelopeDto.fixture(data: AccountMetadataDto.fixture().copyWith(onboardingCompleted: onboardingCompleted)),
        );
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, onboardingCompleted ? '/feed' : '/welcome');
        expect(router.canPop(), isFalse);
        expect(find.byType(WelcomeView), onboardingCompleted ? findsNothing : findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    testWidgets('while metadata is pending, it should keep loading and prevent duplicate requests', (tester) async {
      await tester.pumpWidget(
        WelcomeLoginTestHelpers.app(
          router: router,
          authRepository: authRepository,
          meRepository: meRepository,
          whatsapp: whatsapp,
        ),
      );
      await tester.pump();
      await WelcomeLoginTestHelpers.login(tester);

      expect(tester.widget<MateoButton>(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey)).isLoading, isTrue);
      await tester.tap(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey));
      await tester.pump();
      verify(() => meRepository.getMetadata()).called(1);
      verify(() => authRepository.createNotpIntent(channel: AuthChannel.whatsapp)).called(1);
      expect(router.routeInformationProvider.value.uri.path, '/welcome');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('when metadata fails, it should retain login and retry metadata without reopening WhatsApp', (
      tester,
    ) async {
      await tester.pumpWidget(
        WelcomeLoginTestHelpers.app(
          router: router,
          authRepository: authRepository,
          meRepository: meRepository,
          whatsapp: whatsapp,
        ),
      );
      await tester.pump();
      await WelcomeLoginTestHelpers.login(tester);
      final container = ProviderScope.containerOf(tester.element(find.byType(WelcomeView)));
      final session = container.read(appAuthStateProvider);
      metadataRequest.completeError(Exception('metadata unavailable'));
      await tester.pumpAndSettle();

      expect(find.text(i18n.welcome.metadataError), findsOneWidget);
      expect(container.read(appAuthStateProvider), same(session));
      expect(session, isNotNull);
      expect(router.routeInformationProvider.value.uri.path, '/welcome');

      when(() => meRepository.getMetadata()).thenAnswer(
        (_) async => ApiEnvelopeDto.fixture(data: AccountMetadataDto.fixture().copyWith(onboardingCompleted: true)),
      );
      await tester.tap(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey));
      await tester.pumpAndSettle();

      verify(() => meRepository.getMetadata()).called(2);
      verify(() => authRepository.createNotpIntent(channel: AuthChannel.whatsapp)).called(1);
      verify(() => whatsapp.chat(message: WhatsappConnectionButtonTestHelpers.message)).called(1);
      expect(router.routeInformationProvider.value.uri.path, '/feed');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('when WhatsApp cannot open, it should not request metadata', (tester) async {
      when(() => whatsapp.chat(message: WhatsappConnectionButtonTestHelpers.message)).thenAnswer((_) async => false);
      await tester.pumpWidget(
        WelcomeLoginTestHelpers.app(
          router: router,
          authRepository: authRepository,
          meRepository: meRepository,
          whatsapp: whatsapp,
        ),
      );
      await tester.pump();
      await WelcomeLoginTestHelpers.login(tester);
      await tester.pumpAndSettle();

      verifyNever(() => meRepository.getMetadata());
      expect(router.routeInformationProvider.value.uri.path, '/welcome');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('when login is abandoned before completion, it should not request metadata', (tester) async {
      final exchangeRequest = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
      when(
        () => authRepository.exchangeNotpIntent(intentToken: WhatsappConnectionButtonTestHelpers.intentToken),
      ).thenAnswer((_) => exchangeRequest.future);
      await tester.pumpWidget(
        WelcomeLoginTestHelpers.app(
          router: router,
          authRepository: authRepository,
          meRepository: meRepository,
          whatsapp: whatsapp,
        ),
      );
      await tester.pump();
      await WelcomeLoginTestHelpers.login(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      exchangeRequest.complete(WhatsappConnectionButtonTestHelpers.issuedSessionEnvelope);
      await tester.pump();

      verifyNever(() => meRepository.getMetadata());
      expect(tester.takeException(), isNull);
    });

    for (final fails in [false, true]) {
      testWidgets(
        'when Welcome is disposed before metadata ${fails ? 'fails' : 'completes'}, it should ignore the result',
        (tester) async {
          await tester.pumpWidget(
            WelcomeLoginTestHelpers.app(
              router: router,
              authRepository: authRepository,
              meRepository: meRepository,
              whatsapp: whatsapp,
            ),
          );
          await tester.pump();
          await WelcomeLoginTestHelpers.login(tester);
          verify(() => meRepository.getMetadata()).called(1);
          await tester.pumpWidget(const SizedBox.shrink());

          if (fails) {
            metadataRequest.completeError(Exception('metadata unavailable'));
          } else {
            metadataRequest.complete(
              ApiEnvelopeDto.fixture(data: AccountMetadataDto.fixture().copyWith(onboardingCompleted: true)),
            );
          }
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(router.routeInformationProvider.value.uri.path, '/welcome');
        },
      );
    }
  });

  goldenTest(
    'when metadata is pending after login, it should show the Welcome loading state',
    fileName: 'welcome_metadata_loading',
    constraints: const BoxConstraints.tightFor(width: 390, height: 844),
    builder: () => WelcomeLoginTestHelpers.app(
      router: router,
      authRepository: authRepository,
      meRepository: meRepository,
      whatsapp: whatsapp,
    ),
    whilePerforming: (tester) async {
      await WelcomeLoginTestHelpers.login(tester);
      await tester.pump(const Duration(seconds: 5));
      await WelcomeViewTestHelpers.prepareGoldenCapture(tester: tester);
      return null;
    },
  );

  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
      goldenTest(
        'when metadata fails after login, it should show the localized error and allow retry',
        fileName: 'welcome_metadata_error',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        builder: () => WelcomeLoginTestHelpers.app(
          router: router,
          authRepository: authRepository,
          meRepository: meRepository,
          whatsapp: whatsapp,
        ),
        whilePerforming: (tester) async {
          await WelcomeLoginTestHelpers.login(tester);
          metadataRequest.completeError(Exception('metadata unavailable'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          await WelcomeViewTestHelpers.prepareGoldenCapture(tester: tester);
          expect(find.text(i18n.welcome.metadataError), findsOneWidget);
          return null;
        },
      );
    },
  );
}
