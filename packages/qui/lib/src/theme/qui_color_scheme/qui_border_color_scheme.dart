part of 'qui_color_scheme.dart';

/// Border and outline roles for standard QUI surfaces.
///
/// Use this group when a UI element needs boundary treatment instead of text or
/// fill treatment. The properties distinguish normal, subtle, disabled, focus,
/// validation, and floating-surface cases so app code can choose the intended
/// border role directly.
@immutable
class QuiBorderColorScheme {
  /// Creates border roles for standard QUI surfaces.
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

  /// {@macro qui_color_scheme_lerp}
  factory QuiBorderColorScheme.lerp(QuiBorderColorScheme a, QuiBorderColorScheme b, double t) {
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

  /// Default boundary color for standard interactive and structural surfaces.
  final Color standard;

  /// Reduced-emphasis boundary color for separators and quiet structure.
  final Color subtle;

  /// Boundary color used while a pointer-hover interaction is active.
  final Color hover;

  /// Boundary color for disabled elements that should read as non-interactive.
  final Color disabled;

  /// Boundary color used to communicate focus visibility.
  final Color focus;

  /// Boundary color used for error validation and destructive feedback.
  final Color error;

  /// Boundary color used for success validation and positive feedback.
  final Color success;

  /// Boundary color that remains visible on variable or floating backgrounds.
  final Color translucent;

  /// {@macro qui_color_scheme_copy_with}
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
}
