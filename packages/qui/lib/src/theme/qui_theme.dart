import 'package:flutter/material.dart';
import 'package:qui/gen/fonts.gen.dart';

import 'qui_color_scheme/qui_color_scheme.dart';
import 'qui_palette/qui_palette.dart';
import 'qui_theme_data.dart';
import 'qui_typography.dart';

/// Factory for QUI [ThemeData] objects.
///
/// Material components and QUI widgets resolve from the same semantic scheme,
/// preventing framework defaults from drifting away from package tokens.
abstract final class QuiTheme {
  /// Creates the fully specified light appearance from [primaryColor] and
  /// [onPrimary].
  ///
  /// When omitted, [primaryColor] and [onPrimary] defaults to the default QUI colors
  ///
  /// ```dart
  /// MaterialApp(
  ///   theme: QuiTheme.light(),
  ///   home: const HomeScreen(),
  /// )
  /// ```
  static ThemeData light({Color? primaryColor, Color? onPrimary}) {
    final palette = QuiPalette(primaryColor: primaryColor);
    final colorScheme = QuiColorScheme.light(palette: palette, onPrimary: onPrimary);

    return _build(QuiThemeData(colorScheme: colorScheme, palette: palette));
  }

  static ThemeData _build(QuiThemeData quiData) {
    final quiColorScheme = quiData.colorScheme;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: quiColorScheme.colors.primary.solid,
      onPrimary: quiColorScheme.colors.primary.onSolid,
      primaryContainer: quiColorScheme.colors.primary.subtle,
      onPrimaryContainer: quiColorScheme.text.brandPrimary,
      secondary: quiColorScheme.colors.teal.solid,
      onSecondary: quiColorScheme.colors.teal.onSolid,
      secondaryContainer: quiColorScheme.colors.teal.subtle,
      onSecondaryContainer: quiColorScheme.colors.teal.text,
      tertiary: quiColorScheme.colors.orange.solid,
      onTertiary: quiColorScheme.colors.orange.onSolid,
      tertiaryContainer: quiColorScheme.colors.orange.subtle,
      onTertiaryContainer: quiColorScheme.colors.orange.text,
      error: quiColorScheme.error.solid,
      onError: quiColorScheme.error.onSolid,
      errorContainer: quiColorScheme.error.subtle,
      onErrorContainer: quiColorScheme.error.text,
      surface: quiColorScheme.background,
      onSurface: quiColorScheme.text.primary,
      onSurfaceVariant: quiColorScheme.text.secondary,
      outline: quiColorScheme.border.standard,
      outlineVariant: quiColorScheme.border.subtle,
      shadow: const Color(0xFF000000),
      scrim: quiColorScheme.scrim,
      inverseSurface: quiColorScheme.inverse.background,
      onInverseSurface: quiColorScheme.inverse.onBackground,
      inversePrimary: quiColorScheme.inverse.primary,
      surfaceTint: quiColorScheme.colors.primary.solid,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: FontFamily.inter,
      scaffoldBackgroundColor: quiData.colorScheme.background,
      textTheme: _buildTextTheme(quiData.typography),
      extensions: [quiData],
    );
  }

  static TextTheme _buildTextTheme(QuiTypography typography) {
    return TextTheme(
      displayLarge: typography.displayLarge,
      displayMedium: typography.displayMedium,
      displaySmall: typography.displaySmall,
      headlineLarge: typography.headlineLarge,
      headlineMedium: typography.headlineMedium,
      headlineSmall: typography.headlineSmall,
      titleLarge: typography.titleLarge,
      titleMedium: typography.titleMedium,
      titleSmall: typography.titleSmall,
      bodyLarge: typography.bodyLarge,
      bodyMedium: typography.bodyMedium,
      bodySmall: typography.bodySmall,
      labelLarge: typography.labelLarge,
      labelMedium: typography.labelMedium,
      labelSmall: typography.labelSmall,
    );
  }
}
