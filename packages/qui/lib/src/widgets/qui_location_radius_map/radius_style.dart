part of 'qui_location_radius_map.dart';

/// Visual styling for the radius circle drawn by [QuiLocationRadiusMap].
///
/// Any color left as `null` falls back to the current [QuiTheme] primary color
/// with the opacity chosen by the map widget. This lets callers customize only
/// the pieces they need while keeping the default Cataquí radius treatment.
class RadiusStyle {
  /// Creates a radius style.
  const RadiusStyle({this.color, this.borderColor, this.borderWidth = 0})
    : assert(borderWidth >= 0, 'borderWidth must be greater than or equal to zero.');

  /// Fill color for the radius circle.
  ///
  /// When `null`, [QuiLocationRadiusMap] uses the current `qui` primary color
  /// with a soft transparent opacity.
  final Color? color;

  /// Border color for the radius circle.
  ///
  /// When `null`, [QuiLocationRadiusMap] uses the current `qui` primary color
  /// with a stronger opacity than the fill.
  final Color? borderColor;

  /// Width of the radius border in logical pixels.
  final double borderWidth;
}
