import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/saved_contact_dto.dart';
import 'package:cataqui_app/core/enums/contact_method.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/post/contact/post_contact_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';
import '../../me/fake_app_auth_state.dart';

void main() {
  late MockUserRepository userRepository;

  setUp(() {
    userRepository = MockUserRepository();
  });

  test('when contacts load, it should preserve API order and format every supported identifier', () async {
    when(userRepository.getContacts).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: [
          SavedContactDto.fixture().copyWith(
            contactId: 'whatsapp-username',
            method: ContactMethod.whatsapp,
            identifier: 'Ventairy.Dev',
          ),
          SavedContactDto.fixture().copyWith(
            contactId: 'phone-us',
            method: ContactMethod.phoneCall,
            identifier: '+1 (202) 555-0123',
          ),
          SavedContactDto.fixture().copyWith(
            contactId: 'whatsapp-br',
            method: ContactMethod.whatsapp,
            identifier: '+55 11 91234 5678',
          ),
        ],
      ),
    );
    final container = _PostContactStateTestHelpers.createContainer(userRepository);

    final options = await container.read(postContactStateProvider.future);

    expect(options.map((option) => (option.contact.contactId, option.displayIdentifier)).toList(), [
      ('whatsapp-username', '@ventairy.dev'),
      ('phone-us', '+1 202-555-0123'),
      ('whatsapp-br', '+55 11 91234-5678'),
    ]);
  });

  test('when contacts load, it should fetch them from the authenticated user repository', () async {
    when(userRepository.getContacts).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: <SavedContactDto>[]));
    final container = _PostContactStateTestHelpers.createContainer(userRepository);

    await container.read(postContactStateProvider.future);

    verify(userRepository.getContacts).called(1);
  });

  test('when the account changes, it should replace saved contacts with the current account contacts', () async {
    final authState = FakeAppAuthState(AuthSessionDto.fixture().copyWith(userId: 'first-poster'));
    final firstContact = SavedContactDto.fixture().copyWith(contactId: 'first-poster-contact');
    final secondContact = SavedContactDto.fixture().copyWith(contactId: 'second-poster-contact');
    var requestCount = 0;
    when(userRepository.getContacts).thenAnswer((_) async {
      requestCount += 1;
      return ApiEnvelopeDto.fixture(data: [if (requestCount == 1) firstContact else secondContact]);
    });
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(userRepository),
        appAuthStateProvider.overrideWith(() => authState),
      ],
    )..listen(postContactStateProvider, (_, _) {});
    addTearDown(container.dispose);
    container.read(appAuthStateProvider);
    await container.read(postContactStateProvider.future);

    authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'second-poster');
    await container.pump();
    final contacts = await container.read(postContactStateProvider.future);

    expect(contacts.map((option) => option.contact.contactId).toList(), ['second-poster-contact']);
  });

  test('when the repository fails, it should expose the transport error', () async {
    when(userRepository.getContacts).thenThrow(StateError('transport failed'));
    final container = _PostContactStateTestHelpers.createContainer(userRepository);

    await expectLater(container.read(postContactStateProvider.future), throwsA(isA<StateError>()));
  });

  test('when a phone identifier is invalid, it should expose a format error', () async {
    when(userRepository.getContacts).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: [SavedContactDto.fixture().copyWith(method: ContactMethod.phoneCall, identifier: 'not a phone number')],
      ),
    );
    final container = _PostContactStateTestHelpers.createContainer(userRepository);

    await expectLater(container.read(postContactStateProvider.future), throwsFormatException);
  });

  test('when a contact method is unknown, it should expose an unsupported-method error', () async {
    when(userRepository.getContacts).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(data: [SavedContactDto.fixture().copyWith(method: ContactMethod.unknown)]),
    );
    final container = _PostContactStateTestHelpers.createContainer(userRepository);

    await expectLater(container.read(postContactStateProvider.future), throwsUnsupportedError);
  });

  test('when the last listener closes, reopening should expose fresh loading from a new request', () async {
    var requestCount = 0;
    final secondRequest = Completer<ApiEnvelopeDto<List<SavedContactDto>>>();
    when(userRepository.getContacts).thenAnswer((_) {
      requestCount += 1;
      if (requestCount == 1) return Future.value(ApiEnvelopeDto.fixture(data: <SavedContactDto>[]));
      return secondRequest.future;
    });
    final container = ProviderContainer(overrides: [userRepositoryProvider.overrideWithValue(userRepository)]);
    addTearDown(container.dispose);
    final firstSubscription = container.listen(postContactStateProvider, (_, _) {});
    await container.read(postContactStateProvider.future);

    firstSubscription.close();
    await container.pump();
    final secondSubscription = container.listen(postContactStateProvider, (_, _) {});
    addTearDown(secondSubscription.close);
    await container.pump();

    expect(
      (requestCount: requestCount, isLoading: container.read(postContactStateProvider).isLoading),
      (requestCount: 2, isLoading: true),
    );
  });
}

abstract final class _PostContactStateTestHelpers {
  static ProviderContainer createContainer(MockUserRepository userRepository) {
    final container = ProviderContainer(overrides: [userRepositoryProvider.overrideWithValue(userRepository)])
      ..listen(postContactStateProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }
}
