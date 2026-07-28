import 'package:cataqui_app/app_state.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppState', () {
    test('when building, it should default to pt_BR locale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(appStateProvider);

      expect(state.currentLocale, AppLocale.ptBr);
    });

    test('when setting locale, it should update the current locale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appStateProvider.notifier).setLocale(AppLocale.ptBr);

      expect(container.read(appStateProvider).currentLocale, AppLocale.ptBr);
    });
  });
}
