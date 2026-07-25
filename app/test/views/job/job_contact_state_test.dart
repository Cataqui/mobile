import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
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
    MockTelephony? telephony,
  }) {
    final overrides = [jobRepositoryProvider.overrideWithValue(repository)];
    if (whatsapp != null) {
      overrides.add(whatsappProvider.overrideWithValue(whatsapp));
    }
    if (telephony != null) {
      overrides.add(telephonyProvider.overrideWithValue(telephony));
    }
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container;
  }
}

void main() {
  late MockJobRepository repository;

  setUp(() {
    registerFallbackValue(Uri());
    repository = MockJobRepository();
    when(
      () => repository.getJobContact(
        jobId: any(named: 'jobId'),
        contactId: any(named: 'contactId'),
      ),
    ).thenAnswer(
      (_) async => ApiEnvelopeDto<JobContactDto>.fixture(
        data: JobContactDto.fixture().copyWith(contactMethod: JobContactMethod.whatsapp, identifier: '+5511999999999'),
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
        final whatsapp = MockWhatsapp();
        final telephony = MockTelephony();
        final container = _JobContactStateTestHelpers.container(
          repository: repository,
          whatsapp: whatsapp,
          telephony: telephony,
        );
        final provider = jobContactStateProvider(jobId: 'job-call', contactId: 'contact-call');
        await container.read(provider.future);

        await container.read(provider.notifier).contact();

        verify(() => repository.getJobContact(jobId: 'job-call', contactId: 'contact-call')).called(1);
      });

      test('when the contact fetch succeeds with a whatsapp method, it should launch WhatsApp', () async {
        final whatsapp = MockWhatsapp();
        when(() => whatsapp.launchChat(number: any(named: 'number'))).thenAnswer((_) async => true);

        final container = _JobContactStateTestHelpers.container(repository: repository, whatsapp: whatsapp);

        final notifier = container.read(jobContactStateProvider(jobId: 'job-wpp', contactId: 'contact-wpp').notifier);
        await notifier.contact();

        verify(() => whatsapp.launchChat(number: '+5511999999999')).called(1);
      });

      test('when the contact fetch succeeds with a phone call method, it should launch a phone call', () async {
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenAnswer(
          (_) async => ApiEnvelopeDto<JobContactDto>.fixture(
            data: JobContactDto.fixture().copyWith(
              contactMethod: JobContactMethod.phoneCall,
              identifier: '+5511888888888',
            ),
          ),
        );

        final telephony = MockTelephony();
        when(() => telephony.call(number: any(named: 'number'))).thenAnswer((_) async => true);

        final container = _JobContactStateTestHelpers.container(repository: repository, telephony: telephony);

        final notifier = container.read(
          jobContactStateProvider(jobId: 'job-phone', contactId: 'contact-phone').notifier,
        );
        await notifier.contact();

        verify(() => telephony.call(number: '+5511888888888')).called(1);
      });

      test('when the contact method is unknown, it should not launch WhatsApp or telephony', () async {
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenAnswer(
          (_) async => ApiEnvelopeDto<JobContactDto>.fixture(
            data: JobContactDto.fixture().copyWith(contactMethod: JobContactMethod.unknown),
          ),
        );

        final whatsapp = MockWhatsapp();
        final telephony = MockTelephony();
        final container = _JobContactStateTestHelpers.container(
          repository: repository,
          whatsapp: whatsapp,
          telephony: telephony,
        );

        final notifier = container.read(
          jobContactStateProvider(jobId: 'job-unknown', contactId: 'contact-unknown').notifier,
        );
        await notifier.contact();

        verifyNever(() => whatsapp.launchChat(number: any(named: 'number')));
        verifyNever(() => telephony.call(number: any(named: 'number')));
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

        final whatsapp = MockWhatsapp();
        final telephony = MockTelephony();
        final container = _JobContactStateTestHelpers.container(
          repository: repository,
          whatsapp: whatsapp,
          telephony: telephony,
        );

        final notifier = container.read(
          jobContactStateProvider(jobId: 'job-fail-nolaunch', contactId: 'contact-fail-nolaunch').notifier,
        );
        await notifier.contact();

        verifyNever(() => whatsapp.launchChat(number: any(named: 'number')));
        verifyNever(() => telephony.call(number: any(named: 'number')));
      });

      test('when the dispatch itself fails, it should expose an AsyncError', () async {
        final whatsapp = MockWhatsapp();
        when(() => whatsapp.launchChat(number: any(named: 'number'))).thenThrow(StateError('launch failed'));

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
