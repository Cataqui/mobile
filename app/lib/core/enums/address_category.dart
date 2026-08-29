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
      case AddressCategory.shoppingMall:
      case AddressCategory.store:
      case AddressCategory.vehicleDealer:
      case AddressCategory.supermarket:
      case AddressCategory.gasStation:
        return palette.orange[9];

      case AddressCategory.bar:
        return palette.amber[9];

      case AddressCategory.cocktailBar:
        return palette.pink[9];

      case AddressCategory.wineBar:
        return palette.red[9];

      case AddressCategory.hookahBar:
        return palette.violet[9];

      case AddressCategory.nightClub:
      case AddressCategory.amusementPark:
      case AddressCategory.hairCare:
      case AddressCategory.theater:
      case AddressCategory.movieTheater:
        return palette.pink[9];

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

  Widget icon({double? size, Color? color}) {
    switch (this) {
      case AddressCategory.street:
      case AddressCategory.neighborhood:
      case AddressCategory.city:
      case AddressCategory.other:
        return MateoIcon.mapPin(width: size, height: size, color: color);

      case AddressCategory.restaurant:
        return MateoIcon.forkKnife(width: size, height: size, color: color);

      case AddressCategory.cafe:
        return MateoIcon.hotCoffeeCup(width: size, height: size, color: color);

      case AddressCategory.bar:
        return MateoIcon.beerMug(width: size, height: size, color: color);

      case AddressCategory.cocktailBar:
        return MateoIcon.matiniGlass(width: size, height: size, color: color);

      case AddressCategory.wineBar:
        return MateoIcon.wineGlass(width: size, height: size, color: color);

      case AddressCategory.hookahBar:
        return MateoIcon.hookah(width: size, height: size, color: color);

      case AddressCategory.nightClub:
        return MateoIcon.discoBall(width: size, height: size, color: color);

      case AddressCategory.park:
        return MateoIcon.tree(width: size, height: size, color: color);

      case AddressCategory.amusementPark:
        return MateoIcon.ferrisWheel(width: size, height: size, color: color);

      case AddressCategory.shoppingMall:
      case AddressCategory.store:
        return MateoIcon.shoppingBag(width: size, height: size, color: color);

      case AddressCategory.hairCare:
        return MateoIcon.scissors(width: size, height: size, color: color);

      case AddressCategory.automotiveShop:
        return MateoIcon.tire(width: size, height: size, color: color);

      case AddressCategory.bicycleShop:
        return MateoIcon.bicycle(width: size, height: size, color: color);

      case AddressCategory.vehicleDealer:
        return MateoIcon.shoppingBag(width: size, height: size, color: color);

      case AddressCategory.vehicleRepair:
        return MateoIcon.wrench(width: size, height: size, color: color);

      case AddressCategory.vehicleWash:
        return MateoIcon.dropFoam(width: size, height: size, color: color);

      case AddressCategory.supermarket:
        return MateoIcon.shoppingCart(width: size, height: size, color: color);

      case AddressCategory.lodging:
        return MateoIcon.sleepingFigure(width: size, height: size, color: color);

      case AddressCategory.school:
      case AddressCategory.university:
        return MateoIcon.graduateCap(width: size, height: size, color: color);

      case AddressCategory.library:
        return MateoIcon.book(width: size, height: size, color: color);

      case AddressCategory.hospital:
        return MateoIcon.medicalCross(width: size, height: size, color: color);

      case AddressCategory.pharmacy:
        return MateoIcon.pills(width: size, height: size, color: color);

      case AddressCategory.gym:
        return MateoIcon.dumbbell(width: size, height: size, color: color);

      case AddressCategory.stadium:
        return MateoIcon.stadium(width: size, height: size, color: color);

      case AddressCategory.racingVenue:
        return MateoIcon.checkeredFlag(width: size, height: size, color: color);

      case AddressCategory.sportsVenue:
        return MateoIcon.runningFigure(width: size, height: size, color: color);

      case AddressCategory.museum:
        return MateoIcon.classicBuilding(width: size, height: size, color: color);

      case AddressCategory.theater:
        return MateoIcon.sadMaskHappyMask(width: size, height: size, color: color);

      case AddressCategory.movieTheater:
        return MateoIcon.popcorn(width: size, height: size, color: color);

      case AddressCategory.busStation:
        return MateoIcon.busFront(width: size, height: size, color: color);

      case AddressCategory.trainStation:
        return MateoIcon.trainFront(width: size, height: size, color: color);

      case AddressCategory.airport:
        return MateoIcon.planeUpRight(width: size, height: size, color: color);

      case AddressCategory.heliport:
        return MateoIcon.helicopterFront(width: size, height: size, color: color);

      case AddressCategory.parking:
        return MateoIcon.parkingSign(width: size, height: size, color: color);

      case AddressCategory.chargingStation:
        return MateoIcon.evPlug(width: size, height: size, color: color);

      case AddressCategory.gasStation:
        return MateoIcon.gasStation(width: size, height: size, color: color);

      case AddressCategory.bank:
        return MateoIcon.bankBuilding(width: size, height: size, color: color);

      case AddressCategory.policeStation:
        return MateoIcon.policeBadge(width: size, height: size, color: color);

      case AddressCategory.fireStation:
        return MateoIcon.flame(width: size, height: size, color: color);

      case AddressCategory.placeOfWorship:
        return MateoIcon.prayingFigure(width: size, height: size, color: color);

      case AddressCategory.governmentOffice:
        return MateoIcon.governmentBuilding(width: size, height: size, color: color);
    }
  }
}
