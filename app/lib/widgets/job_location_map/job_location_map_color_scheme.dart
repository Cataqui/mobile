// ### CURRENTLY NOT USED, NEED IMPROVEMENT ON COLOR SCHEME TO LOOK BETTER

import 'package:flutter/material.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

@immutable
final class JobLocationMapColorScheme {
  const JobLocationMapColorScheme._({
    required this.background,
    required this.allGeometry,
    required this.allLabel,
    required this.allLabelHalo,
    required this.landscapeGeometry,
    required this.manMadeFill,
    required this.manMadeStroke,
    required this.naturalGeometry,
    required this.administrativeLabel,
    required this.administrativeCountryLabel,
    required this.administrativeLocalityLabel,
    required this.administrativeNeighborhoodLabel,
    required this.administrativeProvinceLabel,
    required this.pointOfInterestGeometry,
    required this.attractionGeometry,
    required this.attractionLabel,
    required this.attractionIcon,
    required this.businessGeometry,
    required this.businessIcon,
    required this.governmentGeometry,
    required this.governmentLabel,
    required this.governmentLabelHalo,
    required this.governmentIcon,
    required this.medicalGeometry,
    required this.parkGeometry,
    required this.parkLabel,
    required this.parkLabelHalo,
    required this.parkIcon,
    required this.schoolGeometry,
    required this.sportsComplexGeometry,
    required this.sportsComplexLabel,
    required this.sportsComplexLabelHalo,
    required this.sportsComplexIcon,
    required this.roadGeometryFill,
    required this.roadGeometryStroke,
    required this.roadLabel,
    required this.roadLabelHalo,
    required this.arterialRoadGeometryFill,
    required this.arterialRoadGeometryStroke,
    required this.arterialRoadLabel,
    required this.highwayGeometryFill,
    required this.highwayLabel,
    required this.localRoadGeometryFill,
    required this.localRoadLabel,
    required this.transitStationGeometry,
    required this.transitStationLabel,
    required this.transitStationLabelHalo,
    required this.transitStationIcon,
    required this.railStationLabel,
    required this.railStationLabelHalo,
    required this.railStationIcon,
    required this.waterGeometry,
    required this.waterLabel,
    required this.waterLabelHalo,
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
      background: palette.neutral[2],
      allGeometry: palette.neutral[2],
      allLabel: palette.neutral[8],
      allLabelHalo: palette.neutral[1],
      landscapeGeometry: palette.neutral[2],
      manMadeFill: palette.neutral[2],
      manMadeStroke: palette.neutral[5],
      naturalGeometry: palette.green[5],
      administrativeLabel: palette.neutral[7],
      administrativeCountryLabel: palette.neutral[8],
      administrativeLocalityLabel: palette.neutral[8],
      administrativeNeighborhoodLabel: palette.neutral[7],
      administrativeProvinceLabel: palette.neutral[7],
      pointOfInterestGeometry: palette.neutral[1],
      attractionGeometry: palette.neutral[1],
      attractionLabel: palette.neutral[8],
      attractionIcon: palette.violet[7],
      businessGeometry: palette.neutral[1],
      businessIcon: palette.neutral[8],
      governmentGeometry: palette.neutral[1],
      governmentLabel: palette.amber[8],
      governmentLabelHalo: palette.neutral[1],
      governmentIcon: palette.amber[8],
      medicalGeometry: palette.neutral[1],
      parkGeometry: palette.green[4],
      parkLabel: palette.green[8],
      parkLabelHalo: palette.neutral[1],
      parkIcon: palette.green[8],
      schoolGeometry: palette.neutral[1],
      sportsComplexGeometry: palette.neutral[1],
      sportsComplexLabel: palette.violet[8],
      sportsComplexLabelHalo: palette.neutral[1],
      sportsComplexIcon: palette.violet[7],
      roadGeometryFill: Colors.white,
      roadGeometryStroke: palette.neutral[1],
      roadLabel: palette.neutral[10],
      roadLabelHalo: palette.neutral[1],
      arterialRoadGeometryFill: Colors.white,
      arterialRoadGeometryStroke: palette.neutral[1],
      arterialRoadLabel: palette.neutral[10],
      highwayGeometryFill: Colors.white,
      highwayLabel: palette.neutral[10],
      localRoadGeometryFill: palette.neutral[1],
      localRoadLabel: palette.neutral[10],
      transitStationGeometry: palette.blue[1],
      transitStationLabel: palette.blue[8],
      transitStationLabelHalo: palette.neutral[1],
      transitStationIcon: palette.blue[8],
      railStationLabel: palette.blue[8],
      railStationLabelHalo: palette.neutral[1],
      railStationIcon: palette.blue[6],
      waterGeometry: palette.cyan[2],
      waterLabel: palette.cyan[8],
      waterLabelHalo: palette.neutral[1],
      locationRadius: palette.orange[8].withValues(alpha: 0.15),
    );
  }

  final Color background;
  final Color allGeometry;
  final Color allLabel;
  final Color allLabelHalo;
  final Color landscapeGeometry;
  final Color manMadeFill;
  final Color manMadeStroke;
  final Color naturalGeometry;
  final Color administrativeLabel;
  final Color administrativeCountryLabel;
  final Color administrativeLocalityLabel;
  final Color administrativeNeighborhoodLabel;
  final Color administrativeProvinceLabel;
  final Color pointOfInterestGeometry;
  final Color attractionGeometry;
  final Color attractionLabel;
  final Color attractionIcon;
  final Color businessGeometry;
  final Color businessIcon;
  final Color governmentGeometry;
  final Color governmentLabel;
  final Color governmentLabelHalo;
  final Color governmentIcon;
  final Color medicalGeometry;
  final Color parkGeometry;
  final Color parkLabel;
  final Color parkLabelHalo;
  final Color parkIcon;
  final Color schoolGeometry;
  final Color sportsComplexGeometry;
  final Color sportsComplexLabel;
  final Color sportsComplexLabelHalo;
  final Color sportsComplexIcon;
  final Color roadGeometryFill;
  final Color roadGeometryStroke;
  final Color roadLabel;
  final Color roadLabelHalo;
  final Color arterialRoadGeometryFill;
  final Color arterialRoadGeometryStroke;
  final Color arterialRoadLabel;
  final Color highwayGeometryFill;
  final Color highwayLabel;
  final Color localRoadGeometryFill;
  final Color localRoadLabel;
  final Color transitStationGeometry;
  final Color transitStationLabel;
  final Color transitStationLabelHalo;
  final Color transitStationIcon;
  final Color railStationLabel;
  final Color railStationLabelHalo;
  final Color railStationIcon;
  final Color waterGeometry;
  final Color waterLabel;
  final Color waterLabelHalo;
  final Color locationRadius;
}
