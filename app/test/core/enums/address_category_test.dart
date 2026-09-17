import 'package:cataqui_app/core/enums/address_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

void main() {
  group('AddressCategory', () {
    test('when resolving icons, each category should use its assigned dotdart-backed icon', () {
      final categoryIconTypes = AddressCategory.values
          .map((category) => category.icon(opticalCenter: false).runtimeType)
          .toList(growable: false);

      expect(categoryIconTypes, <Type>[
        const MateoIcon(.mapPin).runtimeType,
        const MateoIcon(.mapPin).runtimeType,
        const MateoIcon(.mapPin).runtimeType,
        const MateoIcon(.forkKnife).runtimeType,
        const MateoIcon(.hotCoffeeCup).runtimeType,
        const MateoIcon(.beerMug).runtimeType,
        const MateoIcon(.matiniGlass).runtimeType,
        const MateoIcon(.wineGlass).runtimeType,
        const MateoIcon(.hookah).runtimeType,
        const MateoIcon(.discoBall).runtimeType,
        const MateoIcon(.tree).runtimeType,
        const MateoIcon(.ferrisWheel).runtimeType,
        const MateoIcon(.shoppingBag).runtimeType,
        const MateoIcon(.shoppingBag).runtimeType,
        const MateoIcon(.scissors).runtimeType,
        const MateoIcon(.tire).runtimeType,
        const MateoIcon(.bicycle).runtimeType,
        const MateoIcon(.shoppingBag).runtimeType,
        const MateoIcon(.wrench).runtimeType,
        const MateoIcon(.dropFoam).runtimeType,
        const MateoIcon(.shoppingCart).runtimeType,
        const MateoIcon(.sleepingFigure).runtimeType,
        const MateoIcon(.graduateCap).runtimeType,
        const MateoIcon(.graduateCap).runtimeType,
        const MateoIcon(.book).runtimeType,
        const MateoIcon(.medicalCross).runtimeType,
        const MateoIcon(.pills).runtimeType,
        const MateoIcon(.dumbbell).runtimeType,
        const MateoIcon(.stadium).runtimeType,
        const MateoIcon(.checkeredFlag).runtimeType,
        const MateoIcon(.runningFigure).runtimeType,
        const MateoIcon(.classicBuilding).runtimeType,
        const MateoIcon(.sadMaskHappyMask).runtimeType,
        const MateoIcon(.popcorn).runtimeType,
        const MateoIcon(.busFront).runtimeType,
        const MateoIcon(.trainFront).runtimeType,
        const MateoIcon(.planeUpRight).runtimeType,
        const MateoIcon(.helicopterFront).runtimeType,
        const MateoIcon(.parkingSign).runtimeType,
        const MateoIcon(.evPlug).runtimeType,
        const MateoIcon(.gasStation).runtimeType,
        const MateoIcon(.bankBuilding).runtimeType,
        const MateoIcon(.policeBadge).runtimeType,
        const MateoIcon(.flame).runtimeType,
        const MateoIcon(.prayingFigure).runtimeType,
        const MateoIcon(.governmentBuilding).runtimeType,
        const MateoIcon(.mapPin).runtimeType,
      ]);
    });

    test('when optical centering is enabled, asymmetric category icons should use size-relative offsets', () {
      final beerAt20 = AddressCategory.bar.icon(size: 20) as Transform;
      final beerAt40 = AddressCategory.bar.icon(size: 40) as Transform;
      final hookahAt20 = AddressCategory.hookahBar.icon(size: 20) as Transform;
      final hookahAt40 = AddressCategory.hookahBar.icon(size: 40) as Transform;
      final parkingAt20 = AddressCategory.parking.icon(size: 20) as Transform;
      final parkingAt40 = AddressCategory.parking.icon(size: 40) as Transform;

      expect(
        (
          beerAt20.transform.getTranslation().x,
          beerAt40.transform.getTranslation().x,
          hookahAt20.transform.getTranslation().x,
          hookahAt40.transform.getTranslation().x,
          parkingAt20.transform.getTranslation().x,
          parkingAt40.transform.getTranslation().x,
        ),
        (1.0, 2.0, -1.5, -3.0, 1.0, 2.0),
      );
    });

    test('when optical centering is disabled, asymmetric category icons should remain untouched', () {
      expect(
        (
          AddressCategory.bar.icon(opticalCenter: false).runtimeType,
          AddressCategory.hookahBar.icon(opticalCenter: false).runtimeType,
          AddressCategory.parking.icon(opticalCenter: false).runtimeType,
        ),
        (
          const MateoIcon(.beerMug).runtimeType,
          const MateoIcon(.hookah).runtimeType,
          const MateoIcon(.parkingSign).runtimeType,
        ),
      );
    });

    test('when resolving an icon with a background, it should pass the color to MateoIcon', () {
      final backgroundColor = MateoPalette().neutral[12];
      final icon = AddressCategory.street.icon(backgroundColor: backgroundColor, opticalCenter: false) as MateoIcon;

      expect(icon.backgroundColor, backgroundColor);
    });

    test('when resolving colors, each category should use its semantic Mateo color family', () {
      final palette = MateoPalette();
      final categoryColors = AddressCategory.values
          .map((category) => category.color(palette: palette))
          .toList(growable: false);

      expect(categoryColors, <Color>[
        palette.neutral[10],
        palette.neutral[10],
        palette.neutral[10],
        palette.orange[9],
        palette.orange[9],
        palette.amber[9],
        palette.pink[9],
        palette.red[9],
        palette.violet[9],
        palette.green[9],
        palette.green[9],
        palette.green[9],
        palette.blue[9],
        palette.blue[9],
        palette.amber[9],
        palette.blue[11],
        palette.green[9],
        palette.blue[9],
        palette.neutral[12],
        palette.cyan[10],
        palette.blue[9],
        palette.teal[9],
        palette.blue[9],
        palette.blue[9],
        palette.blue[9],
        palette.red[9],
        palette.red[9],
        palette.violet[9],
        palette.violet[9],
        palette.violet[9],
        palette.violet[9],
        palette.violet[9],
        palette.green[9],
        palette.green[9],
        palette.blue[9],
        palette.blue[9],
        palette.blue[9],
        palette.blue[9],
        palette.blue[9],
        palette.green[9],
        palette.orange[9],
        palette.red[11],
        palette.blue[9],
        palette.red[9],
        palette.violet[9],
        palette.blue[11],
        palette.neutral[10],
      ]);
    });
  });
}
