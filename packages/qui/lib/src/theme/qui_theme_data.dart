import 'package:flutter/material.dart';

import 'qui_color_scheme/qui_color_scheme.dart';
import 'qui_palette/qui_palette.dart';
import 'qui_typography.dart';

@immutable
/// The reusable QUI tokens registered on a Material [ThemeData].
class QuiThemeData extends ThemeExtension<QuiThemeData> {
  /// Creates theme data from the required semantic [colorScheme] and [palette].
  const QuiThemeData({required this.colorScheme, required this.palette, this.typography = const QuiTypography()});

  /// The semantic color contract shared by QUI and Material components.
  final QuiColorScheme colorScheme;

  /// The QUI typography scale.
  final QuiTypography typography;

  /// The raw primitive color palette used to build the color scheme.
  final QuiPalette palette;

  @override
  QuiThemeData copyWith({QuiColorScheme? colorScheme, QuiTypography? typography, QuiPalette? palette}) {
    return QuiThemeData(
      colorScheme: colorScheme ?? this.colorScheme,
      typography: typography ?? this.typography,
      palette: palette ?? this.palette,
    );
  }

  @override
  QuiThemeData lerp(covariant QuiThemeData? other, double t) {
    if (other == null) return this;
    return QuiThemeData(
      colorScheme: QuiColorScheme.lerp(colorScheme, other.colorScheme, t),
      typography: t < 0.5 ? typography : other.typography,
      palette: t < 0.5 ? palette : other.palette,
    );
  }
}
