import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/job/job_contact_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockJobRepository repository;

  setUp(() {
    repository = MockJobRepository();
    when(
      () => repository.getJobContact(
        jobId: any(named: 'jobId'),
        contactId: any(named: 'contactId'),
      ),
    ).thenAnswer((_) async => _envelope());
  });

  group('JobContactState', () {
    test('when the provider is first read, it should expose the job contact data', () async {
      final container = _container(repository: repository);

      final jobContactState = await container.read(
        jobContactStateProvider(jobId: 'job-001', contactId: 'contact-001').future,
      );

      expect(jobContactState.contact.identifier, '+5511999999999');
    });

    test(
      'when the provider is first read, it should pass the requested job id and contact id to the repository',
      () async {
        final container = _container(repository: repository);

        await container.read(jobContactStateProvider(jobId: 'custom-job', contactId: 'custom-contact').future);

        verify(() => repository.getJobContact(jobId: 'custom-job', contactId: 'custom-contact')).called(1);
      },
    );

    test('when retry is called, it should fetch the contact again', () async {
      final container = _container(repository: repository);
      await container.read(jobContactStateProvider(jobId: 'retry-job', contactId: 'retry-contact').future);

      final secondContact = JobContactDto.fixture().copyWith(identifier: '+5511888888888');

      when(
        () => repository.getJobContact(
          jobId: any(named: 'jobId'),
          contactId: any(named: 'contactId'),
        ),
      ).thenAnswer((_) async => _envelope(contact: secondContact));

      await container.read(jobContactStateProvider(jobId: 'retry-job', contactId: 'retry-contact').notifier).retry();

      expect(
        container
            .read(jobContactStateProvider(jobId: 'retry-job', contactId: 'retry-contact'))
            .value
            ?.contact
            .identifier,
        '+5511888888888',
      );
    });

    test('when retry fails after a successful load, it should expose an AsyncError', () async {
      final container = _container(repository: repository);
      await container.read(jobContactStateProvider(jobId: 'retry-fail-job', contactId: 'retry-fail-contact').future);
      when(
        () => repository.getJobContact(
          jobId: any(named: 'jobId'),
          contactId: any(named: 'contactId'),
        ),
      ).thenThrow(StateError('retry failed'));

      await container
          .read(jobContactStateProvider(jobId: 'retry-fail-job', contactId: 'retry-fail-contact').notifier)
          .retry();

      expect(
        container.read(jobContactStateProvider(jobId: 'retry-fail-job', contactId: 'retry-fail-contact')).hasError,
        isTrue,
      );
    });

    test('when the initial fetch fails, it should expose an AsyncError', () async {
      final failingRepository = MockJobRepository();
      when(
        () => failingRepository.getJobContact(
          jobId: any(named: 'jobId'),
          contactId: any(named: 'contactId'),
        ),
      ).thenThrow(StateError('initial fetch failed'));

      final container = _container(repository: failingRepository);

      await expectLater(
        container.read(jobContactStateProvider(jobId: 'fail-job', contactId: 'fail-contact').future),
        throwsA(isA<StateError>()),
      );
    });
  });
}

ProviderContainer _container({required MockJobRepository repository}) {
  final container = ProviderContainer(overrides: [jobRepositoryProvider.overrideWithValue(repository)]);
  addTearDown(container.dispose);
  return container;
}

ApiEnvelopeDto<JobContactDto> _envelope({JobContactDto? contact}) {
  return ApiEnvelopeDto<JobContactDto>(
    data:
        contact ??
        JobContactDto.fixture().copyWith(contactMethod: JobContactMethod.whatsapp, identifier: '+5511999999999'),
    requestId: 'contact-req-001',
    timestamp: DateTime.parse('2026-06-06T00:37:46.623Z'),
    endpoint: '/job/test-job/contact/test-contact',
  );
}
