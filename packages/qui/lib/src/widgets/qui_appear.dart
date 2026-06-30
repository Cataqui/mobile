import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/src/theme/qui_theme.dart';

part 'qui_appear_controller.dart';
part 'qui_appear_enums.dart';

/// Animates [child] into view on demand.
///
/// Use a [QuiAppearController] to control when the widget appears or
/// disappears. The widget does not animate automatically.
///
/// ```dart
/// final _controller = QuiAppearController();
///
/// QuiAppear(
///   controller: _controller,
///   child: const Text('Hello'),
/// )
/// ```
class QuiAppear extends StatefulWidget {
  /// Creates a QUI appear animation around [child].
  const QuiAppear({
    required this.controller,
    required this.child,
    this.animation = QuiAppearAnimationType.fade,
    this.appearDuration = const Duration(milliseconds: 300),
    this.destroyDuration = const Duration(milliseconds: 300),
    super.key,
  });

  /// Controller that drives the appear/destroy animation.
  final QuiAppearController controller;

  /// Widget that appears or disappears with the [animation].
  final Widget child;

  /// The type of appear animation.
  final QuiAppearAnimationType animation;

  /// How long the appear animation takes.
  final Duration appearDuration;

  /// How long the destroy (disappear) animation takes.
  final Duration destroyDuration;

  @override
  State<QuiAppear> createState() => _QuiAppearState();
}

class _QuiAppearState extends State<QuiAppear> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double? _pendingTargetValue;
  bool _initComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.appearDuration,
      reverseDuration: widget.destroyDuration,
      vsync: this,
    );
    widget.controller._register(_onControllerTrigger);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initComplete) {
      _initComplete = true;
      final pending = _pendingTargetValue;
      if (pending != null) {
        _pendingTargetValue = null;
        _runAppearance(pending);
      }
    }
  }

  @override
  void didUpdateWidget(covariant QuiAppear oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._unregister();
      widget.controller._register(_onControllerTrigger);
    }
    if (oldWidget.appearDuration != widget.appearDuration) {
      _controller.duration = widget.appearDuration;
    }
    if (oldWidget.destroyDuration != widget.destroyDuration) {
      _controller.reverseDuration = widget.destroyDuration;
    }
  }

  @override
  void dispose() {
    widget.controller._unregister();
    _controller.dispose();
    super.dispose();
  }

  void _onControllerTrigger(double targetValue) {
    if (!mounted) return;
    if (!_initComplete) {
      _pendingTargetValue = targetValue;
      return;
    }
    _runAppearance(targetValue);
  }

  void _runAppearance(double targetValue) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = targetValue;
    } else if (targetValue == 1.0) {
      unawaited(_controller.forward());
    } else {
      unawaited(_controller.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.animation) {
      QuiAppearAnimationType.fade => FadeTransition(opacity: _controller, child: widget.child),
    };
  }
}

@Preview(name: 'QuiAppear', group: 'Feedback')
Widget quiAppearPreview() {
  final controller = QuiAppearController();

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuiAppear(
              controller: controller,
              child: const Text('Appearing text', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: controller.appear, child: const Text('Appear')),
          ],
        ),
      ),
    ),
  );
}
