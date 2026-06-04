import 'package:flutter/material.dart';

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
///   color: context.qui.backgroundColor,
/// )
/// ```
@immutable
class QuiThemeData extends ThemeExtension<QuiThemeData> {
  /// Creates a [QuiThemeData] with the given design tokens.
  const QuiThemeData({
    required this.backgroundColor,
    this.typography = const QuiTypography(),
  });

  /// The background color used for screens and surfaces.
  final Color backgroundColor;

  /// Cataquí typography tokens (Inter font family, -0.02em letter spacing).
  final QuiTypography typography;

  @override
  QuiThemeData copyWith({
    Color? backgroundColor,
    QuiTypography? typography,
  }) {
    return QuiThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      typography: typography ?? this.typography,
    );
  }

  @override
  QuiThemeData lerp(covariant QuiThemeData? other, double t) {
    if (other == null) return this;
    return QuiThemeData(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      typography: t < 0.5 ? typography : other.typography,
    );
  }
}
