import 'package:flutter/widgets.dart';

import '../qui_hero.dart';
import '../qui_hero_extension/qui_hero_drag_to_close_extension/qui_hero_drag_to_close_extension.dart';
import 'qui_hero_page_route.dart';

/// A [Page] subclass that creates a [QuiHeroPageRoute] for hero transitions
/// between screens.
///
/// ## What it provides
///
/// Using [QuiHeroPage] as the destination page in a navigation operation
/// enables:
///
///  * **Transparent route compositing** — the source route stays visible
///    beneath the hero flight overlay, so the shared element can be seen
///    moving across the original background.
///  * **Reduced-motion support** — when [MediaQuery.disableAnimationsOf]
///    reports `true`, both [transitionDuration] and
///    [reverseTransitionDuration] are overridden to [Duration.zero],
///    disabling all hero animations and showing the destination immediately.
///  * **Drag-to-close** — when paired with
///    [QuiHeroDragToCloseExtension]`({...})`, the route exposes an
///    interactive-pop API that the extension drives.
///
/// ## Usage
///
/// Use [QuiHeroPage] in your `pageBuilder` callback:
///
/// ```dart
/// Navigator.of(context).push(
///   PageRouteBuilder(
///     pageBuilder: (context, animation, secondaryAnimation) =>
///         QuiHeroPage(
///           builder: (_) => const JobDetailScreen(feedJob: feedJob),
///         ),
///   ),
/// );
/// ```
///
/// Or with [showGeneralDialog] / [Navigator.push]:
///
/// ```dart
/// Navigator.of(context).push(
///   QuiHeroPageRoute(
///     builder: (_) => const JobDetailScreen(feedJob: feedJob),
///     transitionDuration: const Duration(milliseconds: 560),
///     reverseTransitionDuration: const Duration(milliseconds: 430),
///   ),
/// );
/// ```
///
/// See also:
///  * [QuiHeroPageRoute], the route created by this page that manages hero
///    animations and the interactive-pop API.
///  * [QuiHero], the hero widget that flies between the source route and
///    this page.
///  * [QuiHeroDragToCloseExtension], the extension that wires drag gestures
///    to the route's interactive-pop API.
class QuiHeroPage extends Page<void> {
  /// Creates a [QuiHeroPage].
  ///
  /// The [builder] is called by [QuiHeroPageRoute.buildPage] to produce the
  /// destination content.
  const QuiHeroPage({
    required this.builder,
    this.transitionDuration = defaultTransitionDuration,
    this.reverseTransitionDuration = defaultReverseTransitionDuration,
    super.key,
  });

  /// How long the forward hero transition lasts.
  ///
  /// Defaults to 560 ms — a duration long enough to feel smooth and
  /// deliberate but short enough to feel responsive on mid-range devices.
  ///
  /// Automatically overridden to [Duration.zero] when
  /// [MediaQuery.disableAnimationsOf] returns `true`.
  static const defaultTransitionDuration = Duration(milliseconds: 560);

  /// How long the reverse hero transition (pop) lasts.
  ///
  /// Defaults to 430 ms — shorter than the forward transition to feel snappy
  /// on dismissal.
  ///
  /// Automatically overridden to [Duration.zero] when
  /// [MediaQuery.disableAnimationsOf] returns `true`.
  static const defaultReverseTransitionDuration = Duration(milliseconds: 430);

  /// Called by [QuiHeroPageRoute] to build the page content.
  ///
  /// The [BuildContext] is the route's context and has access to [Navigator],
  /// [MediaQuery], and [QuiHeroPageRoute.maybeOf].
  final WidgetBuilder builder;

  /// The duration of the forward hero transition.
  ///
  /// Automatically overridden to [Duration.zero] when
  /// [MediaQuery.disableAnimationsOf] returns `true`.
  final Duration transitionDuration;

  /// The duration of the reverse hero transition (pop).
  ///
  /// Automatically overridden to [Duration.zero] when
  /// [MediaQuery.disableAnimationsOf] returns `true`.
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
