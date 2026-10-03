import 'package:cataqui_app/core/dtos/contact_dto.dart';
import 'package:cataqui_app/core/enums/contact_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContactDto', () {
    test('when parsing a job contact, it should map the contact method', () {
      final contact = ContactDto.fromJson(const <String, Object?>{
        'identifier': '+5511999999999',
        'method': 'WHATSAPP',
      });

      expect(contact.method, ContactMethod.whatsapp);
    });

    test('when parsing an unknown contact method, it should use unknown', () {
      final contact = ContactDto.fromJson(const <String, Object?>{'identifier': '+5511999999999', 'method': 'SMS'});

      expect(contact.method, ContactMethod.unknown);
    });

    test('when parsing a job contact, it should map the identifier', () {
      final contact = ContactDto.fromJson(const <String, Object?>{
        'identifier': '+5511888888888',
        'method': 'WHATSAPP',
      });

      expect(contact.identifier, '+5511888888888');
    });

    test('when serializing a job contact, it should use the method wire key', () {
      final json = ContactDto.fixture().toJson();

      expect(json, containsPair('method', 'WHATSAPP'));
    });
  });
}
