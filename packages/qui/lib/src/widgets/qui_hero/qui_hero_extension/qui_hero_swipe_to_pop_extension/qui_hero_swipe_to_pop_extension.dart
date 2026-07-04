import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../qui_hero.dart';
import '../../qui_hero_page/qui_hero_page.dart';
import '../../qui_hero_page/qui_hero_page_route.dart';
import '../qui_hero_extension.dart';

part '_qui_hero_swipe_to_pop_extension_gesture.dart';
part 'qui_hero_swipe_to_pop_extension_enums.dart';

/// Adds swipe-to-pop behavior to a hero destination page.
///
/// Pass this extension to a [QuiHero] variant — typically [QuiHero.background] —
/// displayed on a destination opened by [QuiHeroPage]. The extension tracks
/// downward swipe gestures and drives the route's interactive-pop API to create
/// a natural swipe-to-dismiss experience.
///
/// ## Scroll awareness
///
/// When a [scrollController] is provided, the extension only activates
/// swipe-to-pop when the scroll position is at the top of its scroll extent.
/// This prevents the gesture from conflicting with scrolling content:
///
///  * User scrolls down through content → extension stays idle.
///  * User scrolls back to top, then swipes further down → extension activates
///    swipe-to-pop.
///
/// When [scrollController] is `null`, downward swipe always triggers
/// swipe-to-pop, regardless of scroll state. Use this when there is no
/// scrollable content on the destination page.
///
/// ## Reduced motion
///
/// When [MediaQuery.disableAnimationsOf] reports reduced motion, the extension
/// skips the animated transition and commits or cancels the pop immediately
/// based on the [threshold], without flying the shared element.
///
/// ## Fast swipes
///
/// A fast downward swipe commits the pop action even when the swipe progress
/// is still below [threshold]. This matches the fast-swipe intent used
/// by other QUI gesture components while keeping upward swipes ignored.
///
/// ## Lifecycle callbacks
///
/// Pass an [onSwipeStateChanged] callback to react to gesture lifecycle
/// changes. The callback receives [QuiHeroSwipeToPopState.idle] when a
/// gesture ends (cancelled or restored) and
/// [QuiHeroSwipeToPopState.dragging] when a gesture begins.
///
/// ```dart
/// QuiHero.background(
///   tag: 'job-1-surface',
///   extensions: [
///     QuiHeroSwipeToPopExtension(
///       scrollController: scrollController,
///       onSwipeStateChanged: (state) {
///         if (state == QuiHeroSwipeToPopState.dragging) {
///           // Hide dismiss affordances, pause autoplay, etc.
///         }
///       },
///     ),
///   ],
///   child: CustomScrollView(controller: scrollController),
/// )
/// ```
///
/// See also:
///  * [QuiHeroPageRoute], whose interactive-pop API this extension drives.
///  * [QuiHeroExtension], the base class for hero extensions.
///  * [QuiHeroSwipeToPopState], the lifecycle states reported by
///    [onSwipeStateChanged].
class QuiHeroSwipeToPopExtension extends QuiHeroExtension {
  /// Creates a swipe-to-pop extension for a [QuiHero] variant.
  ///
  /// The extension must be used inside a [QuiHeroPageRoute]. Passing it to a
  /// hero on a route created by anything other than [QuiHeroPage] will throw a
  /// [FlutterError] at runtime.
  const QuiHeroSwipeToPopExtension({
    this.scrollController,
    this.threshold = 0.5,
    this.sensibility = 0.5,
    this.onSwipeStateChanged,
  }) : assert(threshold >= 0.0 && threshold <= 1.0, 'commitThreshold must be between 0.0 and 1.0.'),
       assert(sensibility >= 0.0 && sensibility <= 1.0, 'sensibility must be between 0.0 and 1.0.');

  /// An optional scroll controller for scroll-aware swipe-to-pop.
  ///
  /// When provided, the extension only activates swipe-to-pop when the
  /// scroll position is at the top of its scroll extent. See the class
  /// documentation for the full interaction model.
  ///
  /// When `null`, downward swipe always triggers swipe-to-pop.
  final ScrollController? scrollController;

  /// The responsiveness of swipe progress to the user's finger movement.
  ///
  /// A value of `0.0` makes the gesture less sensitive, so the user must swipe
  /// farther to reach the same closing progress. A value of `1.0` makes the
  /// gesture more sensitive, so a small swipe advances the close progress
  /// quickly.
  ///
  /// This does not change [threshold]. It only changes how quickly
  /// finger movement becomes swipe progress. Must be between `0.0` and `1.0`.
  /// Defaults to `0.5`, which preserves the standard swipe feel.
  final double sensibility;

  /// The fraction of the swipe progress at which releasing commits the pop.
  ///
  /// When the user has swiped at least this far, lifting the finger commits
  /// the pop and dismisses the page. If the swipe progress is below this
  /// threshold, the page animates back to its open position.
  ///
  /// Must be between `0.0` and `1.0`. Defaults to `0.5`.
  final double threshold;

  /// Called whenever the swipe-to-pop lifecycle changes.
  ///
  /// Receives [QuiHeroSwipeToPopState.dragging] when a swipe gesture begins
  /// and [QuiHeroSwipeToPopState.idle] when it ends — whether cancelled,
  /// restored, or committed. Use this to adjust UI elements (for example,
  /// hiding a dismiss handle when the gesture is active).
  final ValueChanged<QuiHeroSwipeToPopState>? onSwipeStateChanged;

  @override
  Widget wrap({required BuildContext context, required Widget child}) {
    return _QuiHeroSwipeToPopExtensionGesture(
      scrollController: scrollController,
      commitThreshold: threshold,
      sensibility: sensibility,
      onSwipeStateChanged: onSwipeStateChanged,
      child: child,
    );
  }
}
