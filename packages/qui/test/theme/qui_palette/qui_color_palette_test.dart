import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiPalette', () {
    const brandColor = Color(0xFFFF4A4B);
    final palette = QuiPalette(primaryColor: brandColor);

    // ----------------------------------------------------------------
    // Primary scale — default brand color (exact hex match)
    // ----------------------------------------------------------------
    group('primary scale with default brand color', () {
      test('when using the default brand color, step 1 should be #FFFCFC', () {
        expect(palette.primary[1], const Color(0xFFFFFCFC));
      });

      test('when using the default brand color, step 2 should be #FFF8F8', () {
        expect(palette.primary[2], const Color(0xFFFFF8F8));
      });

      test('when using the default brand color, step 3 should be #FFEDEC', () {
        expect(palette.primary[3], const Color(0xFFFFEDEC));
      });

      test('when using the default brand color, step 4 should be #FFE0E0', () {
        expect(palette.primary[4], const Color(0xFFFFE0E0));
      });

      test('when using the default brand color, step 5 should be #FFD0D0', () {
        expect(palette.primary[5], const Color(0xFFFFD0D0));
      });

      test('when using the default brand color, step 6 should be #FFC0C0', () {
        expect(palette.primary[6], const Color(0xFFFFC0C0));
      });

      test('when using the default brand color, step 7 should be #F8A0A0', () {
        expect(palette.primary[7], const Color(0xFFF8A0A0));
      });

      test('when using the default brand color, step 8 should be #F08080', () {
        expect(palette.primary[8], const Color(0xFFF08080));
      });

      test('when using the default brand color, step 9 should be #FF4A4B', () {
        expect(palette.primary[9], const Color(0xFFFF4A4B));
      });

      test('when using the default brand color, step 10 should be #E83A3B', () {
        expect(palette.primary[10], const Color(0xFFE83A3B));
      });

      test('when using the default brand color, step 11 should be #C52D2E', () {
        expect(palette.primary[11], const Color(0xFFC52D2E));
      });

      test('when using the default brand color, step 12 should be #7A1C1D', () {
        expect(palette.primary[12], const Color(0xFF7A1C1D));
      });
    });

    // ----------------------------------------------------------------
    // Neutral scale — default brand color (exact hex match)
    // ----------------------------------------------------------------
    group('neutral scale with default brand color', () {
      test('when using the default brand color, step 1 should be #FDFDFC', () {
        expect(palette.neutral[1], const Color(0xFFFDFDFC));
      });

      test('when using the default brand color, step 2 should be #F9F9F8', () {
        expect(palette.neutral[2], const Color(0xFFF9F9F8));
      });

      test('when using the default brand color, step 3 should be #F1F0EF', () {
        expect(palette.neutral[3], const Color(0xFFF1F0EF));
      });

      test('when using the default brand color, step 4 should be #E9E8E6', () {
        expect(palette.neutral[4], const Color(0xFFE9E8E6));
      });

      test('when using the default brand color, step 5 should be #E2E1DE', () {
        expect(palette.neutral[5], const Color(0xFFE2E1DE));
      });

      test('when using the default brand color, step 6 should be #DAD9D6', () {
        expect(palette.neutral[6], const Color(0xFFDAD9D6));
      });

      test('when using the default brand color, step 7 should be #CFCECA', () {
        expect(palette.neutral[7], const Color(0xFFCFCECA));
      });

      test('when using the default brand color, step 8 should be #BCBBB5', () {
        expect(palette.neutral[8], const Color(0xFFBCBBB5));
      });

      test('when using the default brand color, step 9 should be #8D8D86', () {
        expect(palette.neutral[9], const Color(0xFF8D8D86));
      });

      test('when using the default brand color, step 10 should be #82827C', () {
        expect(palette.neutral[10], const Color(0xFF82827C));
      });

      test('when using the default brand color, step 11 should be #63635E', () {
        expect(palette.neutral[11], const Color(0xFF63635E));
      });

      test('when using the default brand color, step 12 should be #21201C', () {
        expect(palette.neutral[12], const Color(0xFF21201C));
      });
    });

    // ----------------------------------------------------------------
    // Fixed scales — step 9 (anchor) exact match
    // ----------------------------------------------------------------
    group('fixed scales', () {
      test('when accessing pink directly, it should return step 9', () {
        expect(palette.pink.toARGB32(), palette.pink[9].toARGB32());
      });

      test('when accessing success directly, it should return step 9', () {
        expect(palette.success.toARGB32(), palette.success[9].toARGB32());
      });

      test('when accessing warning directly, it should return step 9', () {
        expect(palette.warning.toARGB32(), palette.warning[9].toARGB32());
      });

      test('when accessing error directly, it should return step 9', () {
        expect(palette.error.toARGB32(), palette.error[9].toARGB32());
      });

      test('when accessing info directly, it should return step 9', () {
        expect(palette.info.toARGB32(), palette.info[9].toARGB32());
      });

      test('when accessing cyan directly, it should return step 9', () {
        expect(palette.cyan.toARGB32(), palette.cyan[9].toARGB32());
      });

      test('when accessing violet directly, it should return step 9', () {
        expect(palette.violet.toARGB32(), palette.violet[9].toARGB32());
      });

      test('when accessing teal directly, it should return step 9', () {
        expect(palette.teal.toARGB32(), palette.teal[9].toARGB32());
      });

      test('when accessing orange directly, it should return step 9', () {
        expect(palette.orange.toARGB32(), palette.orange[9].toARGB32());
      });

      test('when accessing yellow directly, it should return step 9', () {
        expect(palette.yellow.toARGB32(), palette.yellow[9].toARGB32());
      });

      test('when accessing primary directly, it should return step 9', () {
        expect(palette.primary.toARGB32(), palette.primary[9].toARGB32());
      });

      test('when accessing neutral directly, it should return step 9', () {
        expect(palette.neutral.toARGB32(), palette.neutral[9].toARGB32());
      });

      test('when creating the palette, success step 9 should be #00D757', () {
        expect(palette.success[9], const Color(0xFF00D757));
      });

      test('when creating the palette, warning step 9 should be #FFB224', () {
        expect(palette.warning[9], const Color(0xFFFFB224));
      });

      test('when creating the palette, error step 9 should be #E5484D', () {
        expect(palette.error[9], const Color(0xFFE5484D));
      });

      test('when creating the palette, info step 9 should be #0090FF', () {
        expect(palette.info[9], const Color(0xFF0090FF));
      });

      test('when creating the palette, cyan step 9 should be #00A2C7', () {
        expect(palette.cyan[9], const Color(0xFF00A2C7));
      });

      test('when creating the palette, violet step 9 should be #6E56CF', () {
        expect(palette.violet[9], const Color(0xFF6E56CF));
      });

      test('when creating the palette, teal step 9 should be #12A594', () {
        expect(palette.teal[9], const Color(0xFF12A594));
      });

      test('when creating the palette, orange step 9 should be #F76B15', () {
        expect(palette.orange[9], const Color(0xFFF76B15));
      });

      test('when creating the palette, pink step 9 should be #D6409F', () {
        expect(palette.pink[9], const Color(0xFFD6409F));
      });

      test('when creating the palette, yellow step 9 should be #E0C500', () {
        expect(palette.yellow[9], const Color(0xFFE0C500));
      });
    });

    // ----------------------------------------------------------------
    // Custom primary color
    // ----------------------------------------------------------------
    group('custom primary color', () {
      test('when using a blue primary color, primary step 9 should have a blue hue', () {
        final bluePalette = QuiPalette(primaryColor: const Color(0xFF0090FF));
        final step9 = bluePalette.primary[9];
        expect(step9.r, lessThan(step9.b));
      });

      test('when using a blue primary color, neutral step 12 should have a slight blue tint', () {
        final bluePalette = QuiPalette(primaryColor: const Color(0xFF0090FF));
        final neutral12 = bluePalette.neutral[12];
        final defaultNeutral12 = palette.neutral[12];
        expect(neutral12.b, greaterThan(defaultNeutral12.b));
      });
    });

    // ----------------------------------------------------------------
    // Equality
    // ----------------------------------------------------------------
    group('equality', () {
      test('when two palettes have the same primary color, they should be equal', () {
        final a = QuiPalette(primaryColor: const Color(0xFFFF4A4B));
        final b = QuiPalette(primaryColor: const Color(0xFFFF4A4B));
        expect(a, equals(b));
      });

      test('when two palettes have different primary colors, they should not be equal', () {
        final a = QuiPalette(primaryColor: const Color(0xFFFF4A4B));
        final b = QuiPalette(primaryColor: const Color(0xFF0090FF));
        expect(a, isNot(equals(b)));
      });

      test('when two palettes have the same primary color, their hash codes should be equal', () {
        final a = QuiPalette(primaryColor: const Color(0xFFFF4A4B));
        final b = QuiPalette(primaryColor: const Color(0xFFFF4A4B));
        expect(a.hashCode, equals(b.hashCode));
      });
    });
  });
}
