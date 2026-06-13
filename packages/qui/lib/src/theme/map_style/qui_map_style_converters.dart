/// JSON serialization converters for [QuiMapLibreStyleValue] and [QuiMapLibreStyleLayer].
///
/// These converters are used by `json_serializable` when generating `toJson`
/// code for Freezed DTOs that contain these types. They delegate to the
/// extension-based `toJson()` methods defined on each sealed class.
///
/// Only `toJson()` is supported. `fromJson()` throws `UnsupportedError`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:qui/src/theme/map_style/qui_map_style_layer.dart';
import 'package:qui/src/theme/map_style/qui_map_style_value.dart';

/// Converts [QuiMapLibreStyleValue] to/from its JSON representation.
///
/// Used via `@QuiMapLibreStyleValueConverter()` annotation on DTO fields.
class QuiMapLibreStyleValueConverter implements JsonConverter<QuiMapLibreStyleValue, Object> {
  const QuiMapLibreStyleValueConverter();

  @override
  QuiMapLibreStyleValue fromJson(Object json) => throw UnsupportedError('QuiMapLibreStyleValue.fromJson is not supported');

  @override
  Object toJson(QuiMapLibreStyleValue value) => value.toJson();
}

/// Converts a list of [QuiMapLibreStyleLayer] to/from its JSON representation.
///
/// Used via `@QuiMapLibreStyleLayerConverter()` annotation on DTO fields.
class QuiMapLibreStyleLayerConverter implements JsonConverter<List<QuiMapLibreStyleLayer>, List<dynamic>> {
  const QuiMapLibreStyleLayerConverter();

  @override
  List<QuiMapLibreStyleLayer> fromJson(List<dynamic> json) =>
      throw UnsupportedError('QuiMapLibreStyleLayer.fromJson is not supported');

  @override
  List<dynamic> toJson(List<QuiMapLibreStyleLayer> layers) =>
      layers.map((l) => l.toJson()).toList();
}
