import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiBottomSheetColorScheme', () {
    final palette = QuiPalette();
    final scheme = QuiBottomSheetColorScheme(
      background: palette.neutral[1],
      handle: palette.neutral[6],
    );

    test('when created, it should expose the supplied background color', () {
      expect(scheme.background, palette.neutral[1]);
    });

    test('when created, it should expose the supplied handle color', () {
      expect(scheme.handle, palette.neutral[6]);
    });

    test('when copied without overrides, it should preserve every role', () {
      expect(scheme.copyWith(), scheme);
    });

    test(
      'when copied with a handle override, it should replace the handle color',
      () {
        expect(
          scheme.copyWith(handle: palette.primary[9]).handle,
          palette.primary[9],
        );
      },
    );

    test('when interpolated halfway, it should blend every role', () {
      final target = QuiBottomSheetColorScheme(
        background: palette.neutral[12],
        handle: palette.neutral[1],
      );

      expect(
        QuiBottomSheetColorScheme.lerp(scheme, target, 0.5),
        QuiBottomSheetColorScheme(
          background: Color.lerp(scheme.background, target.background, 0.5)!,
          handle: Color.lerp(scheme.handle, target.handle, 0.5)!,
        ),
      );
    });

    test('when roles are equal, it should produce the same hash code', () {
      final equalScheme = QuiBottomSheetColorScheme(
        background: palette.neutral[1],
        handle: palette.neutral[6],
      );

      expect(scheme.hashCode, equalScheme.hashCode);
    });
  });
}
