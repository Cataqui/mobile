part of 'qui_palette.dart';

/// An immutable 12-step primitive color scale in the QUI palette.
///
/// Steps run from 1, the lightest surface color, through 12, the darkest text
/// color. The scale itself is a [Color] whose channels match step 9, allowing
/// it to be passed directly to Flutter APIs that accept a solid color.
///
/// Access a token with its one-based step number:
///
/// ```dart
/// final palette = QuiPalette(primaryColor: const Color(0xFFFF4A4B));
/// final solid = palette.primary;
/// final subtleBackground = palette.primary[2];
/// final highContrastText = palette.primary[12];
/// ```
///
/// Invalid steps throw [RangeError] instead of resolving to a different token.
@immutable
final class QuiColorScale extends ColorSwatch<int> {
  factory QuiColorScale._({required List<Color> steps}) {
    if (steps.length != 12) {
      throw ArgumentError.value(steps.length, 'steps.length', 'must contain exactly 12 colors');
    }

    return QuiColorScale._immutable(List<Color>.unmodifiable(steps));
  }

  QuiColorScale._immutable(this.colors)
    : super(
        colors[8].toARGB32(),
        Map<int, Color>.unmodifiable(<int, Color>{for (var i = 0; i < 12; i++) i + 1: colors[i]}),
      );

  /// The colors in ascending step order from 1 through 12.
  ///
  /// The returned list is immutable.
  final List<Color> colors;

  /// The color assigned to [step].
  ///
  /// Valid steps are the integers from 1 through 12. A value outside that
  /// range throws [RangeError].
  @override
  Color operator [](int step) {
    if (step < 1 || step > 12) {
      throw RangeError.range(step, 1, 12, 'step');
    }

    return super[step]!;
  }

  /// Equality based on all 12 colors in this scale.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QuiColorScale) return false;
    return listEquals(colors, other.colors);
  }

  /// The hash code derived from all 12 colors in this scale.
  @override
  int get hashCode => Object.hashAll(colors);
}
