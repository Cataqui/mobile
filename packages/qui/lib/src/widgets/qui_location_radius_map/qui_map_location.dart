part of 'qui_location_radius_map.dart';

/// Geographic coordinates used by [QuiLocationRadiusMap].
class QuiMapLocation {
  /// Creates a location from decimal-degree latitude and longitude.
  const QuiMapLocation({required this.latitude, required this.longitude})
    : assert(latitude >= -90 && latitude <= 90, 'latitude must be between -90 and 90'),
      assert(longitude >= -180 && longitude <= 180, 'longitude must be between -180 and 180');

  /// Latitude in decimal degrees.
  ///
  /// Must be between `-90` and `90`.
  final double latitude;

  /// Longitude in decimal degrees.
  ///
  /// Must be between `-180` and `180`.
  final double longitude;
}
