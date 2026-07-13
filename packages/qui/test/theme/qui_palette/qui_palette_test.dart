import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiPalette', () {
    const brandColor = Color(0xFFFF4A4B);
    final palette = QuiPalette(primaryColor: brandColor);
    final expectedScales = <String, (QuiColorScale, List<Color>)>{
      'primary': (
        palette.primary,
        const <Color>[
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
      ),
      'neutral': (
        palette.neutral,
        const <Color>[
          Color(0xFFFDFBFB),
          Color(0xFFF7F4F4),
          Color(0xFFEEEAE9),
          Color(0xFFE5E0DF),
          Color(0xFFDCD6D5),
          Color(0xFFD3CCCB),
          Color(0xFFC6BFBE),
          Color(0xFF969190),
          Color(0xFF757070),
          Color(0xFF676261),
          Color(0xFF433F3E),
          Color(0xFF1B1717),
        ],
      ),
      'success': (
        palette.green,
        const <Color>[
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
      ),
      'warning': (
        palette.amber,
        const <Color>[
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
      ),
      'error': (
        palette.red,
        const <Color>[
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
      ),
      'info': (
        palette.blue,
        const <Color>[
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
      ),
      'whatsapp': (
        palette.whatsapp,
        const <Color>[
          Color(0xFFF9FDFA),
          Color(0xFFF4FAF5),
          Color(0xFFECF7ED),
          Color(0xFFE2F3E5),
          Color(0xFFD6F2DA),
          Color(0xFFC9F0CE),
          Color(0xFFB5EFBE),
          Color(0xFF7FDE92),
          Color(0xFF25D366),
          Color(0xFF01B950),
          Color(0xFF126E2A),
          Color(0xFF002002),
        ],
      ),
      'cyan': (
        palette.cyan,
        const <Color>[
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
      ),
      'violet': (
        palette.violet,
        const <Color>[
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
      ),
      'teal': (
        palette.teal,
        const <Color>[
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
      ),
      'orange': (
        palette.orange,
        const <Color>[
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
      ),
      'pink': (
        palette.pink,
        const <Color>[
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
      ),
      'yellow': (
        palette.yellow,
        const <Color>[
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
      ),
    };

    for (final MapEntry(key: scaleName, value: (scale, expectedColors)) in expectedScales.entries) {
      for (var index = 0; index < expectedColors.length; index++) {
        final step = index + 1;
        test('when reading $scaleName step $step, it should match the decided QUI palette value', () {
          expect(scale[step], expectedColors[index]);
        });
      }
    }

    test('when using a custom primary color, it should preserve that exact color at step 9', () {
      final customPalette = QuiPalette(primaryColor: const Color(0xFF0090FF));
      expect(customPalette.primary[9], const Color(0xFF0090FF));
    });

    test('when using a blue primary color, it should derive blue surrounding primary steps', () {
      final customPalette = QuiPalette(primaryColor: const Color(0xFF0090FF));
      expect(customPalette.primary[8].b, greaterThan(customPalette.primary[8].r));
    });

    test('when using a blue primary color, it should tint the neutral scale toward blue', () {
      final customPalette = QuiPalette(primaryColor: const Color(0xFF0090FF));
      expect(customPalette.neutral[12].b, greaterThan(palette.neutral[12].b));
    });

    test('when using a transparent primary color, it should reject the non-primitive color', () {
      expect(() => QuiPalette(primaryColor: const Color(0x80FF4A4B)), throwsArgumentError);
    });

    test('when two palettes use the same primary color, they should be equal', () {
      final other = QuiPalette(primaryColor: brandColor);
      expect(palette, other);
    });

    test('when the default palette is requested repeatedly, it should reuse the precomputed instance', () {
      final other = QuiPalette(primaryColor: brandColor);
      expect(identical(palette, other), isTrue);
    });

    test('when two palettes use different primary colors, they should not be equal', () {
      final other = QuiPalette(primaryColor: const Color(0xFF0090FF));
      expect(palette, isNot(other));
    });

    test('when two palettes are equal, they should have equal hash codes', () {
      final other = QuiPalette(primaryColor: brandColor);
      expect(palette.hashCode, other.hashCode);
    });
  });
}
