library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' hide Image;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/src/theme/qui_colors.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_data.dart';

part '_qui_skeleton_canvas.dart';
part '_qui_skeleton_leaf_registry.dart';
part '_qui_skeleton_painting_context.dart';
part '_qui_skeleton_preview.dart';
part '_qui_skeleton_render_object.dart';
part '_qui_skeleton_render_object_widget.dart';
part 'effects/qui_skeleton_effect.dart';
part 'effects/qui_skeleton_shimmer_effect.dart';

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
/// Rendering is driven at the render-object level — the effect animation
/// calls `markNeedsPaint` directly on the render object without any
/// `setState` or widget rebuilds.  When [effect] is `null`, no
/// [AnimationController] is created and the skeleton is rendered as a static
/// solid fill, adding zero per-frame cost.  Animated effects also fall back
/// to the static path when [MediaQueryData.disableAnimations] is `true`.
///
/// ## Usage
///
/// ```dart
/// // Simple wrap — static bones, zero per-frame cost.
/// QuiSkeleton(child: myCardWidget);
///
/// // Animated shimmer sweep.
/// QuiSkeleton(effect: QuiSkeletonShimmerEffect(), child: myCardWidget);
///
/// // Via the `.skeleton()` widget extension:
/// myCardWidget.skeleton();
/// myCardWidget.skeleton(effect: QuiSkeletonShimmerEffect());
/// ```
///
/// See also:
///  * [QuiSkeletonStaticEffectBase], the base class for static skeleton effects.
///  * [QuiSkeletonAnimatedEffectBase], the base class for animated skeleton effects.
///  * [QuiSkeletonShimmerEffect], the built-in animated shimmer sweep effect.
///  * `WidgetExtension` (`.skeleton()`), the widget extension that wraps any
///    widget with [QuiSkeleton].
class QuiSkeleton extends StatefulWidget {
  /// Creates a QUI skeleton loading placeholder.
  const QuiSkeleton({required this.child, super.key, this.enabled = true, this.effect});

  /// The widget subtree to skeletonize when [enabled] is `true`.
  final Widget child;

  /// Whether the skeleton effect is active.
  ///
  /// When `false`, the [child] renders normally with zero skeleton overhead.
  final bool enabled;

  /// The paint effect applied to the skeleton bones.
  ///
  /// When `null`, bones render as a static solid fill (zero per-frame cost).
  /// Pass a [QuiSkeletonShimmerEffect] to animate the bones with a shimmer
  /// sweep, or create a custom effect by extending
  /// [QuiSkeletonStaticEffectBase] or [QuiSkeletonAnimatedEffectBase].
  ///
  /// The resting bone color is always driven by the theme's `skeleton` token.
  /// An effect may define its own configurable parameters (like the shimmer
  /// effect's [QuiSkeletonShimmerEffect.color] and
  /// [QuiSkeletonShimmerEffect.angle]), but it cannot override the resting
  /// skeleton color.
  final QuiSkeletonEffect? effect;

  @override
  State<QuiSkeleton> createState() => _QuiSkeletonState();
}

class _QuiSkeletonState extends State<QuiSkeleton> with TickerProviderStateMixin {
  AnimationController? _controller;
  bool _disableAnimations = false;

  bool get _shouldAnimate => widget.enabled && widget.effect is QuiSkeletonAnimatedEffectBase && !_disableAnimations;

  bool get _effectActive {
    if (widget.effect == null) return false;
    if (widget.effect is QuiSkeletonAnimatedEffectBase && _disableAnimations) return false;
    return true;
  }

  void _syncAnimationController() {
    if (_shouldAnimate) {
      final effect = widget.effect! as QuiSkeletonAnimatedEffectBase;

      _controller ??= AnimationController(
        vsync: this,
        duration: effect.duration,
        lowerBound: effect.lowerBound,
        upperBound: effect.upperBound,
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
    final effectChanged = !_effectEquals(oldWidget.effect, widget.effect);
    final enabledChanged = widget.enabled != oldWidget.enabled;
    if (effectChanged || enabledChanged) {
      _syncAnimationController();
    }
  }

  bool _effectEquals(QuiSkeletonEffect? a, QuiSkeletonEffect? b) {
    if (identical(a, b)) return true;
    return a == b;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final colors = Theme.of(context).extension<QuiThemeData>()!.colors;

    return _QuiSkeletonRenderObjectWidget(
      colors: colors,
      effect: _effectActive ? widget.effect : null,
      effectAnimation: _shouldAnimate ? _controller : null,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 340, child: QuiSkeleton(child: _PreviewCard())),
              SizedBox(height: 24),
              SizedBox(
                width: 340,
                child: QuiSkeleton(effect: QuiSkeletonShimmerEffect(), child: _PreviewCard()),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
