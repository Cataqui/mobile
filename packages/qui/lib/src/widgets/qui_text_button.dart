import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';

part 'qui_text_button_enums.dart';

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
    this.icon,
    this.iconPosition = QuiTextButtonIconPosition.leading,
    this.iconSpacing = 4,
    this.color,
    this.iconMatchesTextColor = true,
  });

  /// Visible button label.
  final String text;

  /// Called when the button is pressed.
  ///
  /// When null, the button renders disabled and ignores pointer input.
  final VoidCallback? onPressed;

  /// Optional icon rendered before or after [text].
  final Widget? icon;

  /// Controls whether [icon] is leading or trailing.
  final QuiTextButtonIconPosition iconPosition;

  /// Horizontal spacing between [icon] and [text].
  final double iconSpacing;

  /// Text and matched-icon color.
  ///
  /// Defaults to `context.qui.colors.textPrimary` when enabled and
  /// `context.qui.colors.placeholder` when disabled.
  final Color? color;

  /// Whether [icon] should be tinted with the same color as [text].
  final bool iconMatchesTextColor;

  @override
  State<QuiTextButton> createState() => _QuiTextButtonState();
}

class _QuiTextButtonState extends State<QuiTextButton> {
  static const _pressedOpacity = 0.2;
  static const _pressedScale = 0.94;
  static const _pressInDuration = Duration(milliseconds: 400);
  static const _releaseDuration = Duration(milliseconds: 800);

  bool _isPressed = false;
  bool get _isEnabled => widget.onPressed != null;

  @override
  void didUpdateWidget(covariant QuiTextButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isEnabled && _isPressed) _isPressed = false;
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isEnabled) return;
    _setPressed(true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isEnabled) return;

    _setPressed(false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (!_isEnabled) return;
    _setPressed(false);
  }

  void _setPressed(bool isPressed) {
    if (_isPressed == isPressed) return;
    setState(() => _isPressed = isPressed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.qui.colors;
    final resolvedColor = _isEnabled ? widget.color ?? colors.textPrimary : colors.placeholder;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final shouldShowPressedState = _isEnabled && _isPressed && !disableAnimations;
    final animationDuration = shouldShowPressedState ? _pressInDuration : _releaseDuration;

    Widget content = Text(widget.text, style: context.qui.typography.labelLarge.copyWith(color: resolvedColor));

    final icon = widget.icon;

    if (icon != null) {
      final resolvedIcon = widget.iconMatchesTextColor ? _tintIcon(icon, resolvedColor) : icon;

      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: switch (widget.iconPosition) {
          QuiTextButtonIconPosition.leading => [
            Padding(
              padding: EdgeInsets.only(right: widget.iconSpacing),
              child: resolvedIcon,
            ),
            content,
          ],
          QuiTextButtonIconPosition.trailing => [
            content,
            Padding(
              padding: EdgeInsets.only(left: widget.iconSpacing),
              child: resolvedIcon,
            ),
          ],
        },
      );
    }

    return Semantics(
      button: true,
      enabled: _isEnabled,
      onTap: _isEnabled ? widget.onPressed : null,
      child: MouseRegion(
        cursor: _isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: _isEnabled ? _handleTapDown : null,
          onTapUp: _isEnabled ? _handleTapUp : null,
          onTapCancel: _isEnabled ? _handleTapCancel : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            duration: disableAnimations ? Duration.zero : animationDuration,
            curve: shouldShowPressedState ? Curves.easeOutCubic : Curves.easeOutBack,
            scale: shouldShowPressedState ? _pressedScale : 1,
            child: AnimatedOpacity(
              duration: disableAnimations ? Duration.zero : animationDuration,
              curve: Curves.easeOutCubic,
              opacity: shouldShowPressedState ? _pressedOpacity : 1,
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tintIcon(Widget icon, Color color) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: IconTheme.merge(
        data: IconThemeData(color: color),
        child: icon,
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
            QuiTextButton(text: 'Buscar', icon: const Icon(Icons.search, size: 18), onPressed: () {}),
            const SizedBox(height: 20),
            QuiTextButton(
              text: 'Continuar',
              icon: const Icon(Icons.arrow_forward, size: 18),
              iconPosition: QuiTextButtonIconPosition.trailing,
              color: const Color(0xFFFF4A4B),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            QuiTextButton(
              text: 'Mapa',
              icon: const Icon(Icons.location_on, size: 18, color: Color(0xFF00A676)),
              iconMatchesTextColor: false,
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            const QuiTextButton(text: 'Indisponivel', icon: Icon(Icons.lock, size: 18)),
          ],
        ),
      ),
    ),
  );
}
