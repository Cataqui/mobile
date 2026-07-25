import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/job_contact_reference_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/job/job_contact_button.dart';
import 'package:cataqui_app/views/job/job_data.dart';
import 'package:cataqui_app/views/job/job_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locale/locale.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../mocks.dart';
import 'job_view_test_helpers.dart';

void main() {
  late Translations i18n;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
  });

  group('JobContactButton Golden Tests', () {
    goldenTest(
      'when the contact method is whatsapp, it should render the WhatsApp button with green accent on dark background',
      fileName: 'job_contact_button_whatsapp',
      builder: () => _buildContactButton(contactMethod: JobContactMethod.whatsapp, i18n: i18n),
    );

    goldenTest(
      'when the contact method is phone call, it should render the phone call button with green background and dark text',
      fileName: 'job_contact_button_phone_call',
      builder: () => _buildContactButton(contactMethod: JobContactMethod.phoneCall, i18n: i18n),
    );

    goldenTest(
      'when the contact method is unknown, it should render the disabled unavailable button with circle block icon',
      fileName: 'job_contact_button_unknown',
      builder: () => _buildContactButton(contactMethod: JobContactMethod.unknown, i18n: i18n),
    );

    goldenTest(
      'when the contact fetch fails with a general error, it should show the error toast',
      fileName: 'job_contact_button_general_error_toast',
      builder: () {
        final repository = MockJobRepository();
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenThrow(StateError('network error'));
        return _buildContactButtonWithRepository(repository: repository, i18n: i18n);
      },
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.text(i18n.job.contactButton.whatsapp));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    goldenTest(
      'when the contact fetch fails with an offline connection error, it should show the offline toast with wifi exclamation icon',
      fileName: 'job_contact_button_offline_toast',
      builder: () {
        final repository = MockJobRepository();
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: const OfflineConnectionDioException(message: 'No internet connection'),
          ),
        );
        return _buildContactButtonWithRepository(repository: repository, i18n: i18n);
      },
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.text(i18n.job.contactButton.whatsapp));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}

Widget _buildContactButton({required JobContactMethod contactMethod, required Translations i18n}) {
  final contactReference = JobContactReferenceDto.fixture().copyWith(
    contactMethod: contactMethod,
    contactId: 'test-contact',
  );

  final jobData = JobData(job: JobDto.fixture().copyWith(contactReference: contactReference));

  final fakeJobState = FakeJobState(initialAsyncValue: AsyncData(jobData));

  return SizedBox(
    width: 390,
    height: 80,
    child: ProviderScope(
      overrides: [
        jobStateProvider('test-job').overrideWith(() => fakeJobState),
        translationProvider.overrideWithValue(i18n),
      ],
      child: const TickerMode(enabled: false, child: JobContactButton(jobId: 'test-job')),
    ),
  );
}

Widget _buildContactButtonWithRepository({required MockJobRepository repository, required Translations i18n}) {
  final contactReference = JobContactReferenceDto.fixture().copyWith(
    contactMethod: JobContactMethod.whatsapp,
    contactId: 'test-contact',
  );

  final jobData = JobData(job: JobDto.fixture().copyWith(contactReference: contactReference));

  final fakeJobState = FakeJobState(initialAsyncValue: AsyncData(jobData));

  return SizedBox(
    width: 390,
    height: 500,
    child: ProviderScope(
      overrides: [
        jobStateProvider('test-job').overrideWith(() => fakeJobState),
        jobRepositoryProvider.overrideWithValue(repository),
        translationProvider.overrideWithValue(i18n),
      ],
      child: const Center(child: JobContactButton(jobId: 'test-job')),
    ),
  );
}
