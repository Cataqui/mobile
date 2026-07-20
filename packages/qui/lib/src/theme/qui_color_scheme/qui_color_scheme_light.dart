part of 'qui_color_scheme.dart';

class _LightQuiColorScheme extends QuiColorScheme {
  factory _LightQuiColorScheme({required QuiPalette palette, Color? onPrimary}) {
    return _LightQuiColorScheme._(palette: palette, onPrimary: onPrimary ?? const Color(0xFFFFFFFF));
  }

  _LightQuiColorScheme._({required QuiPalette palette, required Color onPrimary})
    : super(
        background: _background,

        text: QuiTextColorScheme(
          primary: palette.neutral[12],
          secondary: palette.neutral[10],
          tertiary: palette.neutral[9],
          placeholder: palette.neutral[11],
          disabled: palette.neutral[9],
          inverse: const Color(0xFFFFFFFF),
          brandPrimary: palette.primary[11],
          success: palette.green[11],
          warning: palette.amber[11],
          error: palette.red[11],
          info: palette.blue[11],
          profit: palette.green[10],
        ),

        border: QuiBorderColorScheme(
          standard: palette.neutral[8],
          subtle: palette.neutral[6],
          hover: palette.neutral[9],
          disabled: palette.neutral[5],
          focus: palette.primary[9],
          error: palette.red[9],
          success: palette.green[11],
          translucent: const Color(0x14000000),
        ),

        colors: QuiColorsColorScheme(
          primary: QuiColorVariantColorScheme(
            solid: palette.primary[9],
            hover: _hoverColor(background: palette.primary[9], foreground: onPrimary, dark: palette.neutral[12]),
            pressed: _pressedColor(background: palette.primary[9], foreground: onPrimary, dark: palette.neutral[12]),
            subtle: palette.primary[3],
            subtleHover: palette.primary[4],
            subtlePressed: palette.primary[5],
            text: palette.primary[11],
            border: palette.primary[7],
            onSolid: onPrimary,
          ),
          neutral: QuiColorVariantColorScheme(
            solid: palette.neutral[12],
            hover: palette.neutral[11],
            pressed: palette.neutral[11],
            subtle: palette.neutral[3],
            subtleHover: palette.neutral[4],
            subtlePressed: palette.neutral[5],
            text: palette.neutral[11],
            border: palette.neutral[7],
            onSolid: const Color(0xFFFFFFFF),
          ),
          orange: QuiColorVariantColorScheme(
            solid: palette.orange[9],
            hover: palette.orange[10],
            pressed: palette.orange[10],
            subtle: palette.orange[3],
            subtleHover: palette.orange[4],
            subtlePressed: palette.orange[5],
            text: palette.orange[11],
            border: palette.orange[7],
            onSolid: palette.neutral[12],
          ),
          teal: QuiColorVariantColorScheme(
            solid: palette.teal[9],
            hover: palette.teal[10],
            pressed: palette.teal[10],
            subtle: palette.teal[3],
            subtleHover: palette.teal[4],
            subtlePressed: palette.teal[5],
            text: palette.teal[11],
            border: palette.teal[7],
            onSolid: palette.neutral[12],
          ),
          cyan: QuiColorVariantColorScheme(
            solid: palette.cyan[9],
            hover: palette.cyan[10],
            pressed: palette.cyan[10],
            subtle: palette.cyan[3],
            subtleHover: palette.cyan[4],
            subtlePressed: palette.cyan[5],
            text: palette.cyan[11],
            border: palette.cyan[7],
            onSolid: palette.neutral[12],
          ),
          violet: QuiColorVariantColorScheme(
            solid: palette.violet[9],
            hover: palette.violet[10],
            pressed: palette.violet[10],
            subtle: palette.violet[3],
            subtleHover: palette.violet[4],
            subtlePressed: palette.violet[5],
            text: palette.violet[11],
            border: palette.violet[7],
            onSolid: const Color(0xFFFFFFFF),
          ),
          pink: QuiColorVariantColorScheme(
            solid: palette.pink[10],
            hover: palette.pink[11],
            pressed: palette.pink[11],
            subtle: palette.pink[3],
            subtleHover: palette.pink[4],
            subtlePressed: palette.pink[5],
            text: palette.pink[11],
            border: palette.pink[7],
            onSolid: const Color(0xFFFFFFFF),
          ),
          yellow: QuiColorVariantColorScheme(
            solid: palette.yellow[9],
            hover: palette.yellow[10],
            pressed: palette.yellow[10],
            subtle: palette.yellow[3],
            subtleHover: palette.yellow[4],
            subtlePressed: palette.yellow[5],
            text: palette.yellow[11],
            border: palette.yellow[7],
            onSolid: palette.neutral[12],
          ),
          whatsapp: QuiColorVariantColorScheme(
            solid: palette.whatsapp[9],
            hover: palette.whatsapp[10],
            pressed: palette.whatsapp[10],
            subtle: palette.whatsapp[3],
            subtleHover: palette.whatsapp[4],
            subtlePressed: palette.whatsapp[5],
            text: palette.whatsapp[11],
            border: palette.whatsapp[7],
            onSolid: palette.neutral[12],
          ),
        ),

        success: QuiColorVariantColorScheme(
          solid: palette.green[9],
          hover: palette.green[10],
          pressed: palette.green[10],
          subtle: palette.green[3],
          subtleHover: palette.green[4],
          subtlePressed: palette.green[5],
          onSolid: palette.neutral[12],
          text: palette.green[11],
          border: palette.green[11],
        ),

        warning: QuiColorVariantColorScheme(
          solid: palette.amber[9],
          hover: palette.amber[10],
          pressed: palette.amber[10],
          subtle: palette.amber[3],
          subtleHover: palette.amber[4],
          subtlePressed: palette.amber[5],
          onSolid: palette.neutral[12],
          text: palette.amber[11],
          border: palette.amber[11],
        ),

        error: QuiColorVariantColorScheme(
          solid: palette.red[10],
          hover: palette.red[11],
          pressed: palette.red[11],
          subtle: palette.red[3],
          subtleHover: palette.red[4],
          subtlePressed: palette.red[5],
          onSolid: const Color(0xFFFFFFFF),
          text: palette.red[11],
          border: palette.red[9],
        ),

        info: QuiColorVariantColorScheme(
          solid: palette.blue[9],
          hover: palette.blue[10],
          pressed: palette.blue[10],
          subtle: palette.blue[3],
          subtleHover: palette.blue[4],
          subtlePressed: palette.blue[5],
          onSolid: palette.neutral[12],
          text: palette.blue[11],
          border: palette.blue[9],
        ),

        selectionHighlight: palette.primary[9].withValues(alpha: 0.30),

        scrim: const Color(0x66000000),

        notificationDot: palette.primary[9],

        buttons: QuiButtonsColorScheme(
          primary: QuiButtonColorScheme(
            background: palette.primary[9],
            backgroundHover: _hoverColor(
              background: palette.primary[9],
              foreground: onPrimary,
              dark: palette.neutral[12],
            ),
            backgroundDisabled: palette.neutral[4],
            foreground: onPrimary,
            foregroundDisabled: palette.neutral[9],
          ),
          secondary: QuiButtonColorScheme(
            background: palette.primary[2],
            backgroundHover: palette.primary[3],
            backgroundDisabled: palette.neutral[4],
            foreground: palette.primary[9],
            foregroundDisabled: palette.neutral[9],
          ),
          tertiary: QuiButtonColorScheme(
            background: palette.neutral[12],
            backgroundHover: palette.neutral[11],
            backgroundDisabled: palette.neutral[4],
            foreground: const Color(0xFFFFFFFF),
            foregroundDisabled: palette.neutral[9],
          ),
          text: QuiButtonColorScheme(
            background: const Color(0x00000000),
            backgroundHover: palette.neutral[12].withValues(alpha: 0.05),
            backgroundDisabled: const Color(0x00000000),
            foreground: palette.neutral[12],
            foregroundDisabled: palette.neutral[9],
          ),
          danger: QuiButtonColorScheme(
            background: palette.red[10],
            backgroundHover: _hoverColor(
              background: palette.red[10],
              foreground: const Color(0xFFFFFFFF),
              dark: palette.neutral[12],
            ),
            backgroundDisabled: palette.neutral[4],
            foreground: const Color(0xFFFFFFFF),
            foregroundDisabled: palette.neutral[9],
          ),
          success: QuiButtonColorScheme(
            background: palette.green[9],
            backgroundHover: _hoverColor(
              background: palette.green[9],
              foreground: palette.neutral[12],
              dark: palette.neutral[12],
            ),
            backgroundDisabled: palette.neutral[4],
            foreground: palette.neutral[12],
            foregroundDisabled: palette.neutral[9],
          ),
          floating: QuiFloatingButtonColorScheme(
            background: const Color(0xFFFFFFFF),
            backgroundHover: palette.neutral[4],
            backgroundDisabled: palette.neutral[4],
            foreground: palette.neutral[12],
            foregroundDisabled: palette.neutral[9],
            border: palette.neutral[1],
            shadow: const Color(0x1A000000),
          ),
          whatsapp: QuiBrandedButtonColorScheme(
            primary: QuiButtonColorScheme(
              background: palette.whatsapp[9],
              backgroundHover: palette.whatsapp[10],
              backgroundDisabled: palette.neutral[4],
              foreground: palette.neutral[12],
              foregroundDisabled: palette.neutral[9],
            ),
            secondary: QuiButtonColorScheme(
              background: palette.whatsapp[3],
              backgroundHover: palette.whatsapp[4],
              backgroundDisabled: palette.neutral[4],
              foreground: palette.whatsapp[11],
              foregroundDisabled: palette.neutral[9],
            ),
            tertiary: QuiButtonColorScheme(
              background: palette.whatsapp[12],
              backgroundHover: palette.whatsapp[11],
              backgroundDisabled: palette.neutral[4],
              foreground: palette.whatsapp,
              foregroundDisabled: palette.neutral[9],
            ),
          ),
        ),

        overlay: const QuiOverlayColorScheme(scrim: Color(0x66000000)),

        bottomSheet: QuiBottomSheetColorScheme(background: _background, handle: palette.neutral[6]),

        toast: QuiToastColorScheme(
          success: QuiToastVariantColorScheme(
            background: palette.green[12],
            foreground: const Color(0xFFFFFFFF),
            icon: palette.green[9],
          ),
          error: QuiToastVariantColorScheme(
            background: palette.red[12],
            foreground: const Color(0xFFFFFFFF),
            icon: palette.red[9],
          ),
          warning: QuiToastVariantColorScheme(
            background: palette.amber[12],
            foreground: const Color(0xFFFFFFFF),
            icon: palette.amber[9],
          ),
          info: QuiToastVariantColorScheme(
            background: palette.blue[12],
            foreground: const Color(0xFFFFFFFF),
            icon: palette.blue[9],
          ),
          neutral: QuiToastVariantColorScheme(
            background: palette.neutral[12],
            foreground: const Color(0xFFFFFFFF),
            icon: palette.neutral[9],
          ),
        ),

        divider: QuiDividerColorScheme(standard: palette.neutral[6], strong: palette.neutral[7]),

        scrollbar: QuiScrollbarColorScheme(
          thumb: palette.neutral[9],
          thumbHover: palette.neutral[10],
          track: const Color(0x00000000),
        ),

        skeleton: QuiSkeletonColorScheme(
          bone: palette.neutral[3],
          shimmerGlow: palette.neutral[1],
          skeletonText: palette.neutral[8],
          skeletonTextGlow: palette.neutral[4],
        ),

        inverse: QuiInverseColorScheme(
          background: palette.neutral[12],
          onBackground: const Color(0xFFFFFFFF),
          primary: palette.primary[3],
        ),

        controls: QuiControlsColorScheme(
          track: palette.neutral[8],
          trackFilled: palette.primary[9],
          indicator: palette.primary[9],
          indicatorForeground: const Color(0xFFFFFFFF),
          caret: palette.primary[9],
        ),

        map: QuiMapColorScheme(
          background: palette.neutral[2],
          landcover: palette.green[5],
          landuse: palette.neutral[2],
          landuseBusiness: palette.neutral[2],
          landuseRecreation: palette.green[5],
          park: palette.green[5],
          water: palette.cyan[5],
          waterway: palette.cyan[5],
          building: palette.neutral[4],
          buildingOutline: palette.neutral[6],
          boundary: palette.neutral[7],
          tunnel: palette.neutral[6],
          road: const Color(0xFFFFFFFF),
          labelHalo: const Color(0xFFFFFFFF),
          administrativeLabel: palette.neutral[9],
          cityLabel: palette.neutral[11],
          townLabel: palette.neutral[8],
          neighborhoodLabel: palette.neutral[10],
          roadMajorLabel: palette.neutral[9],
          roadLocalLabel: palette.neutral[8],
          pointOfInterestLabel: palette.neutral[8],
          locationRadius: palette.cyan[9].withValues(alpha: 0.15),
        ),
      );

  static const Color _background = Colors.white;

  static Color _hoverColor({required Color background, required Color foreground, required Color dark}) {
    final overlay = foreground == const Color(0xFFFFFFFF) ? dark : const Color(0xFFFFFFFF);
    return Color.alphaBlend(overlay.withValues(alpha: 0.08), background);
  }

  static Color _pressedColor({required Color background, required Color foreground, required Color dark}) {
    final alpha = foreground == const Color(0xFFFFFFFF) ? 0.12 : 0.08;
    return Color.alphaBlend(dark.withValues(alpha: alpha), background);
  }
}
