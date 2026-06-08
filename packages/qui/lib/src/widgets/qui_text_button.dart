import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';
import 'package:qui/src/widgets/qui_tap_animation.dart';

part 'qui_text_button_enums.dart';
part 'qui_text_button_types.dart';

/// A lightweight Cataquí text button with optional icon support.
///
/// `QuiTextButton` renders as clickable text without Material button chrome.
/// It is intended for compact actions where the text itself is the affordance.
class QuiTextButton extends StatefulWidget {
  /// Creates a Cataquí text button.
  const QuiTextButton({
    required this.text,
    super.key,
    this.onPressed,
    this.iconBuilder,
    this.iconPosition = QuiTextButtonIconPosition.leading,
    this.iconSpacing = 4,
    this.color,
  });

  /// Visible button label.
  final String text;

  /// Called when the button is pressed.
  ///
  /// When null, the button renders disabled and ignores pointer input.
  final VoidCallback? onPressed;

  /// Optional icon rendered before or after [text].
  final QuiTextButtonIconBuilder? iconBuilder;

  /// Controls whether the built icon is leading or trailing.
  final QuiTextButtonIconPosition iconPosition;

  /// Horizontal spacing between the built icon and [text].
  final double iconSpacing;

  /// Text and matched-icon color.
  ///
  /// Defaults to `context.qui.colors.textPrimary` when enabled and
  /// `context.qui.colors.placeholder` when disabled.
  final Color? color;

  @override
  State<QuiTextButton> createState() => _QuiTextButtonState();
}

class _QuiTextButtonState extends State<QuiTextButton> {
  bool get _isEnabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.qui.colors;
    final resolvedColor = _isEnabled ? widget.color ?? colors.textPrimary : colors.placeholder;

    Widget content = Text(widget.text, style: context.qui.typography.labelLarge.copyWith(color: resolvedColor));

    final iconBuilder = widget.iconBuilder;

    if (iconBuilder != null) {
      final iconState = QuiTextButtonIconState(isEnabled: _isEnabled, recommendedIconColor: resolvedColor);
      final icon = iconBuilder(iconState);

      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: switch (widget.iconPosition) {
          QuiTextButtonIconPosition.leading => [
            Padding(
              padding: EdgeInsets.only(right: widget.iconSpacing),
              child: icon,
            ),
            content,
          ],
          QuiTextButtonIconPosition.trailing => [
            content,
            Padding(
              padding: EdgeInsets.only(left: widget.iconSpacing),
              child: icon,
            ),
          ],
        },
      );
    }

    return Semantics(
      button: true,
      enabled: _isEnabled,
      onTap: _isEnabled ? widget.onPressed : null,
      child: QuiTapAnimation(onPressed: widget.onPressed, animation: QuiTapAnimationType.scaleFade, child: content),
    );
  }
}

/// Preview of the [QuiTextButton] widget.
@Preview(name: 'QuiTextButton', group: 'Buttons')
Widget quiTextButtonPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuiTextButton(text: 'Ver oportunidades', onPressed: () {}),
            const SizedBox(height: 20),
            QuiTextButton(
              text: 'Buscar',
              iconBuilder: (state) => Icon(Icons.search, color: state.recommendedIconColor, size: 18),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            QuiTextButton(
              text: 'Continuar',
              iconBuilder: (state) => Icon(Icons.arrow_forward, color: state.recommendedIconColor, size: 18),
              iconPosition: QuiTextButtonIconPosition.trailing,
              color: const Color(0xFFFF4A4B),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            QuiTextButton(
              text: 'Mapa',
              iconBuilder: (state) => const Icon(Icons.location_on, size: 18, color: Color(0xFF00A676)),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            QuiTextButton(
              text: 'Indisponivel',
              iconBuilder: (state) => Icon(Icons.lock, color: state.recommendedIconColor, size: 18),
            ),
          ],
        ),
      ),
    ),
  );
}
