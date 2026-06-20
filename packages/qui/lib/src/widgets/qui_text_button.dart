import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';
import 'package:qui/src/widgets/qui_tap_animation.dart';

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
    this.leadingIconBuilder,
    this.trailingIconBuilder,
    this.leadingIconSpacing = 4,
    this.trailingIconSpacing = 4,
    this.color,
  });

  /// Visible button label.
  final String text;

  /// Called when the button is pressed.
  ///
  /// When null, the button renders disabled and ignores pointer input.
  final VoidCallback? onPressed;

  /// Optional icon rendered before [text].
  final QuiTextButtonIconBuilder? leadingIconBuilder;

  /// Optional icon rendered after [text].
  final QuiTextButtonIconBuilder? trailingIconBuilder;

  /// Horizontal spacing between [leadingIconBuilder]'s icon and [text].
  final double leadingIconSpacing;

  /// Horizontal spacing between [text] and [trailingIconBuilder]'s icon.
  final double trailingIconSpacing;

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

    Widget content = Text(
      widget.text,
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: resolvedColor),
    );

    final iconState = QuiTextButtonIconState(isEnabled: _isEnabled, recommendedIconColor: resolvedColor);
    final hasLeading = widget.leadingIconBuilder != null;
    final hasTrailing = widget.trailingIconBuilder != null;

    if (hasLeading || hasTrailing) {
      final children = <Widget>[];
      if (hasLeading) {
        children.add(
          Padding(
            padding: EdgeInsets.only(right: widget.leadingIconSpacing),
            child: widget.leadingIconBuilder!(iconState),
          ),
        );
      }
      children.add(content);
      if (hasTrailing) {
        children.add(
          Padding(
            padding: EdgeInsets.only(left: widget.trailingIconSpacing),
            child: widget.trailingIconBuilder!(iconState),
          ),
        );
      }
      content = Row(mainAxisSize: MainAxisSize.min, children: children);
    }

    return Semantics(
      button: true,
      enabled: _isEnabled,
      onTap: _isEnabled ? widget.onPressed : null,
      child: QuiTapAnimation(
        onPressed: widget.onPressed != null
            ? (animation) async {
                widget.onPressed!();
              }
            : null,
        animation: QuiTapAnimationType.scaleFade,
        child: content,
      ),
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
              leadingIconBuilder: (state) => Icon(Icons.search, color: state.recommendedIconColor, size: 18),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            QuiTextButton(
              text: 'Continuar',
              trailingIconBuilder: (state) => Icon(Icons.arrow_forward, color: state.recommendedIconColor, size: 18),
              color: const Color(0xFFFF4A4B),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            QuiTextButton(
              text: 'Mapa',
              leadingIconBuilder: (state) => const Icon(Icons.location_on, size: 18, color: Color(0xFF00A676)),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            QuiTextButton(
              text: 'Indisponivel',
              leadingIconBuilder: (state) => Icon(Icons.lock, color: state.recommendedIconColor, size: 18),
            ),
            const SizedBox(height: 20),
            QuiTextButton(
              text: 'Distância',
              leadingIconBuilder: (state) => Icon(Icons.near_me, color: state.recommendedIconColor, size: 18),
              trailingIconBuilder: (state) => Icon(Icons.info_outline, color: state.recommendedIconColor, size: 18),
              onPressed: () {},
            ),
          ],
        ),
      ),
    ),
  );
}
