library;

import 'package:flutter/material.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'qui_palette_color.dart';

/// The raw primitive color palette for the QUI design system.
///
/// Contains 12-step color scales for [primary], [neutral], [success],
/// [warning], [error], [info], and six accent colors ([cyan], [violet],
/// [teal], [orange], [pink], [yellow]).
///
/// The [primary] and [neutral] scales are **auto-derived** from the
/// `primaryColor` parameter using OKLCH color space generation. All other scales
/// are fixed values from the QUI palette specification.
///
/// This is a **primitive** palette — it has no dark/light mode and no
/// semantic token assignments. Build semantic color schemes on top of
/// these primitives.
///
/// ```dart
/// final palette = QuiPalette(primaryColor: Color(0xFFFF4A4B));
/// final brandRed = palette.primary[9];
/// final warmGray = palette.neutral[12];
/// ```
@immutable
class QuiPalette {
  /// Creates a QUI color palette generated from [primaryColor].
  ///
  /// The [primary] and [neutral] scales are derived from [primaryColor]
  /// using OKLCH color space generation. All other scales are fixed.
  factory QuiPalette({required Color primaryColor}) {
    final isDefault = primaryColor == _defaultBrandColor;
    final oklch = Oklch.fromColor(primaryColor);
    final hue = oklch.h;
    final chromaScale = (oklch.c / _primaryChroma[8]).clamp(0.0, 1.0);

    return QuiPalette._(
      primaryColor: primaryColor,
      primary: isDefault
          ? _defaultPrimaryScale
          : _generateScale(
              lightness: _primaryLightness,
              chroma: _primaryChroma.map((c) => c * chromaScale).toList(),
              hueDrift: _primaryHueDrift,
              baseHue: hue,
            ),
      neutral: isDefault
          ? _defaultNeutralScale
          : _generateScale(
              lightness: _neutralLightness,
              chroma: _neutralChroma,
              hueDrift: _neutralHueDrift,
              baseHue: hue,
            ),
      success: _successScale,
      warning: _warningScale,
      error: _errorScale,
      info: _infoScale,
      cyan: _cyanScale,
      violet: _violetScale,
      teal: _tealScale,
      orange: _orangeScale,
      pink: _pinkScale,
      yellow: _yellowScale,
    );
  }

  const QuiPalette._({
    required this._primaryColor,
    required this.primary,
    required this.neutral,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.cyan,
    required this.violet,
    required this.teal,
    required this.orange,
    required this.pink,
    required this.yellow,
  });

  final Color _primaryColor;

  // ---- Auto-derived scales ----

  /// The brand color scale, derived from the `primaryColor` parameter.
  ///
  /// Step 9 is the anchor — the "pure" brand color. The scale drifts warmer
  /// at the light end and cooler at the dark end.
  final QuiPaletteColor primary;

  /// The warm primary-tinted neutral scale, derived from the `primaryColor` parameter's hue.
  ///
  /// Very low chroma (0.003–0.015) — reads as a warm-alive gray, not pink.
  /// Replaces pure gray for subconscious cohesion with the brand color.
  final QuiPaletteColor neutral;

  // ---- Fixed scales ----

  /// Bright green — success states, confirmations, money/pay display.
  final QuiPaletteColor success;

  /// Amber — warning states, caution, attention-requiring UI.
  final QuiPaletteColor warning;

  /// Cooler dark red — error states, danger, destructive actions.
  final QuiPaletteColor error;

  /// Blue — informational states, links, non-critical notifications.
  final QuiPaletteColor info;

  /// Cyan accent — cool complement to the warm primary.
  final QuiPaletteColor cyan;

  /// Violet accent — creative, playful.
  final QuiPaletteColor violet;

  /// Teal accent — fresh, local-feeling, map and location contexts.
  final QuiPaletteColor teal;

  /// Orange accent — warm, marketing energy, secondary CTAs.
  final QuiPaletteColor orange;

  /// Pink accent — warm pink/rose, social media, playful UI.
  final QuiPaletteColor pink;

  /// Yellow accent — highlight badges, "new" tags, attention-grabbing.
  final QuiPaletteColor yellow;

  // ---- Equality ----

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QuiPalette) return false;
    return _primaryColor == other._primaryColor;
  }

  @override
  int get hashCode => _primaryColor.hashCode;

  // ---- Default brand color ----

  static const Color _defaultBrandColor = Color(0xFFFF4A4B);

  /// Exact primary scale for the default brand color (#FF4A4B).
  static final QuiPaletteColor _defaultPrimaryScale = QuiPaletteColor(
    steps: const [
      Color(0xFFFFFCFC),
      Color(0xFFFFF8F8),
      Color(0xFFFFEDEC),
      Color(0xFFFFE0E0),
      Color(0xFFFFD0D0),
      Color(0xFFFFC0C0),
      Color(0xFFF8A0A0),
      Color(0xFFF08080),
      Color(0xFFFF4A4B),
      Color(0xFFE83A3B),
      Color(0xFFC52D2E),
      Color(0xFF7A1C1D),
    ],
  );

  /// Exact neutral scale for the default brand color (#FF4A4B).
  static final QuiPaletteColor _defaultNeutralScale = QuiPaletteColor(
    steps: const [
      Color(0xFFFDFDFC),
      Color(0xFFF9F9F8),
      Color(0xFFF1F0EF),
      Color(0xFFE9E8E6),
      Color(0xFFE2E1DE),
      Color(0xFFDAD9D6),
      Color(0xFFCFCECA),
      Color(0xFFBCBBB5),
      Color(0xFF8D8D86),
      Color(0xFF82827C),
      Color(0xFF63635E),
      Color(0xFF21201C),
    ],
  );

  // ---- Fixed scale constants ----

  static final QuiPaletteColor _successScale = QuiPaletteColor(
    steps: const [
      Color(0xFFFBFEFC),
      Color(0xFFF4FBF6),
      Color(0xFFE6F6EB),
      Color(0xFFD6F1DF),
      Color(0xFFC4E8D1),
      Color(0xFFADDCC0),
      Color(0xFF8ECFAA),
      Color(0xFF5BB98B),
      Color(0xFF00D757),
      Color(0xFF00C04E),
      Color(0xFF00963D),
      Color(0xFF005226),
    ],
  );

  static final QuiPaletteColor _warningScale = QuiPaletteColor(
    steps: const [
      Color(0xFFFFFEFB),
      Color(0xFFFFFCF5),
      Color(0xFFFFF8E6),
      Color(0xFFFFF3D6),
      Color(0xFFFFECC4),
      Color(0xFFFFE3AD),
      Color(0xFFFFD68E),
      Color(0xFFFFC45B),
      Color(0xFFFFB224),
      Color(0xFFF0A300),
      Color(0xFF946800),
      Color(0xFF4D3500),
    ],
  );

  static final QuiPaletteColor _errorScale = QuiPaletteColor(
    steps: const [
      Color(0xFFFFFCFC),
      Color(0xFFFFF7F7),
      Color(0xFFFEEBEC),
      Color(0xFFFFDBDC),
      Color(0xFFFFCDCE),
      Color(0xFFFDBDBE),
      Color(0xFFF4A9AA),
      Color(0xFFEB8E90),
      Color(0xFFE5484D),
      Color(0xFFDC3E42),
      Color(0xFFCE2C31),
      Color(0xFF641723),
    ],
  );

  static final QuiPaletteColor _infoScale = QuiPaletteColor(
    steps: const [
      Color(0xFFFBFDFF),
      Color(0xFFF4FAFF),
      Color(0xFFE6F4FE),
      Color(0xFFD5EFFF),
      Color(0xFFC2E5FF),
      Color(0xFFACD8FC),
      Color(0xFF8EC8F6),
      Color(0xFF5EB1EF),
      Color(0xFF0090FF),
      Color(0xFF0588F0),
      Color(0xFF0D74CE),
      Color(0xFF113264),
    ],
  );

  static final QuiPaletteColor _cyanScale = QuiPaletteColor(
    steps: const [
      Color(0xFFFAFDFE),
      Color(0xFFF2FAFB),
      Color(0xFFDEF7F9),
      Color(0xFFCAF1F6),
      Color(0xFFB5E9F0),
      Color(0xFF9DDDE7),
      Color(0xFF7DCEDC),
      Color(0xFF3DB9CF),
      Color(0xFF00A2C7),
      Color(0xFF0797B9),
      Color(0xFF107D98),
      Color(0xFF0D3C48),
    ],
  );

  static final QuiPaletteColor _violetScale = QuiPaletteColor(
    steps: const [
      Color(0xFFFDFCFE),
      Color(0xFFFAF8FF),
      Color(0xFFF4F0FE),
      Color(0xFFEBE4FF),
      Color(0xFFE1D9FF),
      Color(0xFFD4CAFE),
      Color(0xFFC2B5F5),
      Color(0xFFAA99EC),
      Color(0xFF6E56CF),
      Color(0xFF654DC4),
      Color(0xFF6550B9),
      Color(0xFF2F265F),
    ],
  );

  static final QuiPaletteColor _tealScale = QuiPaletteColor(
    steps: const [
      Color(0xFFFAFEFD),
      Color(0xFFF3FBF9),
      Color(0xFFE0F8F3),
      Color(0xFFCCF3EA),
      Color(0xFFB8EAE0),
      Color(0xFFA1DED2),
      Color(0xFF83CDC1),
      Color(0xFF53B9AB),
      Color(0xFF12A594),
      Color(0xFF0D9B8A),
      Color(0xFF008573),
      Color(0xFF0D3D38),
    ],
  );

  static final QuiPaletteColor _orangeScale = QuiPaletteColor(
    steps: const [
      Color(0xFFFFFEFC),
      Color(0xFFFFFCF8),
      Color(0xFFFFF8EE),
      Color(0xFFFFF3E0),
      Color(0xFFFFECD0),
      Color(0xFFFFE3BD),
      Color(0xFFFFD6A0),
      Color(0xFFFFC47A),
      Color(0xFFF76B15),
      Color(0xFFE85E0A),
      Color(0xFFB84A00),
      Color(0xFF5C2500),
    ],
  );

  static final QuiPaletteColor _pinkScale = QuiPaletteColor(
    steps: const [
      Color(0xFFFFFCFE),
      Color(0xFFFEF7FB),
      Color(0xFFFEE9F5),
      Color(0xFFFBDCEF),
      Color(0xFFF6CEE7),
      Color(0xFFEFBFDD),
      Color(0xFFE7ACD0),
      Color(0xFFDD93C2),
      Color(0xFFD6409F),
      Color(0xFFCF3897),
      Color(0xFFC2298A),
      Color(0xFF651249),
    ],
  );

  static final QuiPaletteColor _yellowScale = QuiPaletteColor(
    steps: const [
      Color(0xFFFEFEF5),
      Color(0xFFFDFCF0),
      Color(0xFFFAF8E6),
      Color(0xFFF6F3D6),
      Color(0xFFF0ECC4),
      Color(0xFFE9E3AD),
      Color(0xFFDFD88E),
      Color(0xFFD1C75B),
      Color(0xFFE0C500),
      Color(0xFFC9B000),
      Color(0xFF8C7A00),
      Color(0xFF4A4100),
    ],
  );

  // ---- Template curves for scale generation ----

  static const List<double> _primaryLightness = [
    0.99,
    0.97,
    0.94,
    0.91,
    0.88,
    0.85,
    0.81,
    0.73,
    0.65,
    0.60,
    0.45,
    0.25,
  ];

  static const List<double> _primaryChroma = [0.005, 0.01, 0.02, 0.04, 0.07, 0.11, 0.16, 0.21, 0.23, 0.22, 0.20, 0.12];

  /// Hue drift offsets (degrees) — warmer at light end, cooler at dark end.
  static const List<double> _primaryHueDrift = [2, 2, 1, 1, 0, 0, 0, 0, 0, -1, -2, -3];

  static const List<double> _neutralLightness = [
    0.99,
    0.975,
    0.94,
    0.91,
    0.88,
    0.85,
    0.81,
    0.73,
    0.55,
    0.51,
    0.39,
    0.21,
  ];

  static const List<double> _neutralChroma = [
    0.003,
    0.005,
    0.008,
    0.01,
    0.012,
    0.015,
    0.015,
    0.012,
    0.012,
    0.012,
    0.012,
    0.012,
  ];

  /// Neutral has no hue drift — all steps use the base hue.
  static const List<double> _neutralHueDrift = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  // ---- Scale generation ----

  /// Generates a 12-step [QuiPaletteColor] from template curves and a base hue.
  static QuiPaletteColor _generateScale({
    required List<double> lightness,
    required List<double> chroma,
    required List<double> hueDrift,
    required double baseHue,
  }) {
    final colors = <Color>[];

    for (var i = 0; i < 12; i++) {
      final h = (baseHue + hueDrift[i] + 360) % 360;
      colors.add(Oklch.toColor(lightness[i], chroma[i], h));
    }

    return QuiPaletteColor(steps: colors);
  }
}
