part of 'qui_color_scheme.dart';

/// Semantic basemap roles used by QUI map rendering.
///
/// These roles describe map surfaces and label tiers semantically instead of
/// requiring app code to duplicate MapLibre style values. Override this group
/// when an app needs a different themed basemap while keeping the same map
/// feature vocabulary.
@immutable
class QuiMapColorScheme {
  /// Creates semantic basemap roles used by QUI map rendering.
  const QuiMapColorScheme({
    required this.background,
    required this.landcover,
    required this.landuse,
    required this.landuseBusiness,
    required this.landuseRecreation,
    required this.park,
    required this.water,
    required this.waterway,
    required this.building,
    required this.buildingOutline,
    required this.boundary,
    required this.tunnel,
    required this.road,
    required this.labelHalo,
    required this.administrativeLabel,
    required this.cityLabel,
    required this.townLabel,
    required this.neighborhoodLabel,
    required this.roadMajorLabel,
    required this.roadLocalLabel,
    required this.pointOfInterestLabel,
    required this.locationRadius,
  });

  /// {@macro qui_color_scheme_lerp}
  factory QuiMapColorScheme.lerp(QuiMapColorScheme a, QuiMapColorScheme b, double t) {
    return QuiMapColorScheme(
      background: Color.lerp(a.background, b.background, t)!,
      landcover: Color.lerp(a.landcover, b.landcover, t)!,
      landuse: Color.lerp(a.landuse, b.landuse, t)!,
      landuseBusiness: Color.lerp(a.landuseBusiness, b.landuseBusiness, t)!,
      landuseRecreation: Color.lerp(a.landuseRecreation, b.landuseRecreation, t)!,
      park: Color.lerp(a.park, b.park, t)!,
      water: Color.lerp(a.water, b.water, t)!,
      waterway: Color.lerp(a.waterway, b.waterway, t)!,
      building: Color.lerp(a.building, b.building, t)!,
      buildingOutline: Color.lerp(a.buildingOutline, b.buildingOutline, t)!,
      boundary: Color.lerp(a.boundary, b.boundary, t)!,
      tunnel: Color.lerp(a.tunnel, b.tunnel, t)!,
      road: Color.lerp(a.road, b.road, t)!,
      labelHalo: Color.lerp(a.labelHalo, b.labelHalo, t)!,
      administrativeLabel: Color.lerp(a.administrativeLabel, b.administrativeLabel, t)!,
      cityLabel: Color.lerp(a.cityLabel, b.cityLabel, t)!,
      townLabel: Color.lerp(a.townLabel, b.townLabel, t)!,
      neighborhoodLabel: Color.lerp(a.neighborhoodLabel, b.neighborhoodLabel, t)!,
      roadMajorLabel: Color.lerp(a.roadMajorLabel, b.roadMajorLabel, t)!,
      roadLocalLabel: Color.lerp(a.roadLocalLabel, b.roadLocalLabel, t)!,
      pointOfInterestLabel: Color.lerp(a.pointOfInterestLabel, b.pointOfInterestLabel, t)!,
      locationRadius: Color.lerp(a.locationRadius, b.locationRadius, t)!,
    );
  }

  /// Background color for map areas not occupied by specific features.
  final Color background;

  /// Fill color for general landcover areas.
  final Color landcover;

  /// Fill color for generic landuse areas.
  final Color landuse;

  /// Fill color for business-oriented landuse areas.
  final Color landuseBusiness;

  /// Fill color for recreation-oriented landuse areas.
  final Color landuseRecreation;

  /// Fill color for parks and similar green public spaces.
  final Color park;

  /// Fill color for water bodies.
  final Color water;

  /// Stroke or fill color for waterways.
  final Color waterway;

  /// Fill color for building masses.
  final Color building;

  /// Outline color for building edges.
  final Color buildingOutline;

  /// Color for administrative and boundary lines.
  final Color boundary;

  /// Color for tunnel geometry.
  final Color tunnel;

  /// Color for road geometry.
  final Color road;

  /// Halo color behind map labels for legibility.
  final Color labelHalo;

  /// Label color for administrative labels.
  final Color administrativeLabel;

  /// Label color for city labels.
  final Color cityLabel;

  /// Label color for town labels.
  final Color townLabel;

  /// Label color for neighborhood labels.
  final Color neighborhoodLabel;

  /// Label color for major road labels.
  final Color roadMajorLabel;

  /// Label color for local road labels.
  final Color roadLocalLabel;

  /// Label color for points of interest.
  final Color pointOfInterestLabel;

  /// Accent color for the location-radius overlay rendered on the map.
  final Color locationRadius;

  /// {@macro qui_color_scheme_copy_with}
  QuiMapColorScheme copyWith({
    Color? background,
    Color? landcover,
    Color? landuse,
    Color? landuseBusiness,
    Color? landuseRecreation,
    Color? park,
    Color? water,
    Color? waterway,
    Color? building,
    Color? buildingOutline,
    Color? boundary,
    Color? tunnel,
    Color? road,
    Color? labelHalo,
    Color? administrativeLabel,
    Color? cityLabel,
    Color? townLabel,
    Color? neighborhoodLabel,
    Color? roadMajorLabel,
    Color? roadLocalLabel,
    Color? pointOfInterestLabel,
    Color? locationRadius,
  }) {
    return QuiMapColorScheme(
      background: background ?? this.background,
      landcover: landcover ?? this.landcover,
      landuse: landuse ?? this.landuse,
      landuseBusiness: landuseBusiness ?? this.landuseBusiness,
      landuseRecreation: landuseRecreation ?? this.landuseRecreation,
      park: park ?? this.park,
      water: water ?? this.water,
      waterway: waterway ?? this.waterway,
      building: building ?? this.building,
      buildingOutline: buildingOutline ?? this.buildingOutline,
      boundary: boundary ?? this.boundary,
      tunnel: tunnel ?? this.tunnel,
      road: road ?? this.road,
      labelHalo: labelHalo ?? this.labelHalo,
      administrativeLabel: administrativeLabel ?? this.administrativeLabel,
      cityLabel: cityLabel ?? this.cityLabel,
      townLabel: townLabel ?? this.townLabel,
      neighborhoodLabel: neighborhoodLabel ?? this.neighborhoodLabel,
      roadMajorLabel: roadMajorLabel ?? this.roadMajorLabel,
      roadLocalLabel: roadLocalLabel ?? this.roadLocalLabel,
      pointOfInterestLabel: pointOfInterestLabel ?? this.pointOfInterestLabel,
      locationRadius: locationRadius ?? this.locationRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiMapColorScheme &&
          background == other.background &&
          landcover == other.landcover &&
          landuse == other.landuse &&
          landuseBusiness == other.landuseBusiness &&
          landuseRecreation == other.landuseRecreation &&
          park == other.park &&
          water == other.water &&
          waterway == other.waterway &&
          building == other.building &&
          buildingOutline == other.buildingOutline &&
          boundary == other.boundary &&
          tunnel == other.tunnel &&
          road == other.road &&
          labelHalo == other.labelHalo &&
          administrativeLabel == other.administrativeLabel &&
          cityLabel == other.cityLabel &&
          townLabel == other.townLabel &&
          neighborhoodLabel == other.neighborhoodLabel &&
          roadMajorLabel == other.roadMajorLabel &&
          roadLocalLabel == other.roadLocalLabel &&
          pointOfInterestLabel == other.pointOfInterestLabel &&
          locationRadius == other.locationRadius;

  @override
  int get hashCode => Object.hashAll([
    background,
    landcover,
    landuse,
    landuseBusiness,
    landuseRecreation,
    park,
    water,
    waterway,
    building,
    buildingOutline,
    boundary,
    tunnel,
    road,
    labelHalo,
    administrativeLabel,
    cityLabel,
    townLabel,
    neighborhoodLabel,
    roadMajorLabel,
    roadLocalLabel,
    pointOfInterestLabel,
    locationRadius,
  ]);
}
