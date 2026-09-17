import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/saved_contact_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/post/contact/post_contact_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

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
            contactMethod: JobContactMethod.whatsapp,
            identifier: 'Ventairy.Dev',
          ),
          SavedContactDto.fixture().copyWith(
            contactId: 'phone-us',
            contactMethod: JobContactMethod.phoneCall,
            identifier: '+1 (202) 555-0123',
          ),
          SavedContactDto.fixture().copyWith(
            contactId: 'whatsapp-br',
            contactMethod: JobContactMethod.whatsapp,
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

  test('when the repository fails, it should expose the transport error', () async {
    when(userRepository.getContacts).thenThrow(StateError('transport failed'));
    final container = _PostContactStateTestHelpers.createContainer(userRepository);

    await expectLater(container.read(postContactStateProvider.future), throwsA(isA<StateError>()));
  });

  test('when a phone identifier is invalid, it should expose a format error', () async {
    when(userRepository.getContacts).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: [
          SavedContactDto.fixture().copyWith(
            contactMethod: JobContactMethod.phoneCall,
            identifier: 'not a phone number',
          ),
        ],
      ),
    );
    final container = _PostContactStateTestHelpers.createContainer(userRepository);

    await expectLater(container.read(postContactStateProvider.future), throwsFormatException);
  });

  test('when a contact method is unknown, it should expose an unsupported-method error', () async {
    when(userRepository.getContacts).thenAnswer(
      (_) async =>
          ApiEnvelopeDto.fixture(data: [SavedContactDto.fixture().copyWith(contactMethod: JobContactMethod.unknown)]),
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
