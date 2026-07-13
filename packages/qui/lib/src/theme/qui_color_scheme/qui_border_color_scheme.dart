part of 'qui_color_scheme.dart';

@immutable
class QuiBorderColorScheme {
  const QuiBorderColorScheme({
    required this.standard,
    required this.subtle,
    required this.hover,
    required this.disabled,
    required this.focus,
    required this.error,
    required this.success,
    required this.translucent,
  });

  final Color standard;
  final Color subtle;
  final Color hover;
  final Color disabled;
  final Color focus;
  final Color error;
  final Color success;
  final Color translucent;

  QuiBorderColorScheme copyWith({
    Color? standard,
    Color? subtle,
    Color? hover,
    Color? disabled,
    Color? focus,
    Color? error,
    Color? success,
    Color? translucent,
  }) {
    return QuiBorderColorScheme(
      standard: standard ?? this.standard,
      subtle: subtle ?? this.subtle,
      hover: hover ?? this.hover,
      disabled: disabled ?? this.disabled,
      focus: focus ?? this.focus,
      error: error ?? this.error,
      success: success ?? this.success,
      translucent: translucent ?? this.translucent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiBorderColorScheme &&
          standard == other.standard &&
          subtle == other.subtle &&
          hover == other.hover &&
          disabled == other.disabled &&
          focus == other.focus &&
          error == other.error &&
          success == other.success &&
          translucent == other.translucent;

  @override
  int get hashCode => Object.hash(standard, subtle, hover, disabled, focus, error, success, translucent);

  static QuiBorderColorScheme lerp(QuiBorderColorScheme a, QuiBorderColorScheme b, double t) {
    return QuiBorderColorScheme(
      standard: Color.lerp(a.standard, b.standard, t)!,
      subtle: Color.lerp(a.subtle, b.subtle, t)!,
      hover: Color.lerp(a.hover, b.hover, t)!,
      disabled: Color.lerp(a.disabled, b.disabled, t)!,
      focus: Color.lerp(a.focus, b.focus, t)!,
      error: Color.lerp(a.error, b.error, t)!,
      success: Color.lerp(a.success, b.success, t)!,
      translucent: Color.lerp(a.translucent, b.translucent, t)!,
    );
  }
}
