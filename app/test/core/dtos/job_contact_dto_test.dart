import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobContactDto', () {
    test('when parsing a job contact, it should map the contact method', () {
      final contact = JobContactDto.fromJson(const <String, Object?>{
        'identifier': '+5511999999999',
        'contactMethod': 'WHATSAPP',
      });

      expect(contact.contactMethod, JobContactMethod.whatsapp);
    });

    test('when parsing an unknown contact method, it should use unknown', () {
      final contact = JobContactDto.fromJson(const <String, Object?>{
        'identifier': '+5511999999999',
        'contactMethod': 'SMS',
      });

      expect(contact.contactMethod, JobContactMethod.unknown);
    });

    test('when parsing a job contact, it should map the identifier', () {
      final contact = JobContactDto.fromJson(const <String, Object?>{
        'identifier': '+5511888888888',
        'contactMethod': 'WHATSAPP',
      });

      expect(contact.identifier, '+5511888888888');
    });

    test('when serializing a job contact, it should use camelCase keys', () {
      final json = JobContactDto.fixture().toJson();

      expect(json, containsPair('contactMethod', 'WHATSAPP'));
    });
  });
}
