import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:qui/src/theme/qui_theme.dart';
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
    final colors = context.qui.colors;
    final isEnabled = _isEnabled;
    final resolvedLabel = label;
    final resolvedBackgroundColor = isEnabled
        ? backgroundColor ?? colors.primary
        : disabledBackgroundColor ?? colors.disabledButtonBackground;
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
              .copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600)
              .merge(labelStyle),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Preview of the [QuiIconButton] widget.
@Preview(name: 'QuiIconButton', group: 'Buttons')
Widget quiIconButtonPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuiIconButton(
              label: 'Buscar',
              iconBuilder: (state) => Icon(Icons.search, color: state.recommendedIconColor, size: state.iconSize),
              onPressed: () {},
            ),
            const SizedBox(width: 24),
            QuiIconButton(
              backgroundColor: const Color(0xFF00A676),
              iconBuilder: (state) => Icon(Icons.location_on, color: state.recommendedIconColor, size: state.iconSize),
              onPressed: () {},
            ),
            const SizedBox(width: 24),
            QuiIconButton(
              label: 'Bloqueado',
              iconBuilder: (state) => Icon(Icons.lock, color: state.recommendedIconColor, size: state.iconSize),
            ),
          ],
        ),
      ),
    ),
  );
}
