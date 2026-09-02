import 'package:cataqui_app/core/enums/address_category.dart';
import 'package:flutter/material.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

@immutable
final class JobLocationMapFeatureColorScheme {
  const JobLocationMapFeatureColorScheme({
    this.all,
    this.geometry,
    this.geometryFill,
    this.geometryStroke,
    this.geometryWeight,
    this.labels,
    this.labelsIcon,
    this.labelsText,
    this.labelsTextFill,
    this.labelsTextStroke,
  });

  final Color? all;
  final Color? geometry;
  final Color? geometryFill;
  final Color? geometryStroke;
  final int? geometryWeight;
  final Color? labels;
  final Color? labelsIcon;
  final Color? labelsText;
  final Color? labelsTextFill;
  final Color? labelsTextStroke;
}

@immutable
final class JobLocationMapColorScheme {
  const JobLocationMapColorScheme._({
    required this.all,
    required this.administrative,
    required this.administrativeCountry,
    required this.administrativeLandParcel,
    required this.administrativeLocality,
    required this.administrativeNeighborhood,
    required this.administrativeProvince,
    required this.landscape,
    required this.landscapeManMade,
    required this.landscapeNatural,
    required this.landscapeNaturalLandcover,
    required this.landscapeNaturalTerrain,
    required this.pointOfInterest,
    required this.pointOfInterestAttraction,
    required this.pointOfInterestBusiness,
    required this.pointOfInterestGovernment,
    required this.pointOfInterestMedical,
    required this.pointOfInterestPark,
    required this.pointOfInterestPlaceOfWorship,
    required this.pointOfInterestSchool,
    required this.pointOfInterestSportsComplex,
    required this.road,
    required this.roadArterial,
    required this.roadHighway,
    required this.roadHighwayControlledAccess,
    required this.roadLocal,
    required this.transit,
    required this.transitLine,
    required this.transitStation,
    required this.transitStationAirport,
    required this.transitStationBus,
    required this.transitStationRail,
    required this.water,
    required this.background,
    required this.locationRadius,
  });

  factory JobLocationMapColorScheme.fromBrightness({required Brightness brightness, required MateoPalette palette}) {
    return switch (brightness) {
      Brightness.light => JobLocationMapColorScheme.light(palette: palette),
      Brightness.dark => throw UnsupportedError('Dark job location maps are not supported.'),
    };
  }

  factory JobLocationMapColorScheme.light({required MateoPalette palette}) {
    return JobLocationMapColorScheme._(
      all: const JobLocationMapFeatureColorScheme(),
      administrative: const JobLocationMapFeatureColorScheme(),
      administrativeCountry: const JobLocationMapFeatureColorScheme(),
      administrativeLandParcel: const JobLocationMapFeatureColorScheme(),
      administrativeLocality: const JobLocationMapFeatureColorScheme(),
      administrativeNeighborhood: const JobLocationMapFeatureColorScheme(),
      administrativeProvince: const JobLocationMapFeatureColorScheme(),
      landscape: JobLocationMapFeatureColorScheme(geometry: palette.neutral[2].lighten(0.2)),
      landscapeManMade: JobLocationMapFeatureColorScheme(geometry: palette.neutral[2].lighten(0.2)),
      landscapeNatural: JobLocationMapFeatureColorScheme(geometry: palette.neutral[2].lighten(0.2)),
      landscapeNaturalLandcover: const JobLocationMapFeatureColorScheme(),
      landscapeNaturalTerrain: const JobLocationMapFeatureColorScheme(),
      pointOfInterest: const JobLocationMapFeatureColorScheme(),
      pointOfInterestAttraction: const JobLocationMapFeatureColorScheme(),
      pointOfInterestBusiness: const JobLocationMapFeatureColorScheme(),
      pointOfInterestGovernment: const JobLocationMapFeatureColorScheme(),
      pointOfInterestMedical: const JobLocationMapFeatureColorScheme(),
      pointOfInterestPark: JobLocationMapFeatureColorScheme(
        labelsIcon: AddressCategory.park.color(palette: palette),
        geometryFill: palette.green[6],
      ),
      pointOfInterestPlaceOfWorship: const JobLocationMapFeatureColorScheme(),
      pointOfInterestSchool: const JobLocationMapFeatureColorScheme(),
      pointOfInterestSportsComplex: const JobLocationMapFeatureColorScheme(),
      road: JobLocationMapFeatureColorScheme(geometryFill: palette.neutral[1]),
      roadArterial: const JobLocationMapFeatureColorScheme(
        geometry: Colors.white,
        // geometryFill: palette.neutral[3],
        // geometryStroke: palette.neutral[5],
        geometryWeight: 1,
      ),
      roadHighway: JobLocationMapFeatureColorScheme(
        geometry: palette.neutral[5],
        // geometryStroke: palette.green[1],
        geometryWeight: 1,
      ),
      roadHighwayControlledAccess: const JobLocationMapFeatureColorScheme(),
      roadLocal: JobLocationMapFeatureColorScheme(
        geometry: palette.neutral[2].darken(0.06),
        // geometryStroke: Colors.red,
        // geometryStroke: Colors.white,
        geometryWeight: 1,
      ),
      transit: const JobLocationMapFeatureColorScheme(),
      transitLine: const JobLocationMapFeatureColorScheme(),
      transitStation: const JobLocationMapFeatureColorScheme(),
      transitStationAirport: const JobLocationMapFeatureColorScheme(),
      transitStationBus: const JobLocationMapFeatureColorScheme(),
      transitStationRail: const JobLocationMapFeatureColorScheme(),
      water: JobLocationMapFeatureColorScheme(geometryFill: palette.cyan[7]),
      background: palette.neutral[2],
      locationRadius: palette.green[9].withValues(alpha: 0.12),
    );
  }

  final JobLocationMapFeatureColorScheme all;
  final JobLocationMapFeatureColorScheme administrative;
  final JobLocationMapFeatureColorScheme administrativeCountry;
  final JobLocationMapFeatureColorScheme administrativeLandParcel;
  final JobLocationMapFeatureColorScheme administrativeLocality;
  final JobLocationMapFeatureColorScheme administrativeNeighborhood;
  final JobLocationMapFeatureColorScheme administrativeProvince;
  final JobLocationMapFeatureColorScheme landscape;
  final JobLocationMapFeatureColorScheme landscapeManMade;
  final JobLocationMapFeatureColorScheme landscapeNatural;
  final JobLocationMapFeatureColorScheme landscapeNaturalLandcover;
  final JobLocationMapFeatureColorScheme landscapeNaturalTerrain;
  final JobLocationMapFeatureColorScheme pointOfInterest;
  final JobLocationMapFeatureColorScheme pointOfInterestAttraction;
  final JobLocationMapFeatureColorScheme pointOfInterestBusiness;
  final JobLocationMapFeatureColorScheme pointOfInterestGovernment;
  final JobLocationMapFeatureColorScheme pointOfInterestMedical;
  final JobLocationMapFeatureColorScheme pointOfInterestPark;
  final JobLocationMapFeatureColorScheme pointOfInterestPlaceOfWorship;
  final JobLocationMapFeatureColorScheme pointOfInterestSchool;
  final JobLocationMapFeatureColorScheme pointOfInterestSportsComplex;
  final JobLocationMapFeatureColorScheme road;
  final JobLocationMapFeatureColorScheme roadArterial;
  final JobLocationMapFeatureColorScheme roadHighway;
  final JobLocationMapFeatureColorScheme roadHighwayControlledAccess;
  final JobLocationMapFeatureColorScheme roadLocal;
  final JobLocationMapFeatureColorScheme transit;
  final JobLocationMapFeatureColorScheme transitLine;
  final JobLocationMapFeatureColorScheme transitStation;
  final JobLocationMapFeatureColorScheme transitStationAirport;
  final JobLocationMapFeatureColorScheme transitStationBus;
  final JobLocationMapFeatureColorScheme transitStationRail;
  final JobLocationMapFeatureColorScheme water;
  final Color background;
  final Color locationRadius;
}
