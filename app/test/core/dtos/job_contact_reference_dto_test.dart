import 'package:cataqui_app/core/dtos/job_contact_reference_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobContactReferenceDto', () {
    test('when parsing a contact reference, it should map the contact id', () {
      final ref = JobContactReferenceDto.fromJson(const <String, Object?>{
        'contactId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'contactMethod': 'WHATSAPP',
      });

      expect(ref.contactId, 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
    });

    test('when parsing a contact reference, it should map the contact method', () {
      final ref = JobContactReferenceDto.fromJson(const <String, Object?>{
        'contactId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'contactMethod': 'WHATSAPP',
      });

      expect(ref.contactMethod, JobContactMethod.whatsapp);
    });

    test('when parsing an unknown contact method, it should use unknown', () {
      final ref = JobContactReferenceDto.fromJson(const <String, Object?>{
        'contactId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'contactMethod': 'SMS',
      });

      expect(ref.contactMethod, JobContactMethod.unknown);
    });

    test('when serializing a contact reference, it should use camelCase keys', () {
      final json = JobContactReferenceDto.fixture().toJson();

      expect(json.keys, containsAll(<String>['contactId', 'contactMethod']));
    });
  });
}
