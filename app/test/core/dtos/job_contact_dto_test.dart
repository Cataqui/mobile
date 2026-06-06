import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/dtos/job_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dto_json_fixtures.dart';

void main() {
  group('JobContactDto', () {
    test('when parsing a job contact, it should map the contact method', () {
      final contact = JobContactDto.fromJson(
        detailedJobJson['contact']! as Map<String, Object?>,
      );

      expect(contact.contactMethod, JobContactMethod.whatsapp);
    });

    test('when parsing an unknown contact method, it should use unknown', () {
      final contact = JobContactDto.fromJson(const <String, Object?>{
        'name': 'Cataqui Teste',
        'phone_number': '+5511999999999',
        'contact_method': 'SMS',
      });

      expect(contact.contactMethod, JobContactMethod.unknown);
    });
  });
}
