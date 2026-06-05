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
    required this.primaryColor,
    this.typography = const QuiTypography(),
  });

  /// The background color used for screens and surfaces.
  final Color backgroundColor;

  /// The brand primary color used as the seed for Material 3's
  /// [ColorScheme.fromSeed]. Drives the color of buttons, FABs, switches,
  /// chips, and other M3 components.
  final Color primaryColor;

  /// Cataquí typography tokens (Inter font family, -0.02em letter spacing).
  final QuiTypography typography;

  @override
  QuiThemeData copyWith({
    Color? backgroundColor,
    Color? primaryColor,
    QuiTypography? typography,
  }) {
    return QuiThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      primaryColor: primaryColor ?? this.primaryColor,
      typography: typography ?? this.typography,
    );
  }

  @override
  QuiThemeData lerp(covariant QuiThemeData? other, double t) {
    if (other == null) return this;
    return QuiThemeData(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      typography: t < 0.5 ? typography : other.typography,
    );
  }
}
