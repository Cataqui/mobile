import 'package:flutter/material.dart';

import 'qui_color_scheme/qui_color_scheme.dart';
import 'qui_typography.dart';

@immutable
/// The reusable QUI tokens registered on a Material [ThemeData].
class QuiThemeData extends ThemeExtension<QuiThemeData> {
  /// Creates theme data from the required semantic [colorScheme].
  const QuiThemeData({required this.colorScheme, this.typography = const QuiTypography()});

  /// The semantic color contract shared by QUI and Material components.
  final QuiColorScheme colorScheme;

  /// The QUI typography scale.
  final QuiTypography typography;

  @override
  QuiThemeData copyWith({QuiColorScheme? colorScheme, QuiTypography? typography}) {
    return QuiThemeData(colorScheme: colorScheme ?? this.colorScheme, typography: typography ?? this.typography);
  }

  @override
  QuiThemeData lerp(covariant QuiThemeData? other, double t) {
    if (other == null) return this;
    return QuiThemeData(
      colorScheme: QuiColorScheme.lerp(colorScheme, other.colorScheme, t),
      typography: t < 0.5 ? typography : other.typography,
    );
  }
}
