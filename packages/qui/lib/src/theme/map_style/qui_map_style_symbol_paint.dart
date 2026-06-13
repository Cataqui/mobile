/// Paint properties for a MapLibre GL symbol layer that renders text.
///
/// Models a subset of the symbol layer paint properties, specifically those
/// for text rendering. The Cataquí light theme does not use icon paint
/// properties.
///
/// ## MapLibre JSON mapping
/// {@template qui_symbol_paint_json}
/// ```json
/// {
///   "text-color": "#555657",
///   "text-halo-color": "#ffffff",
///   "text-halo-width": 1,
///   "text-opacity": 0.5
/// }
/// ```
/// {@endtemplate}
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'qui_map_style_symbol_paint.freezed.dart';
part 'qui_map_style_symbol_paint.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class QuiMapLibreStyleSymbolPaint with _$QuiMapLibreStyleSymbolPaint {
  const factory QuiMapLibreStyleSymbolPaint({
    /// The text fill color as a hex string (e.g. `"#555657"`).
    ///
    /// Mapped to the `text-color` JSON key.
    @JsonKey(name: 'text-color') required String textColor,

    /// The color of the text halo (outline) as a hex string.
    ///
    /// Mapped to the `text-halo-color` JSON key. A white halo improves
    /// legibility against varied backgrounds.
    @JsonKey(name: 'text-halo-color') required String textHaloColor,

    /// The width of the text halo in pixels.
    ///
    /// Mapped to the `text-halo-width` JSON key.
    @JsonKey(name: 'text-halo-width') required double textHaloWidth,

    /// The text opacity from 0 (transparent) to 1 (opaque).
    ///
    /// Mapped to the `text-opacity` JSON key. When null, defaults to 1
    /// in MapLibre.
    @JsonKey(name: 'text-opacity') double? textOpacity,
  }) = _QuiMapLibreStyleSymbolPaint;
}
