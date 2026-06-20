import 'package:flutter/material.dart';

import 'qui_colors.dart';
import 'qui_typography.dart';

/// Cataquí design tokens registered as a [ThemeExtension].
///
/// Use `QuiThemeData` to access branded colors, typography, and styling
/// values consistently across the widget tree. Register it via
/// `QuiTheme.light` (or a custom [ThemeData.extensions] list), then
/// retrieve it with `context.qui` or
/// `Theme.of(context).extension<QuiThemeData>()`.
///
/// ```dart
/// Container(
///   color: context.qui.colors.searchBarButtonBackground,
/// )
/// ```
@immutable
class QuiThemeData extends ThemeExtension<QuiThemeData> {
  /// Creates a [QuiThemeData] with the given design tokens.
  const QuiThemeData({
    required this.colors,
    this.typography = const QuiTypography(),
  });

  /// Cataquí semantic color tokens.
  final QuiColors colors;

  /// Cataquí typography tokens (Inter font family, -0.02em letter spacing).
  final QuiTypography typography;

  @override
  QuiThemeData copyWith({
    QuiColors? colors,
    QuiTypography? typography,
  }) {
    return QuiThemeData(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
    );
  }

  @override
  QuiThemeData lerp(covariant QuiThemeData? other, double t) {
    if (other == null) return this;
    return QuiThemeData(
      colors: QuiColors.lerp(colors, other.colors, t),
      typography: t < 0.5 ? typography : other.typography,
    );
  }
}
