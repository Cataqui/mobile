import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'qui_tap_animation_enums.dart';

/// Reusable Cataquí tap feedback animation.
class QuiTapAnimation extends StatefulWidget {
  /// Creates tap feedback around [child].
  const QuiTapAnimation({
    required this.child,
    super.key,
    this.onPressed,
    this.animation = QuiTapAnimationType.scaleFade,
  });

  /// Widget that receives the tap feedback.
  final Widget child;

  /// Called when the child is pressed.
  ///
  /// When null, the child renders without pointer feedback and ignores taps.
  final VoidCallback? onPressed;

  /// The tap feedback style.
  final QuiTapAnimationType animation;

  @override
  State<QuiTapAnimation> createState() => _QuiTapAnimationState();
}

class _QuiTapAnimationState extends State<QuiTapAnimation> {
  static const _pressedOpacity = 0.2;
  static const _pressedScale = 0.94;
  static const _pressInDuration = Duration(milliseconds: 400);
  static const _releaseDuration = Duration(milliseconds: 800);

  bool _isPressed = false;
  bool get _isEnabled => widget.onPressed != null;

  @override
  void didUpdateWidget(covariant QuiTapAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isEnabled && _isPressed) _isPressed = false;
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
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
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final shouldShowPressedState = _isEnabled && _isPressed && !disableAnimations;
    final animationDuration = shouldShowPressedState ? _pressInDuration : _releaseDuration;

    return MouseRegion(
      cursor: _isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: _isEnabled ? _handleTapDown : null,
        onTapUp: _isEnabled ? _handleTapUp : null,
        onTapCancel: _isEnabled ? _handleTapCancel : null,
        behavior: HitTestBehavior.opaque,
        child: switch (widget.animation) {
          QuiTapAnimationType.scaleFade => AnimatedScale(
            duration: disableAnimations ? Duration.zero : animationDuration,
            curve: shouldShowPressedState ? Curves.easeOutCubic : Curves.easeOutBack,
            scale: shouldShowPressedState ? _pressedScale : 1,
            child: AnimatedOpacity(
              duration: disableAnimations ? Duration.zero : animationDuration,
              curve: Curves.easeOutCubic,
              opacity: shouldShowPressedState ? _pressedOpacity : 1,
              child: widget.child,
            ),
          ),
        },
      ),
    );
  }
}
