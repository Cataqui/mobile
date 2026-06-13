/// Layout properties for a MapLibre GL symbol layer that renders text labels.
///
/// Models a subset of the symbol layer layout properties. These control the
/// position, appearance, and behavior of text labels on the map. The Cataquí
/// light theme does not use icon layout properties.
///
/// ## MapLibre JSON mapping
/// {@template qui_symbol_layout_json}
/// ```json
/// {
///   "text-field": "{name}",
///   "text-font": ["Inter"],
///   "text-size": { "stops": [[8, 11], [10, 13], [14, 18]] },
///   "text-max-width": 8,
///   "text-anchor": "bottom",
///   "text-letter-spacing": 0.15,
///   "text-transform": "uppercase",
///   "symbol-placement": "line"
/// }
/// ```
/// {@endtemplate}
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:qui/src/theme/map_style/qui_map_style_converters.dart';
import 'package:qui/src/theme/map_style/qui_map_style_value.dart';

part 'qui_map_style_symbol_layout.freezed.dart';
part 'qui_map_style_symbol_layout.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class QuiMapStyleSymbolLayout with _$QuiMapStyleSymbolLayout {
  const factory QuiMapStyleSymbolLayout({
    /// The text content expression (e.g. `"{name}"` to use a feature property).
    ///
    /// Mapped to the `text-field` JSON key. Accepts a field reference (in
    /// curly braces) or a string literal. When null, no text is rendered.
    @JsonKey(name: 'text-field') String? textField,

    /// Ordered list of font stacks to use for text rendering.
    ///
    /// Mapped to the `text-font` JSON key. The first available font is used.
    /// Supports comma-separated fallback names within each string entry.
    /// When null, falls back to MapLibre's default font.
    @JsonKey(name: 'text-font') List<String>? textFont,

    /// The font size, which may be a constant scalar or a zoom-dependent stop
    /// function.
    ///
    /// Mapped to the `text-size` JSON key in pixels. Uses
    /// [QuiMapStyleValueConverter] for serialization.
    @JsonKey(name: 'text-size')
    @QuiMapStyleValueConverter()
    QuiMapStyleValue? textSize,

    /// The maximum line width for text wrapping, in ems.
    ///
    /// Mapped to the `text-max-width` JSON key. When null, MapLibre default
    /// (`10`) applies.
    @JsonKey(name: 'text-max-width') double? textMaxWidth,

    /// The text anchor position relative to the label point.
    ///
    /// Mapped to the `text-anchor` JSON key. Values: `"center"`, `"top"`,
    /// `"bottom"`, `"left"`, `"right"`, `"top-left"`, `"top-right"`,
    /// `"bottom-left"`, `"bottom-right"`. Defaults to `"center"` when null.
    @JsonKey(name: 'text-anchor') String? textAnchor,

    /// Letter spacing in ems (e.g. `0.15` adds 15% of one em between letters).
    ///
    /// Mapped to the `text-letter-spacing` JSON key. When null, MapLibre
    /// default (`0`) applies.
    @JsonKey(name: 'text-letter-spacing') double? textLetterSpacing,

    /// Text transform applied to the label content.
    ///
    /// Mapped to the `text-transform` JSON key. Values: `"none"`,
    /// `"uppercase"`, `"lowercase"`. When null, `"none"` applies.
    @JsonKey(name: 'text-transform') String? textTransform,

    /// Label placement mode relative to the geometry.
    ///
    /// Mapped to the `symbol-placement` JSON key. `"point"` places labels at
    /// fixed points; `"line"` places them along lines (useful for road names).
    /// When null, `"point"` applies.
    @JsonKey(name: 'symbol-placement') String? symbolPlacement,
  }) = _QuiMapStyleSymbolLayout;
}
