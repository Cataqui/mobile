import 'dart:async';

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
    this.fireHapticFeedback = true,
  });

  /// Widget that receives the tap feedback.
  final Widget child;

  /// Called when the child is pressed.
  ///
  /// The [animation] future resolves when the release animation completes.
  /// Callers may `await animation` to wait for the visual feedback before
  /// performing navigation or other side effects.
  ///
  /// When null, the child renders without pointer feedback and ignores taps.
  final Future<void> Function(Future<void> animation)? onPressed;

  /// Whether haptic feedback fires when the widget is pressed.
  ///
  /// When `false`, [HapticFeedback.lightImpact] is not called. Defaults to
  /// `true`.
  final bool fireHapticFeedback;

  /// The tap feedback style.
  final QuiTapAnimationType animation;

  @override
  State<QuiTapAnimation> createState() => _QuiTapAnimationState();
}

class _QuiTapAnimationState extends State<QuiTapAnimation> with TickerProviderStateMixin {
  final _pressedOpacity = 0.4;
  final _pressedScale = 0.96;
  final _pressInDuration = const Duration(milliseconds: 150);
  final _releaseDuration = const Duration(milliseconds: 150);

  late final AnimationController _controller;
  late final CurvedAnimation _scaleCurve;
  late final CurvedAnimation _opacityCurve;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  bool _releaseRequested = false;
  Completer<void>? _releaseCompleter;
  bool get _isEnabled => widget.onPressed != null;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: _pressInDuration, reverseDuration: _releaseDuration, vsync: this);
    _controller.addStatusListener(_onStatusChanged);

    _scaleCurve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.linear);
    _scaleAnimation = Tween<double>(begin: 1, end: _pressedScale).animate(_scaleCurve);

    _opacityCurve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeOutCubic);
    _opacityAnimation = Tween<double>(begin: 1, end: _pressedOpacity).animate(_opacityCurve);
  }

  @override
  void dispose() {
    _releaseCompleter?.complete();
    _opacityCurve.dispose();
    _scaleCurve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QuiTapAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isEnabled && _controller.value > 0) {
      _releaseCompleter?.complete();
      _releaseCompleter = null;
      _releaseRequested = false;
      _controller.reset();
    }
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _releaseRequested) {
      _releaseRequested = false;
      _controller.reverse();
    } else if (status == AnimationStatus.dismissed) {
      _releaseCompleter?.complete();
      _releaseCompleter = null;
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isEnabled) return;
    if (widget.fireHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    _releaseRequested = false;
    _releaseCompleter?.complete();
    _releaseCompleter = null;

    if (!MediaQuery.disableAnimationsOf(context)) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isEnabled) return;

    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onPressed?.call(Future<void>.value());
      return;
    }

    _releaseCompleter = Completer<void>();
    widget.onPressed?.call(_releaseCompleter!.future);
    _requestRelease();
  }

  void _handleTapCancel() {
    if (!_isEnabled) return;
    _requestRelease();
  }

  void _requestRelease() {
    if (_controller.status == AnimationStatus.dismissed) return;
    if (_controller.status == AnimationStatus.completed) {
      _controller.reverse();
    } else {
      _releaseRequested = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: _isEnabled ? _handleTapDown : null,
        onTapUp: _isEnabled ? _handleTapUp : null,
        onTapCancel: _isEnabled ? _handleTapCancel : null,
        behavior: HitTestBehavior.opaque,
        child: switch (widget.animation) {
          QuiTapAnimationType.scaleFade => ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(opacity: _opacityAnimation, child: widget.child),
          ),
          QuiTapAnimationType.scale => ScaleTransition(scale: _scaleAnimation, child: widget.child),
        },
      ),
    );
  }
}
