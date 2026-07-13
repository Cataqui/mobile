/// Semantic color tokens for QUI themes.
///
/// [QuiColorScheme] is the mode-agnostic semantic color contract used by QUI.
/// It groups readable roles such as text, borders, status feedback, overlays,
/// controls, and component-specific button patterns into a single object that a
/// consuming app can read from its active QUI theme.
///
/// The semantic contract is intentionally separate from [QuiPalette]. The
/// palette provides configurable color scales, while [QuiColorScheme] exposes
/// the roles a package consumer needs when styling app UI. Read semantic roles
/// from [QuiColorScheme] instead of hardcoding assumptions about specific color
/// values or palette steps.
///
/// Use [QuiColorScheme.light] to create the current light-mode scheme. Other
/// brightness modes can expose the same semantic roles through additional
/// factories later.
library;

import 'package:flutter/material.dart';

import '../qui_palette/qui_palette.dart';

part 'qui_border_color_scheme.dart';
part 'qui_branded_button_color_scheme.dart';
part 'qui_button_color_scheme.dart';
part 'qui_buttons_color_scheme.dart';
part 'qui_color_scheme_light.dart';
part 'qui_colors_color_scheme.dart';
part 'qui_controls_color_scheme.dart';
part 'qui_divider_color_scheme.dart';
part 'qui_floating_button_color_scheme.dart';
part 'qui_inverse_color_scheme.dart';
part 'qui_map_color_scheme.dart';
part 'qui_overlay_color_scheme.dart';
part 'qui_scrollbar_color_scheme.dart';
part 'qui_skeleton_color_scheme.dart';
part 'qui_text_color_scheme.dart';
part 'qui_toast_color_scheme.dart';

/// {@template qui_color_scheme_copy_with}
/// Creates a copy of this scheme with the provided overrides.
///
/// Unspecified parameters preserve the corresponding value from this instance.
/// Use this to adapt a scheme for an app brand, screen, or embedded package
/// without rebuilding every role.
/// {@endtemplate}
///
/// {@template qui_color_scheme_lerp}
/// Creates interpolated semantic tokens between `a` and `b`.
///
/// Use this for animated theme transitions and [ThemeExtension] interpolation.
/// Consumers normally read the resulting scheme from the active theme rather
/// than calling this directly.
/// {@endtemplate}
///
/// A semantic color contract for the active QUI theme.
///
/// This object is the top-level entrypoint for reading QUI color roles. It
/// organizes the theme into stable groups so package consumers can choose the
/// right role without inferring meaning from raw [Color] values.
///
/// Read top-level properties such as [QuiColorScheme.background],
/// [QuiColorScheme.selectionHighlight], and [QuiColorScheme.scrim] for shared
/// surface roles. Read grouped properties such as [QuiColorScheme.text],
/// [QuiColorScheme.border], [QuiColorScheme.colors],
/// [QuiColorScheme.buttons], and [QuiColorScheme.map] when a UI concern has
/// its own dedicated token family.
///
/// Prefer consuming this contract through the active QUI theme extension, such
/// as `context.qui.colorScheme`, so UI code follows the package theme selected
/// by the app.
///
/// ```dart
/// final QuiColorScheme colorScheme = context.qui.colorScheme;
///
/// Container(
///   color: colorScheme.background,
///   child: Text(
///     'Opportunity',
///     style: TextStyle(color: colorScheme.text.primary),
///   ),
/// )
/// ```
///
/// See also:
///  * [QuiPalette], the configurable color scales used to create semantic
///    roles.
///  * `QuiThemeData`, the `ThemeExtension` that exposes this contract to a
///    Material theme.
///  * `QuiTheme`, the helper that builds QUI-integrated theme data.
@immutable
class QuiColorScheme {
  /// Creates a semantic QUI color contract from already-resolved role groups.
  ///
  /// Use this when an app or package needs to provide every color role
  /// explicitly, such as for a custom brand theme.
  const QuiColorScheme({
    required this.background,
    required this.text,
    required this.border,
    required this.colors,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.selectionHighlight,
    required this.scrim,
    required this.notificationDot,
    required this.buttons,
    required this.overlay,
    required this.toast,
    required this.divider,
    required this.scrollbar,
    required this.skeleton,
    required this.inverse,
    required this.controls,
    required this.map,
  });

  /// {@macro qui_color_scheme_lerp}
  factory QuiColorScheme.lerp(QuiColorScheme a, QuiColorScheme b, double t) {
    return QuiColorScheme(
      background: Color.lerp(a.background, b.background, t)!,
      text: QuiTextColorScheme.lerp(a.text, b.text, t),
      border: QuiBorderColorScheme.lerp(a.border, b.border, t),
      colors: QuiColorsColorScheme.lerp(a.colors, b.colors, t),
      success: QuiColorVariantColorScheme.lerp(a.success, b.success, t),
      warning: QuiColorVariantColorScheme.lerp(a.warning, b.warning, t),
      error: QuiColorVariantColorScheme.lerp(a.error, b.error, t),
      info: QuiColorVariantColorScheme.lerp(a.info, b.info, t),
      selectionHighlight: Color.lerp(a.selectionHighlight, b.selectionHighlight, t)!,
      scrim: Color.lerp(a.scrim, b.scrim, t)!,
      notificationDot: Color.lerp(a.notificationDot, b.notificationDot, t)!,
      buttons: QuiButtonsColorScheme.lerp(a.buttons, b.buttons, t),
      overlay: QuiOverlayColorScheme.lerp(a.overlay, b.overlay, t),
      toast: QuiToastColorScheme.lerp(a.toast, b.toast, t),
      divider: QuiDividerColorScheme.lerp(a.divider, b.divider, t),
      scrollbar: QuiScrollbarColorScheme.lerp(a.scrollbar, b.scrollbar, t),
      skeleton: QuiSkeletonColorScheme.lerp(a.skeleton, b.skeleton, t),
      inverse: QuiInverseColorScheme.lerp(a.inverse, b.inverse, t),
      controls: QuiControlsColorScheme.lerp(a.controls, b.controls, t),
      map: QuiMapColorScheme.lerp(a.map, b.map, t),
    );
  }

  /// Creates the current light-mode scheme for [QuiColorScheme].
  ///
  /// The [palette] customizes the color scales used by the light scheme. The
  /// [onPrimary] color customizes the readable foreground placed on top of solid
  /// primary surfaces. This factory creates the current light scheme; future
  /// brightness modes can use the same role names with different values.
  factory QuiColorScheme.light({QuiPalette? palette, Color? onPrimary}) =>
      _LightQuiColorScheme(palette: palette ?? QuiPalette(), onPrimary: onPrimary);

  /// Primary background surface color for the active QUI theme.
  final Color background;

  /// Semantic text roles shared across QUI surfaces and states.
  final QuiTextColorScheme text;

  /// Semantic border and outline roles for standard UI states.
  final QuiBorderColorScheme border;

  /// Reusable semantic color families such as primary, accent, and branded sets.
  final QuiColorsColorScheme colors;

  /// Semantic success feedback colors for positive states and messaging.
  final QuiColorVariantColorScheme success;

  /// Semantic warning feedback colors for cautionary states and messaging.
  final QuiColorVariantColorScheme warning;

  /// Semantic error feedback colors for destructive or invalid states.
  final QuiColorVariantColorScheme error;

  /// Semantic informational feedback colors for neutral status messaging.
  final QuiColorVariantColorScheme info;

  /// Highlight color used for text selection and similar emphasized ranges.
  final Color selectionHighlight;

  /// Shared scrim color for modal, sheet, and overlay separation.
  final Color scrim;

  /// Accent color used for compact unread or attention-seeking indicators.
  final Color notificationDot;

  /// Component-pattern button roles grouped by button family and interaction style.
  final QuiButtonsColorScheme buttons;

  /// Overlay-specific semantic roles that complement shared surface tokens.
  final QuiOverlayColorScheme overlay;

  /// Semantic roles for toast backgrounds, foregrounds, and status accents.
  final QuiToastColorScheme toast;

  /// Semantic divider roles for subtle and strong separators.
  final QuiDividerColorScheme divider;

  /// Semantic roles for scrollbar thumb and track rendering.
  final QuiScrollbarColorScheme scrollbar;

  /// Semantic roles for skeleton placeholders and shimmer treatments.
  final QuiSkeletonColorScheme skeleton;

  /// High-contrast inverse surface roles used on dark or emphasized containers.
  final QuiInverseColorScheme inverse;

  /// Semantic control roles for tracks, indicators, and carets.
  final QuiControlsColorScheme controls;

  /// Semantic basemap roles for map rendering and map-adjacent UI.
  final QuiMapColorScheme map;

  /// {@macro qui_color_scheme_copy_with}
  QuiColorScheme copyWith({
    Color? background,
    QuiTextColorScheme? text,
    QuiBorderColorScheme? border,
    QuiColorsColorScheme? colors,
    QuiColorVariantColorScheme? success,
    QuiColorVariantColorScheme? warning,
    QuiColorVariantColorScheme? error,
    QuiColorVariantColorScheme? info,
    Color? selectionHighlight,
    Color? scrim,
    Color? notificationDot,
    QuiButtonsColorScheme? buttons,
    QuiOverlayColorScheme? overlay,
    QuiToastColorScheme? toast,
    QuiDividerColorScheme? divider,
    QuiScrollbarColorScheme? scrollbar,
    QuiSkeletonColorScheme? skeleton,
    QuiInverseColorScheme? inverse,
    QuiControlsColorScheme? controls,
    QuiMapColorScheme? map,
  }) {
    return QuiColorScheme(
      background: background ?? this.background,
      text: text ?? this.text,
      border: border ?? this.border,
      colors: colors ?? this.colors,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      selectionHighlight: selectionHighlight ?? this.selectionHighlight,
      scrim: scrim ?? this.scrim,
      notificationDot: notificationDot ?? this.notificationDot,
      buttons: buttons ?? this.buttons,
      overlay: overlay ?? this.overlay,
      toast: toast ?? this.toast,
      divider: divider ?? this.divider,
      scrollbar: scrollbar ?? this.scrollbar,
      skeleton: skeleton ?? this.skeleton,
      inverse: inverse ?? this.inverse,
      controls: controls ?? this.controls,
      map: map ?? this.map,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiColorScheme &&
          runtimeType == other.runtimeType &&
          background == other.background &&
          text == other.text &&
          border == other.border &&
          colors == other.colors &&
          success == other.success &&
          warning == other.warning &&
          error == other.error &&
          info == other.info &&
          selectionHighlight == other.selectionHighlight &&
          scrim == other.scrim &&
          notificationDot == other.notificationDot &&
          buttons == other.buttons &&
          overlay == other.overlay &&
          toast == other.toast &&
          divider == other.divider &&
          scrollbar == other.scrollbar &&
          skeleton == other.skeleton &&
          inverse == other.inverse &&
          controls == other.controls &&
          map == other.map;

  @override
  int get hashCode => Object.hashAll([
    background,
    text,
    border,
    colors,
    success,
    warning,
    error,
    info,
    selectionHighlight,
    scrim,
    notificationDot,
    buttons,
    overlay,
    toast,
    divider,
    scrollbar,
    skeleton,
    inverse,
    controls,
    map,
  ]);
}
