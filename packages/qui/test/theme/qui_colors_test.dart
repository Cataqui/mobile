import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/src/theme/qui_colors.dart';

const _lightColors = QuiColors.light();

const _lerpA = QuiColors(
  primary: Color(0xFFFF4A4B),
  background: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFFFF),
  textPrimary: Color(0xFF1A1A1A),
  textSecondary: Color(0xFF757575),
  placeholder: Color(0xFF9E9E9E),
  searchBarBackground: Color(0xFFFAFAFA),
  searchBarPlaceholder: Color(0xFF9E9E9E),
  frostedGlassBackground: Color(0x4DFFFFFF),
  frostedGlassBorder: Color(0xFFE0E0E0),
);

const _lerpB = QuiColors(
  primary: Color(0xFF000000),
  background: Color(0xFF000000),
  surface: Color(0xFF000000),
  textPrimary: Color(0xFF000000),
  textSecondary: Color(0xFF000000),
  placeholder: Color(0xFF000000),
  searchBarBackground: Color(0xFF000000),
  searchBarPlaceholder: Color(0xFF000000),
  frostedGlassBackground: Color(0xFF000000),
  frostedGlassBorder: Color(0xFF000000),
);

void main() {
  group('QuiColors', () {
    // ----------------------------------------------------------------
    // Constructor defaults
    // ----------------------------------------------------------------

    test('light() sets primary to default brand color', () {
      expect(_lightColors.primary, equals(const Color(0xFFFF4A4B)));
    });

    test('light() sets background to white', () {
      expect(_lightColors.background, equals(const Color(0xFFFFFFFF)));
    });

    test('light() sets surface to white', () {
      expect(_lightColors.surface, equals(const Color(0xFFFFFFFF)));
    });

    test('light() sets textPrimary to near-black', () {
      expect(_lightColors.textPrimary, equals(const Color(0xFF1A1A1A)));
    });

    test('light() sets textSecondary to medium gray', () {
      expect(_lightColors.textSecondary, equals(const Color(0xFF757575)));
    });

    test('light() sets placeholder to light gray', () {
      expect(_lightColors.placeholder, equals(const Color(0xFF9E9E9E)));
    });

    test('light() sets searchBarBackground to off-white', () {
      expect(
        _lightColors.searchBarBackground,
        equals(const Color(0xFFFAFAFA)),
      );
    });

    test('light() sets searchBarPlaceholder to light gray', () {
      expect(
        _lightColors.searchBarPlaceholder,
        equals(const Color(0xFF9E9E9E)),
      );
    });

    test('light() sets frostedGlassBackground to semi-transparent white', () {
      expect(
        _lightColors.frostedGlassBackground,
        equals(const Color(0x4DFFFFFF)),
      );
    });

    test('light() sets frostedGlassBorder to light gray', () {
      expect(
        _lightColors.frostedGlassBorder,
        equals(const Color(0xFFE0E0E0)),
      );
    });

    test('light(primary:) overrides primary color', () {
      const custom = Color(0xFF0984E3);
      const colors = QuiColors.light(primary: custom);

      expect(colors.primary, equals(custom));
    });

    test('is const-constructible with all required fields', () {
      const colors = QuiColors(
        primary: Color(0xFFFF4A4B),
        background: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        textPrimary: Color(0xFF1A1A1A),
        textSecondary: Color(0xFF757575),
        placeholder: Color(0xFF9E9E9E),
        searchBarBackground: Color(0xFFFAFAFA),
        searchBarPlaceholder: Color(0xFF9E9E9E),
        frostedGlassBackground: Color(0x4DFFFFFF),
        frostedGlassBorder: Color(0xFFE0E0E0),
      );

      expect(colors, isA<QuiColors>());
    });

    // ----------------------------------------------------------------
    // copyWith
    // ----------------------------------------------------------------

    test('copyWith with no arguments preserves all values', () {
      final result = _lightColors.copyWith();

      expect(result.primary, equals(_lightColors.primary));
    });

    test('copyWith replaces primary when provided', () {
      const custom = Color(0xFF0984E3);
      final result = _lightColors.copyWith(primary: custom);

      expect(result.primary, equals(custom));
    });

    test('copyWith replaces background when provided', () {
      const custom = Color(0xFFEEEEEE);
      final result = _lightColors.copyWith(background: custom);

      expect(result.background, equals(custom));
    });

    test('copyWith replaces surface when provided', () {
      const custom = Color(0xFFF5F5F5);
      final result = _lightColors.copyWith(surface: custom);

      expect(result.surface, equals(custom));
    });

    test('copyWith replaces textPrimary when provided', () {
      const custom = Color(0xFF333333);
      final result = _lightColors.copyWith(textPrimary: custom);

      expect(result.textPrimary, equals(custom));
    });

    test('copyWith replaces textSecondary when provided', () {
      const custom = Color(0xFF999999);
      final result = _lightColors.copyWith(textSecondary: custom);

      expect(result.textSecondary, equals(custom));
    });

    test('copyWith replaces placeholder when provided', () {
      const custom = Color(0xFFCCCCCC);
      final result = _lightColors.copyWith(placeholder: custom);

      expect(result.placeholder, equals(custom));
    });

    test('copyWith replaces searchBarBackground when provided', () {
      const custom = Color(0xFFF0F0F0);
      final result = _lightColors.copyWith(searchBarBackground: custom);

      expect(result.searchBarBackground, equals(custom));
    });

    test('copyWith replaces searchBarPlaceholder when provided', () {
      const custom = Color(0xFFCCCCCC);
      final result = _lightColors.copyWith(searchBarPlaceholder: custom);

      expect(result.searchBarPlaceholder, equals(custom));
    });

    test('copyWith replaces frostedGlassBackground when provided', () {
      const custom = Color(0x80FFFFFF);
      final result = _lightColors.copyWith(frostedGlassBackground: custom);

      expect(result.frostedGlassBackground, equals(custom));
    });

    test('copyWith replaces frostedGlassBorder when provided', () {
      const custom = Color(0xFFCCCCCC);
      final result = _lightColors.copyWith(frostedGlassBorder: custom);

      expect(result.frostedGlassBorder, equals(custom));
    });

    // ----------------------------------------------------------------
    // lerp
    // ----------------------------------------------------------------

    test('lerp at t=0 returns source colors', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0);

      expect(result.primary, equals(_lerpA.primary));
    });

    test('lerp at t=1 returns target colors', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 1);

      expect(result.primary, equals(_lerpB.primary));
    });

    test('lerp interpolates primary at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.primary,
        equals(Color.lerp(_lerpA.primary, _lerpB.primary, 0.5)),
      );
    });

    test('lerp interpolates background at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.background,
        equals(Color.lerp(_lerpA.background, _lerpB.background, 0.5)),
      );
    });

    test('lerp interpolates surface at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.surface,
        equals(Color.lerp(_lerpA.surface, _lerpB.surface, 0.5)),
      );
    });

    test('lerp interpolates textPrimary at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.textPrimary,
        equals(Color.lerp(_lerpA.textPrimary, _lerpB.textPrimary, 0.5)),
      );
    });

    test('lerp interpolates textSecondary at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.textSecondary,
        equals(Color.lerp(_lerpA.textSecondary, _lerpB.textSecondary, 0.5)),
      );
    });

    test('lerp interpolates placeholder at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.placeholder,
        equals(Color.lerp(_lerpA.placeholder, _lerpB.placeholder, 0.5)),
      );
    });

    test('lerp interpolates searchBarBackground at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.searchBarBackground,
        equals(
          Color.lerp(
            _lerpA.searchBarBackground,
            _lerpB.searchBarBackground,
            0.5,
          ),
        ),
      );
    });

    test('lerp interpolates searchBarPlaceholder at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.searchBarPlaceholder,
        equals(
          Color.lerp(
            _lerpA.searchBarPlaceholder,
            _lerpB.searchBarPlaceholder,
            0.5,
          ),
        ),
      );
    });

    test('lerp interpolates frostedGlassBackground at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.frostedGlassBackground,
        equals(
          Color.lerp(
            _lerpA.frostedGlassBackground,
            _lerpB.frostedGlassBackground,
            0.5,
          ),
        ),
      );
    });

    test('lerp interpolates frostedGlassBorder at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.frostedGlassBorder,
        equals(
          Color.lerp(
            _lerpA.frostedGlassBorder,
            _lerpB.frostedGlassBorder,
            0.5,
          ),
        ),
      );
    });

    // ----------------------------------------------------------------
    // Equality & hashCode
    // ----------------------------------------------------------------

    test('== returns true for equal instances', () {
      const a = QuiColors.light();
      const b = QuiColors.light();

      expect(a == b, isTrue);
    });

    test('== returns false for different primary colors', () {
      const a = QuiColors.light();
      const b = QuiColors.light(primary: Color(0xFF000000));

      expect(a == b, isFalse);
    });

    test('== returns false for different backgrounds', () {
      const a = _lightColors;
      final b = _lightColors.copyWith(background: const Color(0xFF000000));

      expect(a == b, isFalse);
    });

    test('equal instances have identical hash codes', () {
      const a = QuiColors.light();
      const b = QuiColors.light();

      expect(a.hashCode, equals(b.hashCode));
    });

    test('different instances have distinct hash codes', () {
      const a = QuiColors.light();
      const b = QuiColors.light(primary: Color(0xFF000000));

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });
}
