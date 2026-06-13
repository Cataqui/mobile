/// A typed representation of a MapLibre GL filter expression.
///
/// Filters select which features from a vector tile source layer are rendered
/// by a layer. The MapLibre GL Style Specification uses operator-based filter
/// expressions. This sealed class models the subset of filter operators used
/// by the Cataquí light theme.
///
/// ## MapLibre JSON mapping
/// Each variant serializes to the equivalent filter array:
/// - `equals` → `["==", key, value]`
/// - `greaterThanOrEqual` → `[">=", key, value]`
/// - `lessThanOrEqual` → `["<=", key, value]`
/// - `any` → `["any", filter1, filter2, ...]`
///
/// ## Supported operators
/// | Operator | Constructor | Description |
/// |---|---|---|
/// | `==` | `equals` | Feature key equals value |
/// | `>=` | `greaterThanOrEqual` | Feature key `>=` numeric value |
/// | `<=` | `lessThanOrEqual` | Feature key `<=` numeric value |
/// | `any` | `any` | Logical OR of child filters |
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'qui_map_style_filter.freezed.dart';

@Freezed(toJson: false, fromJson: false)
sealed class QuiMapStyleFilter with _$QuiMapStyleFilter {
  /// Creates a filter that matches features where [key] equals [value].
  ///
  /// Corresponds to the MapLibre `["==", key, value]` expression.
  const factory QuiMapStyleFilter.equals({
    required String key,
    required Object value,
  }) = QuiMapStyleEqualsFilter;

  /// Creates a filter that matches features where [key] `>=` [value].
  ///
  /// Corresponds to the MapLibre `[">=", key, value]` expression.
  const factory QuiMapStyleFilter.greaterThanOrEqual({
    required String key,
    required num value,
  }) = QuiMapStyleGteFilter;

  /// Creates a filter that matches features where [key] `<=` [value].
  ///
  /// Corresponds to the MapLibre `["<=", key, value]` expression.
  const factory QuiMapStyleFilter.lessThanOrEqual({
    required String key,
    required num value,
  }) = QuiMapStyleLteFilter;

  /// Creates a filter that matches features matching any of [filters].
  ///
  /// Corresponds to the MapLibre `["any", ...]` expression. Child filters
  /// are evaluated with logical OR semantics.
  const factory QuiMapStyleFilter.any({
    required List<QuiMapStyleFilter> filters,
  }) = QuiMapStyleAnyFilter;
}

/// JSON serialization extension for [QuiMapStyleFilter].
extension QuiMapStyleFilterJson on QuiMapStyleFilter {
  /// Serializes this filter to a MapLibre-compatible array expression.
  List<dynamic> toJson() => switch (this) {
        QuiMapStyleEqualsFilter(:final key, :final value) => ['==', key, value],
        QuiMapStyleGteFilter(:final key, :final value) => ['>=', key, value],
        QuiMapStyleLteFilter(:final key, :final value) => ['<=', key, value],
        QuiMapStyleAnyFilter(:final filters) => [
          'any',
          ...filters.map((f) => f.toJson()),
        ],
      };
}
