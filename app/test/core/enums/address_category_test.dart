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
        MateoIcon.mapPin().runtimeType,
        MateoIcon.mapPin().runtimeType,
        MateoIcon.mapPin().runtimeType,
        MateoIcon.forkKnife().runtimeType,
        MateoIcon.hotCoffeeCup().runtimeType,
        MateoIcon.beerMug().runtimeType,
        MateoIcon.matiniGlass().runtimeType,
        MateoIcon.wineGlass().runtimeType,
        MateoIcon.hookah().runtimeType,
        MateoIcon.discoBall().runtimeType,
        MateoIcon.tree().runtimeType,
        MateoIcon.ferrisWheel().runtimeType,
        MateoIcon.shoppingBag().runtimeType,
        MateoIcon.shoppingBag().runtimeType,
        MateoIcon.scissors().runtimeType,
        MateoIcon.tire().runtimeType,
        MateoIcon.bicycle().runtimeType,
        MateoIcon.shoppingBag().runtimeType,
        MateoIcon.wrench().runtimeType,
        MateoIcon.dropFoam().runtimeType,
        MateoIcon.shoppingCart().runtimeType,
        MateoIcon.sleepingFigure().runtimeType,
        MateoIcon.graduateCap().runtimeType,
        MateoIcon.graduateCap().runtimeType,
        MateoIcon.book().runtimeType,
        MateoIcon.medicalCross().runtimeType,
        MateoIcon.pills().runtimeType,
        MateoIcon.dumbbell().runtimeType,
        MateoIcon.stadium().runtimeType,
        MateoIcon.checkeredFlag().runtimeType,
        MateoIcon.runningFigure().runtimeType,
        MateoIcon.classicBuilding().runtimeType,
        MateoIcon.sadMaskHappyMask().runtimeType,
        MateoIcon.popcorn().runtimeType,
        MateoIcon.busFront().runtimeType,
        MateoIcon.trainFront().runtimeType,
        MateoIcon.planeUpRight().runtimeType,
        MateoIcon.helicopterFront().runtimeType,
        MateoIcon.parkingSign().runtimeType,
        MateoIcon.evPlug().runtimeType,
        MateoIcon.gasStation().runtimeType,
        MateoIcon.bankBuilding().runtimeType,
        MateoIcon.policeBadge().runtimeType,
        MateoIcon.flame().runtimeType,
        MateoIcon.prayingFigure().runtimeType,
        MateoIcon.governmentBuilding().runtimeType,
        MateoIcon.mapPin().runtimeType,
      ]);
    });

    test('when optical centering is enabled, asymmetric category icons should use size-relative offsets', () {
      final hookahAt20 = AddressCategory.hookahBar.icon(size: 20) as Transform;
      final hookahAt40 = AddressCategory.hookahBar.icon(size: 40) as Transform;
      final parkingAt20 = AddressCategory.parking.icon(size: 20) as Transform;
      final parkingAt40 = AddressCategory.parking.icon(size: 40) as Transform;

      expect(
        (
          hookahAt20.transform.getTranslation().x,
          hookahAt40.transform.getTranslation().x,
          parkingAt20.transform.getTranslation().x,
          parkingAt40.transform.getTranslation().x,
        ),
        (-1.5, -3.0, 1.0, 2.0),
      );
    });

    test('when optical centering is disabled, asymmetric category icons should remain untouched', () {
      expect(
        (
          AddressCategory.hookahBar.icon(opticalCenter: false).runtimeType,
          AddressCategory.parking.icon(opticalCenter: false).runtimeType,
        ),
        (MateoIcon.hookah().runtimeType, MateoIcon.parkingSign().runtimeType),
      );
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
        palette.pink[9],
        palette.green[9],
        palette.pink[9],
        palette.orange[9],
        palette.orange[9],
        palette.pink[9],
        palette.blue[11],
        palette.green[9],
        palette.orange[9],
        palette.neutral[12],
        palette.cyan[10],
        palette.orange[9],
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
        palette.pink[9],
        palette.pink[9],
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
