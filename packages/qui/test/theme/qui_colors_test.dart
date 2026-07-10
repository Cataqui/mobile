import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/src/theme/qui_colors.dart';

const _lightColors = QuiColors.light();

const _lerpA = QuiColors(
  primary: Color(0xFFFF4A4B),
  background: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFFFF),
  textPrimary: Color(0xFF1A1A1A),
  textSecondary: Color(0xFFB3B3B3),
  description: Color(0xFF737373),
  borderOnBackground: Color(0xFF9E9E9E),
  placeholder: Color(0xFF9E9E9E),
  disabledButtonBackground: Color(0xFFE1E1E1),
  disabledButtonForeground: Color(0xFF8E8E8E),
  searchBarButtonBackground: Color(0xFFFAFAFA),
  searchBarButtonShadow: Color(0x1A000000),
  viewBackButtonBackground: Color(0xFFFAFAFA),
  viewBackButtonShadow: Color(0x1A000000),
  money: Color(0xFF00D757),
  mapBackground: Color(0xFFF4F2EF),
  neutralButtonBackground: Color(0xFF000000),
  ghost: Color(0xFFCDCDCD),
  shimmerTextBase: Color(0xFFB3B3B3),
  shimmerTextGlow: Color(0xFFE0E0E0),
  skeleton: Color(0xFFEFEFEF),
  skeletonShimmerGlow: Color(0xFFFAFAFA),
);

const _lerpB = QuiColors(
  primary: Color(0xFF000000),
  background: Color(0xFF000000),
  surface: Color(0xFF000000),
  textPrimary: Color(0xFF000000),
  textSecondary: Color(0xFF000000),
  description: Color(0xFF000000),
  borderOnBackground: Color(0xFF000000),
  placeholder: Color(0xFF000000),
  disabledButtonBackground: Color(0xFF000000),
  disabledButtonForeground: Color(0xFF000000),
  searchBarButtonBackground: Color(0xFF000000),
  searchBarButtonShadow: Color(0xFF000000),
  viewBackButtonBackground: Color(0xFF000000),
  viewBackButtonShadow: Color(0xFF000000),
  money: Color(0xFF000000),
  mapBackground: Color(0xFF000000),
  neutralButtonBackground: Color(0xFF000000),
  ghost: Color(0xFF000000),
  shimmerTextBase: Color(0xFF000000),
  shimmerTextGlow: Color(0xFF000000),
  skeleton: Color(0xFF000000),
  skeletonShimmerGlow: Color(0xFF000000),
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

    test('light() sets textSecondary to soft gray', () {
      expect(_lightColors.textSecondary, equals(const Color(0xFF9A9A9A)));
    });

    test('light() sets description to medium-dark gray', () {
      expect(_lightColors.description, equals(const Color(0xFF9A9A9A)));
    });

    test('when light colors are created, it should set borderOnBackground to light gray', () {
      expect(_lightColors.borderOnBackground, equals(const Color(0xFFE6E6E6)));
    });

    test('light() sets placeholder to light gray', () {
      expect(_lightColors.placeholder, equals(const Color(0xFF9E9E9E)));
    });

    test('when light colors are created, it should set disabled button background to light gray', () {
      expect(_lightColors.disabledButtonBackground, equals(const Color(0xFFE1E1E1)));
    });

    test('when light colors are created, it should set disabled button foreground to medium gray', () {
      expect(_lightColors.disabledButtonForeground, equals(const Color(0xFF8E8E8E)));
    });

    test('when light colors are created, it should set searchBarButtonBackground to off-white', () {
      expect(_lightColors.searchBarButtonBackground, equals(const Color(0xFFFAFAFA)));
    });

    test('when light colors are created, it should set searchBarButtonShadow to black with baked alpha', () {
      expect(_lightColors.searchBarButtonShadow, equals(const Color(0x1A000000)));
    });

    test('when light colors are created, it should set backButtonBackground to off-white', () {
      expect(_lightColors.viewBackButtonBackground, equals(const Color(0xFFFAFAFA)));
    });

    test('when light colors are created, it should set backButtonShadow to black with baked alpha', () {
      expect(_lightColors.viewBackButtonShadow, equals(const Color(0x1A000000)));
    });

    test('light() sets shimmerTextBase to soft gray', () {
      expect(_lightColors.shimmerTextBase, equals(const Color(0xFFB3B3B3)));
    });

    test('light() sets shimmerTextGlow to light gray', () {
      expect(_lightColors.shimmerTextGlow, equals(const Color(0xFFE0E0E0)));
    });

    test('when light colors are created, it should set skeleton to light gray', () {
      expect(_lightColors.skeleton, equals(const Color(0xFFEFEFEF)));
    });

    test('when light colors are created, it should set skeletonShimmerGlow to very light gray', () {
      expect(_lightColors.skeletonShimmerGlow, equals(const Color(0xFFFAFAFA)));
    });

    test('light() sets money to green', () {
      expect(_lightColors.money, equals(const Color(0xFF00D757)));
    });

    test('when light colors are created, it should set neutralButtonBackground to black', () {
      expect(_lightColors.neutralButtonBackground, equals(const Color(0xFF000000)));
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
        textSecondary: Color(0xFFB3B3B3),
        description: Color(0xFF9A9A9A),
        borderOnBackground: Color(0xFF9E9E9E),
        placeholder: Color(0xFF9E9E9E),
        disabledButtonBackground: Color(0xFFE1E1E1),
        disabledButtonForeground: Color(0xFF8E8E8E),
        searchBarButtonBackground: Color(0xFFFAFAFA),
        searchBarButtonShadow: Color(0x1A000000),
        viewBackButtonBackground: Color(0xFFFAFAFA),
        viewBackButtonShadow: Color(0x1A000000),
        money: Color(0xFF00D757),
        mapBackground: Color(0xFFF4F2EF),
        neutralButtonBackground: Color(0xFF000000),
        ghost: Color(0xFFCDCDCD),
        shimmerTextBase: Color(0xFFB3B3B3),
        shimmerTextGlow: Color(0xFFE0E0E0),
        skeleton: Color(0xFFEFEFEF),
        skeletonShimmerGlow: Color(0xFFFAFAFA),
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

    test('copyWith replaces description when provided', () {
      const custom = Color(0xFF777777);
      final result = _lightColors.copyWith(description: custom);

      expect(result.description, equals(custom));
    });

    test('when copyWith receives borderOnBackground, it should replace borderOnBackground', () {
      const custom = Color(0xFF8F8F8F);
      final result = _lightColors.copyWith(borderOnBackground: custom);

      expect(result.borderOnBackground, equals(custom));
    });

    test('copyWith replaces placeholder when provided', () {
      const custom = Color(0xFFCCCCCC);
      final result = _lightColors.copyWith(placeholder: custom);

      expect(result.placeholder, equals(custom));
    });

    test('when copyWith receives disabled button background, it should replace disabled button background', () {
      const custom = Color(0xFFDDDDDD);
      final result = _lightColors.copyWith(disabledButtonBackground: custom);

      expect(result.disabledButtonBackground, equals(custom));
    });

    test('when copyWith receives disabled button foreground, it should replace disabled button foreground', () {
      const custom = Color(0xFF888888);
      final result = _lightColors.copyWith(disabledButtonForeground: custom);

      expect(result.disabledButtonForeground, equals(custom));
    });

    test('when copyWith receives searchBarButtonBackground, it should replace searchBarButtonBackground', () {
      const custom = Color(0xFFF0F0F0);
      final result = _lightColors.copyWith(searchBarButtonBackground: custom);

      expect(result.searchBarButtonBackground, equals(custom));
    });

    test('when copyWith receives searchBarButtonShadow, it should replace searchBarButtonShadow', () {
      const custom = Color(0xFF000000);
      final result = _lightColors.copyWith(searchBarButtonShadow: custom);

      expect(result.searchBarButtonShadow, equals(custom));
    });

    test('when copyWith receives backButtonBackground, it should replace backButtonBackground', () {
      const custom = Color(0xFFF0F0F0);
      final result = _lightColors.copyWith(backButtonBackground: custom);

      expect(result.viewBackButtonBackground, equals(custom));
    });

    test('when copyWith receives backButtonShadow, it should replace backButtonShadow', () {
      const custom = Color(0xFF000000);
      final result = _lightColors.copyWith(backButtonShadow: custom);

      expect(result.viewBackButtonShadow, equals(custom));
    });

    test('copyWith replaces money when provided', () {
      const custom = Color(0xFF00AA55);
      final result = _lightColors.copyWith(money: custom);

      expect(result.money, equals(custom));
    });

    test('when copyWith receives neutralButtonBackground, it should replace neutralButtonBackground', () {
      const custom = Color(0xFFEEEEEE);
      final result = _lightColors.copyWith(neutralButtonBackground: custom);

      expect(result.neutralButtonBackground, equals(custom));
    });

    test('when copyWith receives skeleton, it should replace skeleton', () {
      const custom = Color(0xFFCCCCCC);
      final result = _lightColors.copyWith(skeleton: custom);

      expect(result.skeleton, equals(custom));
    });

    test('when copyWith receives skeletonShimmerGlow, it should replace skeletonShimmerGlow', () {
      const custom = Color(0xFFFFFFFF);
      final result = _lightColors.copyWith(skeletonShimmerGlow: custom);

      expect(result.skeletonShimmerGlow, equals(custom));
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

      expect(result.primary, equals(Color.lerp(_lerpA.primary, _lerpB.primary, 0.5)));
    });

    test('lerp interpolates background at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(result.background, equals(Color.lerp(_lerpA.background, _lerpB.background, 0.5)));
    });

    test('lerp interpolates surface at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(result.surface, equals(Color.lerp(_lerpA.surface, _lerpB.surface, 0.5)));
    });

    test('lerp interpolates textPrimary at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(result.textPrimary, equals(Color.lerp(_lerpA.textPrimary, _lerpB.textPrimary, 0.5)));
    });

    test('lerp interpolates textSecondary at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(result.textSecondary, equals(Color.lerp(_lerpA.textSecondary, _lerpB.textSecondary, 0.5)));
    });

    test('lerp interpolates description at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(result.description, equals(Color.lerp(_lerpA.description, _lerpB.description, 0.5)));
    });

    test('when lerping at t=0.5, it should interpolate borderOnBackground', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(result.borderOnBackground, equals(Color.lerp(_lerpA.borderOnBackground, _lerpB.borderOnBackground, 0.5)));
    });

    test('lerp interpolates placeholder at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(result.placeholder, equals(Color.lerp(_lerpA.placeholder, _lerpB.placeholder, 0.5)));
    });

    test('when lerping at t=0.5, it should interpolate disabled button background', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.disabledButtonBackground,
        equals(Color.lerp(_lerpA.disabledButtonBackground, _lerpB.disabledButtonBackground, 0.5)),
      );
    });

    test('when lerping at t=0.5, it should interpolate disabled button foreground', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.disabledButtonForeground,
        equals(Color.lerp(_lerpA.disabledButtonForeground, _lerpB.disabledButtonForeground, 0.5)),
      );
    });

    test('when lerping at t=0.5, it should interpolate searchBarButtonBackground', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.searchBarButtonBackground,
        equals(Color.lerp(_lerpA.searchBarButtonBackground, _lerpB.searchBarButtonBackground, 0.5)),
      );
    });

    test('when lerping at t=0.5, it should interpolate searchBarButtonShadow', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.searchBarButtonShadow,
        equals(Color.lerp(_lerpA.searchBarButtonShadow, _lerpB.searchBarButtonShadow, 0.5)),
      );
    });

    test('when lerping at t=0.5, it should interpolate backButtonBackground', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.viewBackButtonBackground,
        equals(Color.lerp(_lerpA.viewBackButtonBackground, _lerpB.viewBackButtonBackground, 0.5)),
      );
    });

    test('when lerping at t=0.5, it should interpolate backButtonShadow', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.viewBackButtonShadow,
        equals(Color.lerp(_lerpA.viewBackButtonShadow, _lerpB.viewBackButtonShadow, 0.5)),
      );
    });

    test('lerp interpolates money at t=0.5', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(result.money, equals(Color.lerp(_lerpA.money, _lerpB.money, 0.5)));
    });

    test('when lerping at t=0.5, it should interpolate neutralButtonBackground', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.neutralButtonBackground,
        equals(Color.lerp(_lerpA.neutralButtonBackground, _lerpB.neutralButtonBackground, 0.5)),
      );
    });

    test('when lerping at t=0.5, it should interpolate skeleton', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(result.skeleton, equals(Color.lerp(_lerpA.skeleton, _lerpB.skeleton, 0.5)));
    });

    test('when lerping at t=0.5, it should interpolate skeletonShimmerGlow', () {
      final result = QuiColors.lerp(_lerpA, _lerpB, 0.5);

      expect(
        result.skeletonShimmerGlow,
        equals(Color.lerp(_lerpA.skeletonShimmerGlow, _lerpB.skeletonShimmerGlow, 0.5)),
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

    test('when borderOnBackground differs, it should return false for equality', () {
      const a = _lightColors;
      final b = _lightColors.copyWith(borderOnBackground: const Color(0xFF000000));

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

    test('when borderOnBackground differs, it should have a distinct hash code', () {
      const a = _lightColors;
      final b = _lightColors.copyWith(borderOnBackground: const Color(0xFF000000));

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('when skeleton differs, it should return false for equality', () {
      const a = _lightColors;
      final b = _lightColors.copyWith(skeleton: const Color(0xFF000000));

      expect(a == b, isFalse);
    });

    test('when skeletonShimmerGlow differs, it should return false for equality', () {
      const a = _lightColors;
      final b = _lightColors.copyWith(skeletonShimmerGlow: const Color(0xFF000000));

      expect(a == b, isFalse);
    });

    test('when skeleton differs, it should have a distinct hash code', () {
      const a = _lightColors;
      final b = _lightColors.copyWith(skeleton: const Color(0xFF000000));

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('when skeletonShimmerGlow differs, it should have a distinct hash code', () {
      const a = _lightColors;
      final b = _lightColors.copyWith(skeletonShimmerGlow: const Color(0xFF000000));

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('when neutralButtonBackground differs, it should return false for equality', () {
      const a = _lightColors;
      final b = _lightColors.copyWith(neutralButtonBackground: const Color(0xFFEEEEEE));

      expect(a == b, isFalse);
    });

    test('when neutralButtonBackground differs, it should have a distinct hash code', () {
      const a = _lightColors;
      final b = _lightColors.copyWith(neutralButtonBackground: const Color(0xFFEEEEEE));

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });
}
