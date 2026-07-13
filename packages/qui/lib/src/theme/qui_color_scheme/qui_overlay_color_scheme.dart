part of 'qui_color_scheme.dart';

/// Overlay-specific roles that complement shared surface tokens.
///
/// Use this group for overlay chrome such as modal scrims when app UI needs
/// overlay behavior instead of a normal surface or background role.
@immutable
class QuiOverlayColorScheme {
  /// Creates overlay-specific roles that complement shared surface tokens.
  const QuiOverlayColorScheme({required this.scrim});

  /// {@macro qui_color_scheme_lerp}
  factory QuiOverlayColorScheme.lerp(QuiOverlayColorScheme a, QuiOverlayColorScheme b, double t) {
    return QuiOverlayColorScheme(scrim: Color.lerp(a.scrim, b.scrim, t)!);
  }

  /// Scrim color applied behind modal or elevated overlay content.
  final Color scrim;

  /// {@macro qui_color_scheme_copy_with}
  QuiOverlayColorScheme copyWith({Color? scrim}) {
    return QuiOverlayColorScheme(scrim: scrim ?? this.scrim);
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is QuiOverlayColorScheme && scrim == other.scrim;

  @override
  int get hashCode => scrim.hashCode;
}
