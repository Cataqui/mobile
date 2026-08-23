import 'package:cataqui_app/core/dtos/address_details_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

void main() {
  group('AddressDetailsDto', () {
    test('when address details omit coordinates, it should reject the malformed response', () {
      expect(() => AddressDetailsDto.fromJson(const <String, Object?>{}), throwsA(isA<MissingRequiredKeysException>()));
    });

    test('when address details contain invalid coordinates, it should reject the malformed response', () {
      expect(
        () => AddressDetailsDto.fromJson(const <String, Object?>{'latitude': 'north', 'longitude': -46.655981}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
