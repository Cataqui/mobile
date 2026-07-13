import 'package:flutter/material.dart';
import 'package:qui/src/enums/qui_button_alignment.dart';
import 'package:qui/src/enums/qui_button_fit.dart';
import 'package:qui/src/theme/qui_theme_context.dart';
import 'package:qui/src/widgets/qui_tap_animation.dart';

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
    this.alignment = QuiButtonAlignment.center,
    this.fit = QuiButtonFit.fit,
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

  /// Controls the horizontal alignment of the label and icons within the
  /// button bounds.
  ///
  /// Only has a visible effect when [fit] is [QuiButtonFit.expand],
  /// since a shrink-wrapped button is exactly as wide as its content.
  ///
  /// Defaults to [QuiButtonAlignment.center].
  final QuiButtonAlignment alignment;

  /// Controls the width sizing behavior.
  ///
  /// [QuiButtonFit.fit] shrink-wraps the button to its content.
  /// [QuiButtonFit.expand] fills the available horizontal width.
  final QuiButtonFit fit;

  bool get _isEnabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.qui.colorScheme;
    final isEnabled = _isEnabled;

    final resolvedBackground = isEnabled
        ? backgroundColor ?? colorScheme.buttons.secondary.background
        : disabledBackgroundColor ?? colorScheme.buttons.secondary.backgroundDisabled;

    final resolvedForeground = _isEnabled
        ? foregroundColor ?? colorScheme.buttons.secondary.foreground
        : disabledForegroundColor ?? colorScheme.buttons.secondary.foregroundDisabled;

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
      width: fit == QuiButtonFit.expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      decoration: BoxDecoration(color: resolvedBackground, borderRadius: BorderRadius.circular(9999)),
      child: fit == QuiButtonFit.expand ? _alignedContent(content) : content,
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
        animation: QuiTapAnimationType.scale,
        child: button,
      ),
    );
  }

  Widget _alignedContent(Widget content) {
    switch (alignment) {
      case QuiButtonAlignment.left:
        return Align(alignment: Alignment.centerLeft, child: content);
      case QuiButtonAlignment.center:
        return Center(child: content);
      case QuiButtonAlignment.right:
        return Align(alignment: Alignment.centerRight, child: content);
    }
  }
}
