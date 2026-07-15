import 'dart:async';

import 'package:flutter/material.dart';

part 'qui_appear_controller.dart';
part 'qui_appear_enums.dart';

/// Animates [child] into view on demand.
///
/// Use a [QuiAppearController] to control when the widget appears or
/// disappears. The widget does not animate automatically.
///
/// ## Unmount behavior
///
/// By default ([unmount] is `false`), `destroy` fades [child] to opacity 0
/// but keeps it mounted in the widget tree. Set [unmount] to `true` to
/// remove [child] from the widget tree once the destroy animation completes.
/// The child's element subtree is genuinely disposed — its `State.dispose`
/// runs, its render object is detached, and its `BuildContext` becomes
/// invalid. Calling `appear()` after an unmount creates a fresh element
/// subtree and fades it back in.
///
/// ```dart
/// final _controller = QuiAppearController();
///
/// QuiAppear(
///   controller: _controller,
///   unmount: true,
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
    this.unmount = false,
    this.onAppear,
    this.onDestroy,
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

  /// Whether `destroy` removes [child] from the widget tree once the
  /// destroy animation completes.
  ///
  /// When `true`, the child's element subtree is disposed (its
  /// `State.dispose` runs, its render object is detached). Calling
  /// `appear()` after an unmount re-mounts the child
  /// and plays the appear animation.
  ///
  /// When `false` (the default), [child] stays mounted at opacity 0
  /// after `destroy` completes.
  final bool unmount;

  /// Called when `appear` is requested.
  ///
  /// Fires immediately when [QuiAppearController.appear] is called, before
  /// the appear animation plays. The [animation] future completes when the
  /// animation reaches opacity 1 (or immediately if already in the
  /// appeared state or when animations are disabled).
  ///
  /// ```dart
  /// QuiAppear(
  ///   controller: controller,
  ///   onAppear: (animation) async {
  ///     await animation;
  ///     // child is now fully visible
  ///   },
  /// )
  /// ```
  final void Function(Future<void> animation)? onAppear;

  /// Called when `destroy` is requested.
  ///
  /// Fires immediately when [QuiAppearController.destroy] is called, before
  /// the destroy animation plays. The [animation] future completes when the
  /// animation reaches opacity 0 (or immediately if already in the
  /// destroyed state or when animations are disabled).
  ///
  /// ```dart
  /// QuiAppear(
  ///   controller: controller,
  ///   onDestroy: (animation) async {
  ///     await animation;
  ///     // child is now hidden
  ///   },
  /// )
  /// ```
  final void Function(Future<void> animation)? onDestroy;

  @override
  State<QuiAppear> createState() => _QuiAppearState();
}

class _QuiAppearState extends State<QuiAppear> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double? _pendingTargetValue;
  bool _initComplete = false;
  bool _unmounted = false;
  Completer<void>? _destroyCompleter;
  Completer<void>? _appearCompleter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.appearDuration,
      reverseDuration: widget.destroyDuration,
      vsync: this,
    );
    _controller.addStatusListener(_onAnimationStatus);
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
    if (!oldWidget.unmount && widget.unmount && _controller.value == 0) {
      setState(() => _unmounted = true);
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    widget.controller._unregister();
    _controller.dispose();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _completeDestroy();
      if (widget.unmount) setState(() => _unmounted = true);
    } else if (status == AnimationStatus.completed) {
      _completeAppear();
    }
  }

  void _onControllerTrigger(double targetValue) {
    if (!mounted) return;
    if (targetValue == 0) {
      _completeDestroy();
      _completeAppear();
      final completer = Completer<void>();
      widget.onDestroy?.call(completer.future);
      _destroyCompleter = completer;
    } else {
      _completeDestroy();
      _completeAppear();
      final completer = Completer<void>();
      widget.onAppear?.call(completer.future);
      _appearCompleter = completer;
    }
    if (!_initComplete) {
      _pendingTargetValue = targetValue;
      return;
    }
    if (targetValue == 1.0 && _unmounted) {
      setState(() => _unmounted = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // ignore: prefer_int_literals — `1` is an int literal, not a double
        _runAppearance(1.0);
      });
      return;
    }
    _runAppearance(targetValue);
  }

  void _runAppearance(double targetValue) {
    if (MediaQuery.disableAnimationsOf(context)) {
      if (targetValue == 0 && _controller.value == 0) {
        _completeDestroy();
      }

      _controller.value = targetValue;
    } else if (targetValue == 1.0) {
      unawaited(_controller.forward());
    } else {
      if (_controller.value == 0) {
        _completeDestroy();
      }
      unawaited(_controller.reverse());
    }
  }

  void _completeDestroy() {
    final completer = _destroyCompleter;

    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }

    _destroyCompleter = null;
  }

  void _completeAppear() {
    final completer = _appearCompleter;

    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }

    _appearCompleter = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_unmounted) return const SizedBox.shrink();
    return switch (widget.animation) {
      QuiAppearAnimationType.fade => FadeTransition(opacity: _controller, child: widget.child),
    };
  }
}
