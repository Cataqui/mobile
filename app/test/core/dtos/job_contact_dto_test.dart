import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/dtos/job_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobContactDto', () {
    test('when parsing a job contact, it should map the contact method', () {
      final contact = JobContactDto.fixture().copyWith(contactMethod: JobContactMethod.whatsapp);

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
