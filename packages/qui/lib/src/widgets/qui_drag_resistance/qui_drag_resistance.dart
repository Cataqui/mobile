import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

part 'qui_drag_resistance_render_object.dart';
part 'qui_drag_resistance_transform.dart';

/// Makes [child] move slightly with the user's finger, then spring back.
///
/// Use this wrapper to give a widget a soft, physical edge instead of leaving
/// it completely rigid during a drag. For example, a button wrapped with
/// [QuiDragResistance] can move a few pixels to the left or right as the user
/// pulls it, with increasing resistance that prevents it from moving freely.
/// Releasing or cancelling the pointer animates the child back to its original
/// position.
///
/// This is a visual interaction only. It does not dismiss, reorder, scroll, or
/// trigger an action, and it does not take gestures away from [child]. Buttons
/// remain tappable and the child's existing gesture callbacks continue to
/// work.
///
/// [top], [right], [bottom], and [left] select the physical directions in which
/// the child may move.
/// [offset] controls the maximum horizontal and vertical movement. For
/// example, `Offset(8, 3)` allows up to 8 logical pixels horizontally and 3
/// logical pixels vertically. Use [Offset.zero] to disable all resistance, or
/// set one component to zero to disable only that axis.
///
/// [QuiDragResistance] does not detect scrolling. If [child] scrolls, disable
/// resistance on the scrolling axis so the visual movement does not compete
/// with the scroll interaction.
///
/// The resistance movement is disabled when
/// [MediaQueryData.disableAnimations] is enabled.
///
/// ```dart
/// QuiDragResistance(
///   top: false,
///   bottom: false,
///   offset: const Offset(6, 0),
///   child: QuiButton(
///     variant: QuiButtonVariant.primary,
///     label: 'Continue',
///     onPressed: () {},
///   ),
/// )
/// ```
///
/// For vertically scrollable content, keep the vertical component at zero:
///
/// ```dart
/// QuiDragResistance(
///   top: false,
///   bottom: false,
///   offset: const Offset(6, 0),
///   child: ListView(
///     children: const [
///       Text('First item'),
///       Text('Second item'),
///     ],
///   ),
/// )
/// ```
class QuiDragResistance extends StatefulWidget {
  /// Creates a wrapper that lets [child] move slightly against drag resistance.
  ///
  /// Set [top], [right], [bottom], or [left] to `false` to prevent movement in
  /// that direction. The [offset] contains the maximum horizontal and vertical
  /// translations approached under increasingly long drags.
  const QuiDragResistance({
    required this.child,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.left = true,
    this.offset = const Offset(6, 6),
    super.key,
  });

  /// The widget that moves slightly while the user drags it.
  final Widget child;

  /// Whether [child] may move upward with resistance.
  final bool top;

  /// Whether [child] may move rightward with resistance.
  final bool right;

  /// Whether [child] may move downward with resistance.
  final bool bottom;

  /// Whether [child] may move leftward with resistance.
  final bool left;

  /// The maximum horizontal and vertical movement in logical pixels.
  ///
  /// The `dx` component limits left and right movement, while `dy` limits up
  /// and down movement. The child approaches these limits with increasing
  /// resistance and never moves beyond them.
  ///
  /// Use [Offset.zero] to disable all resistance. Use a zero component, such
  /// as `Offset(6, 0)`, to disable only that axis. Both components must be
  /// finite and non-negative.
  final Offset offset;

  @override
  State<QuiDragResistance> createState() => _QuiDragResistanceState();
}

class _QuiDragResistanceState extends State<QuiDragResistance> with SingleTickerProviderStateMixin {
  static const double _dampingDistance = 96;
  static const Duration _resetDuration = Duration(milliseconds: 180);

  final ValueNotifier<Offset> _resistanceOffsetNotifier = ValueNotifier<Offset>(Offset.zero);
  AnimationController? _resetController;
  int? _activePointer;
  bool _disableAnimations = false;
  double _dragDistanceX = 0;
  double _dragDistanceY = 0;
  Offset _offsetAtResetStart = Offset.zero;

  bool get _hasEnabledResistance {
    final horizontalResistanceEnabled = widget.offset.dx > 0 && (widget.left || widget.right);
    final verticalResistanceEnabled = widget.offset.dy > 0 && (widget.top || widget.bottom);
    return horizontalResistanceEnabled || verticalResistanceEnabled;
  }

  void _stopResetAnimation() {
    if (_resetController case final resetController? when resetController.isAnimating) {
      resetController.stop();
    }
  }

  void _disableResistance() {
    _activePointer = null;
    _dragDistanceX = 0;
    _dragDistanceY = 0;
    _stopResetAnimation();
    _resistanceOffsetNotifier.value = Offset.zero;
  }

  double _resolveAxisOffset({
    required double distance,
    required double maximumOffset,
    required bool negativeDirectionEnabled,
    required bool positiveDirectionEnabled,
  }) {
    if (maximumOffset == 0 || distance == 0) return 0;
    if (distance < 0 && !negativeDirectionEnabled) return 0;
    if (distance > 0 && !positiveDirectionEnabled) return 0;

    final progress = 1 - 1 / (1 + distance.abs() / _dampingDistance);
    return distance.sign * maximumOffset * progress;
  }

  Offset _resolveResistanceOffset() {
    return Offset(
      _resolveAxisOffset(
        distance: _dragDistanceX,
        maximumOffset: widget.offset.dx,
        negativeDirectionEnabled: widget.left,
        positiveDirectionEnabled: widget.right,
      ),
      _resolveAxisOffset(
        distance: _dragDistanceY,
        maximumOffset: widget.offset.dy,
        negativeDirectionEnabled: widget.top,
        positiveDirectionEnabled: widget.bottom,
      ),
    );
  }

  void _updateResistanceOffset(Offset pointerDelta) {
    _dragDistanceX += pointerDelta.dx;
    _dragDistanceY += pointerDelta.dy;
    if (_disableAnimations) return;

    _stopResetAnimation();
    _resistanceOffsetNotifier.value = _resolveResistanceOffset();
  }

  void _resetResistanceOffset() {
    _dragDistanceX = 0;
    _dragDistanceY = 0;
    final currentOffset = _resistanceOffsetNotifier.value;
    if (currentOffset == Offset.zero) return;

    if (_disableAnimations) {
      _resistanceOffsetNotifier.value = Offset.zero;
      return;
    }

    _offsetAtResetStart = currentOffset;
    final resetController = _resetController ??= AnimationController(duration: _resetDuration, vsync: this)
      ..addListener(_syncResetOffset);
    unawaited(resetController.forward(from: 0));
  }

  void _syncResetOffset() {
    final progress = Curves.easeOutCubic.transform(_resetController!.value);
    _resistanceOffsetNotifier.value = Offset.lerp(_offsetAtResetStart, Offset.zero, progress)!;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointer != null) return;

    _activePointer = event.pointer;
    _dragDistanceX = 0;
    _dragDistanceY = 0;
    _stopResetAnimation();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointer != event.pointer) return;
    _updateResistanceOffset(event.delta);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_activePointer != event.pointer) return;

    _activePointer = null;
    _resetResistanceOffset();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_activePointer != event.pointer) return;

    _activePointer = null;
    _resetResistanceOffset();
  }

  @override
  void initState() {
    super.initState();
    assert(
      widget.offset.isFinite && widget.offset.dx >= 0 && widget.offset.dy >= 0,
      'offset components must be finite and non-negative.',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations == _disableAnimations) return;

    _disableAnimations = disableAnimations;
    if (_disableAnimations) _disableResistance();
  }

  @override
  void didUpdateWidget(covariant QuiDragResistance oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(
      widget.offset.isFinite && widget.offset.dx >= 0 && widget.offset.dy >= 0,
      'offset components must be finite and non-negative.',
    );
    if (oldWidget.offset == widget.offset &&
        oldWidget.top == widget.top &&
        oldWidget.right == widget.right &&
        oldWidget.bottom == widget.bottom &&
        oldWidget.left == widget.left) {
      return;
    }

    if (!_hasEnabledResistance) {
      _disableResistance();
      return;
    }

    _stopResetAnimation();
    _resistanceOffsetNotifier.value = _disableAnimations ? Offset.zero : _resolveResistanceOffset();
  }

  @override
  void dispose() {
    _resistanceOffsetNotifier.dispose();
    _resetController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_disableAnimations || !_hasEnabledResistance) return widget.child;

    return _QuiDragResistanceTransform(
      resistanceListenable: _resistanceOffsetNotifier,
      child: RepaintBoundary(
        child: Listener(
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          behavior: HitTestBehavior.translucent,
          child: widget.child,
        ),
      ),
    );
  }
}
