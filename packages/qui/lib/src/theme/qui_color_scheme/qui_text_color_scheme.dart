part of 'qui_color_scheme.dart';

/// Semantic text roles shared across QUI surfaces and states.
///
/// Read this group whenever app UI needs a text or icon color that depends on
/// message meaning, emphasis, or background relationship rather than on a
/// specific component pattern.
@immutable
class QuiTextColorScheme {
  /// Creates semantic text roles shared across QUI surfaces and states.
  const QuiTextColorScheme({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.placeholder,
    required this.disabled,
    required this.inverse,
    required this.brandPrimary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.profit,
  });

  /// {@macro qui_color_scheme_lerp}
  factory QuiTextColorScheme.lerp(QuiTextColorScheme a, QuiTextColorScheme b, double t) {
    return QuiTextColorScheme(
      primary: Color.lerp(a.primary, b.primary, t)!,
      secondary: Color.lerp(a.secondary, b.secondary, t)!,
      tertiary: Color.lerp(a.tertiary, b.tertiary, t)!,
      placeholder: Color.lerp(a.placeholder, b.placeholder, t)!,
      disabled: Color.lerp(a.disabled, b.disabled, t)!,
      inverse: Color.lerp(a.inverse, b.inverse, t)!,
      brandPrimary: Color.lerp(a.brandPrimary, b.brandPrimary, t)!,
      success: Color.lerp(a.success, b.success, t)!,
      warning: Color.lerp(a.warning, b.warning, t)!,
      error: Color.lerp(a.error, b.error, t)!,
      info: Color.lerp(a.info, b.info, t)!,
      profit: Color.lerp(a.profit, b.profit, t)!,
    );
  }

  /// Primary readable text color for standard content.
  final Color primary;

  /// Secondary readable text color for supporting content.
  final Color secondary;

  /// Tertiary readable text color for lower-emphasis metadata.
  final Color tertiary;

  /// Placeholder text color for inputs and similar affordances.
  final Color placeholder;

  /// Text color for disabled or unavailable content.
  final Color disabled;

  /// Readable text color for inverse or dark-emphasis surfaces.
  final Color inverse;

  /// Brand-primary text color for places that intentionally use the app brand slot.
  final Color brandPrimary;

  /// Text color for positive or successful messaging.
  final Color success;

  /// Text color for cautionary or warning messaging.
  final Color warning;

  /// Text color for destructive or error messaging.
  final Color error;

  /// Text color for informational messaging.
  final Color info;

  /// Text color used for profit, earnings, or gain-related emphasis.
  final Color profit;

  /// {@macro qui_color_scheme_copy_with}
  QuiTextColorScheme copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? placeholder,
    Color? disabled,
    Color? inverse,
    Color? brandPrimary,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? profit,
  }) {
    return QuiTextColorScheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      placeholder: placeholder ?? this.placeholder,
      disabled: disabled ?? this.disabled,
      inverse: inverse ?? this.inverse,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      profit: profit ?? this.profit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiTextColorScheme &&
          primary == other.primary &&
          secondary == other.secondary &&
          tertiary == other.tertiary &&
          placeholder == other.placeholder &&
          disabled == other.disabled &&
          inverse == other.inverse &&
          brandPrimary == other.brandPrimary &&
          success == other.success &&
          warning == other.warning &&
          error == other.error &&
          info == other.info &&
          profit == other.profit;

  @override
  int get hashCode => Object.hashAll([
    primary,
    secondary,
    tertiary,
    placeholder,
    disabled,
    inverse,
    brandPrimary,
    success,
    warning,
    error,
    info,
    profit,
  ]);
}
