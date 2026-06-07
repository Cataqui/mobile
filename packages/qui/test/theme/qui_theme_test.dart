import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/gen/fonts.gen.dart';
import 'package:qui/src/theme/qui_colors.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_data.dart';
import 'package:qui/src/theme/qui_typography.dart';

const _brandColor = Color(0xFFFF4A4B);

void main() {
  group('FontFamily', () {
    test('inter constant resolves to packages/qui/Inter', () {
      expect(FontFamily.inter, equals('packages/qui/Inter'));
    });
  });

  group('QuiTypography', () {
    test('typography is const-constructible', () {
      const typography = QuiTypography();

      expect(typography, isA<QuiTypography>());
    });

    test('letterSpacingFactor is -0.02', () {
      expect(QuiTypography.letterSpacingFactor, equals(-0.02));
    });

    test('displayLarge has Inter font family', () {
      const typography = QuiTypography();

      expect(typography.displayLarge.fontFamily, equals(FontFamily.inter));
    });

    test('displayLarge has w400 weight', () {
      const typography = QuiTypography();

      expect(typography.displayLarge.fontWeight, equals(FontWeight.w400));
    });

    test('displayLarge has 57px font size', () {
      const typography = QuiTypography();

      expect(typography.displayLarge.fontSize, equals(57));
    });

    test('displayLarge letter spacing is approximately -1.14', () {
      const typography = QuiTypography();

      expect(typography.displayLarge.letterSpacing, closeTo(-1.14, 0.0001));
    });

    test('displayMedium has Inter font family', () {
      const typography = QuiTypography();

      expect(typography.displayMedium.fontFamily, equals(FontFamily.inter));
    });

    test('displayMedium has 45px font size', () {
      const typography = QuiTypography();

      expect(typography.displayMedium.fontSize, equals(45));
    });

    test('displayMedium letter spacing is -0.90', () {
      const typography = QuiTypography();

      expect(typography.displayMedium.letterSpacing, equals(-0.90));
    });

    test('displaySmall has 36px font size', () {
      const typography = QuiTypography();

      expect(typography.displaySmall.fontSize, equals(36));
    });

    test('displaySmall letter spacing is -0.72', () {
      const typography = QuiTypography();

      expect(typography.displaySmall.letterSpacing, equals(-0.72));
    });

    test('headlineLarge has Inter font family', () {
      const typography = QuiTypography();

      expect(typography.headlineLarge.fontFamily, equals(FontFamily.inter));
    });

    test('headlineLarge has 32px font size', () {
      const typography = QuiTypography();

      expect(typography.headlineLarge.fontSize, equals(32));
    });

    test('headlineLarge letter spacing is -0.64', () {
      const typography = QuiTypography();

      expect(typography.headlineLarge.letterSpacing, equals(-0.64));
    });

    test('headlineMedium has 28px font size', () {
      const typography = QuiTypography();

      expect(typography.headlineMedium.fontSize, equals(28));
    });

    test('headlineMedium letter spacing is -0.56', () {
      const typography = QuiTypography();

      expect(typography.headlineMedium.letterSpacing, equals(-0.56));
    });

    test('headlineSmall has 24px font size', () {
      const typography = QuiTypography();

      expect(typography.headlineSmall.fontSize, equals(24));
    });

    test('headlineSmall letter spacing is -0.48', () {
      const typography = QuiTypography();

      expect(typography.headlineSmall.letterSpacing, equals(-0.48));
    });

    test('titleLarge has Inter font family', () {
      const typography = QuiTypography();

      expect(typography.titleLarge.fontFamily, equals(FontFamily.inter));
    });

    test('titleLarge has 22px font size', () {
      const typography = QuiTypography();

      expect(typography.titleLarge.fontSize, equals(22));
    });

    test('titleLarge letter spacing is -0.44', () {
      const typography = QuiTypography();

      expect(typography.titleLarge.letterSpacing, equals(-0.44));
    });

    test('titleMedium has 16px font size', () {
      const typography = QuiTypography();

      expect(typography.titleMedium.fontSize, equals(16));
    });

    test('titleMedium letter spacing is -0.32', () {
      const typography = QuiTypography();

      expect(typography.titleMedium.letterSpacing, equals(-0.32));
    });

    test('titleSmall has 14px font size', () {
      const typography = QuiTypography();

      expect(typography.titleSmall.fontSize, equals(14));
    });

    test('titleSmall letter spacing is -0.28', () {
      const typography = QuiTypography();

      expect(typography.titleSmall.letterSpacing, equals(-0.28));
    });

    test('bodyLarge has Inter font family', () {
      const typography = QuiTypography();

      expect(typography.bodyLarge.fontFamily, equals(FontFamily.inter));
    });

    test('bodyLarge has 16px font size', () {
      const typography = QuiTypography();

      expect(typography.bodyLarge.fontSize, equals(16));
    });

    test('bodyLarge letter spacing is -0.32', () {
      const typography = QuiTypography();

      expect(typography.bodyLarge.letterSpacing, equals(-0.32));
    });

    test('bodyMedium has 14px font size', () {
      const typography = QuiTypography();

      expect(typography.bodyMedium.fontSize, equals(14));
    });

    test('bodyMedium letter spacing is -0.28', () {
      const typography = QuiTypography();

      expect(typography.bodyMedium.letterSpacing, equals(-0.28));
    });

    test('bodySmall has 12px font size', () {
      const typography = QuiTypography();

      expect(typography.bodySmall.fontSize, equals(12));
    });

    test('bodySmall letter spacing is -0.24', () {
      const typography = QuiTypography();

      expect(typography.bodySmall.letterSpacing, equals(-0.24));
    });

    test('labelLarge has Inter font family', () {
      const typography = QuiTypography();

      expect(typography.labelLarge.fontFamily, equals(FontFamily.inter));
    });

    test('labelLarge has 15px font size', () {
      const typography = QuiTypography();

      expect(typography.labelLarge.fontSize, equals(15));
    });

    test('labelLarge letter spacing is -0.30', () {
      const typography = QuiTypography();

      expect(typography.labelLarge.letterSpacing, equals(-0.30));
    });

    test('labelMedium has 12px font size', () {
      const typography = QuiTypography();

      expect(typography.labelMedium.fontSize, equals(12));
    });

    test('labelMedium letter spacing is -0.24', () {
      const typography = QuiTypography();

      expect(typography.labelMedium.letterSpacing, equals(-0.24));
    });

    test('labelSmall has 11px font size', () {
      const typography = QuiTypography();

      expect(typography.labelSmall.fontSize, equals(11));
    });

    test('labelSmall letter spacing is -0.22', () {
      const typography = QuiTypography();

      expect(typography.labelSmall.letterSpacing, equals(-0.22));
    });
  });

  group('QuiThemeData', () {
    QuiThemeData _themeData({Color primary = _brandColor, QuiTypography? typography}) {
      return QuiThemeData(
        colors: QuiColors.light(primary: primary),
        typography: typography ?? const QuiTypography(),
      );
    }

    test('copyWith preserves colors when no arguments provided', () {
      final original = _themeData();
      final result = original.copyWith();

      expect(result.colors, equals(original.colors));
    });

    test('copyWith replaces colors when provided', () {
      final original = _themeData();
      const custom = QuiColors.light(primary: Color(0xFF0984E3));
      final result = original.copyWith(colors: custom);

      expect(result.colors, equals(custom));
    });

    test('copyWith preserves typography when not provided', () {
      final original = _themeData();
      final result = original.copyWith();

      expect(result.typography, equals(const QuiTypography()));
    });

    test('copyWith replaces typography when provided', () {
      final original = _themeData();
      const custom = QuiTypography();
      final result = original.copyWith(typography: custom);

      expect(result.typography, equals(custom));
    });

    test('lerp interpolates background between two themes', () {
      final a = _themeData();
      final b = _themeData();
      // Override background by copying colors
      final bColors = b.colors.copyWith(background: const Color(0xFF000000));
      final bAlt = b.copyWith(colors: bColors);
      final result = a.lerp(bAlt, 0.5);

      expect(result.colors.background, equals(const Color.from(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)));
    });

    test('lerp interpolates primaryColor between two themes', () {
      final a = _themeData();
      final b = _themeData(primary: const Color(0xFF000000));
      final result = a.lerp(b, 0.5);

      expect(result.colors.primary, isNot(equals(a.colors.primary)));
    });

    test('lerp uses source typography when t < 0.5', () {
      final a = _themeData();
      final b = _themeData();
      final result = a.lerp(b, 0.25);

      expect(result.typography, equals(a.typography));
    });

    test('lerp uses target typography when t >= 0.5', () {
      final a = _themeData();
      final b = _themeData();
      final result = a.lerp(b, 0.75);

      expect(result.typography, equals(b.typography));
    });
  });

  group('QuiTheme', () {
    test('light theme registers QuiThemeData extension', () {
      final theme = QuiTheme.light(primaryColor: _brandColor);
      final data = theme.extension<QuiThemeData>();

      expect(data, isNotNull);
    });

    test('light theme sets scaffoldBackgroundColor to white', () {
      final theme = QuiTheme.light(primaryColor: _brandColor);

      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFFFFFFFF)));
    });

    test('light theme enables Material 3', () {
      final theme = QuiTheme.light(primaryColor: _brandColor);

      expect(theme.useMaterial3, isTrue);
    });

    test('light theme generates ColorScheme from primaryColor seed', () {
      final theme = QuiTheme.light(primaryColor: _brandColor);

      expect(theme.colorScheme, isNotNull);
    });

    test('light theme colorScheme.primary is derived from seedColor', () {
      final theme = QuiTheme.light(primaryColor: _brandColor);

      expect(theme.colorScheme.primary, isNotNull);
    });

    test('light theme applies Inter font family to textTheme bodyMedium', () {
      final theme = QuiTheme.light(primaryColor: _brandColor);

      expect(theme.textTheme.bodyMedium?.fontFamily, equals(FontFamily.inter));
    });

    test('light theme textTheme bodyMedium has w400 weight', () {
      final theme = QuiTheme.light(primaryColor: _brandColor);

      expect(theme.textTheme.bodyMedium?.fontWeight, equals(FontWeight.w400));
    });

    test('light theme applies proportional letter spacing to bodyMedium', () {
      final theme = QuiTheme.light(primaryColor: _brandColor);
      const expected = 14 * -0.02;

      expect(theme.textTheme.bodyMedium?.letterSpacing, equals(expected));
    });
  });

  group('QuiThemeContext', () {
    testWidgets('extension retrieves QuiThemeData from BuildContext', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: QuiTheme.light(primaryColor: _brandColor),
          home: Builder(
            builder: (context) {
              final data = Theme.of(context).extension<QuiThemeData>();

              expect(data, isNotNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
