import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_auth/login_state.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/created_notp_intent_dto.dart';
import 'package:cataqui_app/core/dtos/notp_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/enums/auth_channel.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockAuthRepository authRepository;
  late MockFlutterSecureStorage secureStorage;
  late MockWhatsapp whatsapp;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<AuthSessionDto?>> subscription;
  late Completer<void> appReturn;

  void initializeContainer() {
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        secureStorageProvider.overrideWithValue(secureStorage),
        whatsappProvider(identifier: _LoginStateTestData.codeReceiver).overrideWithValue(whatsapp),
      ],
    );
    subscription = container.listen(loginStateProvider, (_, __) {}, fireImmediately: true);
    appReturn = Completer<void>();
  }

  void restartContainerInWidgetZone() {
    subscription.close();
    container.dispose();
    initializeContainer();
  }

  setUp(() {
    authRepository = MockAuthRepository();
    secureStorage = MockFlutterSecureStorage();
    whatsapp = MockWhatsapp();
    when(
      () => secureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    initializeContainer();
    _LoginStateTestData.stubSuccessfulRegistration(authRepository: authRepository, whatsapp: whatsapp);
    _LoginStateTestData.stubSuccessfulExchange(authRepository: authRepository);
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  group('LoginState', () {
    test('when starting a login, it should create a WhatsApp NOTP intent', () async {
      await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);

      verify(() => authRepository.createNotpIntent(channel: AuthChannel.whatsapp)).called(1);
    });

    test('when a NOTP intent is created, it should open its receiver with instructions containing the code', () async {
      await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);

      verify(() => whatsapp.chat(message: _LoginStateTestData.message)).called(1);
    });

    test('when WhatsApp opens, it should immediately exchange the exact intent', () async {
      await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);

      verify(() => authRepository.exchangeNotpIntent(intentToken: _LoginStateTestData.intentToken)).called(1);
    });

    test('when exchange succeeds before the app returns, it should keep the session unpublished', () async {
      await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);
      await Future<void>.delayed(Duration.zero);

      expect(
        (
          loginIsLoading: container.read(loginStateProvider) is AsyncLoading<AuthSessionDto?>,
          global: container.read(appAuthStateProvider),
        ),
        (loginIsLoading: true, global: null),
      );
    });

    test('when the app returns after exchange succeeds, it should publish and globally store the session', () async {
      await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);

      appReturn.complete();
      await Future<void>.delayed(Duration.zero);
      final publishedSession = container.read(loginStateProvider).value;

      expect(
        (published: publishedSession, global: container.read(appAuthStateProvider)),
        (published: _LoginStateTestData.authSession, global: _LoginStateTestData.authSession),
      );
    });

    test('when NOTP intent creation fails, it should expose a retryable error', () async {
      when(
        () => authRepository.createNotpIntent(channel: AuthChannel.whatsapp),
      ).thenThrow(StateError('registration failed'));

      await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);

      expect(container.read(loginStateProvider), isA<AsyncError<AuthSessionDto?>>());
    });

    test('when WhatsApp cannot open, it should expose a retryable error', () async {
      when(() => whatsapp.chat(message: _LoginStateTestData.message)).thenAnswer((_) async => false);

      await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);

      expect(container.read(loginStateProvider), isA<AsyncError<AuthSessionDto?>>());
    });

    test('when WhatsApp cannot open, it should not start exchanging the intent', () async {
      when(() => whatsapp.chat(message: _LoginStateTestData.message)).thenAnswer((_) async => false);

      await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);

      verifyNever(() => authRepository.exchangeNotpIntent(intentToken: any(named: 'intentToken')));
    });

    test('when exchange fails before the app returns, it should expose the error only after returning', () async {
      when(
        () => authRepository.exchangeNotpIntent(intentToken: _LoginStateTestData.intentToken),
      ).thenThrow(StateError('exchange failed'));
      await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);
      await Future<void>.delayed(Duration.zero);
      final stateBeforeReturn = container.read(loginStateProvider);

      appReturn.complete();
      await Future<void>.delayed(Duration.zero);

      expect(
        (
          beforeReturnIsLoading: stateBeforeReturn is AsyncLoading<AuthSessionDto?>,
          afterReturnIsError: container.read(loginStateProvider) is AsyncError<AuthSessionDto?>,
        ),
        (beforeReturnIsLoading: true, afterReturnIsError: true),
      );
    });

    test('when retrying after a failed attempt, it should create a fresh NOTP intent', () async {
      var registrationCount = 0;
      when(() => authRepository.createNotpIntent(channel: AuthChannel.whatsapp)).thenAnswer((_) async {
        registrationCount += 1;
        if (registrationCount == 1) throw StateError('registration failed');
        return _LoginStateTestData.createdNotpIntentEnvelope;
      });

      await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);
      await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);

      expect(registrationCount, 2);
    });

    group('NOTP polling', () {
      for (final retryAfterSeconds in [1, 3]) {
        testWidgets('when pending requests ask to wait $retryAfterSeconds seconds, it should honor that interval', (
          tester,
        ) async {
          restartContainerInWidgetZone();
          var requestCount = 0;
          when(() => authRepository.exchangeNotpIntent(intentToken: _LoginStateTestData.intentToken)).thenAnswer((
            _,
          ) async {
            requestCount += 1;
            if (requestCount == 1) {
              return ApiEnvelopeDto.fixture(
                data: NotpIntentExchangeResultDto.pending(retryAfterSeconds: retryAfterSeconds),
              );
            }
            return _LoginStateTestData.issuedSessionEnvelope;
          });
          await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);
          await tester.pump();

          await tester.pump(Duration(seconds: retryAfterSeconds) - const Duration(milliseconds: 1));
          final requestCountBeforeRetry = requestCount;
          await tester.pump(const Duration(milliseconds: 1));
          appReturn.complete();
          await tester.pump();

          expect(
            (
              requestsBeforeRetry: requestCountBeforeRetry,
              requestsAfterRetry: requestCount,
              session: container.read(loginStateProvider).value,
            ),
            (requestsBeforeRetry: 1, requestsAfterRetry: 2, session: _LoginStateTestData.authSession),
          );
        });
      }

      testWidgets('when the app stays in WhatsApp, it should defer the exchange deadline until returning', (
        tester,
      ) async {
        restartContainerInWidgetZone();
        var requestCount = 0;
        when(() => authRepository.exchangeNotpIntent(intentToken: _LoginStateTestData.intentToken)).thenAnswer((
          _,
        ) async {
          requestCount += 1;
          if (requestCount <= 2) {
            return ApiEnvelopeDto.fixture(data: const NotpIntentExchangeResultDto.pending(retryAfterSeconds: 1));
          }
          return _LoginStateTestData.issuedSessionEnvelope;
        });

        late final bool wasLoadingBeforeReturn;
        await withClock(Clock(() => tester.binding.clock.now()), () async {
          await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);
          await tester.pump(const Duration(seconds: 40));
          wasLoadingBeforeReturn = container.read(loginStateProvider).isLoading;
          appReturn.complete();
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
        });

        expect(
          (
            wasLoadingBeforeReturn: wasLoadingBeforeReturn,
            requestCount: requestCount,
            session: container.read(loginStateProvider).value,
          ),
          (wasLoadingBeforeReturn: true, requestCount: 3, session: _LoginStateTestData.authSession),
        );
      });

      testWidgets('when exchanges stay pending for thirty seconds after returning, it should expose a timeout', (
        tester,
      ) async {
        restartContainerInWidgetZone();
        when(() => authRepository.exchangeNotpIntent(intentToken: _LoginStateTestData.intentToken)).thenAnswer(
          (_) async => ApiEnvelopeDto.fixture(data: const NotpIntentExchangeResultDto.pending(retryAfterSeconds: 1)),
        );

        late final bool wasLoadingBeforeDeadline;
        await withClock(Clock(() => tester.binding.clock.now()), () async {
          await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);
          appReturn.complete();
          await tester.pump();
          await tester.pump(const Duration(seconds: 29));
          wasLoadingBeforeDeadline = container.read(loginStateProvider).isLoading;
          await tester.pump(const Duration(seconds: 1));
        });

        expect(
          (
            wasLoadingBeforeDeadline: wasLoadingBeforeDeadline,
            timedOut: container.read(loginStateProvider).error is TimeoutException,
            isExchanging: container.read(loginStateProvider.notifier).isExchangingNotpIntent,
          ),
          (wasLoadingBeforeDeadline: true, timedOut: true, isExchanging: false),
        );
      });

      for (final succeeds in [true, false]) {
        testWidgets(
          'when an in-flight exchange ${succeeds ? 'succeeds' : 'fails'} after the deadline, it should preserve its result',
          (tester) async {
            restartContainerInWidgetZone();
            final response = Completer<ApiEnvelopeDto<NotpIntentExchangeResultDto>>();
            final failure = StateError('intent expired');
            when(
              () => authRepository.exchangeNotpIntent(intentToken: _LoginStateTestData.intentToken),
            ).thenAnswer((_) => response.future);

            await withClock(Clock(() => tester.binding.clock.now()), () async {
              await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);
              appReturn.complete();
              await tester.pump();
              await tester.pump(const Duration(seconds: 31));
              if (succeeds) {
                response.complete(_LoginStateTestData.issuedSessionEnvelope);
              } else {
                response.completeError(failure);
              }
              await tester.pump();
            });

            expect(
              (session: container.read(loginStateProvider).value, error: container.read(loginStateProvider).error),
              (session: succeeds ? _LoginStateTestData.authSession : null, error: succeeds ? null : failure),
            );
          },
        );
      }

      testWidgets('when the login is dismissed during polling, it should stop making exchange requests', (
        tester,
      ) async {
        restartContainerInWidgetZone();
        var requestCount = 0;
        when(() => authRepository.exchangeNotpIntent(intentToken: _LoginStateTestData.intentToken)).thenAnswer((
          _,
        ) async {
          requestCount += 1;
          return ApiEnvelopeDto.fixture(data: const NotpIntentExchangeResultDto.pending(retryAfterSeconds: 1));
        });
        await container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);

        subscription.close();
        await tester.pump(Duration.zero);
        await tester.pump(const Duration(seconds: 1));

        expect(
          (requestCount: requestCount, session: container.read(appAuthStateProvider)),
          (requestCount: 1, session: null),
        );
      });
    });

    testWidgets('when login is dismissed before the intent arrives, it should not open WhatsApp', (tester) async {
      restartContainerInWidgetZone();
      final intent = Completer<ApiEnvelopeDto<CreatedNotpIntentDto>>();
      when(() => authRepository.createNotpIntent(channel: AuthChannel.whatsapp)).thenAnswer((_) => intent.future);
      final login = container.read(loginStateProvider.notifier).loginWithWhatsapp(appReturn: appReturn.future);

      subscription.close();
      await tester.pump(Duration.zero);
      intent.complete(_LoginStateTestData.createdNotpIntentEnvelope);
      await login;

      verifyNever(() => whatsapp.chat(message: any(named: 'message')));
    });
  });
}

abstract final class _LoginStateTestData {
  static const intentToken = 'kJ3YFf0SYkZp6gWlMTq3up5ELXWRw_zTuF8j0M5tJgI';
  static const code = 'NOTP-K7F9Q2M8VD';
  static const codeReceiver = '+5511988887777';
  static const message = 'Entrar com o código $code.\n\nDepois de enviar só voltar pro app e esperar';
  static final createdNotpIntentEnvelope = ApiEnvelopeDto.fixture(
    data: CreatedNotpIntentDto.fixture().copyWith(intentToken: intentToken, code: code, codeReceiver: codeReceiver),
  );
  static final IssuedAuthSessionDto issuedSession =
      NotpIntentExchangeResultDto.issuedSessionFixture() as IssuedAuthSessionDto;
  static final issuedSessionEnvelope = ApiEnvelopeDto.fixture(data: issuedSession);
  static final authSession = AuthSessionDto.fromIssuedAuthSession(issuedSession);

  static void stubSuccessfulRegistration({required MockAuthRepository authRepository, required MockWhatsapp whatsapp}) {
    when(
      () => authRepository.createNotpIntent(channel: AuthChannel.whatsapp),
    ).thenAnswer((_) async => createdNotpIntentEnvelope);
    when(() => whatsapp.chat(message: message)).thenAnswer((_) async => true);
  }

  static void stubSuccessfulExchange({required MockAuthRepository authRepository}) {
    when(
      () => authRepository.exchangeNotpIntent(intentToken: intentToken),
    ).thenAnswer((_) async => issuedSessionEnvelope);
  }
}
