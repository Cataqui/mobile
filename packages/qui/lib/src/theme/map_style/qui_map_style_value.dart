import 'package:freezed_annotation/freezed_annotation.dart';

part 'qui_map_style_value.freezed.dart';

/// A zoom-value pair used in MapLibre GL stop functions.
///
/// Models one entry in a stops array. Each stop defines the value at a
/// specific zoom level; the renderer interpolates between them.
///
/// ## MapLibre JSON mapping
/// ```json
/// [zoom, value]
/// ```
///
/// Both fields are typed as `num` so that whole numbers serialize as JSON
/// integers and fractional numbers as JSON doubles, matching the original
/// MapLibre style file exactly.
@Freezed(toJson: false, fromJson: false)
sealed class QuiMapLibreStyleZoomStop with _$QuiMapLibreStyleZoomStop {
  const factory QuiMapLibreStyleZoomStop({
    /// The zoom level for this stop. Integer zoom levels (e.g. `10`) match
    /// discrete zoom transitions; fractional values would produce
    /// interpolated results.
    required num zoom,

    /// The paint or layout property value at this stop's zoom level.
    /// The type depends on the property (pixel width, font size, opacity, etc.).
    required num value,
  }) = _QuiMapLibreStyleZoomStop;
}

/// A typed representation of a MapLibre GL paint or layout property value.
///
/// In the MapLibre GL Style Specification, properties can be either:
/// - A constant scalar (e.g. `"line-width": 2`)
/// - A zoom-dependent interpolation expression
///   (e.g. `"line-width": ["interpolate", ["linear"], ["zoom"], 10, 1, 16, 6]`)
///
/// This sealed class models both forms. Use [QuiMapLibreStyleValue.scalar] for
/// constant values and [QuiMapLibreStyleValue.stops] for zoom-dependent values.
///
/// ## MapLibre JSON mapping
/// ```json
/// // Scalar
/// 13
/// // Zoom-dependent interpolation
/// ["interpolate", ["linear"], ["zoom"], 10, 1, 16, 6]
/// ```
@Freezed(toJson: false, fromJson: false)
sealed class QuiMapLibreStyleValue with _$QuiMapLibreStyleValue {
  const factory QuiMapLibreStyleValue.scalar(num value) = QuiMapLibreStyleScalarValue;
  const factory QuiMapLibreStyleValue.stops(List<QuiMapLibreStyleZoomStop> stops) = QuiMapLibreStyleStopsValue;
}

/// JSON serialization extension for [QuiMapLibreStyleZoomStop].
extension QuiMapLibreStyleZoomStopJson on QuiMapLibreStyleZoomStop {
  /// Returns `[zoom, value]` as a list of two numbers.
  List<num> toJson() => [zoom, value];
}

/// JSON serialization extension for [QuiMapLibreStyleValue].
extension QuiMapLibreStyleValueJson on QuiMapLibreStyleValue {
  /// Returns either a raw number (for scalar values) or an expression array for
  /// zoom-dependent interpolation.
  ///
  /// Scalar values are inlined as-is. Stop functions are converted to MapLibre
  /// interpolation expressions:
  /// ```json
  /// ["interpolate", ["linear"], ["zoom"], z1, v1, z2, v2, ...]
  /// ```
  Object toJson() => switch (this) {
    QuiMapLibreStyleScalarValue(:final value) => value,
    QuiMapLibreStyleStopsValue(:final stops) => [
      'interpolate',
      ['linear'],
      ['zoom'],
      ...stops.expand((s) => [s.zoom, s.value]),
    ],
  };
}
