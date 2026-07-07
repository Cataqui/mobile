import 'package:flutter/material.dart';
import 'package:qui/src/widgets/qui_skeleton/qui_skeleton.dart';

extension WidgetExtension on Widget {
  /// Wraps this widget with [QuiSkeleton] for loading-placeholder display.
  ///
  /// [enabled] controls whether the skeleton effect is active (default
  /// `true`). Pass a [QuiSkeletonStyle] to customize any subset; `null` uses theme
  /// defaults
  ///
  /// ```dart
  /// Text('Hello').skeleton();
  /// Text('Hello').skeleton(style: QuiSkeletonStyle(effect: QuiSkeletonShimmerEffect()));
  /// CircularProgressIndicator().skeleton(enabled: isLoading);
  /// ```
  Widget skeleton({bool enabled = true, QuiSkeletonStyle? style}) {
    return QuiSkeleton(enabled: enabled, style: style, child: this);
  }
}
