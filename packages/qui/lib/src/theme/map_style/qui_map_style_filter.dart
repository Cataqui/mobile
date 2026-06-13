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
sealed class QuiMapLibreStyleFilter with _$QuiMapLibreStyleFilter {
  /// Creates a filter that matches features where [key] equals [value].
  ///
  /// Corresponds to the MapLibre `["==", key, value]` expression.
  const factory QuiMapLibreStyleFilter.equals({
    required String key,
    required Object value,
  }) = QuiMapLibreStyleEqualsFilter;

  /// Creates a filter that matches features where [key] `>=` [value].
  ///
  /// Corresponds to the MapLibre `[">=", key, value]` expression.
  const factory QuiMapLibreStyleFilter.greaterThanOrEqual({
    required String key,
    required num value,
  }) = QuiMapLibreStyleGteFilter;

  /// Creates a filter that matches features where [key] `<=` [value].
  ///
  /// Corresponds to the MapLibre `["<=", key, value]` expression.
  const factory QuiMapLibreStyleFilter.lessThanOrEqual({
    required String key,
    required num value,
  }) = QuiMapLibreStyleLteFilter;

  /// Creates a filter that matches features matching any of [filters].
  ///
  /// Corresponds to the MapLibre `["any", ...]` expression. Child filters
  /// are evaluated with logical OR semantics.
  const factory QuiMapLibreStyleFilter.any({
    required List<QuiMapLibreStyleFilter> filters,
  }) = QuiMapLibreStyleAnyFilter;
}

/// JSON serialization extension for [QuiMapLibreStyleFilter].
extension QuiMapLibreStyleFilterJson on QuiMapLibreStyleFilter {
  /// Serializes this filter to a MapLibre-compatible array expression.
  List<dynamic> toJson() => switch (this) {
        QuiMapLibreStyleEqualsFilter(:final key, :final value) => ['==', key, value],
        QuiMapLibreStyleGteFilter(:final key, :final value) => ['>=', key, value],
        QuiMapLibreStyleLteFilter(:final key, :final value) => ['<=', key, value],
        QuiMapLibreStyleAnyFilter(:final filters) => [
          'any',
          ...filters.map((f) => f.toJson()),
        ],
      };
}
