import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum AddressCategory {
  street,
  neighborhood,
  city,
  restaurant,
  cafe,
  bar,
  cocktailBar,
  wineBar,
  hookahBar,
  nightClub,
  park,
  amusementPark,
  shoppingMall,
  store,
  hairCare,
  automotiveShop,
  bicycleShop,
  vehicleDealer,
  vehicleRepair,
  vehicleWash,
  supermarket,
  lodging,
  school,
  university,
  library,
  hospital,
  pharmacy,
  gym,
  stadium,
  racingVenue,
  sportsVenue,
  museum,
  theater,
  movieTheater,
  busStation,
  trainStation,
  airport,
  heliport,
  parking,
  chargingStation,
  gasStation,
  bank,
  policeStation,
  fireStation,
  placeOfWorship,
  governmentOffice,
  other;

  static const _defaultIconSize = 20.0;

  Color color({required MateoPalette palette}) {
    switch (this) {
      case AddressCategory.street:
      case AddressCategory.neighborhood:
      case AddressCategory.city:
      case AddressCategory.other:
        return palette.neutral[10];

      case AddressCategory.automotiveShop:
        return palette.blue[11];

      case AddressCategory.restaurant:
      case AddressCategory.cafe:
      case AddressCategory.gasStation:
        return palette.orange[9];

      case AddressCategory.supermarket:
      case AddressCategory.vehicleDealer:
      case AddressCategory.shoppingMall:
      case AddressCategory.store:
        return palette.blue[9];

      case AddressCategory.bar:
        return palette.amber[9];

      case AddressCategory.cocktailBar:
        return palette.pink[9];

      case AddressCategory.wineBar:
        return palette.red[9];

      case AddressCategory.hookahBar:
        return palette.violet[9];

      case AddressCategory.hairCare:
        return palette.amber[9];

      case AddressCategory.nightClub:
      case AddressCategory.amusementPark:
      case AddressCategory.theater:
      case AddressCategory.movieTheater:
      case AddressCategory.park:
      case AddressCategory.bicycleShop:
      case AddressCategory.chargingStation:
        return palette.green[9];

      case AddressCategory.bank:
        return palette.red[11];

      case AddressCategory.lodging:
        return palette.teal[9];

      case AddressCategory.vehicleRepair:
        return palette.neutral[12];

      case AddressCategory.governmentOffice:
        return palette.blue[11];

      case AddressCategory.vehicleWash:
        return palette.cyan[10];

      case AddressCategory.school:
      case AddressCategory.university:
      case AddressCategory.library:
      case AddressCategory.busStation:
      case AddressCategory.trainStation:
      case AddressCategory.airport:
      case AddressCategory.heliport:
      case AddressCategory.parking:
      case AddressCategory.policeStation:
        return palette.blue[9];

      case AddressCategory.gym:
      case AddressCategory.stadium:
      case AddressCategory.racingVenue:
      case AddressCategory.sportsVenue:
      case AddressCategory.museum:
      case AddressCategory.placeOfWorship:
        return palette.violet[9];

      case AddressCategory.hospital:
      case AddressCategory.pharmacy:
      case AddressCategory.fireStation:
        return palette.red[9];
    }
  }

  Widget icon({double? size, Color? color, Color? backgroundColor, bool opticalCenter = true}) {
    switch (this) {
      case AddressCategory.street:
      case AddressCategory.neighborhood:
      case AddressCategory.city:
      case AddressCategory.other:
        return MateoIcon(.mapPin, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.restaurant:
        return MateoIcon(.forkKnife, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.cafe:
        return MateoIcon(.hotCoffeeCup, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.bar:
        final beerIcon = MateoIcon(.beerMug, size: size, color: color, backgroundColor: backgroundColor);
        if (!opticalCenter) return beerIcon;
        return Transform.translate(offset: Offset((size ?? _defaultIconSize) * 0.05, 0), child: beerIcon);

      case AddressCategory.cocktailBar:
        return MateoIcon(.matiniGlass, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.wineBar:
        return MateoIcon(.wineGlass, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.hookahBar:
        final hookahIcon = MateoIcon(.hookah, size: size, color: color, backgroundColor: backgroundColor);

        if (!opticalCenter) return hookahIcon;
        return Transform.translate(offset: Offset(-((size ?? _defaultIconSize) * 0.075), 0), child: hookahIcon);

      case AddressCategory.nightClub:
        return MateoIcon(.discoBall, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.park:
        return MateoIcon(.tree, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.amusementPark:
        return MateoIcon(.ferrisWheel, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.shoppingMall:
      case AddressCategory.store:
        return MateoIcon(.shoppingBag, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.hairCare:
        return MateoIcon(.scissors, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.automotiveShop:
        return MateoIcon(.tire, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.bicycleShop:
        return MateoIcon(.bicycle, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.vehicleDealer:
        return MateoIcon(.shoppingBag, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.vehicleRepair:
        return MateoIcon(.wrench, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.vehicleWash:
        return MateoIcon(.dropFoam, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.supermarket:
        return MateoIcon(.shoppingCart, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.lodging:
        return MateoIcon(.sleepingFigure, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.school:
      case AddressCategory.university:
        return MateoIcon(.graduateCap, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.library:
        return MateoIcon(.book, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.hospital:
        return MateoIcon(.medicalCross, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.pharmacy:
        return MateoIcon(.pills, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.gym:
        return MateoIcon(.dumbbell, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.stadium:
        return MateoIcon(.stadium, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.racingVenue:
        return MateoIcon(.checkeredFlag, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.sportsVenue:
        return MateoIcon(.runningFigure, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.museum:
        return MateoIcon(.classicBuilding, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.theater:
        return MateoIcon(.sadMaskHappyMask, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.movieTheater:
        return MateoIcon(.popcorn, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.busStation:
        return MateoIcon(.busFront, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.trainStation:
        return MateoIcon(.trainFront, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.airport:
        return MateoIcon(.planeUpRight, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.heliport:
        return MateoIcon(.helicopterFront, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.parking:
        final parkingIcon = MateoIcon(.parkingSign, size: size, color: color, backgroundColor: backgroundColor);
        if (!opticalCenter) return parkingIcon;
        return Transform.translate(offset: Offset((size ?? _defaultIconSize) * 0.05, 0), child: parkingIcon);

      case AddressCategory.chargingStation:
        return MateoIcon(.evPlug, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.gasStation:
        return MateoIcon(.gasStation, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.bank:
        return MateoIcon(.bankBuilding, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.policeStation:
        return MateoIcon(.policeBadge, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.fireStation:
        return MateoIcon(.flame, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.placeOfWorship:
        return MateoIcon(.prayingFigure, size: size, color: color, backgroundColor: backgroundColor);

      case AddressCategory.governmentOffice:
        return MateoIcon(.governmentBuilding, size: size, color: color, backgroundColor: backgroundColor);
    }
  }
}
