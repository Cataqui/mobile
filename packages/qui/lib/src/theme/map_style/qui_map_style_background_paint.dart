library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'qui_map_style_background_paint.freezed.dart';
part 'qui_map_style_background_paint.g.dart';

/// Paint properties for a MapLibre GL background layer.
///
/// Models the background layer paint properties. The background layer fills
/// the entire map canvas before any other layers are rendered.
///
/// ## MapLibre JSON mapping
/// {@template qui_background_paint_json}
/// ```json
/// {
///   "background-color": "#ebedef"
/// }
/// ```
/// {@endtemplate}
@Freezed(toJson: true, fromJson: false)
abstract class QuiMapStyleBackgroundPaint with _$QuiMapStyleBackgroundPaint {
  const factory QuiMapStyleBackgroundPaint({
    /// The background fill color as a hex string (e.g. `"#ebedef"`).
    ///
    /// Mapped to the `background-color` JSON key. Accepts any CSS-compatible
    /// hex color. Transparency can be set independently on the fill.
    @JsonKey(name: 'background-color') required String backgroundColor,
  }) = _QuiMapStyleBackgroundPaint;
}
