import 'package:flutter/material.dart';

/// Semantic color tokens for the Cataquí design system.
///
/// Every surfaced color in the application is defined here by its semantic
/// purpose rather than by its literal value.  This makes systematic changes
/// (dark mode, high-contrast accessibility, brand refresh) a single-source
/// edit rather than a scavenger hunt.
///
/// Use these tokens through the theme:
///
/// ```dart
/// Container(
///   color: context.qui.colors.searchBarBackground,
/// )
/// ```
///
/// See also:
///  * `QuiThemeData.colors` — the theme extension that holds a [QuiColors]
///    instance and makes it available via `context.qui.colors`.
@immutable
class QuiColors {
  /// Creates a set of Cataquí color tokens.
  const QuiColors({
    required this.primary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.placeholder,
    required this.disabledButtonBackground,
    required this.disabledButtonForeground,
    required this.searchBarBackground,
    required this.searchBarPlaceholder,
    required this.frostedGlassBackground,
    required this.frostedGlassBorder,
  });

  /// Light-theme defaults.
  ///
  /// [primary] is the brand accent color (e.g. `Color(0xFFFF4A4B)`).
  const factory QuiColors.light({Color primary}) = _LightQuiColors;

  /// The brand primary color used as the seed for Material 3's
  /// [ColorScheme.fromSeed] and for accent elements (active icons, selected
  /// states, etc.).
  final Color primary;

  /// The background color for screens and scaffold surfaces.
  final Color background;

  /// The surface color for elevated cards, sheets, and containers.
  final Color surface;

  /// The default color for body and heading text.
  final Color textPrimary;

  /// The muted color for secondary or supporting text.
  final Color textSecondary;

  /// The subdued color for placeholder text and inactive icons when the
  /// component does **not** have a dedicated placeholder token.
  final Color placeholder;

  /// Background color used by disabled filled buttons.
  final Color disabledButtonBackground;

  /// Recommended foreground color used by disabled filled buttons.
  final Color disabledButtonForeground;

  /// The background color of the search bar in its resting (non-frosted)
  /// state.
  final Color searchBarBackground;

  /// The color of the search bar's placeholder text and magnifier icon.
  final Color searchBarPlaceholder;

  /// The translucent overlay applied on top of the blurred content in the
  /// frosted-glass search bar variant.
  final Color frostedGlassBackground;

  /// The border color of the frosted-glass search bar variant.
  final Color frostedGlassBorder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiColors &&
          runtimeType == other.runtimeType &&
          primary == other.primary &&
          background == other.background &&
          surface == other.surface &&
          textPrimary == other.textPrimary &&
          textSecondary == other.textSecondary &&
          placeholder == other.placeholder &&
          disabledButtonBackground == other.disabledButtonBackground &&
          disabledButtonForeground == other.disabledButtonForeground &&
          searchBarBackground == other.searchBarBackground &&
          searchBarPlaceholder == other.searchBarPlaceholder &&
          frostedGlassBackground == other.frostedGlassBackground &&
          frostedGlassBorder == other.frostedGlassBorder;

  @override
  int get hashCode => Object.hash(
    primary,
    background,
    surface,
    textPrimary,
    textSecondary,
    placeholder,
    disabledButtonBackground,
    disabledButtonForeground,
    searchBarBackground,
    searchBarPlaceholder,
    frostedGlassBackground,
    frostedGlassBorder,
  );

  /// Returns a copy of this [QuiColors] with the given fields replaced.
  QuiColors copyWith({
    Color? primary,
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? placeholder,
    Color? disabledButtonBackground,
    Color? disabledButtonForeground,
    Color? searchBarBackground,
    Color? searchBarPlaceholder,
    Color? frostedGlassBackground,
    Color? frostedGlassBorder,
  }) {
    return QuiColors(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      placeholder: placeholder ?? this.placeholder,
      disabledButtonBackground: disabledButtonBackground ?? this.disabledButtonBackground,
      disabledButtonForeground: disabledButtonForeground ?? this.disabledButtonForeground,
      searchBarBackground: searchBarBackground ?? this.searchBarBackground,
      searchBarPlaceholder: searchBarPlaceholder ?? this.searchBarPlaceholder,
      frostedGlassBackground: frostedGlassBackground ?? this.frostedGlassBackground,
      frostedGlassBorder: frostedGlassBorder ?? this.frostedGlassBorder,
    );
  }

  /// Linearly interpolates between two [QuiColors] instances.
  ///
  /// {@macro flutter.widgets.lerp}
  // ignore: prefer_constructors_over_static_methods
  static QuiColors lerp(QuiColors a, QuiColors b, double t) {
    return QuiColors(
      primary: Color.lerp(a.primary, b.primary, t)!,
      background: Color.lerp(a.background, b.background, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
      placeholder: Color.lerp(a.placeholder, b.placeholder, t)!,
      disabledButtonBackground: Color.lerp(a.disabledButtonBackground, b.disabledButtonBackground, t)!,
      disabledButtonForeground: Color.lerp(a.disabledButtonForeground, b.disabledButtonForeground, t)!,
      searchBarBackground: Color.lerp(a.searchBarBackground, b.searchBarBackground, t)!,
      searchBarPlaceholder: Color.lerp(a.searchBarPlaceholder, b.searchBarPlaceholder, t)!,
      frostedGlassBackground: Color.lerp(a.frostedGlassBackground, b.frostedGlassBackground, t)!,
      frostedGlassBorder: Color.lerp(a.frostedGlassBorder, b.frostedGlassBorder, t)!,
    );
  }
}

class _LightQuiColors extends QuiColors {
  const _LightQuiColors({super.primary = const Color(0xFFFF4A4B)})
    : super(
        background: const Color(0xFFFFFFFF),
        surface: const Color(0xFFFFFFFF),
        textPrimary: const Color(0xFF1A1A1A),
        textSecondary: const Color(0xFF757575),
        placeholder: const Color(0xFF9E9E9E),
        disabledButtonBackground: const Color(0xFFE1E1E1),
        disabledButtonForeground: const Color(0xFF8E8E8E),
        searchBarBackground: const Color(0xFFFAFAFA),
        searchBarPlaceholder: const Color(0xFF9E9E9E),
        frostedGlassBackground: const Color(0x4DFFFFFF),
        frostedGlassBorder: const Color(0xFFE0E0E0),
      );
}
