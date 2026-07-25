import 'package:cataqui_app/core/dtos/job_contact_reference_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobContactReferenceDto', () {
    test('when parsing a contact reference, it should map the contact id', () {
      final ref = JobContactReferenceDto.fromJson(const <String, Object?>{
        'contact_id': 'cm3x-contact-1',
        'contact_method': 'WHATSAPP',
      });

      expect(ref.contactId, 'cm3x-contact-1');
    });

    test('when parsing a contact reference, it should map the contact method', () {
      final ref = JobContactReferenceDto.fromJson(const <String, Object?>{
        'contact_id': 'cm3x-contact-1',
        'contact_method': 'WHATSAPP',
      });

      expect(ref.contactMethod, JobContactMethod.whatsapp);
    });

    test('when parsing an unknown contact method, it should use unknown', () {
      final ref = JobContactReferenceDto.fromJson(const <String, Object?>{
        'contact_id': 'cm3x-contact-1',
        'contact_method': 'SMS',
      });

      expect(ref.contactMethod, JobContactMethod.unknown);
    });
  });
}
