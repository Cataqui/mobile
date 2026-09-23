import 'package:cataqui_app/core/dtos/saved_contact_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavedContactDto', () {
    test('when parsing a saved contact, it should map the contact id', () {
      final contact = SavedContactDto.fromJson(_SavedContactDtoTestData.json);

      expect(contact.contactId, 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
    });

    test('when parsing a saved contact, it should map the contact method', () {
      final contact = SavedContactDto.fromJson(_SavedContactDtoTestData.json);

      expect(contact.contactMethod, JobContactMethod.whatsapp);
    });

    test('when parsing a saved contact, it should map the identifier', () {
      final contact = SavedContactDto.fromJson(_SavedContactDtoTestData.json);

      expect(contact.identifier, '+5511888888888');
    });

    test('when parsing an unknown contact method, it should use unknown', () {
      final contact = SavedContactDto.fromJson(<String, Object?>{..._SavedContactDtoTestData.json, 'method': 'SMS'});

      expect(contact.contactMethod, JobContactMethod.unknown);
    });
  });
}

abstract final class _SavedContactDtoTestData {
  static const json = <String, Object?>{
    'contactId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'method': 'WHATSAPP',
    'identifier': '+5511888888888',
  };
}
