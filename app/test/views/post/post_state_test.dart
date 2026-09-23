import 'package:cataqui_app/core/dtos/address_details_dto.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import '../../mocks.dart';

void main() {
  group('PostState', () {
    test('publishes current coordinates and reuses the key on a later submission', () async {
      final jobRepository = MockJobRepository();
      final geosearchRepository = MockGeosearchRepository();
      final container = _PostStateTestHelpers.createContainer(
        jobRepository: jobRepository,
        geosearchRepository: geosearchRepository,
      );
      final postState = container.read(postStateProvider.notifier)
        ..setDescription('  Preciso de ajuda para descarregar caixas.  ')
        ..selectContact(contactMethod: .whatsapp, identifier: '+5511999999999')
        ..setLocation(latitude: -23.561684, longitude: -46.655981, locationTitle: 'Pinheiros');
      when(
        () => jobRepository.createJob(
          description: '  Preciso de ajuda para descarregar caixas.  ',
          latitude: -23.561684,
          longitude: -46.655981,
          contactMethod: .whatsapp,
          contactIdentifier: '+5511999999999',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: JobDto.fixture()));

      await postState.publish();
      final firstKey =
          verify(
                () => jobRepository.createJob(
                  description: '  Preciso de ajuda para descarregar caixas.  ',
                  latitude: -23.561684,
                  longitude: -46.655981,
                  contactMethod: .whatsapp,
                  contactIdentifier: '+5511999999999',
                  idempotencyKey: captureAny(named: 'idempotencyKey'),
                ),
              ).captured.single
              as String;
      verifyNever(
        () => geosearchRepository.getAddressDetails(
          addressId: any(named: 'addressId'),
          sessionToken: any(named: 'sessionToken'),
        ),
      );

      await postState.publish();
      final secondKey =
          verify(
                () => jobRepository.createJob(
                  description: '  Preciso de ajuda para descarregar caixas.  ',
                  latitude: -23.561684,
                  longitude: -46.655981,
                  contactMethod: .whatsapp,
                  contactIdentifier: '+5511999999999',
                  idempotencyKey: captureAny(named: 'idempotencyKey'),
                ),
              ).captured.single
              as String;

      expect(Uuid.isValidUUID(fromString: firstKey), isTrue);
      expect(secondKey, firstKey);
    });

    test('resolves a searched address before publishing its coordinates', () async {
      final jobRepository = MockJobRepository();
      final geosearchRepository = MockGeosearchRepository();
      final container = _PostStateTestHelpers.createContainer(
        jobRepository: jobRepository,
        geosearchRepository: geosearchRepository,
      );
      final postState = container.read(postStateProvider.notifier)
        ..setDescription('Preciso de ajuda para descarregar caixas.')
        ..selectContact(contactMethod: .phoneCall, identifier: '+5511999999999')
        ..selectAddress(addressId: 'address-id', sessionToken: 'session-token', locationTitle: 'Avenida Paulista');
      when(
        () => geosearchRepository.getAddressDetails(addressId: 'address-id', sessionToken: 'session-token'),
      ).thenAnswer((_) async => const AddressDetailsDto(latitude: -23.561684, longitude: -46.655981));
      when(
        () => jobRepository.createJob(
          description: 'Preciso de ajuda para descarregar caixas.',
          latitude: -23.561684,
          longitude: -46.655981,
          contactMethod: .phoneCall,
          contactIdentifier: '+5511999999999',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: JobDto.fixture()));

      await postState.publish();

      verify(
        () => geosearchRepository.getAddressDetails(addressId: 'address-id', sessionToken: 'session-token'),
      ).called(1);
      verify(
        () => jobRepository.createJob(
          description: 'Preciso de ajuda para descarregar caixas.',
          latitude: -23.561684,
          longitude: -46.655981,
          contactMethod: .phoneCall,
          contactIdentifier: '+5511999999999',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).called(1);
    });

    test('does not post when searched address details fail', () async {
      final jobRepository = MockJobRepository();
      final geosearchRepository = MockGeosearchRepository();
      final container = _PostStateTestHelpers.createContainer(
        jobRepository: jobRepository,
        geosearchRepository: geosearchRepository,
      );
      final postState = container.read(postStateProvider.notifier)
        ..setDescription('Preciso de ajuda para descarregar caixas.')
        ..selectContact(contactMethod: .whatsapp, identifier: '+5511999999999')
        ..selectAddress(addressId: 'address-id', sessionToken: 'session-token', locationTitle: 'Avenida Paulista');
      final error = Exception('Address lookup failed');
      when(
        () => geosearchRepository.getAddressDetails(addressId: 'address-id', sessionToken: 'session-token'),
      ).thenThrow(error);

      await expectLater(postState.publish(), throwsA(same(error)));

      verifyNever(
        () => jobRepository.createJob(
          description: any(named: 'description'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          contactMethod: .whatsapp,
          contactIdentifier: any(named: 'contactIdentifier'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
    });

    test('when selecting a contact, it should preserve the original method and identifier', () {
      final container = _PostStateTestHelpers.createContainer();

      container
          .read(postStateProvider.notifier)
          .selectContact(contactMethod: JobContactMethod.whatsapp, identifier: 'Ventairy.Dev');

      expect(container.read(postStateProvider).contact, (
        contactMethod: JobContactMethod.whatsapp,
        identifier: 'Ventairy.Dev',
      ));
    });

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
  static ProviderContainer createContainer({
    MockJobRepository? jobRepository,
    MockGeosearchRepository? geosearchRepository,
  }) {
    final container = ProviderContainer(
      overrides: [
        if (jobRepository != null) jobRepositoryProvider.overrideWithValue(jobRepository),
        if (geosearchRepository != null) geosearchRepositoryProvider.overrideWithValue(geosearchRepository),
      ],
    )..listen(postStateProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }
}
