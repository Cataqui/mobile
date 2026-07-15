import 'package:flutter/material.dart';
import 'package:qui/src/theme/qui_theme_context.dart';
import 'package:qui/src/widgets/qui_tap/qui_tap.dart';

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
    final colorScheme = context.qui.colorScheme;
    final resolvedColor = _isEnabled
        ? widget.color ?? colorScheme.buttons.text.foreground
        : colorScheme.buttons.text.foregroundDisabled;

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
      child: QuiTap(
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
