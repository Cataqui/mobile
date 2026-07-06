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
  /// `true`).  [shimmer] controls whether an animated shimmer sweep plays
  /// across the skeleton bones (default `true`).
  ///
  /// ```dart
  /// Text('Hello').skeleton();
  /// CircularProgressIndicator().skeleton(enabled: isLoading);
  /// ```
  Widget skeleton({bool enabled = true, bool shimmer = true}) {
    return QuiSkeleton(enabled: enabled, shimmer: shimmer, child: this);
  }
}
