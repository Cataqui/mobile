import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostState', () {
    test('when setting a non-empty description, it should preserve the raw text in post state', () {
      final container = _PostStateTestHelpers.createContainer();

      container.read(postStateProvider.notifier).setDescription('  Preciso de ajuda  ');

      expect(container.read(postStateProvider).descriptionText, '  Preciso de ajuda  ');
    });

    test('when clearing the description, it should store null in post state', () {
      final container = _PostStateTestHelpers.createContainer();
      container.read(postStateProvider.notifier).setDescription('Preciso de ajuda');

      container.read(postStateProvider.notifier).setDescription('');

      expect(container.read(postStateProvider).descriptionText, isNull);
    });

    test('when post creation starts, it should not contain a payment', () {
      final container = _PostStateTestHelpers.createContainer();

      expect(container.read(postStateProvider).payment, isNull);
    });

    test('when setting payment, it should trim its outer whitespace', () {
      final container = _PostStateTestHelpers.createContainer();

      container.read(postStateProvider.notifier).setPayment(r'  R$ 200 por dia  ');

      expect(container.read(postStateProvider).payment, r'R$ 200 por dia');
    });

    test('when setting an empty payment, it should clear it', () {
      final container = _PostStateTestHelpers.createContainer();
      container.read(postStateProvider.notifier)
        ..setPayment(r'R$ 200 por dia')
        ..setPayment('   ');

      expect(container.read(postStateProvider).payment, isNull);
    });

    test('when selecting an address, it should preserve the deferred details identifiers', () {
      final container = _PostStateTestHelpers.createContainer();

      container
          .read(postStateProvider.notifier)
          .selectAddress(
            addressId: 'address-id-123',
            sessionToken: 'session-token-123',
            locationTitle: 'Avenida Paulista',
          );

      expect(container.read(postStateProvider).addressSelection, (
        addressId: 'address-id-123',
        sessionToken: 'session-token-123',
      ));
    });

    test('when selecting an address, it should preserve its concise display label', () {
      final container = _PostStateTestHelpers.createContainer();

      container
          .read(postStateProvider.notifier)
          .selectAddress(
            addressId: 'address-id-123',
            sessionToken: 'session-token-123',
            locationTitle: 'Avenida Paulista',
          );

      expect(container.read(postStateProvider).locationTitle, 'Avenida Paulista');
    });

    test('when clearing an address selection, it should remove the deferred details identifiers', () {
      final container = _PostStateTestHelpers.createContainer();
      container.read(postStateProvider.notifier)
        ..selectAddress(
          addressId: 'address-id-123',
          sessionToken: 'session-token-123',
          locationTitle: 'Avenida Paulista',
        )
        ..clearSelectedAddress();

      expect(container.read(postStateProvider).addressSelection, isNull);
    });

    test('when selecting current coordinates, it should clear the deferred address selection', () {
      final container = _PostStateTestHelpers.createContainer();
      container.read(postStateProvider.notifier)
        ..selectAddress(
          addressId: 'address-id-123',
          sessionToken: 'session-token-123',
          locationTitle: 'Avenida Paulista',
        )
        ..setLocation(latitude: -23.561684, longitude: -46.655981, locationTitle: 'Pinheiros');

      expect(container.read(postStateProvider).addressSelection, isNull);
    });

    test('when selecting current coordinates, it should preserve their concise display label', () {
      final container = _PostStateTestHelpers.createContainer();

      container
          .read(postStateProvider.notifier)
          .setLocation(latitude: -23.561684, longitude: -46.655981, locationTitle: 'Pinheiros, São Paulo');

      expect(container.read(postStateProvider).locationTitle, 'Pinheiros, São Paulo');
    });
  });
}

abstract final class _PostStateTestHelpers {
  static ProviderContainer createContainer() {
    final container = ProviderContainer()..listen(postStateProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }
}
