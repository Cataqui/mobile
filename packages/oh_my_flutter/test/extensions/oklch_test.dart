import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

void main() {
  group('Oklch', () {
    group('fromColor', () {
      test('when converting floating-point sRGB, it should retain the reference lightness', () {
        const color = Color.from(alpha: 1, red: 0.1234, green: 0.5678, blue: 0.9012);
        expect(Oklch.fromColor(color).l, closeTo(0.6383767509, 0.0000001));
      });

      test('when converting floating-point sRGB, it should retain the reference chroma', () {
        const color = Color.from(alpha: 1, red: 0.1234, green: 0.5678, blue: 0.9012);
        expect(Oklch.fromColor(color).c, closeTo(0.1586962734, 0.0000001));
      });

      test('when converting floating-point sRGB, it should retain the reference hue', () {
        const color = Color.from(alpha: 1, red: 0.1234, green: 0.5678, blue: 0.9012);
        expect(Oklch.fromColor(color).h, closeTo(247.4806996, 0.0001));
      });

      test('when converting pure red, it should match the reference OKLCH values', () {
        final result = Oklch.fromColor(const Color(0xFFFF0000));
        expect(
          (result.l, result.c, result.h),
          isA<(double, double, double)>()
              .having((value) => value.$1, 'lightness', closeTo(0.6279553606, 0.0000001))
              .having((value) => value.$2, 'chroma', closeTo(0.2576833077, 0.0000001))
              .having((value) => value.$3, 'hue', closeTo(29.2338852, 0.0001)),
        );
      });

      test('when converting pure green, it should match the reference OKLCH values', () {
        final result = Oklch.fromColor(const Color(0xFF00FF00));
        expect(
          (result.l, result.c, result.h),
          isA<(double, double, double)>()
              .having((value) => value.$1, 'lightness', closeTo(0.8664396115, 0.0000001))
              .having((value) => value.$2, 'chroma', closeTo(0.2948272403, 0.0000001))
              .having((value) => value.$3, 'hue', closeTo(142.4953389, 0.0001)),
        );
      });

      test('when converting pure blue, it should match the reference OKLCH values', () {
        final result = Oklch.fromColor(const Color(0xFF0000FF));
        expect(
          (result.l, result.c, result.h),
          isA<(double, double, double)>()
              .having((value) => value.$1, 'lightness', closeTo(0.4520137184, 0.0000001))
              .having((value) => value.$2, 'chroma', closeTo(0.3132143717, 0.0000001))
              .having((value) => value.$3, 'hue', closeTo(264.0520206, 0.0001)),
        );
      });

      test('when converting the Cataqui brand color, it should match its reference OKLCH values', () {
        final result = Oklch.fromColor(const Color(0xFFFF4A4B));
        expect(
          (result.l, result.c, result.h),
          isA<(double, double, double)>()
              .having((value) => value.$1, 'lightness', closeTo(0.6698468799, 0.0000001))
              .having((value) => value.$2, 'chroma', closeTo(0.2173998691, 0.0000001))
              .having((value) => value.$3, 'hue', closeTo(24.9934213, 0.0001)),
        );
      });

      test('when converting an achromatic color, it should canonicalize hue to zero', () {
        expect(Oklch.fromColor(const Color(0xFF808080)).h, 0);
      });

      test('when converting a transparent color, it should intentionally ignore alpha', () {
        final transparent = Oklch.fromColor(const Color(0x00123456));
        final opaque = Oklch.fromColor(const Color(0xFF123456));
        expect(transparent, opaque);
      });

      test('when converting Display P3, it should match native P3 reference values', () {
        const displayP3 = Color.from(alpha: 1, red: 0.8, green: 0.2, blue: 0.1, colorSpace: ColorSpace.displayP3);
        final result = Oklch.fromColor(displayP3);
        expect(
          (result.l, result.c, result.h),
          isA<(double, double, double)>()
              .having((value) => value.$1, 'lightness', closeTo(0.5719844701, 0.0000001))
              .having((value) => value.$2, 'chroma', closeTo(0.2268995804, 0.0000001))
              .having((value) => value.$3, 'hue', closeTo(31.3556842, 0.0001)),
        );
      });

      test('when converting Display P3 red, it should retain chroma outside sRGB', () {
        const displayP3Red = Color.from(alpha: 1, red: 1, green: 0, blue: 0, colorSpace: ColorSpace.displayP3);
        expect(Oklch.fromColor(displayP3Red).c, closeTo(0.2994852922, 0.0000001));
      });
    });

    group('toColor', () {
      final roundTripColors = <Color>[
        const Color(0xFFFF4A4B),
        const Color(0xFF0090FF),
        const Color(0xFF00D757),
        const Color(0xFFFFB224),
        const Color(0xFF6E56CF),
        const Color(0xFF12A594),
        const Color(0xFF000000),
        const Color(0xFFFFFFFF),
        const Color(0xFF808080),
        const Color(0xFF123456),
        const Color(0xFFABCDEF),
      ];

      for (final color in roundTripColors) {
        final hexadecimal = color.toARGB32().toRadixString(16).padLeft(8, '0');
        test('when round-tripping #$hexadecimal, it should preserve the sRGB color', () {
          expect(Oklch.fromColor(color).toColor(), isSameColorAs(color));
        });
      }

      test('when converting an in-gamut color, it should retain floating-point precision', () {
        final color = Oklch.toColor(0.65, 0.1, 120);
        expect(color.r * 255, isNot(closeTo((color.r * 255).round(), 0.0000001)));
      });

      test('when mapping an out-of-gamut color, it should preserve its requested lightness', () {
        final mapped = Oklch.fromColor(Oklch.toColor(0.5, 0.4, 28));
        expect(mapped.l, closeTo(0.5, 0.02));
      });

      test('when mapping an out-of-gamut color, it should preserve its requested hue', () {
        final mapped = Oklch.fromColor(Oklch.toColor(0.5, 0.4, 28));
        expect(mapped.h, closeTo(28, 3));
      });

      test('when mapping an out-of-gamut color, it should reduce chroma', () {
        final mapped = Oklch.fromColor(Oklch.toColor(0.5, 0.4, 28));
        expect(mapped.c, lessThan(0.4));
      });

      test('when lightness is below zero with nonzero chroma, it should return black', () {
        expect(Oklch.toColor(-0.5, 0.4, 28), isSameColorAs(const Color(0xFF000000)));
      });

      test('when lightness is above one with nonzero chroma, it should return white', () {
        expect(Oklch.toColor(1.5, 0.4, 28), isSameColorAs(const Color(0xFFFFFFFF)));
      });

      test('when chroma is negative, it should convert it as zero chroma', () {
        expect(Oklch.toColor(0.5, -0.2, 28), isSameColorAs(Oklch.toColor(0.5, 0, 28)));
      });

      test('when hue exceeds one turn, it should normalize the angle', () {
        expect(Oklch.toColor(0.5, 0.1, 388), isSameColorAs(Oklch.toColor(0.5, 0.1, 28)));
      });

      test('when hue is negative, it should normalize the angle', () {
        expect(Oklch.toColor(0.5, 0.1, -332), isSameColorAs(Oklch.toColor(0.5, 0.1, 28)));
      });

      test('when lightness is not finite, it should throw an argument error', () {
        expect(() => Oklch.toColor(double.nan, 0.1, 28), throwsArgumentError);
      });

      test('when chroma is not finite, it should throw an argument error', () {
        expect(() => Oklch.toColor(0.5, double.infinity, 28), throwsArgumentError);
      });

      test('when hue is not finite, it should throw an argument error', () {
        expect(() => Oklch.toColor(0.5, 0.1, double.negativeInfinity), throwsArgumentError);
      });

      test('when converting OKLCH to sRGB, it should return an opaque color', () {
        expect(Oklch.toColor(0.5, 0.1, 28).a, 1);
      });

      test('when converting OKLCH to sRGB, it should label the result as sRGB', () {
        expect(Oklch.toColor(0.5, 0.1, 28).colorSpace, ColorSpace.sRGB);
      });

      test('when round-tripping Display P3, it should preserve the native P3 color', () {
        const displayP3 = Color.from(alpha: 1, red: 0.8, green: 0.2, blue: 0.1, colorSpace: ColorSpace.displayP3);
        final result = Oklch.fromColor(displayP3).toColor(colorSpace: ColorSpace.displayP3);
        expect(result, isSameColorAs(displayP3));
      });

      test('when targeting Display P3, it should label the result as Display P3', () {
        expect(Oklch.toColor(0.5, 0.1, 28, colorSpace: ColorSpace.displayP3).colorSpace, ColorSpace.displayP3);
      });

      test('when a color fits Display P3 but not sRGB, P3 should preserve more chroma', () {
        const displayP3Red = Color.from(alpha: 1, red: 1, green: 0, blue: 0, colorSpace: ColorSpace.displayP3);
        final oklch = Oklch.fromColor(displayP3Red);
        final p3Chroma = Oklch.fromColor(oklch.toColor(colorSpace: ColorSpace.displayP3)).c;
        final srgbChroma = Oklch.fromColor(oklch.toColor()).c;
        expect(p3Chroma, greaterThan(srgbChroma));
      });

      test('when a color exceeds both bounded gamuts, P3 should map to a wider boundary', () {
        const oklch = Oklch(0.7, 0.5, 140);
        final p3Chroma = Oklch.fromColor(oklch.toColor(colorSpace: ColorSpace.displayP3)).c;
        final srgbChroma = Oklch.fromColor(oklch.toColor()).c;
        expect(p3Chroma, greaterThan(srgbChroma));
      });

      test('when targeting extended sRGB, it should preserve channels outside the bounded gamut', () {
        final extended = Oklch.toColor(0.7, 0.5, 140, colorSpace: ColorSpace.extendedSRGB);
        expect([
          extended.r,
          extended.g,
          extended.b,
        ], contains(predicate<double>((channel) => channel < 0 || channel > 1)));
      });

      test('when targeting extended sRGB, it should label the result as extended sRGB', () {
        expect(Oklch.toColor(0.7, 0.5, 140, colorSpace: ColorSpace.extendedSRGB).colorSpace, ColorSpace.extendedSRGB);
      });
    });

    group('value semantics', () {
      test('when two OKLCH values have equal components, they should be equal', () {
        expect(const Oklch(0.65, 0.23, 28), const Oklch(0.65, 0.23, 28));
      });

      test('when two OKLCH values differ, they should not be equal', () {
        expect(const Oklch(0.65, 0.23, 28), isNot(const Oklch(0.55, 0.22, 230)));
      });

      test('when two OKLCH values are equal, they should have equal hash codes', () {
        expect(const Oklch(0.65, 0.23, 28).hashCode, const Oklch(0.65, 0.23, 28).hashCode);
      });

      test('when using the extension, it should match the static conversion', () {
        const oklch = Oklch(0.65, 0.23, 28);
        expect(oklch.toColor(), isSameColorAs(Oklch.toColor(0.65, 0.23, 28)));
      });
    });
  });
}
