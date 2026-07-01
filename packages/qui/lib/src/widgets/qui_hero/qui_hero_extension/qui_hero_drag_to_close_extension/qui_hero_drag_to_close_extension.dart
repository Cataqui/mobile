import 'dart:async';

import 'package:flutter/material.dart';

import '../../qui_hero.dart';
import '../../qui_hero_page/qui_hero_page_route.dart';
import '../qui_hero_extension.dart';

part '_qui_hero_drag_to_close_extension_gesture.dart';
part 'qui_hero_drag_to_close_extension_enums.dart';

/// Adds drag-to-close behavior to a [QuiHero] variant.
///
/// Pass this extension to a hero destination, usually [QuiHero.box], when the
/// page is shown by QuiHeroPageRoute. The extension is scroll-aware when a
/// [scrollController] is provided, so downward drags only close the page when
/// the scrollable is already at the top.
///
/// ```dart
/// QuiHero.box(
///   tag: 'job-1-surface',
///   extensions: [
///     QuiHeroDragToCloseExtension(
///       scrollController: scrollController,
///       onDragStateChanged: (state) {},
///     ),
///   ],
///   child: CustomScrollView(controller: scrollController),
/// )
/// ```
class QuiHeroDragToCloseExtension extends QuiHeroExtension {
  /// Creates a drag-to-close extension for a [QuiHero] variant.
  const QuiHeroDragToCloseExtension({
    this.scrollController,
    this.closeDragHeightFactor = 0.42,
    this.commitThreshold = 0.5,
    this.onDragStateChanged,
  });

  /// Optional scroll controller for scroll-aware drag-to-close.
  ///
  /// When provided, the extension only activates drag-to-close when the
  /// scroll position is at the top. When `null`, the extension always allows
  /// drag-to-close.
  final ScrollController? scrollController;

  /// Fraction of the screen height that constitutes a full close gesture.
  ///
  /// Defaults to `0.42`. A smaller value makes closing feel easier.
  final double closeDragHeightFactor;

  /// Fraction of the close drag that must be reached to commit the pop.
  ///
  /// When the drag progress reaches this threshold, releasing commits the
  /// pop. Defaults to `0.5`.
  final double commitThreshold;

  /// Called when the drag-to-close lifecycle changes.
  ///
  /// [QuiHeroDragToCloseState.dragging] means an interactive close gesture is
  /// active. [QuiHeroDragToCloseState.idle] means the gesture was cancelled or
  /// restored.
  final ValueChanged<QuiHeroDragToCloseState>? onDragStateChanged;

  @override
  Widget wrap({required BuildContext context, required Widget child}) {
    return _QuiHeroDragToCloseExtensionGesture(
      scrollController: scrollController,
      closeDragHeightFactor: closeDragHeightFactor,
      commitThreshold: commitThreshold,
      onDragStateChanged: onDragStateChanged,
      child: child,
    );
  }
}
