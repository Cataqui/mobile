import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/dtos/job_contact_reference_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/job/job_contact_button.dart';
import 'package:cataqui_app/views/job/job_data.dart';
import 'package:cataqui_app/views/job/job_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';
import 'job_view_test_helpers.dart';

class _ButtonTestHelpers {
  _ButtonTestHelpers._();

  static JobData jobData({required JobContactMethod contactMethod}) {
    return JobData(
      job: JobDto.fixture().copyWith(
        contactReference: JobContactReferenceDto.fixture().copyWith(
          contactMethod: contactMethod,
          contactId: 'test-contact',
        ),
      ),
    );
  }

  static Widget buildApp({
    required AsyncValue<JobData> jobStateValue,
    required Translations i18n,
    required MockJobRepository repository,
    required MockWhatsapp whatsapp,
    required MockTelephony telephony,
  }) {
    final fakeJobState = FakeJobState(initialAsyncValue: jobStateValue);

    return ProviderScope(
      overrides: [
        jobStateProvider('test-job').overrideWith(() => fakeJobState),
        jobRepositoryProvider.overrideWithValue(repository),
        whatsappProvider.overrideWithValue(whatsapp),
        telephonyProvider.overrideWithValue(telephony),
        translationProvider.overrideWithValue(i18n),
      ],
      child: const TestApp(child: JobContactButton(jobId: 'test-job')),
    );
  }
}

void main() {
  late Translations i18n;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
    registerFallbackValue(Uri());
  });

  group('JobContactButton', () {
    late MockJobRepository repository;
    late MockWhatsapp whatsapp;
    late MockTelephony telephony;

    setUp(() {
      repository = MockJobRepository();
      when(
        () => repository.getJobContact(
          jobId: any(named: 'jobId'),
          contactId: any(named: 'contactId'),
        ),
      ).thenAnswer(
        (_) async => ApiEnvelopeDto<JobContactDto>.fixture(
          data: JobContactDto.fixture().copyWith(
            contactMethod: JobContactMethod.whatsapp,
            identifier: '+5511999999999',
          ),
        ),
      );

      whatsapp = MockWhatsapp();
      when(() => whatsapp.launchChat(number: any(named: 'number'))).thenAnswer((_) async => true);

      telephony = MockTelephony();
      when(() => telephony.call(number: any(named: 'number'))).thenAnswer((_) async => true);
    });

    group('when the job is loading', () {
      testWidgets('it should render the button in loading state', (tester) async {
        await tester.pumpWidget(
          _ButtonTestHelpers.buildApp(
            jobStateValue: const AsyncLoading<JobData>(),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.pump();

        final button = tester.widget<MateoButton>(find.byType(MateoButton));
        expect(button.isLoading, isTrue);
      });
    });

    group('when contact method is whatsapp', () {
      testWidgets('it should render the "Enviar Mensagem" label', (tester) async {
        await tester.pumpWidget(
          _ButtonTestHelpers.buildApp(
            jobStateValue: AsyncData(_ButtonTestHelpers.jobData(contactMethod: JobContactMethod.whatsapp)),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(i18n.job.contactButton.whatsapp), findsOneWidget);
      });

      testWidgets('it should display the whatsapp icon', (tester) async {
        await tester.pumpWidget(
          _ButtonTestHelpers.buildApp(
            jobStateValue: AsyncData(_ButtonTestHelpers.jobData(contactMethod: JobContactMethod.whatsapp)),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(MateoButton), findsOneWidget);
      });

      testWidgets('when tapped, it should fetch the contact and launch WhatsApp', (tester) async {
        await tester.pumpWidget(
          _ButtonTestHelpers.buildApp(
            jobStateValue: AsyncData(_ButtonTestHelpers.jobData(contactMethod: JobContactMethod.whatsapp)),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text(i18n.job.contactButton.whatsapp));
        await tester.pumpAndSettle();

        verify(() => whatsapp.launchChat(number: '+5511999999999')).called(1);
      });
    });

    group('when contact method is phone call', () {
      testWidgets('it should render the "Ligar agora" label', (tester) async {
        await tester.pumpWidget(
          _ButtonTestHelpers.buildApp(
            jobStateValue: AsyncData(_ButtonTestHelpers.jobData(contactMethod: JobContactMethod.phoneCall)),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(i18n.job.contactButton.phoneCall), findsOneWidget);
      });

      testWidgets('when tapped, it should fetch the contact and launch a phone call', (tester) async {
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

        await tester.pumpWidget(
          _ButtonTestHelpers.buildApp(
            jobStateValue: AsyncData(_ButtonTestHelpers.jobData(contactMethod: JobContactMethod.phoneCall)),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text(i18n.job.contactButton.phoneCall));
        await tester.pumpAndSettle();

        verify(() => telephony.call(number: '+5511888888888')).called(1);
      });
    });

    group('when contact method is unknown', () {
      testWidgets('it should render the "Indisponível" label', (tester) async {
        await tester.pumpWidget(
          _ButtonTestHelpers.buildApp(
            jobStateValue: AsyncData(_ButtonTestHelpers.jobData(contactMethod: JobContactMethod.unknown)),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(i18n.job.contactButton.unknown), findsOneWidget);
      });

      testWidgets('tapping the button should not trigger any action', (tester) async {
        await tester.pumpWidget(
          _ButtonTestHelpers.buildApp(
            jobStateValue: AsyncData(_ButtonTestHelpers.jobData(contactMethod: JobContactMethod.unknown)),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text(i18n.job.contactButton.unknown));
        await tester.pumpAndSettle();

        verifyNever(() => whatsapp.launchChat(number: any(named: 'number')));
        verifyNever(() => telephony.call(number: any(named: 'number')));
      });
    });

    group('when the contact fetch fails with a general error', () {
      testWidgets('it should show the generic error toast message', (tester) async {
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenThrow(StateError('network error'));

        await tester.pumpWidget(
          _ButtonTestHelpers.buildApp(
            jobStateValue: AsyncData(_ButtonTestHelpers.jobData(contactMethod: JobContactMethod.whatsapp)),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text(i18n.job.contactButton.whatsapp));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text(i18n.job.contactButton.error.genericMessage), findsOneWidget);
      });

      testWidgets('it should not launch WhatsApp or telephony', (tester) async {
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenThrow(StateError('network error'));

        await tester.pumpWidget(
          _ButtonTestHelpers.buildApp(
            jobStateValue: AsyncData(_ButtonTestHelpers.jobData(contactMethod: JobContactMethod.whatsapp)),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text(i18n.job.contactButton.whatsapp));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        verifyNever(() => whatsapp.launchChat(number: any(named: 'number')));
        verifyNever(() => telephony.call(number: any(named: 'number')));
      });
    });

    group('when the contact fetch fails with an offline connection error', () {
      testWidgets('it should show the offline error toast message', (tester) async {
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

        await tester.pumpWidget(
          _ButtonTestHelpers.buildApp(
            jobStateValue: AsyncData(_ButtonTestHelpers.jobData(contactMethod: JobContactMethod.whatsapp)),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text(i18n.job.contactButton.whatsapp));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text(i18n.job.contactButton.error.offlineMessage), findsOneWidget);
      });

      testWidgets('it should not launch WhatsApp or telephony', (tester) async {
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

        await tester.pumpWidget(
          _ButtonTestHelpers.buildApp(
            jobStateValue: AsyncData(_ButtonTestHelpers.jobData(contactMethod: JobContactMethod.whatsapp)),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text(i18n.job.contactButton.whatsapp));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        verifyNever(() => whatsapp.launchChat(number: any(named: 'number')));
        verifyNever(() => telephony.call(number: any(named: 'number')));
      });
    });
  });
}
