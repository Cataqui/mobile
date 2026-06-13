/// JSON serialization converters for [QuiMapStyleValue] and [QuiMapStyleLayer].
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

/// Converts [QuiMapStyleValue] to/from its JSON representation.
///
/// Used via `@QuiMapStyleValueConverter()` annotation on DTO fields.
class QuiMapStyleValueConverter implements JsonConverter<QuiMapStyleValue, Object> {
  const QuiMapStyleValueConverter();

  @override
  QuiMapStyleValue fromJson(Object json) => throw UnsupportedError('QuiMapStyleValue.fromJson is not supported');

  @override
  Object toJson(QuiMapStyleValue value) => value.toJson();
}

/// Converts a list of [QuiMapStyleLayer] to/from its JSON representation.
///
/// Used via `@QuiMapStyleLayerConverter()` annotation on DTO fields.
class QuiMapStyleLayerConverter implements JsonConverter<List<QuiMapStyleLayer>, List<dynamic>> {
  const QuiMapStyleLayerConverter();

  @override
  List<QuiMapStyleLayer> fromJson(List<dynamic> json) =>
      throw UnsupportedError('QuiMapStyleLayer.fromJson is not supported');

  @override
  List<dynamic> toJson(List<QuiMapStyleLayer> layers) =>
      layers.map((l) => l.toJson()).toList();
}
