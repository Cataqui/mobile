library;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'qui_color_scale.dart';

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
  /// using OKLCH color space generation. The color must be fully opaque, and
  /// it is preserved exactly at primary step 9. All other scales are fixed.
  ///
  /// Throws [ArgumentError] when [primaryColor] is not fully opaque.
  factory QuiPalette({required Color primaryColor}) {
    if (primaryColor.a != 1) throw ArgumentError.value(primaryColor, 'primaryColor', 'must be fully opaque');

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
              anchor: primaryColor,
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

  static const Color _defaultBrandColor = Color(0xFFFF4A4B);

  static final QuiColorScale _defaultPrimaryScale = QuiColorScale._(
    steps: const [
      Color(0xFFFFFBFB),
      Color(0xFFFDF5F3),
      Color(0xFFFCEBE9),
      Color(0xFFFBE2DF),
      Color(0xFFFFD6D2),
      Color(0xFFFFCAC4),
      Color(0xFFFFB9B1),
      Color(0xFFFF847C),
      Color(0xFFFF4A4B),
      Color(0xFFE2363B),
      Color(0xFF8C2127),
      Color(0xFF330407),
    ],
  );

  static final QuiColorScale _defaultNeutralScale = QuiColorScale._(
    steps: const [
      Color(0xFFFEFBFA),
      Color(0xFFF8F4F3),
      Color(0xFFF0E9E8),
      Color(0xFFE8DFDD),
      Color(0xFFDFD5D3),
      Color(0xFFD7CAC8),
      Color(0xFFCABDBB),
      Color(0xFF99908E),
      Color(0xFF786F6E),
      Color(0xFF6A615F),
      Color(0xFF463D3C),
      Color(0xFF1E1615),
    ],
  );

  static final QuiColorScale _successScale = QuiColorScale._(
    steps: const [
      Color(0xFFFAFDFA),
      Color(0xFFF4FAF5),
      Color(0xFFEBF7EC),
      Color(0xFFE2F4E4),
      Color(0xFFD5F3D7),
      Color(0xFFC7F1CB),
      Color(0xFFB2F0BA),
      Color(0xFF78E08A),
      Color(0xFF00D757),
      Color(0xFF00BB41),
      Color(0xFF006F20),
      Color(0xFF002100),
    ],
  );

  static final QuiColorScale _warningScale = QuiColorScale._(
    steps: const [
      Color(0xFFFDFBF9),
      Color(0xFFFCF9F4),
      Color(0xFFFBF4EB),
      Color(0xFFFAF0E2),
      Color(0xFFFCEBD4),
      Color(0xFFFDE6C5),
      Color(0xFFFFDFB0),
      Color(0xFFFCC778),
      Color(0xFFFFB224),
      Color(0xFFDE9700),
      Color(0xFF865700),
      Color(0xFF281300),
    ],
  );

  static final QuiColorScale _errorScale = QuiColorScale._(
    steps: const [
      Color(0xFFFFFBFB),
      Color(0xFFFCF4F3),
      Color(0xFFF9EAE8),
      Color(0xFFF6E0DE),
      Color(0xFFF9D3D1),
      Color(0xFFFAC7C4),
      Color(0xFFFDB6B1),
      Color(0xFFEC7F7B),
      Color(0xFFE5484D),
      Color(0xFFCC373E),
      Color(0xFF80232A),
      Color(0xFF31070B),
    ],
  );

  static final QuiColorScale _infoScale = QuiColorScale._(
    steps: const [
      Color(0xFFFAFCFF),
      Color(0xFFF3F7FC),
      Color(0xFFE7F0FA),
      Color(0xFFDCE9F8),
      Color(0xFFCCE2FB),
      Color(0xFFBCDCFE),
      Color(0xFFA6D2FF),
      Color(0xFF66ADFB),
      Color(0xFF0090FF),
      Color(0xFF007CE4),
      Color(0xFF004E8D),
      Color(0xFF001935),
    ],
  );

  static final QuiColorScale _cyanScale = QuiColorScale._(
    steps: const [
      Color(0xFFFAFCFD),
      Color(0xFFF3F8F9),
      Color(0xFFE8F1F4),
      Color(0xFFDDEAF0),
      Color(0xFFCEE5ED),
      Color(0xFFC0DFEB),
      Color(0xFFAAD8E8),
      Color(0xFF6BB8D2),
      Color(0xFF00A2C7),
      Color(0xFF008DAF),
      Color(0xFF00576B),
      Color(0xFF001D25),
    ],
  );

  static final QuiColorScale _violetScale = QuiColorScale._(
    steps: const [
      Color(0xFFFCFBFE),
      Color(0xFFF5F4FA),
      Color(0xFFEAE9F5),
      Color(0xFFE0DFF0),
      Color(0xFFD5D3F0),
      Color(0xFFCAC8EF),
      Color(0xFFBDB8F0),
      Color(0xFF8D83D8),
      Color(0xFF6E56CF),
      Color(0xFF6149BB),
      Color(0xFF3C3178),
      Color(0xFF161233),
    ],
  );

  static final QuiColorScale _tealScale = QuiColorScale._(
    steps: const [
      Color(0xFFFAFCFC),
      Color(0xFFF3F8F7),
      Color(0xFFE8F1EF),
      Color(0xFFDDEBE8),
      Color(0xFFCFE5E1),
      Color(0xFFC0E0D9),
      Color(0xFFABD9D0),
      Color(0xFF6DBAAD),
      Color(0xFF12A594),
      Color(0xFF009080),
      Color(0xFF04594E),
      Color(0xFF001E19),
    ],
  );

  static final QuiColorScale _orangeScale = QuiColorScale._(
    steps: const [
      Color(0xFFFEFBF9),
      Color(0xFFFCF6F3),
      Color(0xFFFBEDE7),
      Color(0xFFF9E5DC),
      Color(0xFFFCDBCD),
      Color(0xFFFED1BD),
      Color(0xFFFFC3A7),
      Color(0xFFF89669),
      Color(0xFFF76B15),
      Color(0xFFDB5700),
      Color(0xFF873407),
      Color(0xFF300A00),
    ],
  );

  static final QuiColorScale _pinkScale = QuiColorScale._(
    steps: const [
      Color(0xFFFEFBFC),
      Color(0xFFFBF4F7),
      Color(0xFFF8E9F0),
      Color(0xFFF4DEE9),
      Color(0xFFF4D2E3),
      Color(0xFFF5C5DD),
      Color(0xFFF6B2D6),
      Color(0xFFE07AB4),
      Color(0xFFD6409F),
      Color(0xFFBE308C),
      Color(0xFF76205A),
      Color(0xFF2D0621),
    ],
  );

  static final QuiColorScale _yellowScale = QuiColorScale._(
    steps: const [
      Color(0xFFFCFCF9),
      Color(0xFFFAF9F4),
      Color(0xFFF7F6EB),
      Color(0xFFF5F2E2),
      Color(0xFFF3EFD3),
      Color(0xFFF2EBC4),
      Color(0xFFF1E7AE),
      Color(0xFFE5D474),
      Color(0xFFE0C500),
      Color(0xFFC2A800),
      Color(0xFF746200),
      Color(0xFF201700),
    ],
  );

  static const List<double> _primaryLightness = [
    0.99,
    0.975,
    0.954,
    0.932,
    0.91,
    0.888,
    0.859,
    0.75,
    0.67,
    0.602,
    0.426,
    0.21,
  ];

  static const List<double> _primaryChroma = [
    0.005,
    0.009,
    0.019,
    0.028,
    0.047,
    0.066,
    0.095,
    0.151,
    0.217,
    0.208,
    0.142,
    0.076,
  ];

  static const List<double> _primaryHueDrift = [2, 2, 1, 1, 0, 0, 0, 0, 0, 0, -2, -3];

  static const List<double> _neutralLightness = [
    0.99,
    0.97,
    0.94,
    0.91,
    0.88,
    0.85,
    0.81,
    0.66,
    0.55,
    0.50,
    0.37,
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

  static const List<double> _neutralHueDrift = [2, 2, 1, 1, 0, 0, 0, 0, 0, 0, -2, -3];

  static QuiColorScale _generateScale({
    required List<double> lightness,
    required List<double> chroma,
    required List<double> hueDrift,
    required double baseHue,
    Color? anchor,
  }) {
    final colors = <Color>[];

    for (var i = 0; i < 12; i++) {
      if (i == 8 && anchor != null) {
        colors.add(anchor);
        continue;
      }

      final h = (baseHue + hueDrift[i] + 360) % 360;
      colors.add(Oklch.toColor(lightness[i], chroma[i], h));
    }

    return QuiColorScale._(steps: colors);
  }

  /// The brand color scale derived from the palette's primary color.
  ///
  /// Step 9 is exactly the supplied primary color. The surrounding steps use
  /// its OKLCH hue and chroma while following the QUI lightness curve.
  final QuiColorScale primary;

  /// The warm neutral scale tinted toward the palette's primary hue.
  ///
  /// Its low chroma keeps the scale visually neutral while maintaining
  /// cohesion with [primary].
  final QuiColorScale neutral;

  /// The green scale for positive and successful states.
  final QuiColorScale success;

  /// The amber scale for warnings and cautionary states.
  final QuiColorScale warning;

  /// The red scale for errors, danger, and destructive states.
  final QuiColorScale error;

  /// The blue scale for informational states and links.
  final QuiColorScale info;

  /// The cyan accent scale.
  final QuiColorScale cyan;

  /// The violet accent scale.
  final QuiColorScale violet;

  /// The teal accent scale.
  final QuiColorScale teal;

  /// The orange accent scale.
  final QuiColorScale orange;

  /// The pink accent scale.
  final QuiColorScale pink;

  /// The yellow accent scale.
  final QuiColorScale yellow;

  /// Equality based on the primary color that defines this palette.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QuiPalette) return false;
    return _primaryColor == other._primaryColor;
  }

  /// The hash code derived from the primary color that defines this palette.
  @override
  int get hashCode => _primaryColor.hashCode;
}
