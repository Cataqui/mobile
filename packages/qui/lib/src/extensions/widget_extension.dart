import 'package:flutter/material.dart';
import 'package:qui/src/widgets/qui_skeleton/qui_skeleton.dart';

/// Common convenience methods on [Widget] used across Cataquí.
///
/// All widget extension methods live in this single extension to keep the
/// import surface minimal and make methods easy to discover.
extension WidgetExtension on Widget {
  /// Wraps this widget with [QuiSkeleton] for loading-placeholder display.
  ///
  /// [enabled] controls whether the skeleton effect is active (default
  /// `true`).  [effect] controls the paint effect on the skeleton bones
  /// — when `null` (default), bones render as a static solid fill with
  /// zero per-frame cost.
  ///
  /// ```dart
  /// Text('Hello').skeleton();
  /// Text('Hello').skeleton(effect: QuiSkeletonShimmerEffect());
  /// CircularProgressIndicator().skeleton(enabled: isLoading);
  /// ```
  Widget skeleton({bool enabled = true, QuiSkeletonEffect? effect}) {
    return QuiSkeleton(enabled: enabled, effect: effect, child: this);
  }
}
