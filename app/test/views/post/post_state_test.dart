import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/dtos/address_details_dto.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/public_job_dto.dart';
import 'package:cataqui_app/core/enums/contact_method.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/post/post_data.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import '../../mocks.dart';
import '../feed/feed_view_test_helpers.dart';
import '../me/fake_app_auth_state.dart';

void main() {
  group('posting retry identity', () {
    late MockJobRepository repository;
    late MockMapsRepository maps;
    late ProviderContainer container;
    late PostState state;
    late List<String> keys;
    setUp(() {
      repository = MockJobRepository();
      maps = MockMapsRepository();
      keys = [];
      container = _PostStateTestHelpers.createContainer(jobRepository: repository, mapsRepository: maps);
      state = container.read(postStateProvider.notifier)
        ..setDescription('Preciso de ajuda para descarregar caixas.')
        ..selectContact(contactMethod: .whatsapp, identifier: '+5511999999999')
        ..setLocation(latitude: -23, longitude: -46, locationTitle: 'Centro');
      when(
        () => repository.createJob(
          description: any(named: 'description'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locationTitle: any(named: 'locationTitle'),
          contactMethod: .whatsapp,
          contactIdentifier: any(named: 'contactIdentifier'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((invocation) async {
        keys.add(invocation.namedArguments[#idempotencyKey] as String);
        throw Exception('maps unavailable');
      });
      when(
        () => maps.getAddressDetails(
          addressId: any(named: 'addressId'),
          sessionToken: any(named: 'sessionToken'),
        ),
      ).thenAnswer((_) async => const AddressDetailsDto(latitude: -23, longitude: -46));
    });
    test('when an unchanged submission fails, it should preserve the form and posting key', () async {
      await expectLater(state.publish(), throwsException);
      final preserved = container.read(postStateProvider);
      await expectLater(state.publish(), throwsException);
      expect(
        (keys[0] == keys[1], preserved.descriptionText, preserved.isPublishing),
        (true, 'Preciso de ajuda para descarregar caixas.', false),
      );
    });
    test('when a failed submission changes, it should start a new posting key', () async {
      await expectLater(state.publish(), throwsException);
      state.setDescription('Agora preciso de ajuda para organizar o estoque.');
      await expectLater(state.publish(), throwsException);
      expect(keys[1], isNot(keys[0]));
    });
    test('when only surrounding description whitespace changes, it should preserve the failed posting key', () async {
      await expectLater(state.publish(), throwsException);
      state.setDescription('  Preciso de ajuda para descarregar caixas.  ');

      await expectLater(state.publish(), throwsException);

      expect(keys[1], keys[0]);
    });

    test('when an unchanged searched address is retried, it should reuse resolved coordinates', () async {
      state.selectAddress(addressId: 'address', sessionToken: 'session', locationTitle: 'Centro');
      await expectLater(state.publish(), throwsException);
      await expectLater(state.publish(), throwsException);
      verify(() => maps.getAddressDetails(addressId: 'address', sessionToken: 'session')).called(1);
    });
  });

  group('background publication recovery', () {
    late MockJobRepository jobRepository;
    late ProviderContainer container;
    late FakeAppAuthState authState;
    late PostState postState;
    late ProviderSubscription<PostData> subscription;
    late Completer<ApiEnvelopeDto<PublicJobDto>> pendingPublication;
    late List<String> idempotencyKeys;

    setUp(() {
      jobRepository = MockJobRepository();
      authState = FakeAppAuthState(null);
      pendingPublication = Completer<ApiEnvelopeDto<PublicJobDto>>();
      idempotencyKeys = [];
      when(
        () => jobRepository.createJob(
          description: any(named: 'description'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locationTitle: any(named: 'locationTitle'),
          contactMethod: .whatsapp,
          contactIdentifier: any(named: 'contactIdentifier'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((invocation) {
        idempotencyKeys.add(invocation.namedArguments[#idempotencyKey] as String);
        if (idempotencyKeys.length == 1) return pendingPublication.future;
        return Future.error(StateError('publication unavailable'));
      });
      container = ProviderContainer(
        overrides: [
          jobRepositoryProvider.overrideWithValue(jobRepository),
          appAuthStateProvider.overrideWith(() => authState),
          feedStateProvider.overrideWith(FakeFeedState.new),
        ],
      )..read(appAuthStateProvider);
      subscription = container.listen(postStateProvider, (_, _) {});
      postState = container.read(postStateProvider.notifier)
        ..setDescription('Preciso de ajuda para descarregar caixas.')
        ..selectContact(contactMethod: .whatsapp, identifier: '+5511999999999')
        ..setLocation(latitude: -23, longitude: -46, locationTitle: 'Centro');
    });

    tearDown(() => container.dispose());

    test(
      'when publishing fails after closing the composer, it should restore the draft and retry key on reopening',
      () async {
        final publication = expectLater(postState.publish(), throwsStateError);
        subscription.close();
        await container.pump();
        pendingPublication.completeError(StateError('publication unavailable'));
        await publication;
        await container.pump();

        final reopenedSubscription = container.listen(postStateProvider, (_, _) {});
        final restoredDraft = container.read(postStateProvider);
        await expectLater(container.read(postStateProvider.notifier).publish(), throwsStateError);
        reopenedSubscription.close();
        await container.pump();

        expect(
          (
            description: restoredDraft.descriptionText,
            locationTitle: restoredDraft.locationTitle,
            isPublishing: restoredDraft.isPublishing,
            sameRetryKey: idempotencyKeys[0] == idempotencyKeys[1],
            discardedAfterReopening: !container.exists(postStateProvider),
          ),
          (
            description: 'Preciso de ajuda para descarregar caixas.',
            locationTitle: 'Centro',
            isPublishing: false,
            sameRetryKey: true,
            discardedAfterReopening: true,
          ),
        );
      },
    );
    test('when the user signs out after a failed background post, it should discard that account draft', () async {
      authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'original-poster');
      final publication = expectLater(postState.publish(), throwsStateError);
      subscription.close();
      await container.pump();
      pendingPublication.completeError(StateError('publication unavailable'));
      await publication;
      await container.pump();

      authState.currentSession = null;
      await container.pump();
      final reopenedSubscription = container.listen(postStateProvider, (_, _) {});
      await container.pump();
      final restoredDraft = container.read(postStateProvider);
      reopenedSubscription.close();

      expect((restoredDraft.descriptionText, restoredDraft.contact), (null, null));
    });

    for (final fails in [false, true]) {
      test(
        'when the account changes during background publication (fails: $fails), it should ignore the previous account result',
        () async {
          authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'original-poster');
          final publication = postState.publish();
          subscription.close();
          await container.pump();

          authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'different-poster');
          await container.pump();
          if (fails) {
            pendingPublication.completeError(StateError('previous account publication failed'));
          } else {
            pendingPublication.complete(ApiEnvelopeDto.fixture(data: PublicJobDto.fixture()));
          }

          expect(await publication, isNull);
        },
      );
    }

    test('when authentication completes during publication, it should finish the existing draft', () async {
      final publication = postState.publish();
      authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'authenticated-poster');
      await container.pump();
      final postedJob = PublicJobDto.fixture().copyWith(jobId: 'published-after-authentication');
      pendingPublication.complete(ApiEnvelopeDto.fixture(data: postedJob));

      expect(await publication, postedJob);
    });
  });

  group('PostState', () {
    late MockJobRepository jobRepository;
    late MockMapsRepository mapsRepository;

    setUp(() {
      jobRepository = MockJobRepository();
      mapsRepository = MockMapsRepository();
    });

    test('when publication succeeds, it should clear the draft and prevent a repeated submission', () async {
      final container = _PostStateTestHelpers.createContainer(
        jobRepository: jobRepository,
        mapsRepository: mapsRepository,
      );
      final postState = container.read(postStateProvider.notifier)
        ..setDescription('  Preciso de ajuda para descarregar caixas.  ')
        ..selectContact(contactMethod: .whatsapp, identifier: '+5511999999999')
        ..setLocation(latitude: -23.561684, longitude: -46.655981, locationTitle: '  Pinheiros  ');
      when(
        () => jobRepository.createJob(
          description: '  Preciso de ajuda para descarregar caixas.  ',
          latitude: -23.561684,
          longitude: -46.655981,
          locationTitle: 'Pinheiros',
          contactMethod: .whatsapp,
          contactIdentifier: '+5511999999999',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: PublicJobDto.fixture()));

      await postState.publish();
      final firstKey =
          verify(
                () => jobRepository.createJob(
                  description: '  Preciso de ajuda para descarregar caixas.  ',
                  latitude: -23.561684,
                  longitude: -46.655981,
                  locationTitle: 'Pinheiros',
                  contactMethod: .whatsapp,
                  contactIdentifier: '+5511999999999',
                  idempotencyKey: captureAny(named: 'idempotencyKey'),
                ),
              ).captured.single
              as String;
      verifyNever(
        () => mapsRepository.getAddressDetails(
          addressId: any(named: 'addressId'),
          sessionToken: any(named: 'sessionToken'),
        ),
      );

      final repeatedPublication = await postState.publish();
      final draft = container.read(postStateProvider);

      expect(
        (
          validKey: Uuid.isValidUUID(fromString: firstKey),
          repeatedPublication: repeatedPublication,
          description: draft.descriptionText,
          contact: draft.contact,
          location: draft.location,
          locationTitle: draft.locationTitle,
          isPublishing: draft.isPublishing,
        ),
        (
          validKey: true,
          repeatedPublication: null,
          description: null,
          contact: null,
          location: null,
          locationTitle: null,
          isPublishing: false,
        ),
      );
    });

    test('when publishing a searched address, it should resolve its coordinates first', () async {
      final container = _PostStateTestHelpers.createContainer(
        jobRepository: jobRepository,
        mapsRepository: mapsRepository,
      );
      final postState = container.read(postStateProvider.notifier)
        ..setDescription('Preciso de ajuda para descarregar caixas.')
        ..selectContact(contactMethod: .phoneCall, identifier: '+5511999999999')
        ..selectAddress(addressId: 'address-id', sessionToken: 'session-token', locationTitle: 'Avenida Paulista');
      when(
        () => mapsRepository.getAddressDetails(addressId: 'address-id', sessionToken: 'session-token'),
      ).thenAnswer((_) async => const AddressDetailsDto(latitude: -23.561684, longitude: -46.655981));
      when(
        () => jobRepository.createJob(
          description: 'Preciso de ajuda para descarregar caixas.',
          latitude: -23.561684,
          longitude: -46.655981,
          locationTitle: 'Avenida Paulista',
          contactMethod: .phoneCall,
          contactIdentifier: '+5511999999999',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: PublicJobDto.fixture()));

      await postState.publish();

      verify(() => mapsRepository.getAddressDetails(addressId: 'address-id', sessionToken: 'session-token')).called(1);
      verify(
        () => jobRepository.createJob(
          description: 'Preciso de ajuda para descarregar caixas.',
          latitude: -23.561684,
          longitude: -46.655981,
          locationTitle: 'Avenida Paulista',
          contactMethod: .phoneCall,
          contactIdentifier: '+5511999999999',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).called(1);
    });

    test('when searched address details fail, it should not post', () async {
      final container = _PostStateTestHelpers.createContainer(
        jobRepository: jobRepository,
        mapsRepository: mapsRepository,
      );
      final postState = container.read(postStateProvider.notifier)
        ..setDescription('Preciso de ajuda para descarregar caixas.')
        ..selectContact(contactMethod: .whatsapp, identifier: '+5511999999999')
        ..selectAddress(addressId: 'address-id', sessionToken: 'session-token', locationTitle: 'Avenida Paulista');
      final error = Exception('Address lookup failed');
      when(
        () => mapsRepository.getAddressDetails(addressId: 'address-id', sessionToken: 'session-token'),
      ).thenThrow(error);

      await expectLater(postState.publish(), throwsA(same(error)));

      verifyNever(
        () => jobRepository.createJob(
          description: any(named: 'description'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locationTitle: any(named: 'locationTitle'),
          contactMethod: .whatsapp,
          contactIdentifier: any(named: 'contactIdentifier'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
    });

    test('when selecting a contact, it should preserve the original method and identifier', () {
      final container = _PostStateTestHelpers.createContainer();

      container.read(postStateProvider.notifier).selectContact(contactMethod: .whatsapp, identifier: 'Ventairy.Dev');

      expect(container.read(postStateProvider).contact, (
        contactMethod: ContactMethod.whatsapp,
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
  static ProviderContainer createContainer({MockJobRepository? jobRepository, MockMapsRepository? mapsRepository}) {
    final container = ProviderContainer(
      overrides: [
        feedStateProvider.overrideWith(FakeFeedState.new),
        if (jobRepository != null) jobRepositoryProvider.overrideWithValue(jobRepository),
        if (mapsRepository != null) mapsRepositoryProvider.overrideWithValue(mapsRepository),
      ],
    )..listen(postStateProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }
}
