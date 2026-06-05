import 'package:flutter/material.dart';

import 'qui_theme_data.dart';
import 'qui_typography.dart';

/// Factory for Cataquí-branded [ThemeData] objects.
///
/// Pass the result directly to [MaterialApp]:
///
/// ```dart
/// MaterialApp(
///   theme: QuiTheme.light(primaryColor: Color(0xFFFF4A4B)),
///   home: const HomeScreen(),
/// )
/// ```
abstract final class QuiTheme {
  /// A light theme with Cataquí design tokens.
  ///
  /// [primaryColor] is the brand color used as the seed for Material 3's
  /// generated [ColorScheme]. It drives the color of buttons, FABs,
  /// switches, chips, and all other M3 components.
  ///
  /// Registers a [QuiThemeData] extension so that `context.qui` and
  /// `Theme.of(context).extension<QuiThemeData>()` work in every widget.
  static ThemeData light({required Color primaryColor}) =>
      _build(QuiThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        primaryColor: primaryColor,
      ));

  static ThemeData _build(QuiThemeData quiData) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: quiData.primaryColor,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: quiData.backgroundColor,
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
