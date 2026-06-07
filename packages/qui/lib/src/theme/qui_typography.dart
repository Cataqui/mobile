import 'package:flutter/material.dart';
import 'package:qui/gen/fonts.gen.dart';

/// Typography tokens for the Cataquí design system.
///
/// All text styles use the **Inter** typeface with a proportional
/// letter spacing of **-0.02em** (tight, clean) and
/// [FontWeight.w400] as the baseline weight.
///
/// Use the getters to style text directly:
///
/// ```dart
/// Text(
///   'Hello',
///   style: const QuiTypography().bodyLarge,
/// )
/// ```
///
/// Material widgets automatically pick up these styles when
/// the Cataquí theme registers them via [ThemeData.textTheme].
@immutable
class QuiTypography {
  /// Creates a set of Cataquí typography tokens.
  const QuiTypography();

  /// Proportional letter spacing factor applied to all Cataquí text.
  ///
  /// The pixel value for each style is computed at compile time:
  /// `letterSpacing = fontSize * letterSpacingFactor`.
  /// For example, `14px * -0.02` → `-0.28`.
  static const double letterSpacingFactor = -0.02;

  // ---------------------------------------------------------------------------
  // Display
  // ---------------------------------------------------------------------------

  /// The largest display style — 57px, w400, -1.14 letter spacing.
  TextStyle get displayLarge => _style(fontSize: 57, letterSpacing: 57 * letterSpacingFactor, height: 1.12);

  /// Display style — 45px, w400, -0.90 letter spacing.
  TextStyle get displayMedium => _style(fontSize: 45, letterSpacing: 45 * letterSpacingFactor, height: 1.16);

  /// Display style — 36px, w400, -0.72 letter spacing.
  TextStyle get displaySmall => _style(fontSize: 36, letterSpacing: 36 * letterSpacingFactor, height: 1.22);

  // ---------------------------------------------------------------------------
  // Headline
  // ---------------------------------------------------------------------------

  /// Headline style — 32px, w400, -0.64 letter spacing.
  TextStyle get headlineLarge => _style(fontSize: 32, letterSpacing: 32 * letterSpacingFactor, height: 1.25);

  /// Headline style — 28px, w400, -0.56 letter spacing.
  TextStyle get headlineMedium => _style(fontSize: 28, letterSpacing: 28 * letterSpacingFactor, height: 1.29);

  /// Headline style — 24px, w400, -0.48 letter spacing.
  TextStyle get headlineSmall => _style(fontSize: 24, letterSpacing: 24 * letterSpacingFactor, height: 1.33);

  // ---------------------------------------------------------------------------
  // Title
  // ---------------------------------------------------------------------------

  /// Title style — 22px, w400, -0.44 letter spacing.
  TextStyle get titleLarge => _style(fontSize: 22, letterSpacing: 22 * letterSpacingFactor, height: 1.27);

  /// Title style — 16px, w400, -0.32 letter spacing.
  TextStyle get titleMedium => _style(fontSize: 16, letterSpacing: 16 * letterSpacingFactor, height: 1.5);

  /// Title style — 14px, w400, -0.28 letter spacing.
  TextStyle get titleSmall => _style(fontSize: 14, letterSpacing: 14 * letterSpacingFactor, height: 1.43);

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  /// Body style — 16px, w400, -0.32 letter spacing.
  TextStyle get bodyLarge => _style(fontSize: 16, letterSpacing: 16 * letterSpacingFactor, height: 1.5);

  /// Body style — 14px, w400, -0.28 letter spacing.
  TextStyle get bodyMedium => _style(fontSize: 14, letterSpacing: 14 * letterSpacingFactor, height: 1.43);

  /// Body style — 12px, w400, -0.24 letter spacing.
  TextStyle get bodySmall => _style(fontSize: 12, letterSpacing: 12 * letterSpacingFactor, height: 1.33);

  // ---------------------------------------------------------------------------
  // Label
  // ---------------------------------------------------------------------------

  /// Label style — 15px, w400, -0.30 letter spacing.
  TextStyle get labelLarge => _style(fontSize: 15, letterSpacing: 15 * letterSpacingFactor, height: 1.43);

  /// Label style — 12px, w400, -0.24 letter spacing.
  TextStyle get labelMedium => _style(fontSize: 12, letterSpacing: 12 * letterSpacingFactor, height: 1.33);

  /// Label style — 11px, w400, -0.22 letter spacing.
  TextStyle get labelSmall => _style(fontSize: 11, letterSpacing: 11 * letterSpacingFactor, height: 1.45);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  TextStyle _style({required double fontSize, required double letterSpacing, required double? height}) {
    return TextStyle(
      fontFamily: FontFamily.inter,
      fontWeight: FontWeight.w400,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
