import 'dart:async';

import 'package:cataqui_app/core/auth/auth_state.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/registered_auth_intent_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/widgets/whatsapp_login_button/whatsapp_login_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockAuthRepository authRepository;
  late MockWhatsapp whatsapp;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<AuthSessionDto?>> subscription;
  late Completer<void> appReturn;

  setUp(() {
    authRepository = MockAuthRepository();
    whatsapp = MockWhatsapp();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        whatsappProvider.overrideWithValue(whatsapp),
      ],
    );
    subscription = container.listen(whatsappLoginStateProvider, (_, __) {}, fireImmediately: true);
    appReturn = Completer<void>();
    _WhatsappLoginStateTestData.stubSuccessfulRegistration(authRepository: authRepository, whatsapp: whatsapp);
    _WhatsappLoginStateTestData.stubSuccessfulExchange(authRepository: authRepository);
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  group('WhatsappLoginState', () {
    test('when starting a login, it should register a WhatsApp inbound-message intent', () async {
      await container.read(whatsappLoginStateProvider.notifier).startLogin(appReturn: appReturn.future);

      verify(() => authRepository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp)).called(1);
    });

    test('when an intent is registered, it should open its receiver with the unchanged code', () async {
      await container.read(whatsappLoginStateProvider.notifier).startLogin(appReturn: appReturn.future);

      verify(
        () => whatsapp.launchChat(
          number: _WhatsappLoginStateTestData.codeReceiver,
          message: _WhatsappLoginStateTestData.code,
        ),
      ).called(1);
    });

    test('when WhatsApp opens, it should immediately exchange the exact intent with the deferred deadline', () async {
      await container.read(whatsappLoginStateProvider.notifier).startLogin(appReturn: appReturn.future);

      verify(
        () => authRepository.exchangeInboundMessageAuthIntent(
          intentToken: _WhatsappLoginStateTestData.intentToken,
          timeoutStart: appReturn.future,
        ),
      ).called(1);
    });

    test('when exchange succeeds before the app returns, it should keep the session unpublished', () async {
      await container.read(whatsappLoginStateProvider.notifier).startLogin(appReturn: appReturn.future);
      await Future<void>.delayed(Duration.zero);

      expect(
        (
          loginIsLoading: container.read(whatsappLoginStateProvider) is AsyncLoading<AuthSessionDto?>,
          global: container.read(authStateProvider),
        ),
        (loginIsLoading: true, global: null),
      );
    });

    test('when the app returns after exchange succeeds, it should publish and globally store the session', () async {
      await container.read(whatsappLoginStateProvider.notifier).startLogin(appReturn: appReturn.future);

      appReturn.complete();
      await Future<void>.delayed(Duration.zero);
      final publishedSession = container.read(whatsappLoginStateProvider).value;

      expect(
        (published: publishedSession, global: container.read(authStateProvider)),
        (published: _WhatsappLoginStateTestData.authSession, global: _WhatsappLoginStateTestData.authSession),
      );
    });

    test('when intent registration fails, it should expose a retryable error', () async {
      when(
        () => authRepository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp),
      ).thenThrow(StateError('registration failed'));

      await container.read(whatsappLoginStateProvider.notifier).startLogin(appReturn: appReturn.future);

      expect(container.read(whatsappLoginStateProvider), isA<AsyncError<AuthSessionDto?>>());
    });

    test('when WhatsApp cannot open, it should expose a retryable error', () async {
      when(
        () => whatsapp.launchChat(
          number: _WhatsappLoginStateTestData.codeReceiver,
          message: _WhatsappLoginStateTestData.code,
        ),
      ).thenAnswer((_) async => false);

      await container.read(whatsappLoginStateProvider.notifier).startLogin(appReturn: appReturn.future);

      expect(container.read(whatsappLoginStateProvider), isA<AsyncError<AuthSessionDto?>>());
    });

    test('when WhatsApp cannot open, it should not start exchanging the intent', () async {
      when(
        () => whatsapp.launchChat(
          number: _WhatsappLoginStateTestData.codeReceiver,
          message: _WhatsappLoginStateTestData.code,
        ),
      ).thenAnswer((_) async => false);

      await container.read(whatsappLoginStateProvider.notifier).startLogin(appReturn: appReturn.future);

      verifyNever(
        () => authRepository.exchangeInboundMessageAuthIntent(
          intentToken: any(named: 'intentToken'),
          timeoutStart: any(named: 'timeoutStart'),
        ),
      );
    });

    test('when exchange fails before the app returns, it should expose the error only after returning', () async {
      when(
        () => authRepository.exchangeInboundMessageAuthIntent(
          intentToken: _WhatsappLoginStateTestData.intentToken,
          timeoutStart: appReturn.future,
        ),
      ).thenThrow(StateError('exchange failed'));
      await container.read(whatsappLoginStateProvider.notifier).startLogin(appReturn: appReturn.future);
      await Future<void>.delayed(Duration.zero);
      final stateBeforeReturn = container.read(whatsappLoginStateProvider);

      appReturn.complete();
      await Future<void>.delayed(Duration.zero);

      expect(
        (
          beforeReturnIsLoading: stateBeforeReturn is AsyncLoading<AuthSessionDto?>,
          afterReturnIsError: container.read(whatsappLoginStateProvider) is AsyncError<AuthSessionDto?>,
        ),
        (beforeReturnIsLoading: true, afterReturnIsError: true),
      );
    });

    test('when retrying after a failed attempt, it should register a fresh intent', () async {
      var registrationCount = 0;
      when(() => authRepository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp)).thenAnswer((_) async {
        registrationCount += 1;
        if (registrationCount == 1) throw StateError('registration failed');
        return _WhatsappLoginStateTestData.registeredIntentEnvelope;
      });

      await container.read(whatsappLoginStateProvider.notifier).startLogin(appReturn: appReturn.future);
      await container.read(whatsappLoginStateProvider.notifier).startLogin(appReturn: appReturn.future);

      expect(registrationCount, 2);
    });
  });
}

abstract final class _WhatsappLoginStateTestData {
  static const intentToken = 'kJ3YFf0SYkZp6gWlMTq3up5ELXWRw_zTuF8j0M5tJgI';
  static const code = 'AUTH-K7F9Q2M8VD';
  static const codeReceiver = '5511988887777';
  static final registeredIntentEnvelope = ApiEnvelopeDto.fixture(
    data: RegisteredAuthIntentDto.fixture().copyWith(intentToken: intentToken, code: code, codeReceiver: codeReceiver),
  );
  static final IssuedAuthSessionDto issuedSession =
      AuthIntentExchangeResultDto.issuedSessionFixture() as IssuedAuthSessionDto;
  static final issuedSessionEnvelope = ApiEnvelopeDto.fixture(data: issuedSession);
  static final authSession = AuthSessionDto.fromIssuedAuthSession(issuedSession);

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
}
