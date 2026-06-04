import 'package:flutter/material.dart';

import 'qui_theme_data.dart';
import 'qui_typography.dart';

/// Factory for Cataquí-branded [ThemeData] objects.
///
/// Pass the result directly to [MaterialApp]:
///
/// ```dart
/// MaterialApp(
///   theme: QuiTheme.light(),
///   home: const HomeScreen(),
/// )
/// ```
abstract final class QuiTheme {
  /// A light theme with Cataquí design tokens.
  ///
  /// Registers a [QuiThemeData]
  /// extension so that `context.qui` and
  /// `Theme.of(context).extension<QuiThemeData>()` work in every widget.
  static ThemeData light() =>
      _build(const QuiThemeData(backgroundColor: Color(0xFFFFFFFF)));

  static ThemeData _build(QuiThemeData quiData) {
    return ThemeData(
      useMaterial3: true,
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
