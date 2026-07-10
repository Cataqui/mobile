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
///   color: context.qui.colors.searchBarButtonBackground,
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
    required this.description,
    required this.borderOnBackground,
    required this.placeholder,
    required this.disabledButtonBackground,
    required this.disabledButtonForeground,
    required this.searchBarButtonBackground,
    required this.searchBarButtonShadow,
    required this.viewBackButtonBackground,
    required this.viewBackButtonShadow,
    required this.money,
    required this.mapBackground,
    required this.ghost,
    required this.shimmerTextBase,
    required this.shimmerTextGlow,
    required this.skeleton,
    required this.skeletonShimmerGlow,
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

  /// The color for descriptive and body text that users need to read.
  ///
  /// Lighter than [textPrimary] to reduce visual weight in dense paragraphs,
  /// but darker than [textSecondary] to remain comfortably readable.  Use for
  /// job descriptions, post bodies, explanatory text, and any long-form
  /// content where [textPrimary] would feel too heavy.
  final Color description;

  /// The border color for elements drawn directly on the background color.
  final Color borderOnBackground;

  /// The subdued color for placeholder text and inactive icons when the
  /// component does **not** have a dedicated placeholder token.
  final Color placeholder;

  /// Background color used by disabled filled buttons.
  final Color disabledButtonBackground;

  /// Recommended foreground color used by disabled filled buttons.
  final Color disabledButtonForeground;

  /// The background color of the search bar button in its resting state.
  final Color searchBarButtonBackground;

  /// Shadow color cast by the search bar button at rest; alpha baked into
  /// the hex literal so no `.withValues()` call is needed at the usage site.
  final Color searchBarButtonShadow;

  /// The background color of the back button in its resting state.
  final Color viewBackButtonBackground;

  /// Shadow color cast by the back button at rest; alpha baked into
  /// the hex literal so no `.withValues()` call is needed at the usage site.
  final Color viewBackButtonShadow;

  /// The color used for representing money amounts and payment highlights.
  final Color money;

  /// The solid fill color of the map canvas in its loaded state.
  final Color mapBackground;

  /// The color used for representing ghost elements, such as placeholders,
  /// loading states, something blocked, skeletons etc.
  final Color ghost;

  /// The base text color for shimmer loading animations.
  ///
  /// Represents the static resting color of shimmer text before the glow
  /// sweep passes over it.
  final Color shimmerTextBase;

  /// The glow highlight color for shimmer loading animations.
  ///
  /// This is the bright sweep that travels across the shimmer text.
  /// Typically a lightened version of [shimmerTextBase] so the sweep is
  /// visible but not abrupt.
  final Color shimmerTextGlow;

  /// The base fill color of skeleton bones.
  ///
  /// Used as the resting color of skeleton placeholders when the shimmer
  /// sweep is not actively passing over them.
  final Color skeleton;

  /// The bright glow color of the skeleton shimmer sweep animation.
  ///
  /// This highlight travels across the skeleton bones to indicate ongoing
  /// loading.  Typically a lightened version of [skeleton].
  final Color skeletonShimmerGlow;

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
          description == other.description &&
          borderOnBackground == other.borderOnBackground &&
          placeholder == other.placeholder &&
          disabledButtonBackground == other.disabledButtonBackground &&
          disabledButtonForeground == other.disabledButtonForeground &&
          searchBarButtonBackground == other.searchBarButtonBackground &&
          searchBarButtonShadow == other.searchBarButtonShadow &&
          viewBackButtonBackground == other.viewBackButtonBackground &&
          viewBackButtonShadow == other.viewBackButtonShadow &&
          money == other.money &&
          mapBackground == other.mapBackground &&
          ghost == other.ghost &&
          shimmerTextBase == other.shimmerTextBase &&
          shimmerTextGlow == other.shimmerTextGlow &&
          skeleton == other.skeleton &&
          skeletonShimmerGlow == other.skeletonShimmerGlow;

  @override
  int get hashCode => Object.hashAll([
    primary,
    background,
    surface,
    textPrimary,
    textSecondary,
    description,
    borderOnBackground,
    placeholder,
    disabledButtonBackground,
    disabledButtonForeground,
    searchBarButtonBackground,
    searchBarButtonShadow,
    viewBackButtonBackground,
    viewBackButtonShadow,
    money,
    mapBackground,
    ghost,
    shimmerTextBase,
    shimmerTextGlow,
    skeleton,
    skeletonShimmerGlow,
  ]);

  /// Returns a copy of this [QuiColors] with the given fields replaced.
  QuiColors copyWith({
    Color? primary,
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? description,
    Color? borderOnBackground,
    Color? placeholder,
    Color? disabledButtonBackground,
    Color? disabledButtonForeground,
    Color? searchBarButtonBackground,
    Color? searchBarButtonShadow,
    Color? backButtonBackground,
    Color? backButtonShadow,
    Color? money,
    Color? mapBackground,
    Color? ghost,
    Color? shimmerTextBase,
    Color? shimmerTextGlow,
    Color? skeleton,
    Color? skeletonShimmerGlow,
  }) {
    return QuiColors(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      description: description ?? this.description,
      borderOnBackground: borderOnBackground ?? this.borderOnBackground,
      placeholder: placeholder ?? this.placeholder,
      disabledButtonBackground: disabledButtonBackground ?? this.disabledButtonBackground,
      disabledButtonForeground: disabledButtonForeground ?? this.disabledButtonForeground,
      searchBarButtonBackground: searchBarButtonBackground ?? this.searchBarButtonBackground,
      searchBarButtonShadow: searchBarButtonShadow ?? this.searchBarButtonShadow,
      viewBackButtonBackground: backButtonBackground ?? viewBackButtonBackground,
      viewBackButtonShadow: backButtonShadow ?? viewBackButtonShadow,
      money: money ?? this.money,
      mapBackground: mapBackground ?? this.mapBackground,
      ghost: ghost ?? this.ghost,
      shimmerTextBase: shimmerTextBase ?? this.shimmerTextBase,
      shimmerTextGlow: shimmerTextGlow ?? this.shimmerTextGlow,
      skeleton: skeleton ?? this.skeleton,
      skeletonShimmerGlow: skeletonShimmerGlow ?? this.skeletonShimmerGlow,
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
      description: Color.lerp(a.description, b.description, t)!,
      borderOnBackground: Color.lerp(a.borderOnBackground, b.borderOnBackground, t)!,
      placeholder: Color.lerp(a.placeholder, b.placeholder, t)!,
      disabledButtonBackground: Color.lerp(a.disabledButtonBackground, b.disabledButtonBackground, t)!,
      disabledButtonForeground: Color.lerp(a.disabledButtonForeground, b.disabledButtonForeground, t)!,
      searchBarButtonBackground: Color.lerp(a.searchBarButtonBackground, b.searchBarButtonBackground, t)!,
      searchBarButtonShadow: Color.lerp(a.searchBarButtonShadow, b.searchBarButtonShadow, t)!,
      viewBackButtonBackground: Color.lerp(a.viewBackButtonBackground, b.viewBackButtonBackground, t)!,
      viewBackButtonShadow: Color.lerp(a.viewBackButtonShadow, b.viewBackButtonShadow, t)!,
      money: Color.lerp(a.money, b.money, t)!,
      mapBackground: Color.lerp(a.mapBackground, b.mapBackground, t)!,
      ghost: Color.lerp(a.ghost, b.ghost, t)!,
      shimmerTextBase: Color.lerp(a.shimmerTextBase, b.shimmerTextBase, t)!,
      shimmerTextGlow: Color.lerp(a.shimmerTextGlow, b.shimmerTextGlow, t)!,
      skeleton: Color.lerp(a.skeleton, b.skeleton, t)!,
      skeletonShimmerGlow: Color.lerp(a.skeletonShimmerGlow, b.skeletonShimmerGlow, t)!,
    );
  }
}

class _LightQuiColors extends QuiColors {
  const _LightQuiColors({super.primary = const Color(0xFFFF4A4B)})
    : super(
        background: const Color(0xFFFFFFFF),
        surface: const Color(0xFFFFFFFF),
        textPrimary: const Color(0xFF1A1A1A),
        textSecondary: const Color(0xFF9A9A9A),
        description: const Color(0xFF9A9A9A),
        borderOnBackground: const Color(0xFFE6E6E6),
        placeholder: const Color(0xFF9E9E9E),
        disabledButtonBackground: const Color(0xFFE1E1E1),
        disabledButtonForeground: const Color(0xFF8E8E8E),
        searchBarButtonBackground: const Color(0xFFFAFAFA),
        searchBarButtonShadow: const Color(0x1A000000),
        viewBackButtonBackground: const Color(0xFFFAFAFA),
        viewBackButtonShadow: const Color(0x1A000000),
        money: const Color(0xFF00D757),
        mapBackground: const Color(0xFFEFEFEF),
        ghost: const Color(0xFFCDCDCD),
        shimmerTextBase: const Color(0xFFB3B3B3),
        shimmerTextGlow: const Color(0xFFE0E0E0),
        skeleton: const Color(0xFFEFEFEF),
        skeletonShimmerGlow: const Color(0xFFFAFAFA),
      );
}
