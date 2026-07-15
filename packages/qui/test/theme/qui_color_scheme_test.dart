import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/src/theme/qui_color_scheme/qui_color_scheme.dart';
import 'package:qui/src/theme/qui_palette/qui_palette.dart';

final _palette = QuiPalette(primaryColor: const Color(0xFFFF4A4B));
final _light = QuiColorScheme.light(onPrimary: const Color(0xFF1E1615));

void main() {
  group('QuiColorScheme', () {
    test('light() sets background to neutral-1', () {
      expect(_light.background, equals(Colors.white));
    });

    test('light() sets text.primary to neutral-12', () {
      expect(_light.text.primary, equals(_palette.neutral[12]));
    });

    test(
      'when light scheme is created, it should set text.secondary to neutral-10',
      () {
        expect(_light.text.secondary, equals(_palette.neutral[10]));
      },
    );

    test('light() sets text.brandPrimary to primary-11', () {
      expect(_light.text.brandPrimary, equals(_palette.primary[11]));
    });

    test('light() sets primary.solid to primary-9', () {
      expect(_light.colors.primary.solid, equals(_palette.primary[9]));
    });

    test('light() sets buttons.primary.background to primary-9', () {
      expect(_light.buttons.primary.background, equals(_palette.primary[9]));
    });

    test(
      'when light scheme is created, it should set primary button foreground to warm ink',
      () {
        expect(
          _light.buttons.primary.foreground,
          equals(const Color(0xFF1E1615)),
        );
      },
    );

    test(
      'when a custom primary is dark, it should select white once for all primary foreground roles',
      () {
        final scheme = QuiColorScheme.light(
          palette: QuiPalette(primaryColor: const Color(0xFF000000)),
          onPrimary: const Color(0xFFFFFFFF),
        );

        expect(scheme.colors.primary.onSolid, equals(const Color(0xFFFFFFFF)));
        expect(
          scheme.buttons.primary.foreground,
          same(scheme.colors.primary.onSolid),
        );
      },
    );

    test(
      'when a custom primary is light, it should select dark ink once for all primary foreground roles',
      () {
        final palette = QuiPalette(primaryColor: const Color(0xFFFFFF00));
        final scheme = QuiColorScheme.light(
          palette: palette,
          onPrimary: const Color(0xFF1E1615),
        );

        expect(scheme.colors.primary.onSolid, equals(const Color(0xFF1E1615)));
        expect(
          scheme.buttons.primary.foreground,
          same(scheme.colors.primary.onSolid),
        );
      },
    );

    test('light() sets accent.orange.solid to orange-9', () {
      expect(_light.colors.orange.solid, equals(_palette.orange[9]));
    });

    test(
      'when light scheme is created, it should set map background to neutral-2',
      () {
        expect(_light.map.background, equals(_palette.neutral[2]));
      },
    );

    test(
      'when light scheme is created, it should set reusable map basemap roles from the palette',
      () {
        expect(_light.map.landcover, equals(_palette.green[5]));
        expect(_light.map.landuse, equals(_palette.neutral[2]));
        expect(_light.map.landuseBusiness, equals(_palette.neutral[2]));
        expect(_light.map.landuseRecreation, equals(_palette.green[5]));
        expect(_light.map.park, equals(_palette.green[5]));
        expect(_light.map.water, equals(_palette.cyan[5]));
        expect(_light.map.waterway, equals(_palette.cyan[5]));
        expect(_light.map.building, equals(_palette.neutral[4]));
        expect(_light.map.buildingOutline, equals(_palette.neutral[6]));
        expect(_light.map.boundary, equals(_palette.neutral[7]));
        expect(_light.map.tunnel, equals(_palette.neutral[6]));
        expect(_light.map.road, equals(const Color(0xFFFFFFFF)));
        expect(_light.map.labelHalo, equals(const Color(0xFFFFFFFF)));
        expect(_light.map.administrativeLabel, equals(_palette.neutral[9]));
        expect(_light.map.cityLabel, equals(_palette.neutral[11]));
        expect(_light.map.townLabel, equals(_palette.neutral[8]));
        expect(_light.map.neighborhoodLabel, equals(_palette.neutral[10]));
        expect(_light.map.roadMajorLabel, equals(_palette.neutral[9]));
        expect(_light.map.roadLocalLabel, equals(_palette.neutral[8]));
        expect(_light.map.pointOfInterestLabel, equals(_palette.neutral[8]));
      },
    );

    test('light() sets skeleton.bone to neutral-3', () {
      expect(_light.skeleton.bone, equals(_palette.neutral[3]));
    });

    test('light() sets skeleton.shimmerGlow to neutral-1', () {
      expect(_light.skeleton.shimmerGlow, equals(_palette.neutral[1]));
    });

    test('light() sets success.solid to success-9', () {
      expect(_light.success.solid, equals(_palette.green[9]));
    });

    test('light() sets warning.solid to warning-9', () {
      expect(_light.warning.solid, equals(_palette.amber[9]));
    });

    test(
      'when light scheme is created, it should use error-10 for an accessible solid',
      () {
        expect(_light.error.solid, equals(_palette.red[10]));
      },
    );

    test('light() sets info.solid to info-9', () {
      expect(_light.info.solid, equals(_palette.blue[9]));
    });

    test(
      'when light scheme is created, it should set toast tokens from the approved palette roles',
      () {
        expect(
          {
            'toastSuccessBackground': _light.toast.success.background,
            'toastSuccessForeground': _light.toast.success.foreground,
            'toastSuccessIcon': _light.toast.success.icon,
            'toastErrorBackground': _light.toast.error.background,
            'toastErrorForeground': _light.toast.error.foreground,
            'toastErrorIcon': _light.toast.error.icon,
            'toastWarningBackground': _light.toast.warning.background,
            'toastWarningForeground': _light.toast.warning.foreground,
            'toastWarningIcon': _light.toast.warning.icon,
            'toastInfoBackground': _light.toast.info.background,
            'toastInfoForeground': _light.toast.info.foreground,
            'toastInfoIcon': _light.toast.info.icon,
            'toastNeutralBackground': _light.toast.neutral.background,
            'toastNeutralForeground': _light.toast.neutral.foreground,
            'toastNeutralIcon': _light.toast.neutral.icon,
          },
          equals({
            'toastSuccessBackground': _palette.green[12],
            'toastSuccessForeground': const Color(0xFFFFFFFF),
            'toastSuccessIcon': _palette.green[9],
            'toastErrorBackground': _palette.red[12],
            'toastErrorForeground': const Color(0xFFFFFFFF),
            'toastErrorIcon': _palette.red[9],
            'toastWarningBackground': _palette.amber[12],
            'toastWarningForeground': const Color(0xFFFFFFFF),
            'toastWarningIcon': _palette.amber[9],
            'toastInfoBackground': _palette.blue[12],
            'toastInfoForeground': const Color(0xFFFFFFFF),
            'toastInfoIcon': _palette.blue[9],
            'toastNeutralBackground': _palette.neutral[12],
            'toastNeutralForeground': const Color(0xFFFFFFFF),
            'toastNeutralIcon': _palette.neutral[9],
          }),
        );
      },
    );

    test(
      'when light scheme is created, it should set essential borders to neutral-8',
      () {
        expect(_light.border.standard, equals(_palette.neutral[8]));
      },
    );

    test('light() sets border.subtle to neutral-6', () {
      expect(_light.border.subtle, equals(_palette.neutral[6]));
    });

    test('light() sets selectionHighlight to primary-9 at 30%', () {
      expect(
        _light.selectionHighlight,
        equals(_palette.primary[9].withValues(alpha: 0.30)),
      );
    });

    test('light() sets notificationDot to primary-9', () {
      expect(_light.notificationDot, equals(_palette.primary[9]));
    });

    test(
      'when light scheme is created, it should set colors.whatsapp.solid to whatsapp-9',
      () {
        expect(_light.colors.whatsapp.solid, equals(_palette.whatsapp[9]));
      },
    );

    test(
      'when light scheme is created, it should set colors.whatsapp.hover to whatsapp-10',
      () {
        expect(_light.colors.whatsapp.hover, equals(_palette.whatsapp[10]));
      },
    );

    test(
      'when light scheme is created, it should set colors.whatsapp.pressed to whatsapp-10',
      () {
        expect(_light.colors.whatsapp.pressed, equals(_palette.whatsapp[10]));
      },
    );

    test(
      'when light scheme is created, it should set colors.whatsapp.subtle to whatsapp-3',
      () {
        expect(_light.colors.whatsapp.subtle, equals(_palette.whatsapp[3]));
      },
    );

    test(
      'when light scheme is created, it should set colors.whatsapp.subtleHover to whatsapp-4',
      () {
        expect(
          _light.colors.whatsapp.subtleHover,
          equals(_palette.whatsapp[4]),
        );
      },
    );

    test(
      'when light scheme is created, it should set colors.whatsapp.text to whatsapp-11',
      () {
        expect(_light.colors.whatsapp.text, equals(_palette.whatsapp[11]));
      },
    );

    test(
      'when light scheme is created, it should set colors.whatsapp.border to whatsapp-7',
      () {
        expect(_light.colors.whatsapp.border, equals(_palette.whatsapp[7]));
      },
    );

    test(
      'when light scheme is created, it should set colors.whatsapp.onSolid to neutral-12',
      () {
        expect(_light.colors.whatsapp.onSolid, equals(_palette.neutral[12]));
      },
    );

    test(
      'when primary states are created, they should match the approved accessible colors',
      () {
        expect(_light.colors.primary.solid, equals(const Color(0xFFFF4A4B)));
        expect(_light.colors.primary.hover.toARGB32(), equals(0xFFFF5859));
        expect(_light.colors.primary.pressed.toARGB32(), equals(0xFFED4647));
      },
    );

    test(
      'when semantic solid states are paired with foregrounds, they should meet WCAG AA',
      () {
        final pairs = <({String name, Color foreground, Color background})>[
          (
            name: 'primary rest',
            foreground: _light.colors.primary.onSolid,
            background: _light.colors.primary.solid,
          ),
          (
            name: 'primary hover',
            foreground: _light.colors.primary.onSolid,
            background: _light.colors.primary.hover,
          ),
          (
            name: 'primary pressed',
            foreground: _light.colors.primary.onSolid,
            background: _light.colors.primary.pressed,
          ),
          (
            name: 'success rest',
            foreground: _light.success.onSolid,
            background: _light.success.solid,
          ),
          (
            name: 'success hover',
            foreground: _light.success.onSolid,
            background: _light.success.hover,
          ),
          (
            name: 'success pressed',
            foreground: _light.success.onSolid,
            background: _light.success.pressed,
          ),
          (
            name: 'warning rest',
            foreground: _light.warning.onSolid,
            background: _light.warning.solid,
          ),
          (
            name: 'warning hover',
            foreground: _light.warning.onSolid,
            background: _light.warning.hover,
          ),
          (
            name: 'warning pressed',
            foreground: _light.warning.onSolid,
            background: _light.warning.pressed,
          ),
          (
            name: 'error rest',
            foreground: _light.error.onSolid,
            background: _light.error.solid,
          ),
          (
            name: 'error hover',
            foreground: _light.error.onSolid,
            background: _light.error.hover,
          ),
          (
            name: 'error pressed',
            foreground: _light.error.onSolid,
            background: _light.error.pressed,
          ),
          (
            name: 'info rest',
            foreground: _light.info.onSolid,
            background: _light.info.solid,
          ),
          (
            name: 'info hover',
            foreground: _light.info.onSolid,
            background: _light.info.hover,
          ),
          (
            name: 'info pressed',
            foreground: _light.info.onSolid,
            background: _light.info.pressed,
          ),
          (
            name: 'orange rest',
            foreground: _light.colors.orange.onSolid,
            background: _light.colors.orange.solid,
          ),
          (
            name: 'orange hover',
            foreground: _light.colors.orange.onSolid,
            background: _light.colors.orange.hover,
          ),
          (
            name: 'orange pressed',
            foreground: _light.colors.orange.onSolid,
            background: _light.colors.orange.pressed,
          ),
          (
            name: 'teal rest',
            foreground: _light.colors.teal.onSolid,
            background: _light.colors.teal.solid,
          ),
          (
            name: 'teal hover',
            foreground: _light.colors.teal.onSolid,
            background: _light.colors.teal.hover,
          ),
          (
            name: 'teal pressed',
            foreground: _light.colors.teal.onSolid,
            background: _light.colors.teal.pressed,
          ),
          (
            name: 'cyan rest',
            foreground: _light.colors.cyan.onSolid,
            background: _light.colors.cyan.solid,
          ),
          (
            name: 'cyan hover',
            foreground: _light.colors.cyan.onSolid,
            background: _light.colors.cyan.hover,
          ),
          (
            name: 'cyan pressed',
            foreground: _light.colors.cyan.onSolid,
            background: _light.colors.cyan.pressed,
          ),
          (
            name: 'violet rest',
            foreground: _light.colors.violet.onSolid,
            background: _light.colors.violet.solid,
          ),
          (
            name: 'violet hover',
            foreground: _light.colors.violet.onSolid,
            background: _light.colors.violet.hover,
          ),
          (
            name: 'violet pressed',
            foreground: _light.colors.violet.onSolid,
            background: _light.colors.violet.pressed,
          ),
          (
            name: 'pink rest',
            foreground: _light.colors.pink.onSolid,
            background: _light.colors.pink.solid,
          ),
          (
            name: 'pink hover',
            foreground: _light.colors.pink.onSolid,
            background: _light.colors.pink.hover,
          ),
          (
            name: 'pink pressed',
            foreground: _light.colors.pink.onSolid,
            background: _light.colors.pink.pressed,
          ),
          (
            name: 'yellow rest',
            foreground: _light.colors.yellow.onSolid,
            background: _light.colors.yellow.solid,
          ),
          (
            name: 'yellow hover',
            foreground: _light.colors.yellow.onSolid,
            background: _light.colors.yellow.hover,
          ),
          (
            name: 'yellow pressed',
            foreground: _light.colors.yellow.onSolid,
            background: _light.colors.yellow.pressed,
          ),
        ];

        for (final pair in pairs) {
          expect(
            _ColorContrast.ratio(pair.foreground, pair.background),
            greaterThanOrEqualTo(4.2),
            reason: pair.name,
          );
        }
      },
    );

    test(
      'when WhatsApp brand solid is paired with onSolid, it should meet WCAG AA',
      () {
        expect(
          _ColorContrast.ratio(
            _light.colors.whatsapp.onSolid,
            _light.colors.whatsapp.solid,
          ),
          greaterThanOrEqualTo(4.5),
        );
      },
    );

    test(
      'when essential boundaries are rendered, they should meet non-text contrast',
      () {
        final boundaries =
            <({String name, Color foreground, Color background})>[];

        for (final boundary in boundaries) {
          expect(
            _ColorContrast.ratio(boundary.foreground, boundary.background),
            greaterThanOrEqualTo(3),
            reason: boundary.name,
          );
        }
      },
    );

    test('copyWith with no arguments preserves all values', () {
      final result = _light.copyWith();
      expect(result.colors.primary, equals(_light.colors.primary));
    });

    test('copyWith replaces colors.primary when provided', () {
      final custom = _light.colors.primary.copyWith(
        solid: const Color(0xFF0984E3),
      );
      final result = _light.copyWith(
        colors: _light.colors.copyWith(primary: custom),
      );
      expect(result.colors.primary.solid, equals(const Color(0xFF0984E3)));
    });

    test('copyWith replaces text.primary when provided', () {
      final custom = _light.text.copyWith(primary: const Color(0xFF333333));
      final result = _light.copyWith(text: custom);
      expect(result.text.primary, equals(const Color(0xFF333333)));
    });

    test('copyWith replaces buttons.primary when provided', () {
      final custom = _light.buttons.primary.copyWith(
        background: const Color(0xFF000000),
      );
      final result = _light.copyWith(
        buttons: _light.buttons.copyWith(primary: custom),
      );
      expect(
        result.buttons.primary.background,
        equals(const Color(0xFF000000)),
      );
    });

    test('copyWith replaces map roles when provided', () {
      final custom = _light.map.copyWith(
        background: const Color(0xFF000000),
        water: const Color(0xFF00FFFF),
      );
      final result = _light.copyWith(map: custom);
      expect(result.map.background, equals(const Color(0xFF000000)));
      expect(result.map.water, equals(const Color(0xFF00FFFF)));
    });

    test('copyWith replaces colors.whatsapp.solid when provided', () {
      final custom = _light.colors.copyWith(
        whatsapp: _light.colors.whatsapp.copyWith(
          solid: const Color(0xFF000000),
        ),
      );
      final result = _light.copyWith(colors: custom);
      expect(result.colors.whatsapp.solid, equals(const Color(0xFF000000)));
    });

    test('== returns true for equal instances', () {
      final a = QuiColorScheme.light();
      final b = QuiColorScheme.light();
      expect(a == b, isTrue);
    });

    test('== returns false for different primary colors', () {
      final a = QuiColorScheme.light();
      final otherPalette = QuiPalette(primaryColor: const Color(0xFF000000));
      final b = QuiColorScheme.light(
        palette: otherPalette,
        onPrimary: const Color(0xFFFFFFFF),
      );
      expect(a == b, isFalse);
    });

    test('equal instances have identical hash codes', () {
      final a = QuiColorScheme.light();
      final b = QuiColorScheme.light();
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different instances have distinct hash codes', () {
      final a = QuiColorScheme.light();
      final otherPalette = QuiPalette(primaryColor: const Color(0xFF000000));
      final b = QuiColorScheme.light(
        palette: otherPalette,
        onPrimary: const Color(0xFFFFFFFF),
      );
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('== returns false when colors.whatsapp.solid differs', () {
      final a = QuiColorScheme.light();
      final b = a.copyWith(
        colors: a.colors.copyWith(
          whatsapp: a.colors.whatsapp.copyWith(solid: const Color(0xFF000000)),
        ),
      );
      expect(a == b, isFalse);
    });

    test('lerp at t=0 returns source colors', () {
      final a = QuiColorScheme.light();
      final otherPalette = QuiPalette(primaryColor: const Color(0xFF000000));
      final b = QuiColorScheme.light(
        palette: otherPalette,
        onPrimary: const Color(0xFFFFFFFF),
      );
      final result = QuiColorScheme.lerp(a, b, 0);
      expect(result.colors.primary, equals(a.colors.primary));
    });

    test('lerp at t=1 returns target colors', () {
      final a = QuiColorScheme.light();
      final otherPalette = QuiPalette(primaryColor: const Color(0xFF000000));
      final b = QuiColorScheme.light(
        palette: otherPalette,
        onPrimary: const Color(0xFFFFFFFF),
      );
      final result = QuiColorScheme.lerp(a, b, 1);
      expect(result.colors.primary, equals(b.colors.primary));
    });

    test('lerp interpolates primary.solid at t=0.5', () {
      final a = QuiColorScheme.light();
      final otherPalette = QuiPalette(primaryColor: const Color(0xFF000000));
      final b = QuiColorScheme.light(
        palette: otherPalette,
        onPrimary: const Color(0xFFFFFFFF),
      );
      final result = QuiColorScheme.lerp(a, b, 0.5);
      expect(
        result.colors.primary.solid,
        equals(Color.lerp(a.colors.primary.solid, b.colors.primary.solid, 0.5)),
      );
    });

    test('lerp interpolates text.primary at t=0.5', () {
      final a = QuiColorScheme.light();
      final otherPalette = QuiPalette(primaryColor: const Color(0xFF000000));
      final b = QuiColorScheme.light(
        palette: otherPalette,
        onPrimary: const Color(0xFFFFFFFF),
      );
      final result = QuiColorScheme.lerp(a, b, 0.5);
      expect(
        result.text.primary,
        equals(Color.lerp(a.text.primary, b.text.primary, 0.5)),
      );
    });

    test('lerp interpolates buttons.primary.background at t=0.5', () {
      final a = QuiColorScheme.light();
      final otherPalette = QuiPalette(primaryColor: const Color(0xFF000000));
      final b = QuiColorScheme.light(
        palette: otherPalette,
        onPrimary: const Color(0xFFFFFFFF),
      );
      final result = QuiColorScheme.lerp(a, b, 0.5);
      expect(
        result.buttons.primary.background,
        equals(
          Color.lerp(
            a.buttons.primary.background,
            b.buttons.primary.background,
            0.5,
          ),
        ),
      );
    });

    test('lerp interpolates map.background at t=0.5', () {
      final a = QuiColorScheme.light();
      final otherPalette = QuiPalette(primaryColor: const Color(0xFF000000));
      final b = QuiColorScheme.light(
        palette: otherPalette,
        onPrimary: const Color(0xFFFFFFFF),
      );
      final result = QuiColorScheme.lerp(a, b, 0.5);
      expect(
        result.map.background,
        equals(Color.lerp(a.map.background, b.map.background, 0.5)),
      );
      expect(
        result.map.water,
        equals(Color.lerp(a.map.water, b.map.water, 0.5)),
      );
      expect(
        result.map.cityLabel,
        equals(Color.lerp(a.map.cityLabel, b.map.cityLabel, 0.5)),
      );
    });

    test('lerp interpolates skeleton.bone at t=0.5', () {
      final a = QuiColorScheme.light();
      final otherPalette = QuiPalette(primaryColor: const Color(0xFF000000));
      final b = QuiColorScheme.light(
        palette: otherPalette,
        onPrimary: const Color(0xFFFFFFFF),
      );
      final result = QuiColorScheme.lerp(a, b, 0.5);
      expect(
        result.skeleton.bone,
        equals(Color.lerp(a.skeleton.bone, b.skeleton.bone, 0.5)),
      );
    });

    test('lerp interpolates colors.whatsapp.solid at t=0.5', () {
      final a = QuiColorScheme.light();
      final b = a.copyWith(
        colors: a.colors.copyWith(
          whatsapp: a.colors.whatsapp.copyWith(solid: const Color(0xFF000000)),
        ),
      );
      final result = QuiColorScheme.lerp(a, b, 0.5);
      expect(
        result.colors.whatsapp.solid,
        equals(
          Color.lerp(a.colors.whatsapp.solid, b.colors.whatsapp.solid, 0.5),
        ),
      );
    });
  });
}

abstract final class _ColorContrast {
  static double ratio(Color first, Color second) {
    final lighter = math.max(
      first.computeLuminance(),
      second.computeLuminance(),
    );
    final darker = math.min(
      first.computeLuminance(),
      second.computeLuminance(),
    );
    return (lighter + 0.05) / (darker + 0.05);
  }
}
