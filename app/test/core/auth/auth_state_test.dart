import 'package:cataqui_app/core/auth/auth_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthState', () {
    test('when first read, it should expose an unauthenticated session', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final session = container.read(authStateProvider);

      expect(session, isNull);
    });

    test('when setting an authenticated session, it should expose the complete session', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final session = AuthSessionDto.fixture();

      container.read(authStateProvider.notifier).setSession(session);

      expect(container.read(authStateProvider), session);
    });

    test('when the auth state has no active listeners, it should retain the authenticated session', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(authStateProvider, (_, __) {}, fireImmediately: true);
      final session = AuthSessionDto.fixture();
      container.read(authStateProvider.notifier).setSession(session);

      subscription.close();
      await container.pump();

      expect(container.read(authStateProvider), session);
    });
  });
}
