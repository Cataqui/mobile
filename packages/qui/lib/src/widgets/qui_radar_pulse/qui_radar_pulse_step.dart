part of 'qui_radar_pulse.dart';

/// A single pulse ring layer for [QuiRadarPulse].
///
/// Each instance defines the visual appearance of one expanding ring in the
/// pulse sequence. The number of rings equals the length of the [QuiRadarPulse.steps]
/// list. Rings are staggered in time so a ripple effect is always visible.
///
/// Any color left as `null` falls back to the current QUI primary color
/// with a translucent alpha that animates as the ring expands and fades.
///
/// ```dart
/// QuiRadarPulse(
///   steps: const [
///     QuiRadarPulseStep(
///       color: Color(0xFFFF4A4B),
///       borderRadius: BorderRadius.all(Radius.circular(24)),
///       alpha: 0.6,
///     ),
///     QuiRadarPulseStep(color: Color(0xFF00A896), alpha: 0.2),
///   ],
///   child: Icon(Icons.bolt_rounded, size: 48),
/// )
/// ```
@immutable
class QuiRadarPulseStep {
  /// Creates a pulse step.
  const QuiRadarPulseStep({this.color, this.borderRadius = const BorderRadius.all(Radius.circular(9999)), this.alpha})
    : assert(alpha == null || (alpha >= 0 && alpha <= 1), 'alpha must be between 0 and 1, but got $alpha.');

  /// Fill color for this pulse ring.
  ///
  /// When `null`, [QuiRadarPulse] uses the current `qui` primary color with a
  /// translucent alpha that animates as the ring expands and fades.
  final Color? color;

  /// Shape of this pulse ring.
  ///
  /// Defaults to a circle ([BorderRadius.circular] with a large radius).
  /// Pass `BorderRadius.zero` for a square ring or any intermediate value
  /// for a squircle.
  final BorderRadius borderRadius;

  /// Maximum alpha for this pulse ring, in the range `0`–`1`.
  ///
  /// When `null`, [QuiRadarPulse] uses a default base alpha of `0.35` and fades the
  /// ring toward `0` as it expands. When provided, the ring fades from
  /// [alpha] down to `0` as it expands.
  final double? alpha;
}
