part of 'qui_color_scheme.dart';

@immutable
class QuiTextColorScheme {
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

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color placeholder;
  final Color disabled;
  final Color inverse;
  final Color brandPrimary;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color profit;

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

  static QuiTextColorScheme lerp(QuiTextColorScheme a, QuiTextColorScheme b, double t) {
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
}
