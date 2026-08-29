import 'package:cataqui_app/core/dtos/address_search_response_dto.dart';
import 'package:cataqui_app/core/enums/address_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

void main() {
  group('AddressSearchResponseDto', () {
    test('when an address suggestion has no secondary text, it should keep it nullable', () {
      final response = AddressSearchResponseDto.fromJson(_AddressSearchResponseDtoTestData.responseJson());

      expect(response.suggestions.single.secondaryText, isNull);
    });

    test('when address search omits suggestions, it should reject the malformed response', () {
      expect(
        () => AddressSearchResponseDto.fromJson(const <String, Object?>{
          'attribution': <String, Object?>{'text': 'Google Maps'},
        }),
        throwsA(isA<MissingRequiredKeysException>()),
      );
    });

    test('when address search omits attribution, it should reject the malformed response', () {
      expect(
        () => AddressSearchResponseDto.fromJson(const <String, Object?>{'suggestions': <Object?>[]}),
        throwsA(isA<MissingRequiredKeysException>()),
      );
    });

    test('when address search returns null attribution, it should reject the malformed response', () {
      expect(
        () =>
            AddressSearchResponseDto.fromJson(const <String, Object?>{'suggestions': <Object?>[], 'attribution': null}),
        throwsA(isA<TypeError>()),
      );
    });

    test('when address search returns a malformed suggestion, it should reject the response', () {
      expect(
        () => AddressSearchResponseDto.fromJson(const <String, Object?>{
          'suggestions': <Object?>[<String, Object?>{}],
          'attribution': <String, Object?>{'text': 'Google Maps'},
        }),
        throwsA(isA<MissingRequiredKeysException>()),
      );
    });

    test('when an address suggestion has an unknown category, it should reject the response', () {
      expect(
        () => AddressSearchResponseDto.fromJson(
          _AddressSearchResponseDtoTestData.responseJson(category: 'UNRECOGNIZED_CATEGORY'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('when geosearch returns changed category names, it should map the current worker contract', () {
      final categories =
          <String>[
            'COCKTAIL_BAR',
            'WINE_BAR',
            'HOOKAH_BAR',
            'AUTOMOTIVE_SHOP',
            'BICYCLE_SHOP',
            'VEHICLE_DEALER',
            'VEHICLE_REPAIR',
            'VEHICLE_WASH',
            'LODGING',
            'HAIR_CARE',
          ].map(
            (category) => AddressSearchResponseDto.fromJson(
              _AddressSearchResponseDtoTestData.responseJson(category: category),
            ).suggestions.single.category,
          );

      expect(categories, <AddressCategory>[
        AddressCategory.cocktailBar,
        AddressCategory.wineBar,
        AddressCategory.hookahBar,
        AddressCategory.automotiveShop,
        AddressCategory.bicycleShop,
        AddressCategory.vehicleDealer,
        AddressCategory.vehicleRepair,
        AddressCategory.vehicleWash,
        AddressCategory.lodging,
        AddressCategory.hairCare,
      ]);
    });
  });
}

final class _AddressSearchResponseDtoTestData {
  const _AddressSearchResponseDtoTestData._();

  static Map<String, Object?> responseJson({String category = 'STREET'}) {
    return <String, Object?>{
      'suggestions': <Object?>[
        <String, Object?>{
          'addressId': 'address-id-123',
          'fullText': 'Avenida Paulista, Bela Vista, São Paulo - SP, Brasil',
          'primaryText': 'Avenida Paulista',
          'category': category,
          'secondaryText': null,
        },
      ],
      'attribution': <String, Object?>{'text': 'Google Maps'},
    };
  }
}
