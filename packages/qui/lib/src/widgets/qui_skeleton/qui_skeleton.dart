library;

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' hide Image;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_data.dart';

part '_qui_skeleton_canvas.dart';
part '_qui_skeleton_leaf_registry.dart';
part '_qui_skeleton_painting_context.dart';
part '_qui_skeleton_preview.dart';
part '_qui_skeleton_render_object.dart';
part '_qui_skeleton_render_object_widget.dart';

/// A QUI skeleton widget that transforms its child tree into gray bone boxes
/// for loading-placeholder display.
///
/// Wraps any widget subtree and intercepts its painting at the canvas level,
/// replacing leaf draw calls (text, images, icons) with pill-shaped skeleton
/// bones.  Container widgets (cards, backgrounds) pass through unchanged so
/// the layout structure remains visible.
///
/// ## Performance
///
/// Rendering is driven at the render-object level — the shimmer animation
/// calls `markNeedsPaint` directly on the render object without any
/// `setState` or widget rebuilds.  When [shimmer] is `false`, no
/// [AnimationController] is created and the skeleton is rendered as a static
/// solid fill, adding zero per-frame cost.  Shimmer also falls back to the
/// static path when [MediaQueryData.disableAnimations] is `true`.
///
/// ## Usage
///
/// ```dart
/// // Simple wrap — contents become skeleton bones while loading.
/// QuiSkeleton(child: myCardWidget);
///
/// // Via the `.skeleton()` widget extension:
/// myCardWidget.skeleton();
///
/// // Static skeleton (no shimmer animation, zero per-frame cost):
/// QuiSkeleton(shimmer: false, child: myCardWidget);
/// ```
///
/// See also:
///  * `WidgetExtension` (`.skeleton()`), the widget extension that wraps any
///    widget with [QuiSkeleton].
class QuiSkeleton extends StatefulWidget {
  /// Creates a QUI skeleton loading placeholder.
  const QuiSkeleton({required this.child, super.key, this.enabled = true, this.shimmer = true});

  /// The widget subtree to skeletonize when [enabled] is `true`.
  final Widget child;

  /// Whether the skeleton effect is active.
  ///
  /// When `false`, the [child] renders normally with zero skeleton overhead.
  final bool enabled;

  /// Whether a shimmer sweep animation plays across the skeleton bones.
  ///
  /// When `true`, an animated gradient sweeps from left to right across
  /// the skeleton bones.  When `false`, the skeleton renders as static
  /// gray boxes.  Disabling shimmer, or enabling
  /// [MediaQueryData.disableAnimations], adds zero per-frame cost.
  final bool shimmer;

  @override
  State<QuiSkeleton> createState() => _QuiSkeletonState();
}

class _QuiSkeletonState extends State<QuiSkeleton> with TickerProviderStateMixin {
  AnimationController? _controller;
  bool _disableAnimations = false;

  bool get _shouldAnimateShimmer => widget.enabled && widget.shimmer && !_disableAnimations;
  bool get _effectiveShimmer => widget.shimmer && !_disableAnimations;

  void _syncAnimationController() {
    if (_shouldAnimateShimmer) {
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
        lowerBound: -0.5,
        upperBound: 1.5,
      )..repeat();
    } else {
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncAnimationController();
  }

  @override
  void didUpdateWidget(QuiSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled || oldWidget.shimmer != widget.shimmer) {
      _syncAnimationController();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final colors = Theme.of(context).extension<QuiThemeData>()!.colors;

    return _QuiSkeletonRenderObjectWidget(
      skeletonColor: colors.skeleton,
      shimmerGlowColor: colors.skeletonShimmerGlow,
      shimmerAnimation: _controller,
      shimmer: _effectiveShimmer,
      child: widget.child,
    );
  }
}

@Preview(name: 'QuiSkeleton', group: 'Loading')
Widget quiSkeletonPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: const Scaffold(
      backgroundColor: Color(0xFFF6F4F1),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: SizedBox(width: 340, child: QuiSkeleton(shimmer: false, child: _PreviewCard())),
        ),
      ),
    ),
  );
}
