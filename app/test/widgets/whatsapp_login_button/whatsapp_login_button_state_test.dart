import 'dart:async';

import 'package:cataqui_app/core/auth/auth_state.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/registered_auth_intent_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/widgets/whatsapp_login_button/whatsapp_login_button_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockAuthRepository authRepository;
  late MockWhatsapp whatsapp;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<AuthSessionDto?>> subscription;

  setUp(() {
    authRepository = MockAuthRepository();
    whatsapp = MockWhatsapp();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        whatsappProvider.overrideWithValue(whatsapp),
      ],
    );
    subscription = container.listen(whatsappLoginButtonStateProvider, (_, __) {}, fireImmediately: true);
    _WhatsappLoginButtonStateTestData.stubSuccessfulRegistration(authRepository: authRepository, whatsapp: whatsapp);
    _WhatsappLoginButtonStateTestData.stubSuccessfulExchange(authRepository: authRepository);
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  group('WhatsappLoginButtonState', () {
    test('when starting a login, it should register a WhatsApp inbound-message intent', () async {
      await container.read(whatsappLoginButtonStateProvider.notifier).openWhatsappWithCode();

      verify(() => authRepository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp)).called(1);
    });

    test('when an intent is registered, it should open its receiver with the unchanged code', () async {
      await container.read(whatsappLoginButtonStateProvider.notifier).openWhatsappWithCode();

      verify(
        () => whatsapp.launchChat(
          number: _WhatsappLoginButtonStateTestData.codeReceiver,
          message: _WhatsappLoginButtonStateTestData.code,
        ),
      ).called(1);
    });

    test('when WhatsApp opens before the app resumes, it should not exchange the intent', () async {
      await container.read(whatsappLoginButtonStateProvider.notifier).openWhatsappWithCode();

      verifyNever(() => authRepository.exchangeInboundMessageAuthIntent(intentToken: any(named: 'intentToken')));
    });

    test('when the app returns from WhatsApp, it should exchange the exact intent token', () async {
      await container.read(whatsappLoginButtonStateProvider.notifier).openWhatsappWithCode();

      await container.read(whatsappLoginButtonStateProvider.notifier).exchangeIntent();

      verify(
        () =>
            authRepository.exchangeInboundMessageAuthIntent(intentToken: _WhatsappLoginButtonStateTestData.intentToken),
      ).called(1);
    });

    test('when the exchange succeeds, it should publish and globally store the complete auth session', () async {
      await container.read(whatsappLoginButtonStateProvider.notifier).openWhatsappWithCode();
      await container.read(whatsappLoginButtonStateProvider.notifier).exchangeIntent();
      final buttonState = container.read(whatsappLoginButtonStateProvider);
      final publishedSession = buttonState.value;

      expect(
        (published: publishedSession, global: container.read(authStateProvider)),
        (
          published: _WhatsappLoginButtonStateTestData.authSession,
          global: _WhatsappLoginButtonStateTestData.authSession,
        ),
      );
    });

    test('when intent registration fails, it should expose a retryable error', () async {
      when(
        () => authRepository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp),
      ).thenThrow(StateError('registration failed'));

      await container.read(whatsappLoginButtonStateProvider.notifier).openWhatsappWithCode();

      expect(container.read(whatsappLoginButtonStateProvider), isA<AsyncError<AuthSessionDto?>>());
    });

    test('when WhatsApp cannot open, it should expose a retryable error', () async {
      when(
        () => whatsapp.launchChat(
          number: _WhatsappLoginButtonStateTestData.codeReceiver,
          message: _WhatsappLoginButtonStateTestData.code,
        ),
      ).thenAnswer((_) async => false);

      await container.read(whatsappLoginButtonStateProvider.notifier).openWhatsappWithCode();

      expect(container.read(whatsappLoginButtonStateProvider), isA<AsyncError<AuthSessionDto?>>());
    });

    test('when intent exchange fails, it should expose a retryable error', () async {
      when(
        () =>
            authRepository.exchangeInboundMessageAuthIntent(intentToken: _WhatsappLoginButtonStateTestData.intentToken),
      ).thenThrow(StateError('exchange failed'));
      await container.read(whatsappLoginButtonStateProvider.notifier).openWhatsappWithCode();

      await container.read(whatsappLoginButtonStateProvider.notifier).exchangeIntent();

      expect(container.read(whatsappLoginButtonStateProvider), isA<AsyncError<AuthSessionDto?>>());
    });

    test('when retrying after a failed attempt, it should register a fresh intent', () async {
      var registrationCount = 0;
      when(() => authRepository.registerInboundMessageAuthIntent(channel: AuthChannel.whatsapp)).thenAnswer((_) async {
        registrationCount += 1;
        if (registrationCount == 1) throw StateError('registration failed');
        return _WhatsappLoginButtonStateTestData.registeredIntentEnvelope;
      });

      await container.read(whatsappLoginButtonStateProvider.notifier).openWhatsappWithCode();
      await container.read(whatsappLoginButtonStateProvider.notifier).openWhatsappWithCode();

      expect(registrationCount, 2);
    });

    test('when app return is handled twice during exchange, it should start only one exchange', () async {
      final exchangeCompleter = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
      when(
        () =>
            authRepository.exchangeInboundMessageAuthIntent(intentToken: _WhatsappLoginButtonStateTestData.intentToken),
      ).thenAnswer((_) => exchangeCompleter.future);
      await container.read(whatsappLoginButtonStateProvider.notifier).openWhatsappWithCode();

      unawaited(container.read(whatsappLoginButtonStateProvider.notifier).exchangeIntent());
      await container.read(whatsappLoginButtonStateProvider.notifier).exchangeIntent();

      verify(
        () =>
            authRepository.exchangeInboundMessageAuthIntent(intentToken: _WhatsappLoginButtonStateTestData.intentToken),
      ).called(1);
    });
  });
}

abstract final class _WhatsappLoginButtonStateTestData {
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
      () => authRepository.exchangeInboundMessageAuthIntent(intentToken: intentToken),
    ).thenAnswer((_) async => issuedSessionEnvelope);
  }
}
