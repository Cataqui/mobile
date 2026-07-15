import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/job_contact_reference_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/views/job/job_contact_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Translations i18n;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
  });

  group('JobContactButton Golden Tests', () {
    goldenTest(
      'when the contact method is whatsapp, it should render the WhatsApp button with green accent on dark background',
      fileName: 'job_contact_button_whatsapp',
      builder: () => _buildContactButton(
        contactMethod: JobContactMethod.whatsapp,
        i18n: i18n,
      ),
    );

    goldenTest(
      'when the contact method is phone call, it should render the phone call button with green background and dark text',
      fileName: 'job_contact_button_phone_call',
      builder: () => _buildContactButton(
        contactMethod: JobContactMethod.phoneCall,
        i18n: i18n,
      ),
    );

    goldenTest(
      'when the contact method is unknown, it should render the disabled unavailable button with circle block icon',
      fileName: 'job_contact_button_unknown',
      builder: () => _buildContactButton(
        contactMethod: JobContactMethod.unknown,
        i18n: i18n,
      ),
    );
  });
}

Widget _buildContactButton({
  required JobContactMethod contactMethod,
  required Translations i18n,
}) {
  return SizedBox(
    width: 390,
    height: 80,
    child: ProviderScope(
      overrides: [
        translationProvider.overrideWithValue(i18n),
      ],
      child: TickerMode(
        enabled: false,
        child: JobContactButton(
          jobId: 'test-job',
          contactReference: JobContactReferenceDto.fixture().copyWith(
            contactMethod: contactMethod,
          ),
          isLoading: false,
        ),
      ),
    ),
  );
}
