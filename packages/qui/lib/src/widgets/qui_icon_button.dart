import 'package:flutter/material.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:qui/src/theme/qui_theme_context.dart';
import 'package:qui/src/widgets/qui_tap_animation.dart';

part 'qui_icon_button_types.dart';

/// A circular Cataquí icon button with an optional bottom label.
class QuiIconButton extends StatelessWidget {
  /// Creates a Cataquí circular icon button.
  const QuiIconButton({
    required this.iconBuilder,
    super.key,
    this.onPressed,
    this.label,
    this.labelStyle,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.buttonSize = 55,
    this.iconSize = 27,
  });

  /// Builds the icon from the current button state.
  final QuiIconButtonIconBuilder iconBuilder;

  /// Called when the button is pressed.
  ///
  /// When null, the button renders disabled and ignores pointer input.
  final VoidCallback? onPressed;

  /// Optional label rendered below the circular icon button.
  final String? label;

  /// Optional style merged on top of the default label style.
  final TextStyle? labelStyle;

  /// Enabled circle background color.
  ///
  /// Defaults to `context.qui.colors.primary`.
  final Color? backgroundColor;

  /// Disabled circle background color.
  ///
  /// Defaults to `context.qui.colors.disabledButtonBackground`.
  final Color? disabledBackgroundColor;

  /// Diameter of the circular button.
  final double buttonSize;

  /// Recommended icon size passed to [iconBuilder].
  final double iconSize;

  bool get _isEnabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.qui.colorScheme;
    final isEnabled = _isEnabled;
    final resolvedLabel = label;
    final resolvedBackgroundColor = isEnabled
        ? backgroundColor ?? colorScheme.colors.primary.solid
        : disabledBackgroundColor ?? colorScheme.buttons.primary.backgroundDisabled;
    final recommendedIconColor = isEnabled ? Colors.white : resolvedBackgroundColor.darken(0.28);
    final iconState = QuiIconButtonIconState(
      isEnabled: isEnabled,
      recommendedIconColor: recommendedIconColor,
      iconSize: iconSize,
    );

    final button = Semantics(
      key: const Key('qui_icon_button_semantics'),
      button: true,
      enabled: isEnabled,
      label: resolvedLabel,
      onTap: isEnabled ? onPressed : null,
      child: QuiTapAnimation(
        onPressed: onPressed != null
            ? (animation) async {
                onPressed!();
              }
            : null,
        child: Container(
          key: const Key('qui_icon_button_circle'),
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(color: resolvedBackgroundColor, shape: BoxShape.circle),
          child: Center(
            child: SizedBox.square(
              key: const Key('qui_icon_button_icon_box'),
              dimension: iconSize,
              child: FittedBox(fit: BoxFit.contain, child: iconBuilder(iconState)),
            ),
          ),
        ),
      ),
    );

    if (resolvedLabel == null) return button;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: 6),
        Text(
          resolvedLabel,
          style: context.qui.typography.labelMedium
              .copyWith(color: colorScheme.text.primary, fontWeight: FontWeight.w600)
              .merge(labelStyle),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
