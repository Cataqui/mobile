import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';
import 'package:qui/src/widgets/qui_tap_animation.dart';

part 'qui_secondary_button_enums.dart';
part 'qui_secondary_button_types.dart';

/// A pill-shaped secondary action button for the QUI design system.
///
/// ```dart
/// QuiSecondaryButton(
///   label: 'Ver oportunidades',
///   onPressed: () {},
/// )
/// ```
class QuiSecondaryButton extends StatelessWidget {
  /// Creates a Cataquí secondary button.
  const QuiSecondaryButton({
    required this.label,
    super.key,
    this.onPressed,
    this.leadingIconBuilder,
    this.trailingIconBuilder,
    this.leadingIconSpacing = 8,
    this.trailingIconSpacing = 8,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.foregroundColor,
    this.disabledForegroundColor,
    this.fit = QuiSecondaryButtonFit.fit,
  });

  /// Visible button label.
  final String label;

  /// Called when the button is pressed.
  ///
  /// When null, the button renders disabled and ignores pointer input.
  final VoidCallback? onPressed;

  /// Optional icon rendered before [label].
  final QuiSecondaryButtonIconBuilder? leadingIconBuilder;

  /// Optional icon rendered after [label].
  final QuiSecondaryButtonIconBuilder? trailingIconBuilder;

  /// Horizontal spacing between [leadingIconBuilder]'s icon and [label].
  final double leadingIconSpacing;

  /// Horizontal spacing between [label] and [trailingIconBuilder]'s icon.
  final double trailingIconSpacing;

  /// Filled background color when enabled.
  ///
  /// Defaults to `colors.primary` with 0.1 opacity.
  final Color? backgroundColor;

  /// Filled background color when disabled.
  ///
  /// Defaults to `context.qui.colors.disabledButtonBackground`.
  final Color? disabledBackgroundColor;

  /// Label and recommended icon color when enabled.
  ///
  /// Defaults to `context.qui.colors.primary`.
  final Color? foregroundColor;

  /// Label and recommended icon color when disabled.
  ///
  /// Defaults to `context.qui.colors.disabledButtonForeground`.
  final Color? disabledForegroundColor;

  /// Controls the width sizing behavior.
  ///
  /// [QuiSecondaryButtonFit.fit] shrink-wraps the button to its content.
  /// [QuiSecondaryButtonFit.expand] fills the available horizontal width.
  final QuiSecondaryButtonFit fit;

  bool get _isEnabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.qui.colors;
    final isEnabled = _isEnabled;

    final resolvedBackground = isEnabled
        ? backgroundColor ?? colors.primary.withValues(alpha: 0.1)
        : disabledBackgroundColor ?? colors.disabledButtonBackground;

    final resolvedForeground = isEnabled
        ? foregroundColor ?? colors.primary
        : disabledForegroundColor ?? colors.disabledButtonForeground;

    final labelStyle = context.qui.typography.bodyLarge.copyWith(
      fontWeight: FontWeight.w600,
      color: resolvedForeground,
    );

    Widget content = Text(label, style: labelStyle);

    final iconState = QuiSecondaryButtonIconState(isEnabled: isEnabled, foregroundColor: resolvedForeground);

    final hasLeading = leadingIconBuilder != null;
    final hasTrailing = trailingIconBuilder != null;

    if (hasLeading || hasTrailing) {
      final children = <Widget>[];

      if (hasLeading) {
        children.add(
          Padding(
            padding: EdgeInsets.only(right: leadingIconSpacing),
            child: leadingIconBuilder!(iconState),
          ),
        );
      }
      children.add(content);

      if (hasTrailing) {
        children.add(
          Padding(
            padding: EdgeInsets.only(left: trailingIconSpacing),
            child: trailingIconBuilder!(iconState),
          ),
        );
      }
      content = Row(mainAxisSize: MainAxisSize.min, children: children);
    }

    final button = Container(
      key: const Key('qui_secondary_button_container'),
      width: fit == QuiSecondaryButtonFit.expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(color: resolvedBackground, borderRadius: BorderRadius.circular(9999)),
      child: fit == QuiSecondaryButtonFit.expand ? Center(child: content) : content,
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      onTap: isEnabled ? onPressed : null,
      child: QuiTapAnimation(
        onPressed: onPressed != null
            ? (animation) async {
                onPressed!();
              }
            : null,
        animation: QuiTapAnimationType.scaleFade,
        child: button,
      ),
    );
  }
}

/// Preview of the [QuiSecondaryButton] widget.
@Preview(name: 'QuiSecondaryButton', group: 'Buttons')
Widget quiSecondaryButtonPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuiSecondaryButton(label: 'Ver oportunidades', onPressed: () {}),
            const SizedBox(height: 20),
            QuiSecondaryButton(
              label: 'Buscar',
              leadingIconBuilder: (state) => Icon(Icons.search, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            QuiSecondaryButton(
              label: 'Continuar',
              trailingIconBuilder: (state) => Icon(Icons.arrow_forward, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            QuiSecondaryButton(
              label: 'Filtrar',
              leadingIconBuilder: (state) => Icon(Icons.tune, color: state.foregroundColor, size: 20),
              trailingIconBuilder: (state) => Icon(Icons.arrow_drop_down, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            QuiSecondaryButton(
              label: 'Indisponivel',
              leadingIconBuilder: (state) => Icon(Icons.lock, color: state.foregroundColor, size: 20),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: QuiSecondaryButton(label: 'Expandido', fit: QuiSecondaryButtonFit.expand, onPressed: () {}),
            ),
          ],
        ),
      ),
    ),
  );
}
