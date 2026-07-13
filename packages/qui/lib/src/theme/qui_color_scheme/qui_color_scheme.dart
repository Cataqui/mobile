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

@immutable
class QuiColorScheme {
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

  factory QuiColorScheme.light({QuiPalette? palette, Color? onPrimary}) =>
      _LightQuiColorScheme(palette: palette ?? QuiPalette(), onPrimary: onPrimary);

  final Color background;
  final QuiTextColorScheme text;

  final QuiBorderColorScheme border;

  final QuiColorsColorScheme colors;

  final QuiColorVariantColorScheme success;
  final QuiColorVariantColorScheme warning;
  final QuiColorVariantColorScheme error;
  final QuiColorVariantColorScheme info;

  final Color selectionHighlight;

  final Color scrim;

  final Color notificationDot;

  final QuiButtonsColorScheme buttons;
  final QuiOverlayColorScheme overlay;
  final QuiToastColorScheme toast;
  final QuiDividerColorScheme divider;
  final QuiScrollbarColorScheme scrollbar;
  final QuiSkeletonColorScheme skeleton;
  final QuiInverseColorScheme inverse;
  final QuiControlsColorScheme controls;
  final QuiMapColorScheme map;

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

  static QuiColorScheme lerp(QuiColorScheme a, QuiColorScheme b, double t) {
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
}
