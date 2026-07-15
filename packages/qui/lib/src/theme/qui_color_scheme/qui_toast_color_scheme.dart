part of 'qui_color_scheme.dart';

/// Toast-specific roles for transient messaging surfaces.
///
/// Toasts combine a shared container treatment with status accents. This group
/// keeps those roles together so transient messaging can stay consistent
/// without borrowing unrelated status or button tokens directly.
@immutable
class QuiToastColorScheme {
  /// Creates toast-specific roles for transient messaging surfaces.
  const QuiToastColorScheme({
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.neutral,
  });

  /// {@macro qui_color_scheme_lerp}
  factory QuiToastColorScheme.lerp(QuiToastColorScheme a, QuiToastColorScheme b, double t) {
    return QuiToastColorScheme(
      success: QuiToastVariantColorScheme.lerp(a.success, b.success, t),
      error: QuiToastVariantColorScheme.lerp(a.error, b.error, t),
      warning: QuiToastVariantColorScheme.lerp(a.warning, b.warning, t),
      info: QuiToastVariantColorScheme.lerp(a.info, b.info, t),
      neutral: QuiToastVariantColorScheme.lerp(a.neutral, b.neutral, t),
    );
  }

  /// Color roles for success toasts (positive confirmation, task complete).
  final QuiToastVariantColorScheme success;

  /// Color roles for error toasts (failure, destructive action).
  final QuiToastVariantColorScheme error;

  /// Color roles for warning toasts (caution, attention needed).
  final QuiToastVariantColorScheme warning;

  /// Color roles for informational toasts (neutral status, tips).
  final QuiToastVariantColorScheme info;

  /// Color roles for neutral toasts (non-status, general messaging).
  final QuiToastVariantColorScheme neutral;

  /// {@macro qui_color_scheme_copy_with}
  QuiToastColorScheme copyWith({
    QuiToastVariantColorScheme? success,
    QuiToastVariantColorScheme? error,
    QuiToastVariantColorScheme? warning,
    QuiToastVariantColorScheme? info,
    QuiToastVariantColorScheme? neutral,
  }) {
    return QuiToastColorScheme(
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiToastColorScheme &&
          success == other.success &&
          error == other.error &&
          warning == other.warning &&
          info == other.info &&
          neutral == other.neutral;

  @override
  int get hashCode => Object.hashAll([success, error, warning, info, neutral]);
}

/// A set of colors for a single toast variant role.
@immutable
class QuiToastVariantColorScheme {
  /// Creates a toast variant with all color roles.
  const QuiToastVariantColorScheme({required this.background, required this.foreground, required this.icon});

  /// {@macro qui_color_scheme_lerp}
  factory QuiToastVariantColorScheme.lerp(QuiToastVariantColorScheme a, QuiToastVariantColorScheme b, double t) {
    return QuiToastVariantColorScheme(
      background: Color.lerp(a.background, b.background, t)!,
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      icon: Color.lerp(a.icon, b.icon, t)!,
    );
  }

  /// Surface color for this toast variant's background.
  final Color background;

  /// Text color for this toast variant's message text.
  final Color foreground;

  /// Icon tint color for this toast variant's icon.
  final Color icon;

  /// {@macro qui_color_scheme_copy_with}
  QuiToastVariantColorScheme copyWith({Color? background, Color? foreground, Color? icon}) {
    return QuiToastVariantColorScheme(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      icon: icon ?? this.icon,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiToastVariantColorScheme &&
          background == other.background &&
          foreground == other.foreground &&
          icon == other.icon;

  @override
  int get hashCode => Object.hashAll([background, foreground, icon]);
}
