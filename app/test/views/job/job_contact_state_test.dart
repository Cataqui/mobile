import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/contact_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/job/job_contact_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

final class _JobContactStateTestHelpers {
  _JobContactStateTestHelpers._();

  static ProviderContainer container({
    required MockJobRepository repository,
    MockWhatsapp? whatsapp,
    MockPhoneNumber? phoneNumber,
  }) {
    final overrides = [jobRepositoryProvider.overrideWithValue(repository)];
    if (whatsapp != null) {
      overrides.add(whatsappProvider(identifier: '+5511999999999').overrideWithValue(whatsapp));
    }
    if (phoneNumber != null) {
      overrides.add(phoneNumberProvider(value: '+5511888888888').overrideWithValue(phoneNumber));
    }
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container;
  }
}

void main() {
  late MockJobRepository repository;
  late MockWhatsapp whatsapp;
  late MockPhoneNumber phoneNumber;

  setUp(() {
    registerFallbackValue(Uri());
    repository = MockJobRepository();
    whatsapp = MockWhatsapp();
    when(whatsapp.chat).thenAnswer((_) async => true);
    phoneNumber = MockPhoneNumber();
    when(phoneNumber.call).thenAnswer((_) async => true);
    when(
      () => repository.getJobContact(
        jobId: any(named: 'jobId'),
        contactId: any(named: 'contactId'),
      ),
    ).thenAnswer(
      (_) async => ApiEnvelopeDto<ContactDto>.fixture(
        data: ContactDto.fixture().copyWith(method: .whatsapp, identifier: '+5511999999999'),
      ),
    );
  });

  group('JobContactState', () {
    group('when the provider is first read', () {
      test('it should expose a null resting state (no fetch)', () async {
        final container = _JobContactStateTestHelpers.container(repository: repository);

        await container.read(jobContactStateProvider(jobId: 'job-001', contactId: 'contact-001').future);

        verifyNever(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        );
      });

      test('it should not fetch the contact from the repository', () async {
        final container = _JobContactStateTestHelpers.container(repository: repository);

        await container.read(jobContactStateProvider(jobId: 'job-001', contactId: 'contact-001').future);

        expect(container.read(jobContactStateProvider(jobId: 'job-001', contactId: 'contact-001')).hasError, isFalse);
      });
    });

    group('when contact is called', () {
      test('it should fetch the job contact with the correct job id and contact id', () async {
        final container = _JobContactStateTestHelpers.container(
          repository: repository,
          whatsapp: whatsapp,
          phoneNumber: phoneNumber,
        );
        final provider = jobContactStateProvider(jobId: 'job-call', contactId: 'contact-call');
        await container.read(provider.future);

        await container.read(provider.notifier).contact();

        verify(() => repository.getJobContact(jobId: 'job-call', contactId: 'contact-call')).called(1);
      });

      test('when the contact fetch succeeds with a whatsapp method, it should launch WhatsApp', () async {
        final container = _JobContactStateTestHelpers.container(repository: repository, whatsapp: whatsapp);

        final notifier = container.read(jobContactStateProvider(jobId: 'job-wpp', contactId: 'contact-wpp').notifier);
        await notifier.contact();

        verify(whatsapp.chat).called(1);
      });

      test('when the contact fetch succeeds with a phone call method, it should launch a phone call', () async {
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenAnswer(
          (_) async => ApiEnvelopeDto<ContactDto>.fixture(
            data: ContactDto.fixture().copyWith(method: .phoneCall, identifier: '+5511888888888'),
          ),
        );

        final container = _JobContactStateTestHelpers.container(repository: repository, phoneNumber: phoneNumber);

        final notifier = container.read(
          jobContactStateProvider(jobId: 'job-phone', contactId: 'contact-phone').notifier,
        );
        await notifier.contact();

        verify(phoneNumber.call).called(1);
      });

      test('when WhatsApp rejects the launch, it should expose an AsyncError', () async {
        when(whatsapp.chat).thenAnswer((_) async => false);
        final container = _JobContactStateTestHelpers.container(repository: repository, whatsapp: whatsapp);
        final provider = jobContactStateProvider(jobId: 'job-wpp-unavailable', contactId: 'contact-wpp');

        await container.read(provider.notifier).contact();

        expect(container.read(provider).hasError, isTrue);
      });

      test('when the phone app rejects the launch, it should expose an AsyncError', () async {
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenAnswer(
          (_) async => ApiEnvelopeDto<ContactDto>.fixture(
            data: ContactDto.fixture().copyWith(method: .phoneCall, identifier: '+5511888888888'),
          ),
        );
        when(phoneNumber.call).thenAnswer((_) async => false);
        final container = _JobContactStateTestHelpers.container(repository: repository, phoneNumber: phoneNumber);
        final provider = jobContactStateProvider(jobId: 'job-phone-unavailable', contactId: 'contact-phone');

        await container.read(provider.notifier).contact();

        expect(container.read(provider).hasError, isTrue);
      });

      test('when detail closes during the contact fetch, it should finish without launching another app', () async {
        final contactResponse = Completer<ApiEnvelopeDto<ContactDto>>();
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenAnswer((_) => contactResponse.future);
        final container = _JobContactStateTestHelpers.container(repository: repository, whatsapp: whatsapp);
        final provider = jobContactStateProvider(jobId: 'job-closed', contactId: 'contact-closed');
        final subscription = container.listen(provider, (_, _) {});
        final contact = container.read(provider.notifier).contact();

        subscription.close();
        await container.pump();
        contactResponse.complete(
          ApiEnvelopeDto<ContactDto>.fixture(
            data: ContactDto.fixture().copyWith(method: .whatsapp, identifier: '+5511999999999'),
          ),
        );

        await expectLater(contact, completes);
        verifyNever(whatsapp.chat);
      });

      test('when detail closes during an external launch, it should finish without writing disposed state', () async {
        final launchResult = Completer<bool>();
        final launchStarted = Completer<void>();
        when(whatsapp.chat).thenAnswer((_) {
          launchStarted.complete();
          return launchResult.future;
        });
        final container = _JobContactStateTestHelpers.container(repository: repository, whatsapp: whatsapp);
        final provider = jobContactStateProvider(jobId: 'job-launch-closed', contactId: 'contact-launch-closed');
        final subscription = container.listen(provider, (_, _) {});
        final contact = container.read(provider.notifier).contact();
        await launchStarted.future;

        subscription.close();
        await container.pump();
        launchResult.complete(true);

        await expectLater(contact, completes);
      });

      test('when the contact method is unknown, it should not launch WhatsApp or telephony', () async {
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenAnswer(
          (_) async => ApiEnvelopeDto<ContactDto>.fixture(data: ContactDto.fixture().copyWith(method: .unknown)),
        );

        final container = _JobContactStateTestHelpers.container(
          repository: repository,
          whatsapp: whatsapp,
          phoneNumber: phoneNumber,
        );

        final notifier = container.read(
          jobContactStateProvider(jobId: 'job-unknown', contactId: 'contact-unknown').notifier,
        );
        await notifier.contact();

        verifyNever(whatsapp.chat);
        verifyNever(phoneNumber.call);
      });

      test('when the fetch fails, it should expose an AsyncError', () async {
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenThrow(StateError('fetch failed'));

        final container = _JobContactStateTestHelpers.container(repository: repository);

        final notifier = container.read(jobContactStateProvider(jobId: 'job-fail', contactId: 'contact-fail').notifier);
        await notifier.contact();

        expect(container.read(jobContactStateProvider(jobId: 'job-fail', contactId: 'contact-fail')).hasError, isTrue);
      });

      test('when the fetch fails, it should not launch WhatsApp or telephony', () async {
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenThrow(StateError('fetch failed'));

        final container = _JobContactStateTestHelpers.container(
          repository: repository,
          whatsapp: whatsapp,
          phoneNumber: phoneNumber,
        );

        final notifier = container.read(
          jobContactStateProvider(jobId: 'job-fail-nolaunch', contactId: 'contact-fail-nolaunch').notifier,
        );
        await notifier.contact();

        verifyNever(whatsapp.chat);
        verifyNever(phoneNumber.call);
      });

      test('when the dispatch itself fails, it should expose an AsyncError', () async {
        when(whatsapp.chat).thenThrow(StateError('launch failed'));

        final container = _JobContactStateTestHelpers.container(repository: repository, whatsapp: whatsapp);

        final notifier = container.read(
          jobContactStateProvider(jobId: 'job-dispatch-fail', contactId: 'contact-dispatch-fail').notifier,
        );
        await notifier.contact();

        expect(
          container
              .read(jobContactStateProvider(jobId: 'job-dispatch-fail', contactId: 'contact-dispatch-fail'))
              .hasError,
          isTrue,
        );
      });
    });
  });
}
