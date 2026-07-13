import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/dtos/job_contact_reference_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/views/job/job_contact_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qui/qui.dart';

import '../../mocks.dart';

Widget _buildApp({
  required JobContactReferenceDto contactReference,
  required Translations i18n,
  required MockJobRepository repository,
  required MockWhatsapp whatsapp,
  required MockTelephony telephony,
}) {
  return ProviderScope(
    overrides: [
      jobRepositoryProvider.overrideWithValue(repository),
      whatsappProvider.overrideWithValue(whatsapp),
      telephonyProvider.overrideWithValue(telephony),
      translationProvider.overrideWithValue(i18n),
    ],
    child: MaterialApp(
      theme: QuiTheme.light(),
      home: Scaffold(
        body: Center(
          child: JobContactButton(jobId: 'test-job', contactReference: contactReference),
        ),
      ),
    ),
  );
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
      whatsapp = MockWhatsapp();
      telephony = MockTelephony();
    });

    group('when contact method is whatsapp', () {
      testWidgets('it should render the "Enviar Mensagem" label', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            contactReference: JobContactReferenceDto.fixture().copyWith(contactMethod: JobContactMethod.whatsapp),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        expect(find.text(i18n.job.contactButton.whatsapp), findsOneWidget);
      });

      testWidgets('it should display the whatsapp icon', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            contactReference: JobContactReferenceDto.fixture().copyWith(contactMethod: JobContactMethod.whatsapp),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        expect(find.byType(QuiButton), findsOneWidget);
      });
    });

    group('when contact method is phone call', () {
      testWidgets('it should render the "Ligar agora" label', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            contactReference: JobContactReferenceDto.fixture().copyWith(contactMethod: JobContactMethod.phoneCall),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        expect(find.text(i18n.job.contactButton.phoneCall), findsOneWidget);
      });

      testWidgets('it should display the phone icon', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            contactReference: JobContactReferenceDto.fixture().copyWith(contactMethod: JobContactMethod.phoneCall),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        expect(find.byType(QuiButton), findsOneWidget);
      });
    });

    group('when contact method is unknown', () {
      testWidgets('it should render the "Indisponível" label', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            contactReference: JobContactReferenceDto.fixture().copyWith(contactMethod: JobContactMethod.unknown),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        expect(find.text(i18n.job.contactButton.unknown), findsOneWidget);
      });

      testWidgets('tapping the button should not trigger any action', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            contactReference: JobContactReferenceDto.fixture().copyWith(contactMethod: JobContactMethod.unknown),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.tap(find.text(i18n.job.contactButton.unknown));
        await tester.pumpAndSettle();

        expect(find.text(i18n.job.contactButton.unknown), findsOneWidget);
      });
    });

    group('when pressed with whatsapp method', () {
      testWidgets('it should fetch the contact and launch WhatsApp', (tester) async {
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenAnswer(
          (_) async => ApiEnvelopeDto<JobContactDto>(
            data: JobContactDto.fixture().copyWith(
              contactMethod: JobContactMethod.whatsapp,
              identifier: '+5511999999999',
            ),
            requestId: 'req-001',
            timestamp: DateTime(2026, 7, 10),
            endpoint: '/job/test-job/contact/test-contact',
          ),
        );

        when(() => whatsapp.launchChat(number: any(named: 'number'))).thenAnswer((_) async => true);

        await tester.pumpWidget(
          _buildApp(
            contactReference: JobContactReferenceDto.fixture().copyWith(
              contactMethod: JobContactMethod.whatsapp,
              contactId: 'test-contact',
            ),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.tap(find.text(i18n.job.contactButton.whatsapp));
        await tester.pumpAndSettle();

        verify(() => whatsapp.launchChat(number: '+5511999999999')).called(1);
      });
    });

    group('when pressed with phone call method', () {
      testWidgets('it should fetch the contact and launch a phone call', (tester) async {
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenAnswer(
          (_) async => ApiEnvelopeDto<JobContactDto>(
            data: JobContactDto.fixture().copyWith(
              contactMethod: JobContactMethod.phoneCall,
              identifier: '+5511999999999',
            ),
            requestId: 'req-001',
            timestamp: DateTime(2026, 7, 10),
            endpoint: '/job/test-job/contact/test-contact',
          ),
        );

        when(() => telephony.call(number: any(named: 'number'))).thenAnswer((_) async => true);

        await tester.pumpWidget(
          _buildApp(
            contactReference: JobContactReferenceDto.fixture().copyWith(
              contactMethod: JobContactMethod.phoneCall,
              contactId: 'test-contact',
            ),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.tap(find.text(i18n.job.contactButton.phoneCall));
        await tester.pumpAndSettle();

        verify(() => telephony.call(number: '+5511999999999')).called(1);
      });
    });

    group('when contact fetch fails', () {
      testWidgets('it should silently handle the error without crashing', (tester) async {
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenThrow(StateError('network error'));

        await tester.pumpWidget(
          _buildApp(
            contactReference: JobContactReferenceDto.fixture().copyWith(
              contactMethod: JobContactMethod.whatsapp,
              contactId: 'test-contact',
            ),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.tap(find.text(i18n.job.contactButton.whatsapp));
        await tester.pumpAndSettle();

        expect(find.text(i18n.job.contactButton.whatsapp), findsOneWidget);
      });

      testWidgets('it should not launch WhatsApp or telephony', (tester) async {
        when(
          () => repository.getJobContact(
            jobId: any(named: 'jobId'),
            contactId: any(named: 'contactId'),
          ),
        ).thenThrow(StateError('network error'));

        await tester.pumpWidget(
          _buildApp(
            contactReference: JobContactReferenceDto.fixture().copyWith(
              contactMethod: JobContactMethod.whatsapp,
              contactId: 'test-contact',
            ),
            i18n: i18n,
            repository: repository,
            whatsapp: whatsapp,
            telephony: telephony,
          ),
        );

        await tester.tap(find.text(i18n.job.contactButton.whatsapp));
        await tester.pumpAndSettle();

        verifyNever(() => whatsapp.launchChat(number: any(named: 'number')));
        verifyNever(() => telephony.call(number: any(named: 'number')));
      });
    });
  });
}
