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
sealed class QuiMapStyleZoomStop with _$QuiMapStyleZoomStop {
  const factory QuiMapStyleZoomStop({
    /// The zoom level for this stop. Integer zoom levels (e.g. `10`) match
    /// discrete zoom transitions; fractional values would produce
    /// interpolated results.
    required num zoom,

    /// The paint or layout property value at this stop's zoom level.
    /// The type depends on the property (pixel width, font size, opacity, etc.).
    required num value,
  }) = _QuiMapStyleZoomStop;
}

/// A typed representation of a MapLibre GL paint or layout property value.
///
/// In the MapLibre GL Style Specification, properties can be either:
/// - A constant scalar (e.g. `"line-width": 2`)
/// - A zoom-dependent stop function (e.g. `"line-width": { "stops": [[10, 1], [16, 6]] }`)
///
/// This sealed class models both forms. Use [QuiMapStyleValue.scalar] for
/// constant values and [QuiMapStyleValue.stops] for zoom-dependent values.
///
/// ## MapLibre JSON mapping
/// ```json
/// // Scalar
/// 13
/// // Stop function
/// { "stops": [[10, 1], [16, 6]] }
/// ```
@Freezed(toJson: false, fromJson: false)
sealed class QuiMapStyleValue with _$QuiMapStyleValue {
  const factory QuiMapStyleValue.scalar(num value) = QuiMapStyleScalarValue;
  const factory QuiMapStyleValue.stops(List<QuiMapStyleZoomStop> stops) = QuiMapStyleStopsValue;
}

/// JSON serialization extension for [QuiMapStyleZoomStop].
extension QuiMapStyleZoomStopJson on QuiMapStyleZoomStop {
  /// Returns `[zoom, value]` as a list of two numbers.
  List<num> toJson() => [zoom, value];
}

/// JSON serialization extension for [QuiMapStyleValue].
extension QuiMapStyleValueJson on QuiMapStyleValue {
  /// Returns either a raw number (for scalar values) or a stops object map.
  Object toJson() => switch (this) {
    QuiMapStyleScalarValue(:final value) => value,
    QuiMapStyleStopsValue(:final stops) => {'stops': stops.map((s) => s.toJson()).toList()},
  };
}
