import 'package:flutter/widgets.dart';

import 'qui_hero_page_route.dart';

/// A [Page] subclass that creates a [QuiHeroPageRoute] for seamless hero
/// transitions between screens.
///
/// Automatically respects [MediaQuery.disableAnimationsOf] — when reduced
/// motion is enabled, [transitionDuration] and [reverseTransitionDuration]
/// are overridden to [Duration.zero], disabling all hero animations.
///
/// Use [QuiHeroPage] in your `pageBuilder` to enable:
///   * Transparent route compositing so the source route
///     stays visible beneath the hero flight during the transition.
///   * [HeroMode] gating for reduced-motion accessibility.
///   * Interactive drag-to-close via QuiHeroDragToCloseExtension.
///
/// ```dart
/// QuiHeroPage(
///   builder: (_) => MyHeroDestination(feedJob: feedJob),
/// )
/// ```
///
/// See also:
///   * [QuiHeroPageRoute], the route that manages the hero animation.
///   * QuiHeroDragToCloseExtension, the extension that wires drag gestures
///     to the route's interactive-pop API.
class QuiHeroPage extends Page<void> {
  /// Creates a [QuiHeroPage].
  ///
  /// The [builder] is called from [QuiHeroPageRoute.buildPage] to produce the
  /// destination content.
  const QuiHeroPage({
    required this.builder,
    this.transitionDuration = defaultTransitionDuration,
    this.reverseTransitionDuration = defaultReverseTransitionDuration,
    super.key,
  });

  /// Default transition duration for the hero flight (560 ms).
  static const defaultTransitionDuration = Duration(milliseconds: 560);

  /// Default reverse transition duration (430 ms).
  static const defaultReverseTransitionDuration = Duration(milliseconds: 430);

  /// Called by [QuiHeroPageRoute] to build the page content.
  final WidgetBuilder builder;

  /// Duration of the forward hero transition.
  ///
  /// Automatically overridden to [Duration.zero] when
  /// [MediaQuery.disableAnimationsOf] is true.
  final Duration transitionDuration;

  /// Duration of the reverse hero transition (pop).
  ///
  /// Automatically overridden to [Duration.zero] when
  /// [MediaQuery.disableAnimationsOf] is true.
  final Duration reverseTransitionDuration;

  @override
  Route<void> createRoute(BuildContext context) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return QuiHeroPageRoute(
      builder: builder,
      transitionDuration: disableAnimations ? Duration.zero : transitionDuration,
      reverseTransitionDuration: disableAnimations ? Duration.zero : reverseTransitionDuration,
      settings: this,
    );
  }
}
